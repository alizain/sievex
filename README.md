# Sievex

Sievex is a flexible permissions library for Elixir.

Usually, other libraries Unlike other libraries, Sievex applies each rule in-order until one returns an `:allow` or `:deny`. It also takes advantage of Elixir's pattern matching, by automatically ignoring rules that don't match.

Here's a simple example:

```elixir
defmodule AdminRuleset do
  use Sievex.Ruleset, fallback: :deny

  check "is superuser", (%{type: "superuser"}, _action, _subject -> :allow)
  check "allow all reads", (_user, :show, _subject -> :allow)
end

assert {:allow, nil} == AdminRuleset.apply(%{type: "user"}, :show, nil)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sievex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sievex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/sievex](https://hexdocs.pm/sievex).
