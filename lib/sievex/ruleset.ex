defmodule Sievex.Ruleset do
  @arity 3

  defmacro __using__(opts) do
    quote location: :keep do
      import Sievex.Ruleset

      Module.register_attribute(__MODULE__, :sievex_ruleset, accumulate: true)

      @sievex_opts Sievex.Evaluator.validate_config!(unquote(opts))

      @before_compile Sievex.Ruleset
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def opts do
        @sievex_opts
      end

      def ruleset do
        @sievex_ruleset |> Enum.reverse()
      end

      def apply(actor, action, subject) do
        Sievex.Evaluator.evaluate([actor, action, subject], ruleset(), opts())
      end

      # def apply(context) do
      #   Sievex.Evaluator.evaluate([context], ruleset(), opts())
      # end
    end
  end

  defmacro check(func_name) when is_atom(func_name) do
    quote do
      @sievex_ruleset {__MODULE__, unquote(func_name)}
    end
  end

  # TODO: Learn more about how context works!
  defmacro check(description, expr) do
    context = nil
    # [context | _] = __CALLER__.context_modules
    func_args = Macro.generate_arguments(@arity, context)
    func_name = String.to_atom("auto check " <> description)
    func_anon = Sievex.Expression.compile(expr, context)
    quote do
      def unquote(func_name)(unquote_splicing(func_args)) do
        (unquote(func_anon)).(unquote_splicing(func_args))
      end
      @sievex_ruleset {__MODULE__, unquote(func_name)}
    end
  end
end
