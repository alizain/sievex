defmodule Sievex.Evaluator do
  defstruct args: [], ruleset: [], fallback: :deny

  defmodule RuleInvalidResultError do
    defexception [:message]

    @impl true
    def exception(result) do
      %__MODULE__{message: "#{result}"}
    end
  end

  @meaningful_results [:deny, :allow]
  @passthrough_result nil

  # @allowed_results [ @passthrough_result | @meaningful_results ]

  def evaluate(user, action, subject, ruleset, raw_opts \\ %{}) do
    __MODULE__
    |> struct(raw_opts)
    |> struct(%{
      args: [user, action, subject],
      ruleset: ruleset
    })
    |> validate_config()
    |> case do
      {:ok, config} ->
        apply_ruleset(config)
      {:error, _reason} = error ->
        error
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

  def apply_ruleset(%__MODULE__{ruleset: [], fallback: fallback}) do
    {fallback, "no matching rules found"}
  end

  def apply_ruleset(%__MODULE__{args: args, ruleset: [rule | remaining_ruleset]} = config) do
    rule
    |> apply(args)
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
        raise RuleInvalidResultError, result
    end
  end
end
