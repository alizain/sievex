Faker.start()

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

Benchee.run(
  %{
    "Sievex" => fn {digit, letter}->
      SievexBench.Sievex.something(digit, letter)
    end,
  },
  before_each: fn _input -> {Faker.Util.digit(), Faker.Util.letter()} end,
  warmup: 2,
  time: 5
)
