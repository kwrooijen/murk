defmodule MurkHumanTest do
  import Murk
  defmurk do
    field :name, :string
    field :age, :integer, required: false
    field :friends, [MurkHumanTest]
  end
end
