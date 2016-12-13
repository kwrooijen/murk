defmodule Murk do
  defdelegate type(data), to: Murk.Protocol
  defdelegate is_type?(data, type), to: Murk.Protocol
  defdelegate valid?(data), to: Murk.Protocol

  defmacro field(name, type, opts \\ []) do
    quote do
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

  defmacro defmurk(name, do: block) do
    quote do
      unquote(block)
      def murk_validate(_, _), do: true

      defimpl Murk.Protocol, for: unquote(name) do
        def type(_), do: unquote(name)
        def is_type?(_, type), do: type == unquote(name)
        def valid?(data) do
          data
          |> Map.keys
          |> Enum.map(&(unquote(name).murk_validate(data, &1)))
          |> Enum.all?
        end
      end
    end
  end
end
