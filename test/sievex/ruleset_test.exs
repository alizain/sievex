defmodule SievexTest.Ruleset do
  use ExUnit.Case

  describe "TestA" do
    defmodule TestA do
      use Sievex.Ruleset, arity: 2, fallback: :deny
    end

    test "defines `ruleset/0`" do
      assert [] == TestA.ruleset()
    end

    test "defines `opts/0`" do
      assert %{arity: 2, fallback: :deny} == TestA.opts() |> Map.take([:arity, :fallback])
    end

    test "defines `apply/?`" do
      assert {:deny, "fallback"} == TestA.apply(nil, nil)
    end
  end

  describe "TestB" do
    defmodule TestB do
      use Sievex.Ruleset, arity: 3, fallback: :allow

      check :check_thing

      def check_thing(_, _, _) do
        :deny
      end
    end

    test "`check/1` works with atoms" do
      assert [{TestB, :check_thing}] == TestB.ruleset()
    end

    test "apply/3 works correctly" do
      assert {:deny, nil} == TestB.apply(nil, nil, nil)
    end
  end

  describe "TestC" do
    defmodule TestCPermissions do
      def suzuki(%{role: :super}) do
        {:allow, "found a superuser"}
      end

      def suzuki(%{role: role}) when role in [:user, :moderator] do
        {:deny, "uhoh, just a #{role}"}
      end

      def suzuki(_) do
        nil
      end
    end

    defmodule TestC do
      use Sievex.Ruleset, arity: 1, fallback: :deny

      check "suzuki", &TestCPermissions.suzuki/1
    end

    test "`check/2` works with captured functions" do
      func_name = String.to_atom("auto check suzuki")
      assert [{TestC, func_name}] == TestC.ruleset()
      assert true == function_exported?(TestC, func_name, 1)
    end

    test "apply/1 works correctly" do
      assert {:allow, "found a superuser"} == TestC.apply(%{role: :super})
      assert {:deny, "uhoh, just a user"} == TestC.apply(%{role: :user})
      assert {:deny, "uhoh, just a moderator"} == TestC.apply(%{role: :moderator})
      assert {:deny, "fallback"} == TestC.apply(%{})
    end
  end

  describe "TestD" do
    defmodule TestD do
      use Sievex.Ruleset, arity: 2, fallback: :deny

      check "kilimanjaro", (user, _action when user in [1, 2] -> :allow)
    end

    test "`check/2` works with anonymous expressions" do
      func_name = String.to_atom("auto check kilimanjaro")
      assert [{TestD, func_name}] == TestD.ruleset()
      assert true == function_exported?(TestD, func_name, 2)
    end

    test "apply/2 works correctly" do
      assert {:allow, nil} == TestD.apply(1, :save)
      assert {:deny, "fallback"} == TestD.apply(4, :save)
    end
  end
end
