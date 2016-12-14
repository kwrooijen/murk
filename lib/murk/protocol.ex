defmodule Murk.ProtocolError do
  defexception value: nil, message: nil

  def message(%{value: %{__struct__: struct}, message: nil}) do
    "Murk.Protocol not implemented for #{struct}"
  end
  def message(%{value: value, message: nil}) do
    "Murk.Protocol not implemented for #{inspect value}"
  end
end

defmodule Murk.FieldError do
  defexception value: nil, message: nil

  def message(%{value: value, message: nil}) do
    "Invalid fields for #{value.struct}: #{value}"
  end
end


defprotocol Murk.Protocol do
  @fallback_to_any true

  def type(data)
  def is_type?(data, type)
  def valid?(data)
end

defimpl Murk.Protocol, for: BitString do
  def type(_), do: :string
  def is_type?(_, type), do: type == :string
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Integer do
  def type(_), do: :integer
  def is_type?(_, type), do: type == :integer
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Float do
  def type(_), do: :float
  def is_type?(_, type), do: type == :float
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: PID do
  def type(_), do: :pid
  def is_type?(_, type), do: type == :pid
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Map do
  def type(data) do
    data
    |> Enum.map(fn({key, val}) -> {key, Murk.Protocol.type(val)} end)
    |> Enum.into(%{})
    end
  def is_type?(data, type), do: type == Murk.Protocol.type(data)
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Function do
  def type(_), do: :function
  def is_type?(_, type), do: type == :function
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Reference do
  def type(_), do: :reference
  def is_type?(_, type), do: type == :reference
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Port do
  def type(_), do: :port
  def is_type?(_, type), do: type == :port
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: Atom do
  def type(true), do: :boolean
  def type(false), do: :boolean
  def type(_), do: :atom
  def is_type?(true, :boolean), do: true
  def is_type?(false, :boolean), do: true
  def is_type?(_, type), do: type == :atom
  def valid?(_), do: true
end

defimpl Murk.Protocol, for: List do
  def type([]), do: []
  def type([head | _]), do: [Murk.Protocol.type(head)]
  def is_type?(data, type) do
    data
    |> Enum.take(5)
    |> Enum.map(fn(val) ->
      correct_type? = type == [Murk.Protocol.type(val)]
      val == [] || correct_type?
    end)
    |> Enum.all?
  end
  def valid?([]), do: true
  def valid?(data) do
    data = data |> Enum.take(5)
    all_valid? = data
    |> Enum.filter(&(&1 != []))
    |> Enum.map(&Murk.Protocol.valid?/1)
    |> Enum.all?
    one_type? = data
    |> Enum.filter(&(&1 != []))
    |> Enum.map(&Murk.Protocol.type/1)
    |> Enum.uniq
    |> Enum.count
    all_valid? && (one_type? < 2)
  end
end

defimpl Murk.Protocol, for: Tuple do
  def type(data) do
    data
    |> Tuple.to_list
    |> Enum.map(&Murk.Protocol.type/1)
    |> List.to_tuple
  end
  def is_type?(data, type), do: type == Murk.Protocol.type(data)
  def valid?(data) do
    data
    |> Tuple.to_list
    |> Enum.map(&Murk.Protocol.valid?/1)
    |> Enum.all?
  end
end

defimpl Murk.Protocol, for: Any do
  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end

  def deriving(module, _struct, _options) do
    quote do
      defimpl Murk.Protocol, for: unquote(module) do
        def type(_), do: unquote(module)
        def is_type?(_, type), do: type == unquote(module)
        def valid?(data) do
          data
          |> Map.keys
          |> Enum.map(&(unquote(module).murk_valid_field?(data, &1)))
          |> Enum.all?
        end
      end
    end
  end

  def type(data), do: raise Murk.ProtocolError, value: data
  def is_type?(data, _), do: raise Murk.ProtocolError, value: data
  def valid?(data), do: raise Murk.ProtocolError, value: data
end
