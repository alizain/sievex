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

## Discussion

So this library started off with a simple problem: Elixir's pattern-matching is really great when you want a specific clause to be executed. However, there are certain domains where it is useful to execute _all_ clauses that match until the first one returns. I encountered this need was modelling permissions.

(While writing this, I realized that Phoenix `plug`s do pretty much the exact same thing, except for processing web-requests.)

As with plugs, I'd like to break down permissions into smaller functions that are responsible for checking less things than everything else.

### The Strawman

The basic API for defining a rule is:

```elixir
@type result_atom() :: :allow | :deny
@type result_atom_with_reason() :: {result_atom(), any()}
@type result() :: result_atom() | result_atom_with_reason()
@type action() :: [atom()]

@spec rule(any(), action(), any()) :: result()
def rule(subject, action, object)
```

**Aside:** If you've done permissions in the past with Elixir, you might notice that this is essentially the [`Canada.Can`](https://github.com/jarednorman/canada) API. There is one difference though: the `action()` type. I find passing _a list_ of atoms is a lot easier to pattern match against, especially when we want to grant a user access to all sub-actions without explicitly creating a rule for each and every one.

A collection of these rules in a list defines the "permissions" for our app.

```elixir
list_of_rules =
  [
    # Everyone is allowed to access the `:listing` module.
    fn %{}, [:admin, :listing], _subject ->
      :allow
    end,
    # Everyone is allowed to do the `:index` and `:create` action (or any sub-action of those two) on the `:listing` module.
    fn %{}, [:admin, :listing, action | _], _subject when action in [:index, :create] ->
      :allow
    end,
    # If the user doing the action is the same as user that created the listing and if the action is part of an explicit whitelist (`@creator_allowed_actions`), allow the action.
    fn %{id: user_id}, [:admin, :listing, action | _], %Listing{created_by_id: user_id} when action in @creator_allowed_actions ->
      :allow
    end,
    # Allow all actions if the user doing the action is an "admin" for the region this listing is associated with.
    fn %{region_roles: user_region_roles}, [:admin, :listing | _], %Listing{region_id: listing_region_id} ->
      if user_region_roles[listing_region_id] == "admin" do
        :allow
      end
    end
  ]
```

With this strawman API, I've been able to break-down permissions into modular chunks where each function is only responsible for checking a specific condition. Now we need something to evaluate these rules.

The basic properties of the Evaluator API are:
- apply each rule in order
- if the rule returns `nil`, move onto the next rule in the list
- if the rule returns the `result()` type, return that back to the caller and stop further execution
- if there are no more rules left to apply, return some fallback

Notice, there are
