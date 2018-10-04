defmodule Sievex.Expression do
  @arity 3

  def no_op(context, arity \\ @arity) do
    variables = Enum.map 0..(arity - 1), fn _ ->
      Macro.var(:_, context)
    end
    quote do
      unquote_splicing(variables) -> nil
    end
  end

  def compile([{:->, _opts, _block}] = expr, context) do
    {:fn, [], expr ++ no_op(context)}
  end

  def compile({:&, _opts, _block} = expr, _context) do
    expr
  end

  def compile(_args, _context) do
    raise ArgumentError, "invalid expression for `check_if_match/1`"
  end
end
