defmodule Sievex do
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
      |> Enum.map(&tupelize_vars/1)
      |> generate_nested_cases(func_args, func_arity, opts)

    quote do
      def unquote(func_name)(unquote_splicing(func_args)) do
        unquote(exprs)
      end
    end
  end

  def generate_nested_cases([], _func_args, _func_arity, opts) do
    Keyword.fetch!(opts, :fallback)
  end

  def generate_nested_cases([expr | rem_exprs], func_args, func_arity, opts) do
    rem_exprs = generate_nested_cases(rem_exprs, func_args, func_arity, opts)

    noop = Keyword.fetch!(opts, :noop)
    noop_vars =
      Enum.map(0..(func_arity - 1), fn _ ->
        Macro.var(:_, nil)
      end)
    noop_expr =
      quote do
        {unquote_splicing(noop_vars)} -> unquote(noop)
      end

    exprs = [expr] ++ noop_expr

    quote do
      {unquote_splicing(func_args)}
      |> case do
        unquote(exprs)
      end
      |> case do
        unquote(noop) ->
          unquote(rem_exprs)

        result ->
          result
      end
    end
  end

  defp tupelize_vars({:->, opts, [vars | body]}) do
    {:->, opts, [[List.to_tuple(vars)]] ++ body}
  end
end
