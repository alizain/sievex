Faker.start()

defmodule Benchmark do
  defmacro generate({:__aliases__, opts, module}) do
    quote do
      defmodule unquote({:__aliases__, opts, module}) do
        import unquote({:__aliases__, [alias: false], [Elixir | module]})

        defsieve something(user_id, other), fallback: :a, noop: nil do
          1, _ ->
            IO.inspect("haha")

            # some comment

            _ = 1 + 1

            :allow

          2, _ ->
            nil

          3, _ ->
            :deny

          4, _ ->
            IO.inspect("haha")

            # some comment

            _ = 1 + 1

            :allow

          5, _ ->
            nil

          6, _ ->
            :deny

          7, _ ->
            :deny

          8, _ ->
            :deny

          9, _ ->
            :deny
        end
      end
    end
  end
end

defmodule Cases do
  import Benchmark

  generate(Sievex)
  # generate(SievexFuncCase)
  # generate(SievexFuncReduce)
end

Benchee.run(
  %{
    "Sievex" => fn {digit, letter} ->
      Cases.Sievex.something(digit, letter)
    end,
    "SievexFuncCase" => fn {digit, letter} ->
      Cases.SievexFuncCase.something(digit, letter)
    end,
    "SievexFuncReduce" => fn {digit, letter} ->
      Cases.SievexFuncReduce.something(digit, letter)
    end
  },
  before_each: fn _input -> {Faker.Util.digit(), Faker.Util.letter()} end,
  warmup: 2,
  time: 5
)
