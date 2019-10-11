defmodule SievexFuncCase do
  defmodule Expression do
    def no_op(arity, context, opts) do
      variables =
        Enum.map(0..(arity - 1), fn _ ->
          Macro.var(:_, context)
        end)

      noop = Keyword.fetch!(opts, :noop)

      quote do
        unquote_splicing(variables) -> unquote(noop)
      end
    end

    def compile({:->, _opts, _block} = expr, arity, context, opts) do
      {:fn, [], [expr] ++ no_op(arity, context, opts)}
    end

    def compile(_expr, _arity, _context, _opts) do
      raise ArgumentError, "invalid expression"
    end
  end

  @default_opts [
    noop: :pass,
    fallback: nil
  ]

  defmacro defsieve(method, body) do
    quote do
      defsieve(unquote(method), [], unquote(body))
    end
  end

  defmacro defsieve(method, opts, body) do
    # Don't change this order! We rely on `Keyword.fetch/2` to return the first
    # matching key from a list, thereby implicitly always returning a passed-in
    # opt before returning the default
    opts = opts ++ @default_opts

    {func_name, func_args} = Macro.decompose_call(method)
    func_arity = length(func_args)
    func_body = Keyword.fetch!(body, :do)

    exprs =
      func_body
      |> Enum.map(&Expression.compile(&1, func_arity, nil, opts))
      |> generate_nested(func_args, opts)

    quoted =
      quote do
        def unquote(func_name)(unquote_splicing(func_args)) do
          unquote(exprs)
        end
      end

    # Macro.to_string(quoted) |> IO.puts

    quoted
  end

  def generate_nested([], _func_args, opts) do
    Keyword.fetch!(opts, :fallback)
  end

  def generate_nested([expr | rem_exprs], func_args, opts) do
    noop = Keyword.fetch!(opts, :noop)
    nested = generate_nested(rem_exprs, func_args, opts)

    quote do
      case unquote(expr).(unquote_splicing(func_args)) do
        unquote(noop) ->
          unquote(nested)

        result ->
          result
      end
    end
  end
end
