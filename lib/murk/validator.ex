defmodule Murk.Validator do
  @regular_types [:string, :binary, :integer, :float, :pid, :function, :reference, :port, :atom, :boolean]

  def validate_field({name, type, opts}, {data, errors}) do
    value = Map.get(data, name)
    {data, value} = {data, value}
    |> from_string_field(name)
    |> maybe_default(name, opts[:default])
    |> maybe_convert(type, name, opts[:in], opts[:convertable])
    |> maybe_convert_map(type, name)
    |> maybe_convert_list(type, name)

    {_, new_errors} = {value, []}
    |> check_max(name, opts[:max])
    |> check_available(name, opts[:required])
    |> check_type(name, type, opts[:required])
    |> check_in(name, opts[:in], opts[:required])
    {data, errors ++ new_errors}
  end

  def validate_opts(opts) do
    opts
    |> opts_ensure_required
  end

  defp check_max({_, [_|_]} = acc, _, _), do: acc
  defp check_max({value, errors}, name, max) when length(value) > max do
    {value, [ {name, "Field length exceeds #{max} items"} | errors ]}
  end
  defp check_max(acc, _, _), do: acc

  defp check_available({_, [_|_]} = acc, _, _), do: acc
  defp check_available({nil, errors}, name, required)
  when required in [nil, true] do
    {nil, [ {name, "Field is missing"} | errors ]}
  end
  defp check_available({value, errors}, _name, _required) do
    {value, errors}
  end

  defp check_type({_, [_|_]} = acc, _, _, _), do: acc
  defp check_type({nil, errors}, _name, _type, _required = false) do
    {nil, errors}
  end
  defp check_type({value, errors}, name, type, _required) do
    if Murk.is_type?(value, type) && Murk.valid?(value) do
      {value, errors}
    else
      {value, [{name, "Invalid type"} | errors]}
    end
  end

  defp check_in({_, [_|_]} = acc, _, _, _), do: acc
  defp check_in({nil, errors}, _name, _in_list, _required = false) do
    {nil, errors}
  end
  defp check_in({value, errors}, _name, _inlist = nil, _required) do
    {value, errors}
  end
  defp check_in({value, errors}, name, in_list, _required) when is_list(value) do
    all_member? = value
    |> Enum.all?(&(Enum.member?(in_list, &1)))
    if all_member? do
      {value, errors}
    else
      {value, [{name, "Not a member"} | errors]}
    end
  end
  defp check_in({value, errors}, name, in_list, _required) do
    if Enum.member?(in_list, value) do
      {value, errors}
    else
      {value, [{name, "Not a member"} | errors]}
    end
  end

  defp from_string_field({data, nil}, name) do
    string_name = name |> Atom.to_string
    value = Map.get(data, string_name)
    data = data |> Map.put(name, value)
    {data, value}
  end
  defp from_string_field({data, value}, _name), do: {data, value}

  defp maybe_default({data, nil}, name, default) when default != nil do
    data = data |> Map.put(name, default)
    {data, default}
  end
  defp maybe_default({data, value}, _name, _default), do: {data, value}

  defp maybe_convert({data, value}, [:atom], name, [_|_], true) do
    new_value = value
    |> Enum.map(&convert_string_to_atom/1)
    |> Enum.filter(&is_ok/1)
    |> Enum.map(fn({_, value}) -> value end)
    if Enum.count(new_value) == Enum.count(value) do
      data = data |> Map.put(name, new_value)
      {data, new_value}
    else
      {data, value}
    end
  end
  defp maybe_convert({data, value}, :atom, name, [_|_], true)
  when is_binary(value) do
    case convert_string_to_atom(value) do
      {:ok, value} ->
        data = data |> Map.put(name, value)
        {data, value}
      {:error, :invalid} ->
        {data, value}
    end
  end
  defp maybe_convert({data, value}, _, _, _, _), do: {data, value}

  defp maybe_convert_map({data, value}, type, name)
  when is_map(value) and
  is_atom(type) and
  not type in @regular_types do
    case type.new(value) do
      {:ok, value} ->
        data = data |> Map.put(name, value)
        {data, value}
      {:error, _reason} ->
        {data, value}
    end
  end
  defp maybe_convert_map({data, value}, _type, _name) do
    {data, value}
  end

  defp maybe_convert_list({data, []}, _type, _name), do: {data, []}
  defp maybe_convert_list({data, [_|_] = values}, [type], name)
  when not type in @regular_types do
    try do
      values = values |> Enum.map(&type.new!/1)
      data = data |> Map.put(name, values)
      {data, values}
    rescue
      _ ->
        {data, values}
    end
  end
  defp maybe_convert_list({data, value}, _type, _name) do
    {data, value}
  end

  defp opts_ensure_required(opts) do
    if opts[:required] == nil do
      [{:required, true} | opts]
    else
      opts
    end
  end

  defp convert_string_to_atom(atom) when is_atom(atom), do: {:ok, atom}
  defp convert_string_to_atom(string) do
    try do
      value = String.to_existing_atom(string)
      {:ok, value}
    rescue
      _ -> {:error, :invalid}
    end
  end

  defp is_ok({:ok, _}), do: true
  defp is_ok({_, _}), do: false
end
