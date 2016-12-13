defmodule MurkHumanTest do
  import Murk
  defstruct [:name, :age, :friends]

  defmurk MurkHumanTest do
    field :name, :string
    field :age, :integer, required: false
    field :friends, [MurkHumanTest]
  end
end
