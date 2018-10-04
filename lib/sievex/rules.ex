defmodule Sievex.Rules do
  @arity 3

  @no_op (
    case @arity do
      1 -> quote do: (_context -> nil)
      3 -> quote do: (_user, _action, _subject -> nil)
    end
  )

  defmacro check_if_match([{:->, _opts, _block}] = branches) do
    {:fn, [], branches ++ @no_op}
  end

  # defmacro check_if_match({:fn, opts, branches}) do
  #   {:fn, opts, branches ++ @no_op}
  # end

  # defmacro check_if_match({:&, _opts, _block} = expr) do
  #   expr
  # end

  defmacro check_if_match(_args) do
    raise ArgumentError, "invalid expression for `check_if_match/1`"
  end
end
