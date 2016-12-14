defmodule Murk do
  defdelegate type(data), to: Murk.Protocol
  defdelegate is_type?(data, type), to: Murk.Protocol
  defdelegate valid?(data), to: Murk.Protocol

  def is_in?(nil, _list, false), do: true
  def is_in?(_value, nil, _requried), do: true
  def is_in?(value, list, _required) do
    Enum.member?(list, value)
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      fields = Module.get_attribute(__MODULE__, :murk_fields) || []
      Module.put_attribute(__MODULE__, :murk_fields, [unquote(name) | fields])
      def murk_valid_field?(data, unquote(name)) do
        value = data |> Map.get(unquote(name))
        correct_type? = Murk.Protocol.is_type?(value, unquote(type))
        valid? = Murk.Protocol.valid?(value)
        required? = unquote(opts)[:required] != false
        is_in? = Murk.is_in?(value, unquote(opts)[:in], required?)
        if required? do
          correct_type? && is_in? && valid?
        else
          (value == nil || correct_type?) &&  is_in? && valid?
        end
      end
    end
  end

  def new_functions do
    quote do
      def new!(params \\ []) do
        struct = struct(__MODULE__, params)
        if Murk.valid?(struct) do
          struct
        else
          raise Murk.FieldError, value: struct
        end
      end

      def new(params \\ []) do
        struct = struct(__MODULE__, params)
        if Murk.valid?(struct) do
          {:ok, struct}
        else
          {:error, :invalid_fields}
        end
      end
    end
  end

  defmacro defmurk(do: block) do
    quote do
      unquote(Murk.new_functions)
      unquote(block)
      def murk_valid_field?(_, _), do: true
      derive = Module.get_attribute(__MODULE__, :derive) || []
      fields = Module.put_attribute(__MODULE__, :derive, [Murk.Protocol | derive])
      fields = Module.get_attribute(__MODULE__, :murk_fields)
      defstruct(fields)
    end
  end
end
