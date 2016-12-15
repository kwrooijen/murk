defmodule Murk do
  defdelegate type(data), to: Murk.Protocol
  defdelegate is_type?(data, type), to: Murk.Protocol
  defdelegate valid?(data), to: Murk.Protocol

  def is_in?(nil, _list, false), do: true
  def is_in?(_value, nil, _requried), do: true
  def is_in?(value, list, _required) do
    Enum.member?(list, value)
  end

  defmacro __using__(_) do
    quote do
      import Murk
      unquote(Murk.new_functions())
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      new_field = {unquote(name), unquote(type), unquote(opts)}
      keys = Module.get_attribute(__MODULE__, :murk_keys) || []
      fields = Module.get_attribute(__MODULE__, :murk_fields) || []
      Module.put_attribute(__MODULE__, :murk_keys, [ unquote(name) | keys ])
      Module.put_attribute(__MODULE__, :murk_fields, [ new_field | fields ])
    end
  end

  def new_functions do
    quote do
      def new!(params \\ []) do
        data = struct(__MODULE__, params)
        case __MODULE__.murk_validate_fields(data) do
          {:ok, result} ->
            result
          {:error, reasons} ->
            raise Murk.FieldError, value: reasons
        end
      end

      def new(params \\ []) do
        data = struct(__MODULE__, params)
        __MODULE__.murk_validate_fields(data)
      end
    end
  end

  def add_validate_fields() do
    quote do
      def murk_validate_fields(data) do
        acc = {data, []}
        result = @murk_fields
        |> Enum.reduce({data, []}, &Murk.Validator.validate_field/2)
        case result do
          {data, []} ->
            {:ok, data}
          {_data, errors} ->
            {:error, errors}
        end
      end
    end
  end

  defmacro defmurk(do: block) do
    quote do
      unquote(block)
      keys = Module.get_attribute(__MODULE__, :murk_keys) || []
      derive = Module.get_attribute(__MODULE__, :derive) || []
      Module.put_attribute(__MODULE__, :derive, [Murk.Protocol | derive])
      unquote(add_validate_fields())
      defstruct(keys)
    end
  end
end
