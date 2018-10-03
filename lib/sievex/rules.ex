defmodule Sievex.Rules do
  @no_op quote do: (_user, _action, _subject -> nil)

  defmacro check_if_match([{:->, _opts, _block}] = branches) do
    {:fn, [], branches ++ @no_op}
  end

  # defmacro check_if_match({:fn, opts, branches}) do
  #   {:fn, opts, branches ++ @no_op}
  # end

  # defmacro check_if_match({:&, _opts, _block} = expr) do
  #   expr
  # end

  defmacro check_if_match(_) do
    raise ArgumentError, "invalid expression for `check_if_match/1`"
  end

  defmacro allow(expected_user, expected_action, expected_subject) do
    quote do
      check_if_match (unquote(expected_user), unquote(expected_action), unquote(expected_subject) -> :allow)
    end
  end

  defmacro deny(expected_user, expected_action, expected_subject) do
    quote do
      check_if_match (unquote(expected_user), unquote(expected_action), unquote(expected_subject) -> :deny)
    end
  end
end
