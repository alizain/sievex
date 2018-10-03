defmodule SievexTest do
  use ExUnit.Case
  doctest Sievex

  describe "Sievex.Rules" do
    require Sievex.Rules
    import Sievex.Rules

    test "check_if_match/1 works correctly" do
      func = check_if_match (user, _action, _subjcet when user in [1, 2] -> :allow)
      assert func.(2, nil, nil) == :allow
    end

    test "check_if_match/1 returns nil if no match" do
      func = check_if_match (user, _action, _subjcet when user in [1, 2] -> :allow)
      assert func.(3, nil, nil) == nil
    end
  end
end
