defmodule SievexTest.Ruleset do
  use ExUnit.Case

  describe "`use Sievex.Ruleset`" do
    test "works" do

      defmodule TestRuleset do
        use Sievex.Ruleset, fallback: :deny

        check :check_another_thing
        check "do something else",
          &__MODULE__.check_another_thing/3
        check "allow superusers",
          (%{super: true}, action, _subject when action in [1, 2] -> :allow)

        def check_another_thing(_user, _action, _subject) do
          nil
        end
      end

      assert {:allow, nil} == TestRuleset.apply(%{super: true}, 1, nil)
    end
  end
end
