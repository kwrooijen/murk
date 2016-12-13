# Murk

Murk is an Elixir data type validation library.

## Installation
#### Add murk to your list of dependencies in `mix.exs`:
```elixir
  def deps do
    [{:murk, "~> 0.1.0"}]
  end
```

## Usage

Murk provides a few functions for type validation.

```elixir
Murk.type(:test)          #=> :atom
Murk.type("test")         #=> :string
Murk.type(1)              #=> :integer
Murk.type(%{name: "foo"}) #=> %{name: :string}

Murk.is_type?(:test, :atom)   #=> true
Murk.is_type?(:test, :string) #=> false
```

Murk also allows you to extend your structs to be valid Murk types.

```elixir
defmodule Human do
  import Murk
  defstruct [:name, :age]

  defmurk Human do
    field :name, :string
    field :age,  :integer, required: false
  end
end
```

Now `%Human{}` also has access to Murk function, but also the `valid?` function.

```elixir
Murk.valid?(%Human{})                       #=> false
Murk.valid?(%Human{age: 20})                #=> false
Murk.valid?(%Human{name: "human"})          #=> true
Murk.valid?(%Human{name: "human", age: 20}) #=> true
```

You an also add custom nested types, which need to be valid as well

```elixir
field :friends, [Human]
```
