defmodule SievexTest.Ruleset do
  use ExUnit.Case

  describe "`use Sievex.Ruleset`" do
    test "works" do

      defmodule TestRuleset do
        use Sievex.Ruleset, fallback: :deny

        check :check_thing
        check "check another thing", &__MODULE__.check_thing/3
        check "allow superusers", (%{role: role}, _action, _subject when role in [:super] -> :allow)

        def check_thing(_user, _action, _subject) do
          nil
        end
      end

      assert {:allow, nil} == TestRuleset.apply(%{role: :super}, nil, nil)
    end
  end
end
