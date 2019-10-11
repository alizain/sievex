defmodule SievexModuleAttrs.Ruleset do
  @apply_fn_name :apply

  defmacro __using__(opts) do
    quote location: :keep do
      import SievexModuleAttrs.Ruleset

      Module.register_attribute(__MODULE__, :sievex_raw, accumulate: true)
      Module.register_attribute(__MODULE__, :sievex_ruleset, accumulate: true)

      Module.put_attribute(
        __MODULE__,
        :sievex_opts,
        SievexModuleAttrs.Evaluator.validate_config!(unquote(opts))
      )

      @before_compile SievexModuleAttrs.Ruleset
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    opts = Module.get_attribute(module, :sievex_opts)
    raw = Module.get_attribute(module, :sievex_raw)

    rules = generate_rules(raw, opts.arity, nil)
    apply = generate_apply(@apply_fn_name, opts.arity, nil)
    access = generate_access()

    quote do
      unquote(rules)
      unquote(apply)
      unquote(access)
    end
  end

  defmacro check(func_name) when is_atom(func_name) do
    quote do
      @sievex_raw {unquote(func_name)}
    end
  end

  defmacro check(description, expr) when is_binary(description) do
    expr_escaped = Macro.escape(expr)

    quote do
      @sievex_raw {unquote(description), unquote(expr_escaped)}
    end
  end

  def generate_rules(rules, arity, context) when is_list(rules) do
    Enum.map(rules, &generate_rule(&1, arity, context))
  end

  def generate_rule({func_name}, _arity, _context) do
    quote do
      @sievex_ruleset {__MODULE__, unquote(func_name)}
    end
  end

  def generate_rule({description, expr}, arity, context) do
    func_args = Macro.generate_arguments(arity, context)
    func_name = String.to_atom("auto check " <> description)
    func_anon = SievexModuleAttrs.Expression.compile(expr, arity, context)

    quote do
      def unquote(func_name)(unquote_splicing(func_args)) do
        unquote(func_anon).(unquote_splicing(func_args))
      end

      @sievex_ruleset {__MODULE__, unquote(func_name)}
    end
  end

  def generate_apply(func_name, arity, context) do
    func_args = Macro.generate_arguments(arity, context)

    quote do
      def unquote(func_name)(unquote_splicing(func_args)) do
        SievexModuleAttrs.Evaluator.evaluate(unquote(func_args), ruleset(), opts())
      end
    end
  end

  def generate_access() do
    quote do
      def opts do
        @sievex_opts
      end

      def ruleset do
        @sievex_ruleset |> Enum.reverse()
      end
    end
  end
end
