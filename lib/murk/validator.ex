defmodule Murk.Validator do
  def validate_field({name, type, opts}, {data, errors}) do
    value = data |> Map.get(name)
    {_, new_errors} = {value, []}
    |> Murk.Validator.check_available(name, opts[:required])
    |> Murk.Validator.check_type(name, type, opts[:required])
    |> Murk.Validator.check_in(name, opts[:in], opts[:required])
    {data, errors ++ new_errors}
  end

  def check_available({_, [_|_]} = acc, _, _), do: acc
  def check_available({nil, errors}, name, required) when required in [nil, true] do
    {nil, [ {name, "Field is missing"} | errors ]}
  end
  def check_available({value, errors}, _name, _required) do
    {value, errors}
  end

  def check_type({_, [_|_]} = acc, _, _, _), do: acc
  def check_type({nil, errors}, _name, _type, _required = false) do
    {nil, errors}
  end
  def check_type({value, errors}, name, type, _required) do
    if Murk.is_type?(value, type) && Murk.valid?(value) do
      {value, errors}
    else
      {value, [{name, "Invalid type"} | errors]}
    end
  end

  def check_in({_, [_|_]} = acc, _, _, _), do: acc
  def check_in({nil, errors}, _name, _in_list, _required = false) do
    {nil, errors}
  end
  def check_in({value, errors}, _name, _inlist = nil, _required) do
    {value, errors}
  end
  def check_in({value, errors}, name, in_list, _required) do
    if Enum.member?(in_list, value) do
      {value, errors}
    else
      {value, [{name, "Not a member"} | errors]}
    end
  end
end
