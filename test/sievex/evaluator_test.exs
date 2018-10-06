defmodule SievexTest.Evaluator do
  use ExUnit.Case
  import ExUnit.CaptureLog, only: [capture_log: 1]
  alias Sievex.Evaluator

  describe "`validate_config/1`" do
    test "raises when `:fallback` is invalid" do
      [
        %Evaluator{fallback: nil},
        %Evaluator{fallback: "invalid"},
        %Evaluator{fallback: 1_000},
        %Evaluator{fallback: :something},
      ]
      |> Enum.each(fn config ->
        assert {:error, "Invalid value for `:fallback`"} == Evaluator.validate_config(config)
      end)
    end

    test "allows when `:fallback` is valid" do
      [
        %Evaluator{fallback: :allow},
        %Evaluator{fallback: :deny},
      ]
      |> Enum.each(fn config ->
        assert {:ok, config} == Evaluator.validate_config(config)
      end)
    end

    test "converts bare maps to structs" do
      assert {:ok, %Evaluator{fallback: :allow}} == Evaluator.validate_config(%{fallback: :allow})
    end

    test "converts keyword lists to structs" do
      assert {:ok, %Evaluator{fallback: :allow}} == Evaluator.validate_config(fallback: :allow)
    end
  end

  describe "`apply_ruleset/1`" do
    test "falls back when no matching rule is found" do
      config = %Evaluator{
        ruleset: []
      }

      assert Evaluator.apply_ruleset(config) == {:deny, "fallback"}
    end

    test "auto-wrap when the rule returns a bare atom" do
      config = %Evaluator{
        ruleset: [
          fn -> :allow end
        ]
      }

      assert Evaluator.apply_ruleset(config) == {:allow, nil}
    end

    test "allows the rule to return a tuple, that isn't re-wrapped" do
      config = %Evaluator{
        ruleset: [
          fn -> {:deny, "reason..."} end
        ]
      }

      assert Evaluator.apply_ruleset(config) == {:deny, "reason..."}
    end

    test "stops when the first rule returns a valid result" do
      config = %Evaluator{
        ruleset: [
          fn -> {:allow, nil} end,
          fn -> raise "This function should not have executed in the test" end
        ]
      }

      assert Evaluator.apply_ruleset(config) == {:allow, nil}
    end

    test "continues through ruleset if current rule returns `nil`" do
      config = %Evaluator{
        ruleset: [
          fn -> nil end,
          fn -> {:allow, "yes!"} end
        ]
      }

      assert Evaluator.apply_ruleset(config) == {:allow, "yes!"}
    end

    test "executes each rule only once" do
      require Logger

      config = %Evaluator{
        ruleset: [
          fn -> Logger.info "rule no.1 evaluated"; nil end,
          fn -> Logger.info "rule no.2 evaluated"; nil end,
          fn -> Logger.info "rule no.3 evaluated"; nil end,
          fn -> Logger.info "rule no.4 evaluated"; :allow end
        ]
      }

      capture_log(fn ->
        assert Evaluator.apply_ruleset(config) == {:allow, nil}
      end)
      |> String.split("\e[0m\e[22m\n")
      |> Enum.with_index()
      |> Enum.each(fn {msg, index} ->
        assert msg =~ "rule no.#{index + 1} evaluated"
      end)
    end

    test "fails loudly if rule returns something that isn't allowed" do
      config = %Evaluator{
        ruleset: [
          fn -> false end
        ]
      }

      assert_raise(Sievex.Errors.RuleResultError, "false", fn ->
        Evaluator.apply_ruleset(config)
      end)
    end
  end
end
