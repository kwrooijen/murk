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

  def all_signatures do
    :code.all_loaded
    |> Enum.map(&(elem(&1, 0)))
    |> Enum.filter(&Murk.is_murk_module?/1)
    |> Enum.map(&({&1, &1.murk_type_signature}))
  end

  def is_murk_module?(module) do
    module.module_info[:exports]
    |> Enum.member?({:murk_type_signature, 0})
  end

  defmacro field(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      new_field = {name, type, opts |> Murk.Validator.validate_opts}
      keys = Module.get_attribute(__MODULE__, :murk_keys) || []
      fields = Module.get_attribute(__MODULE__, :murk_fields) || []
      Module.put_attribute(__MODULE__, :murk_keys, [ name | keys ])
      Module.put_attribute(__MODULE__, :murk_fields, [ new_field | fields ])
    end
  end

  def new_functions do
    quote do
      def new!(params \\ %{}) do
        case new(params) do
          {:ok, result} ->
            result
          {:error, reasons} ->
            raise Murk.FieldError, value: reasons
        end
      end

      def new(params \\ %{}) do
        case __MODULE__.murk_validate_fields(params) do
          {:ok, data} ->
            {:ok, struct(__MODULE__, data)}
          {:error, errors} ->
            {:error, errors}
        end
      end
    end
  end

  def add_validate_fields do
    quote do
      def murk_validate_fields(data) when is_list(data) do
        data |> Enum.into(%{}) |> murk_validate_fields
      end
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

  def add_type_signature do
    quote do
      def murk_type_signature do
        @murk_fields
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
      unquote(add_type_signature())
      defstruct(keys)
    end
  end
end
