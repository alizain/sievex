defmodule SievexTest.Rules do
  use ExUnit.Case
  require Sievex.Rules
  import Sievex.Rules

  describe "check_if_match/1" do
    test "works" do
      func = check_if_match (user, _action, _subjcet when user in [1, 2] -> :allow)
      assert func.(2, nil, nil) == :allow
    end

    test "returns nil if no match" do
      func = check_if_match (user, _action, _subjcet when user in [1, 2] -> :allow)
      assert func.(3, nil, nil) == nil
    end
  end
end
