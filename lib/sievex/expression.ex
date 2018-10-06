defmodule Sievex.Expression do
  def no_op(arity, context) do
    variables =
      Enum.map 0..(arity - 1), fn _ ->
        Macro.var(:_, context)
      end
    quote do
      unquote_splicing(variables) -> nil
    end
  end

  def compile([{:->, _opts, _block}] = expr, arity, context) do
    {:fn, [], expr ++ no_op(arity, context)}
  end

  def compile({:&, _opts, _block} = expr, _arity, _context) do
    expr
  end

  def compile(_args, _arity, _context) do
    raise ArgumentError, "invalid expression for `check_if_match/1`"
  end
end
