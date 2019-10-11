defmodule SievexFuncReduceTest do
  use ExUnit.Case
  import SievexFuncReduce

  defmodule TestA do
    defsieve something(user_id, other), fallback: :a, noop: nil do
      1, _ ->
        IO.inspect("haha")

        # some comment

        _ = 1 + 1

        :allow

      2, _ ->
        nil

      2, _ ->
        :deny
    end
  end

  test "basic" do
    assert :deny == TestA.something(2, 2)
  end
end
