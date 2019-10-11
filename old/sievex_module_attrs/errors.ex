defmodule SievexModuleAttrs.Errors do
  defmodule RuleError do
    defexception [:message]

    @impl true
    def exception(message) do
      %__MODULE__{message: message}
    end
  end

  defmodule RuleResultError do
    defexception [:message]

    @impl true
    def exception(result) do
      %__MODULE__{message: "#{result}"}
    end
  end

  defmodule ConfigError do
    defexception [:message]

    @impl true
    def exception(message) do
      %__MODULE__{message: "#{message}"}
    end
  end
end
