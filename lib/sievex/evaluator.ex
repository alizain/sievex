defmodule Sievex.Evaluator do
  alias Sievex.Errors

  defstruct args: [], ruleset: [], fallback: :deny, arity: 3

  @meaningful_results [:deny, :allow]
  @passthrough_result nil

  # @allowed_results [ @passthrough_result | @meaningful_results ]

  def evaluate(args, ruleset, opts) do
    opts
    |> validate_config()
    |> case do
      {:ok, config} ->
        config
        |> Map.merge(%{
          args: args,
          ruleset: ruleset
        })
        |> apply_ruleset()

      {:error, _reason} = error ->
        error
    end
  end

  def validate_config!(config) do
    case validate_config(config) do
      {:ok, config} ->
        config

      {:error, message} ->
        raise Errors.ConfigError, message
    end
  end

  def validate_config(%__MODULE__{} = config) do
    cond do
      not Enum.member?(@meaningful_results, config.fallback) ->
        {:error, "Invalid value for `:fallback`"}

      true ->
        {:ok, config}
    end
  end

  def validate_config(%{} = raw_opts) do
    __MODULE__
    |> struct(raw_opts)
    |> validate_config()
  end

  def validate_config(raw_opts) when is_list(raw_opts) do
    raw_opts
    |> Enum.into(%{})
    |> validate_config()
  end

  def apply_ruleset(%__MODULE__{ruleset: [], fallback: fallback}) do
    {fallback, "fallback"}
  end

  def apply_ruleset(
        %__MODULE__{args: args, ruleset: [rule | remaining_ruleset], arity: arity} = config
      ) do
    rule
    |> apply_rule(args, arity)
    |> case do
      result when result in @meaningful_results ->
        {result, nil}

      {result, _reason} = result_tuple when result in @meaningful_results ->
        result_tuple

      @passthrough_result ->
        config
        |> Map.put(:ruleset, remaining_ruleset)
        |> apply_ruleset()

      result ->
        raise Errors.RuleResultError, result
    end
  end

  def apply_rule({module, func}, args, arity) do
    if function_exported?(module, func, arity) do
      apply(module, func, args)
    else
      raise Errors.RuleError, "#{func}/#{arity} could not be found in #{module}"
    end
  end

  def apply_rule(func, args, _arity) when is_function(func) do
    apply(func, args)
  end

  def apply_rule(_rule, _args, _arity) do
    raise Errors.RuleError, "invalid rule"
  end
end
