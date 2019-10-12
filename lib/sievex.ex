defmodule Sievex do
  @moduledoc ~S"""
  Define functions where _all_ matching clauses are executed in order until
  the first one returns a result.
  """

  require Logger

  @default_opts [
    log_compiled_sieve: false,
    continue: :pass,
    fallback: nil
  ]

  @doc ~S"""
  Defines a sieve.

  ## Example

      defsieve my_rules(user, subject) do
        %User{is_admin: true}, _subject ->
          :allow

        %User{id: user_id}, %Post{created_by_id: ^user_id} ->
          :allow
      end

      :allow == my_rules(%User{is_admin: true}, %Post{id: 7})
  """
  defmacro defsieve(method, opts) do
    # Don't change this order! We rely on `Keyword.fetch/2` to return the first
    # matching key from a list, thereby implicitly always returning a passed-in
    # opt before returning the default
    opts = opts ++ @default_opts

    {func_name, func_args} = Macro.decompose_call(method)

    module_func_name = gen_module_func_name(__CALLER__, func_name, func_args)

    body =
      case Keyword.fetch(opts, :do) do
        # For no do-blocks
        :error ->
          Keyword.fetch!(opts, :fallback)

        # For empty do-blocks
        {:ok, {:__block__, _, []}} ->
          Keyword.fetch!(opts, :fallback)

        # All other cases
        {:ok, func_clauses} ->
          if is_valid_syntax?(func_clauses) do
            gen_body(func_clauses, func_args, opts)
          else
            raise SyntaxError,
              line: __CALLER__.line,
              file: __CALLER__.file,
              description: "Invalid syntax in #{module_func_name} sieve"
          end
      end

    quoted =
      quote do
        defp unquote(func_name)(unquote_splicing(func_args)) do
          unquote(body)
        end
      end

    if Keyword.fetch!(opts, :log_compiled_sieve) do
      IO.puts("\n# Generated sieve for #{module_func_name}\n#{Macro.to_string(quoted)}")
    end

    quoted
  end

  @doc false
  defmacro defsieve(method, opts, body) do
    opts = opts ++ body

    quote do
      defsieve(unquote(method), unquote(opts))
    end
  end

  defp is_valid_syntax?(func_clauses) when is_list(func_clauses) do
    Enum.all?(func_clauses, fn
      {:->, _, _} -> true
      _clause -> false
    end)
  end

  defp is_valid_syntax?(_func_clauses) do
    false
  end

  defp gen_body(func_clauses, func_args, opts) when is_list(func_clauses) do
    continue = Keyword.fetch!(opts, :continue)

    match_always_clause = gen_match_always_clause(length(func_args), continue)

    func_clauses
    |> Enum.map(&gen_tupelized_clause/1)
    |> Enum.reverse()
    |> gen_nested_cases(func_args, [match_always_clause: match_always_clause] ++ opts)
  end

  defp gen_nested_cases(func_clauses, func_args, opts) do
    gen_nested_cases(func_clauses, func_args, opts, nil)
  end

  defp gen_nested_cases([], _func_args, _opts, acc) do
    acc
  end

  defp gen_nested_cases([this_clause | rem_clauses], func_args, opts, acc) do
    continue = Keyword.fetch!(opts, :continue)

    match_always_clause = Keyword.fetch!(opts, :match_always_clause)

    clauses = [this_clause] ++ match_always_clause

    fallback_clause =
      case acc do
        nil ->
          Keyword.fetch!(opts, :fallback)

        _acc ->
          acc
      end

    cases =
      quote do
        case {unquote_splicing(func_args)} do
          unquote(clauses)
        end
        |> case do
          unquote(continue) ->
            unquote(fallback_clause)

          result ->
            result
        end
      end

    gen_nested_cases(rem_clauses, func_args, opts, cases)
  end

  defp gen_continue_vars(arity) do
    Enum.map(0..(arity - 1), fn _ ->
      Macro.var(:_, nil)
    end)
  end

  defp gen_match_always_clause(arity, continue) do
    continue_vars = gen_continue_vars(arity)

    quote do
      {unquote_splicing(continue_vars)} -> unquote(continue)
    end
  end

  defp gen_tupelized_clause({:->, opts, [vars | body]}) do
    {:->, opts, [[List.to_tuple(vars)]] ++ body}
  end

  defp gen_module_name(%{module: module}) do
    gen_module_name(module)
  end

  defp gen_module_name(module) when is_atom(module) do
    module |> Module.split() |> Enum.join(".")
  end

  defp gen_module_func_name(module, func_name, func_args) do
    "#{gen_module_name(module)}.#{func_name}/#{length(func_args)}"
  end
end
