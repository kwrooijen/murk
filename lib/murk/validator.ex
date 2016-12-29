defmodule Murk.Validator do
  @regular_types [:string, :binary, :integer, :float, :pid, :function, :reference, :port, :atom, :boolean]

  def validate_field({name, type, opts}, {data, errors}) do
    value = Map.get(data, name)
    {data, value} = {data, value}
    |> from_string_field(name)
    |> maybe_convert(type, name, opts[:in], opts[:convertable])
    |> maybe_convert_map(type, name)

    {_, new_errors} = {value, []}
    |> check_available(name, opts[:required])
    |> check_type(name, type, opts[:required])
    |> check_in(name, opts[:in], opts[:required])
    {data, errors ++ new_errors}
  end

  def validate_opts(opts) do
    opts
    |> opts_ensure_required
  end

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

  defp maybe_convert({data, value}, :atom, name, [_|_], true)
  when is_binary(value) do
    try do
      value = String.to_existing_atom(value)
      data = data |> Map.put(name, value)
      {data, value}
    rescue
      _ in RuntimeError -> {data, value}
    end
  end
  defp maybe_convert({data, value}, _, _, _, _), do: {data, value}

  defp maybe_convert_map({data, value}, type, name)
  when is_map(value) and
  not is_map(type) and
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

  defp opts_ensure_required(opts) do
    if opts[:required] == nil do
      [{:required, true} | opts]
    else
      opts
    end
  end
end
