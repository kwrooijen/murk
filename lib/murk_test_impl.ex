defmodule MurkHumanTest do
  use Murk
  defmurk do
    field :name, :string
    field :age, :integer, required: false
    field :friends, [MurkHumanTest]
    field :gender, :string, in: ["male", "female"], required: false
    field :work, :atom, convertable: true, in: [:programmer, :artist], required: false
  end
end
