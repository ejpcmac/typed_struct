defmodule TypedStruct do
  @moduledoc """
  Documentation for TypedStruct.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import TypedStruct, only: [typedstruct: 1]
    end
  end

  @doc """
  Defines a typed struct.
  """
  defmacro typedstruct(do: block) do
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :types, accumulate: true)
      Module.register_attribute(__MODULE__, :keys_to_enforce, accumulate: true)

      import TypedStruct
      unquote(block)

      @enforce_keys @keys_to_enforce
      defstruct @fields

      TypedStruct.__type__(@types)
    end
  end

  @doc """
  Defines a field in a typed struct.
  """
  defmacro field(name, type, opts \\ []) do
    quote do
      TypedStruct.__field__(
        __MODULE__,
        unquote(name),
        unquote(Macro.escape(type)),
        unquote(opts)
      )
    end
  end

  ##
  ## Callbacks
  ##

  @doc false
  def __field__(mod, name, type, opts) when is_atom(name) do
    if mod |> Module.get_attribute(:fields) |> Keyword.has_key?(name) do
      raise ArgumentError, "the field #{inspect(name)} is already set"
    end

    default = opts[:default]
    enforce? = !!opts[:enforce]

    Module.put_attribute(mod, :fields, {name, default})
    Module.put_attribute(mod, :types, {name, type_for(type, enforce?)})
    if enforce?, do: Module.put_attribute(mod, :keys_to_enforce, name)
  end

  def __field__(_mod, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
  end

  @doc false
  defmacro __type__(types) do
    quote bind_quoted: [types: types] do
      @type t() :: %__MODULE__{unquote_splicing(types)}
    end
  end

  ##
  ## Helpers
  ##

  # Makes the type nullable if the key is not enforced.
  defp type_for(type, true), do: type
  defp type_for(type, _), do: quote(do: unquote(type) | nil)
end
