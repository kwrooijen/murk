defmodule MurkHumanTest do
  use Murk
  defmurk do
    field :name, :string
    field :age, :integer, required: false
    field :friends, [MurkHumanTest], max: 3
    field :gender, :string, in: ["male", "female"], required: false
    field :work, :atom, convertable: true, in: [:programmer, :artist], required: false
    field :armor, MurkArmorTest, required: false
  end
end

defmodule MurkArmorTest do
  use Murk
  defmurk do
    field :name, :string
    field :type, :atom, in: [:light, :medium, :heavy]
    field :weight, :integer, default: 0
  end
end

defmodule MurkHumanTestCopy do
  defstruct [:name, :age, :friends, :gender, :work]
end
