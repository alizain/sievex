defmodule Sievex do
  require Logger

  @default_opts [
    noop: :pass,
    fallback: nil
  ]

  defmacro defsieve(method, opts, body) do
    opts = opts ++ body
    quote do
      defsieve(unquote(method), unquote(opts))
    end
  end

  defmacro defsieve(method, opts) do
    # Don't change this order! We rely on `Keyword.fetch/2` to return the first
    # matching key from a list, thereby implicitly always returning a passed-in
    # opt before returning the default
    opts = opts ++ @default_opts

    {func_name, func_args} = Macro.decompose_call(method)

    case Keyword.fetch(opts, :do) do
      {:ok, func_clauses} ->
        body =
          generate_body(func_clauses, func_args, opts)

        quoted =
          quote do
            def unquote(func_name)(unquote_splicing(func_args)) do
              unquote(body)
            end
          end

        IO.puts ""
        quoted |> Macro.to_string |> IO.puts
        IO.puts ""

        quoted

      :error ->
        Logger.warn "no implementation provided for #{func_name}"
    end
  end

  # For empty do-blocks
  def generate_body({:__block__, _, []}, _func_args, opts) do
    Keyword.fetch!(opts, :fallback)
  end

  # For do-blocks that don't contain clauses
  def generate_body({:__block__, _, _} = func_clauses, _func_args, _opts) do
    Logger.warn "Invalid block syntax"
  end

  # For do-blocks that contain other things
  def generate_body(nil, _func_args, _opts) do
    Logger.warn "Invalid nil syntax"
  end

  # The happy path
  def generate_body(func_clauses, func_args, opts) when is_list(func_clauses) do
    noop = Keyword.fetch!(opts, :noop)
    match_always_clause = generate_match_always_clause(length(func_args), noop)

    func_clauses
    |> Enum.map(&generate_tupelized_clause/1)
    |> Enum.reverse
    |> generate_nested_cases(func_args, [match_always_clause: match_always_clause] ++ opts)
  end

  def generate_nested_cases(func_clauses, func_args, opts) do
    generate_nested_cases(func_clauses, func_args, opts, nil)
  end

  def generate_nested_cases([], _func_args, _opts, acc) do
    acc
  end

  def generate_nested_cases([this_clause | rem_clauses], func_args, opts, acc) do
    noop =
      Keyword.fetch!(opts, :noop)

    match_always_clause =
      Keyword.fetch!(opts, :match_always_clause)

    clauses =
      [this_clause] ++ match_always_clause

    fallback_clause =
      case acc do
        nil ->
          Keyword.fetch!(opts, :fallback)

        _acc ->
          acc
      end

    cases =
      quote do
        {unquote_splicing(func_args)}
        |> case do
          unquote(clauses)
        end
        |> case do
          unquote(noop) ->
            unquote(fallback_clause)

          result ->
            result
        end
      end

    generate_nested_cases(rem_clauses, func_args, opts, cases)
  end

  defp generate_noop_vars(arity) do
    Enum.map(0..(arity - 1), fn _ ->
      Macro.var(:_, nil)
    end)
  end

  defp generate_match_always_clause(arity, noop) do
    noop_vars = generate_noop_vars(arity)
    quote do
      {unquote_splicing(noop_vars)} -> unquote(noop)
    end
  end

  defp generate_tupelized_clause({:->, opts, [vars | body]}) do
    {:->, opts, [[List.to_tuple(vars)]] ++ body}
  end
end
