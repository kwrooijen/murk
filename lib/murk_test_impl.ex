defmodule MurkHumanTest do
  import Murk
  defmurk do
    field :name, :string
    field :age, :integer, required: false
    field :friends, [MurkHumanTest]
    field :gender, :string, in: ["male", "female"], required: false
  end
end
