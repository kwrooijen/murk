defmodule MurkTest do
  use ExUnit.Case
  doctest Murk

  @map %{name: "murk", version: {0, 0, 1}}

  test "murk type" do
    func = fn() -> :ok end
    assert Murk.type("foobar") == :string
    assert Murk.type(:foobar) == :atom
    assert Murk.type([:foobar]) == [:atom]
    assert Murk.type(["foobar"]) == [:string]
    assert Murk.type([["foobar"]]) == [[:string]]
    assert Murk.type(1) == :integer
    assert Murk.type(1.0) == :float
    assert Murk.type(self()) == :pid
    assert Murk.type(@map) == %{name: :string, version: {:integer, :integer, :integer}}
    assert Murk.type(func) == :function
    assert Murk.type(make_ref()) == :reference
    assert Murk.type(%MurkHumanTest{}) == MurkHumanTest
  end

  test "murk is_type" do
    func = fn() -> :ok end
    assert Murk.is_type?("foobar", :string)
    assert Murk.is_type?(:foobar, :atom)
    assert Murk.is_type?([:foobar], [:atom])
    assert Murk.is_type?(["foobar"], [:string])
    assert Murk.is_type?([["foobar"]], [[:string]])
    assert Murk.is_type?([], [:string])
    assert Murk.is_type?([[]], [[:string]])
    assert Murk.is_type?(1, :integer)
    assert Murk.is_type?(1.0, :float)
    assert Murk.is_type?(self(), :pid)
    assert Murk.is_type?(@map, %{name: :string, version: {:integer, :integer, :integer}})
    assert Murk.is_type?(func, :function)
    assert Murk.is_type?(make_ref(), :reference)
    assert Murk.is_type?(%MurkHumanTest{}, MurkHumanTest)
  end

  test "murk valid?" do
    func = fn() -> :ok end
    assert Murk.valid?("foobar")
    assert Murk.valid?(:foobar)
    assert Murk.valid?([:foobar])
    assert Murk.valid?(["foobar"])
    assert Murk.valid?([["foobar"]])
    assert Murk.valid?([])
    assert Murk.valid?([[]])
    assert Murk.valid?(1)
    assert Murk.valid?(1.0)
    assert Murk.valid?(self())
    assert Murk.valid?(@map)
    assert Murk.valid?(func)
    assert Murk.valid?(make_ref())
  end

  test "valid human" do
    refute Murk.valid?(%MurkHumanTest{})
    refute Murk.valid?(%MurkHumanTest{name: "human"})
    assert Murk.valid?(%MurkHumanTest{name: "human", friends: []})
  end

  test "valid human list" do
    refute Murk.valid?(%MurkHumanTest{name: "human", friends: [%MurkHumanTest{}]})
    assert Murk.valid?(%MurkHumanTest{name: "human", friends: [%MurkHumanTest{name: "human2", friends: []}]})
  end

  test "optional human age field" do
    assert Murk.valid?(%MurkHumanTest{name: "human", friends: []})
    assert Murk.valid?(%MurkHumanTest{name: "human", friends: [], age: 12})
    refute Murk.valid?(%MurkHumanTest{name: "human", friends: [], age: "12"})
  end

  test "human gender two options" do
   assert Murk.valid?(%MurkHumanTest{name: "human", friends: [], gender: "female"})
   assert Murk.valid?(%MurkHumanTest{name: "human", friends: [], gender: "male"})
   refute Murk.valid?(%MurkHumanTest{name: "human", friends: [], gender: "murk"})
   assert Murk.valid?(%MurkHumanTest{name: "human", friends: []})
  end

  test "new function" do
    {result1, _} = MurkHumanTest.new
    {result2, _} = MurkHumanTest.new [name: "human"]
    {result3, _} = MurkHumanTest.new [name: "human", friends: []]
    assert result1 == :error
    assert result2 == :error
    assert result3 == :ok
  end

  test "convert string field to atom field" do
    map = %{:name => "foo", :friends => [], "work" => :programmer}
    {:ok, data} = MurkHumanTest.new(map)
    assert data.work == :programmer
  end

  test "convert string value to atom field" do
    map = %{:name => "foo", :friends => [], "work" => "programmer"}
    map2 = %{:name => "foo", :friends => [], :work => "programmer"}
    {:ok, data} = MurkHumanTest.new(map)
    {:ok, data2} = MurkHumanTest.new(map2)
    assert data.work == :programmer
    assert data2.work == :programmer
  end

  test "convert other struct to murk" do
    copy = %MurkHumanTestCopy{name: "test", friends: []}
    {ok, result} = MurkHumanTest.new(copy)
    assert ok == :ok
    assert result.name == "test"
    assert result.friends == []
  end

  test "convert nested field type from map" do
    human = %{"name" => "test", "friends" => [], "armor" => %{"name" => "Cloth", "type" => :light}}
    human2 = %{name: "test", friends: [], armor: %{name: "Cloth", type: :light}}
    {_, human} = MurkHumanTest.new(human)
    {_, human2} = MurkHumanTest.new(human2)
    assert (human |> Map.get(:armor)) == %MurkArmorTest{name: "Cloth", type: :light, weight: 0}
    assert (human2 |> Map.get(:armor)) == %MurkArmorTest{name: "Cloth", type: :light, weight: 0}
  end

  test "convert nested list type from map" do
    human = %{"name" => "test", "friends" => [], "armor" => %{"name" => "Cloth", "type" => :light}}
    human2 = %{name: "test", friends: [human], armor: %{name: "Cloth", type: :light}}
    {ok, _human} = MurkHumanTest.new(human2)
    assert ok == :ok
  end

  test "armor weight should default to 0" do
    {_ok, armor} = MurkArmorTest.new(name: "Cloth", type: :light)
    {_ok, armor2} = MurkArmorTest.new(name: "Cloth", type: :light, weight: 10)
    assert armor.weight == 0
    assert armor2.weight == 10
  end

  test "max friends in list is 3" do
    human1 = %MurkHumanTest{name: "human2", friends: []}
    human2 = %MurkHumanTest{name: "human", friends: [human1, human1, human1]}
    human3 = %MurkHumanTest{name: "human", friends: [human1, human1, human1, human1]}
    assert Murk.valid?(human1)
    assert Murk.valid?(human2)
    refute Murk.valid?(human3)
  end

  test "create atom list" do
    {result1, _} = MurkAtomInTest.new(something: [:foo])
    {result2, _} = MurkAtomInTest.new(something: [:bar])
    {result3, _} = MurkAtomInTest.new(something: [:zzz])
    assert :ok == result1
    assert :ok == result2
    assert :error == result3
  end

  test "convert atom list" do
    {result, _} = MurkAtomInTest.new(something: ["foo", "bar"])
    assert :ok == result
  end
end
