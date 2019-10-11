defmodule SievexBench.Sievex do
  import Sievex

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

Benchee.run(%{
  "Sievex" => fn ->
    SievexBench.Sievex.something(:a, 2)
  end,
}, warmup: 2, time: 5)
