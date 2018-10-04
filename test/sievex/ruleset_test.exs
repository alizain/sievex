defmodule SievexTest.Ruleset do
  use ExUnit.Case

  describe "`use Sievex.Ruleset`" do
    test "works" do

      defmodule TestRuleset do
        use Sievex.Ruleset, fallback: :deny
        require Sievex.Rules

        check_if_match "allow superusers",
          (%{super: true}, action, _subject when action in [1, 2] -> :allow)

      end

      assert {:allow, nil} == TestRuleset.apply(%{super: true}, 1, nil)
    end
  end
end
