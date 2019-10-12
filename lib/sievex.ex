# The story:
# - as a module
# - as defsieve with anon funcs and Enum.reduce
# - switch to anon funcs and case statements
# - switch to pure case statements with {} wrapping
# - sievedocs
# - better error reporting with __CALLER__
# - damn guards, back to anon funcs?
# - okay, guard clauses works with cases and {} wrapping!
# - optional wrapped result, and optional metadata!

defmodule Sievex do
  @moduledoc ~S"""
  Define functions where _all_ matching clauses are executed in order until
  the first one returns a result.
  """

  require Logger

  @default_opts [
    log_compiled_sieve: false,
    return_wrapped: false,
    return_metadata: false,
    continue: :pass,
    fallback: nil,
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
          validate_syntax!(func_clauses, __CALLER__)

          gen_body(func_clauses, func_args, opts, __CALLER__)
      end

    quoted =
      quote do
        def unquote(func_name)(unquote_splicing(func_args)) do
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

  defp validate_syntax!(func_clauses, env) when is_list(func_clauses) do
    Enum.each(func_clauses, fn
      {:->, _, _} -> nil
      {_, opts, _} ->
        raise SyntaxError,
          line: Keyword.get(opts, :line, env.line),
          file: env.file,
          description: "Invalid syntax for sieve"
    end)
  end

  defp validate_syntax!(_func_clauses, env) do
    raise SyntaxError,
      line: env.line,
      file: env.file,
      description: "Invalid syntax for sieve"
  end

  defp gen_body(func_clauses, func_args, opts, env) when is_list(func_clauses) do
    continue = Keyword.fetch!(opts, :continue)

    func_arity = length(func_args)
    match_always_clause = gen_match_always_clause(func_arity, continue)

    func_clauses
    |> Enum.map(&gen_tupelized_clause(&1, func_arity))
    |> Enum.map(&gen_clause_metadata(&1, env))
    |> gen_nested_cases(func_args, [match_always_clause: match_always_clause] ++ opts)
  end

  defp gen_clause_metadata({:->, clause_opts, [clause_head | clause_rem]}, env) do
    {filtered_clause_rem, filtered_clause_metadata} =
      case clause_rem do
        [{:__block__, clause_block_opts, clause_block_body}] ->
          {filtered_clause_block_body, filtered_clause_metadata} =
            extract_metadata_from_block(clause_block_body)

          {[{:__block__, clause_block_opts, filtered_clause_block_body}], filtered_clause_metadata}

        clause_rem ->
          extract_metadata_from_block(clause_rem)
      end
      |> case do
        {[], filtered_clause_metadata} ->
          # We need to handle cases where users have added metadata statements, without
          # any other information. Now the problem is that when the Elixir parser normally
          # runs across such a case, it prints a warning and automatically injects a `nil`
          # statement. This is not handled in the `case` statement itself. If we continue
          # with the filtered list, Elixir will raise the following error (expected ->
          # clauses for :do in "case"). So we will manually print the same error and
          # inject a nil statement.
          IO.warn(
            "an expression is always required on the right side of ->. " <>
            "Please provide a value after ->",
            Macro.Env.stacktrace(%{env | line: Keyword.fetch!(clause_opts, :line)})
          )

          {[nil], filtered_clause_metadata}

        filtered ->
          filtered
      end

    {{:->, clause_opts, [clause_head] ++ filtered_clause_rem}, filtered_clause_metadata}
  end

  defp extract_metadata_from_block(block_stmts) do
    {stmts, metadata} =
      Enum.reduce(block_stmts, {[], %{}}, fn
        {:@, _, [{:sievedoc, _, [doc_body]}]}, {acc_stmts, acc_metadata} ->
          {acc_stmts, Map.put(acc_metadata, :doc, doc_body)}

        stmt, {acc_stmts, acc_metadata} ->
          {[stmt | acc_stmts], acc_metadata}
      end)

    {Enum.reverse(stmts), metadata}
  end

  defp gen_nested_cases(func_clauses, func_args, opts) do
    func_clauses
    |> Enum.reverse
    |> gen_nested_cases(func_args, opts, nil)
  end

  defp gen_nested_cases([], _func_args, _opts, acc) do
    acc
  end

  defp gen_nested_cases([{this_clause, this_metadata} | rem_clauses], func_args, opts, acc) do
    continue = Keyword.fetch!(opts, :continue)
    match_always_clause = Keyword.fetch!(opts, :match_always_clause)
    return_wrapped = Keyword.fetch!(opts, :return_wrapped)
    return_metadata = Keyword.fetch!(opts, :return_metadata)

    quoted_metadata =
      quote do
        %Sievex.Metadata{
          doc: unquote(this_metadata[:doc])
        }
      end

    fallback_body =
      case acc do
        nil ->
          if return_wrapped == true do
            {:fallback, Keyword.fetch!(opts, :fallback)}
          else
            Keyword.fetch!(opts, :fallback)
          end

        _acc ->
          acc
      end

    result_clause =
      cond do
        return_wrapped == true && return_metadata == true ->
          quote do
            {:result, result, unquote(quoted_metadata)}
          end

        return_wrapped == true ->
          quote do
            {:result, result}
          end

        return_metadata == true ->
          quote do
            {result, unquote(quoted_metadata)}
          end

        true ->
          quote do
            result
          end
      end

    clauses = [this_clause] ++ match_always_clause

    cases =
      quote do
        case {unquote_splicing(func_args)} do
          unquote(clauses)
        end
        |> case do
          unquote(continue) ->
            unquote(fallback_body)

          result ->
            unquote(result_clause)
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

  defp gen_tupelized_clause({:->, opts, [[{:when, when_opts, when_body}] | body]}, arity) do
    {vars, [{_, _, _}] = guard_clause} =
      Enum.split(when_body, arity)

    when_clause = {:when, when_opts, [List.to_tuple(vars) | guard_clause]}

    {:->, opts, [[when_clause] | body]}
  end

  defp gen_tupelized_clause({:->, opts, [vars | body]}, _arity) do
    {:->, opts, [[List.to_tuple(vars)] | body]}
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
