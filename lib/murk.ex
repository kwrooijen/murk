defmodule Murk do
  defdelegate type(data), to: Murk.Protocol
  defdelegate is_type?(data, type), to: Murk.Protocol
  defdelegate valid?(data), to: Murk.Protocol

  defmacro field(name, type, opts \\ []) do
    quote do
      fields = Module.get_attribute(__MODULE__, :murk_fields) || []
      Module.put_attribute(__MODULE__, :murk_fields, [unquote(name) | fields])
      def murk_validate(data, unquote(name)) do
        value = data |> Map.get(unquote(name))
        correct_type? = Murk.Protocol.is_type?(value, unquote(type))
        valid? = Murk.Protocol.valid?(value)
        required? = unquote(opts)[:required] != false
        if required? do
          correct_type? && valid?
        else
          (value == nil || correct_type?) && valid?
        end
      end
    end
  end

  defmacro defmurk(do: block) do
    quote do
      unquote(block)
      def murk_validate(_, _), do: true
      derive = Module.get_attribute(__MODULE__, :derive) || []
      fields = Module.put_attribute(__MODULE__, :derive, [Murk.Protocol | derive])
      fields = Module.get_attribute(__MODULE__, :murk_fields)
      defstruct(fields)
    end
  end
end
