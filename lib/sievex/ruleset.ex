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

  defmacro __before_compile__(env) do
    context = env.module
    func_args = Macro.generate_arguments(@arity, context)
    func_name = :apply
    quote do
      def opts do
        @sievex_opts
      end

      def ruleset do
        @sievex_ruleset |> Enum.reverse()
      end

      def unquote(func_name)(unquote_splicing(func_args)) do
        Sievex.Evaluator.evaluate(unquote(func_args), ruleset(), opts())
      end
    end
  end

  defmacro check(func_name) when is_atom(func_name) do
    quote do
      @sievex_ruleset {__MODULE__, unquote(func_name)}
    end
  end

  defmacro check(description, expr) do
    context = __CALLER__.module
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
