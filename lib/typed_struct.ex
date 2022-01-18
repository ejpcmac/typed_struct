defmodule TypedStruct do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc false
  defmacro __using__(_) do
    quote do
      import TypedStruct, only: [typedstruct: 1, typedstruct: 2]
    end
  end

  @doc """
  Defines a typed struct.

  Inside a `typedstruct` block, each field is defined through the `field/2`
  macro.

  ## Options

    * `enforce` - if set to true, sets `enforce: true` to all fields by default.
      This can be overridden by setting `enforce: false` or a default value on
      individual fields.
    * `opaque` - if set to true, creates an opaque type for the struct.
    * `module` - if set, creates the struct in a submodule named `module`.

  ## Examples

      defmodule MyStruct do
        use TypedStruct

        typedstruct do
          field :field_one, String.t()
          field :field_two, integer(), enforce: true
          field :field_three, boolean(), enforce: true
          field :field_four, atom(), default: :hey
        end
      end

  The following is an equivalent using the *enforce by default* behaviour:

      defmodule MyStruct do
        use TypedStruct

        typedstruct enforce: true do
          field :field_one, String.t(), enforce: false
          field :field_two, integer()
          field :field_three, boolean()
          field :field_four, atom(), default: :hey
        end
      end

  You can create the struct in a submodule instead:

      defmodule MyModule do
        use TypedStruct

        typedstruct, module: Struct do
          field :field_one, String.t()
          field :field_two, integer(), enforce: true
          field :field_three, boolean(), enforce: true
          field :field_four, atom(), default: :hey
        end
      end
  """
  defmacro typedstruct(opts \\ [], do: block) do
    if is_nil(opts[:module]) do
      quote do
        Module.eval_quoted(
          __ENV__,
          TypedStruct.__typedstruct__(
            unquote(Macro.escape(block)),
            unquote(opts)
          )
        )
      end
    else
      quote do
        defmodule unquote(opts[:module]) do
          Module.eval_quoted(
            __ENV__,
            TypedStruct.__typedstruct__(
              unquote(Macro.escape(block)),
              unquote(opts)
            )
          )
        end
      end
    end
  end

  @doc false
  def __typedstruct__(block, opts) do
    quote do
      Module.register_attribute(__MODULE__, :ts_plugins, accumulate: true)
      Module.register_attribute(__MODULE__, :ts_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :ts_types, accumulate: true)
      Module.register_attribute(__MODULE__, :ts_enforce_keys, accumulate: true)
      Module.put_attribute(__MODULE__, :ts_enforce?, unquote(!!opts[:enforce]))

      import TypedStruct
      unquote(block)

      @enforce_keys @ts_enforce_keys
      defstruct @ts_fields

      TypedStruct.__type__(@ts_types, unquote(opts))

      Enum.each(@ts_plugins, fn {plugin, plugin_opts} ->
        if {:after_definition, 1} in plugin.__info__(:functions) do
          Module.eval_quoted(__MODULE__, plugin.after_definition(plugin_opts))
        end
      end)

      Module.delete_attribute(__MODULE__, :ts_enforce?)
      Module.delete_attribute(__MODULE__, :ts_enforce_keys)
      Module.delete_attribute(__MODULE__, :ts_types)
      Module.delete_attribute(__MODULE__, :ts_plugins)
    end
  end

  @doc false
  defmacro __type__(types, opts) do
    if Keyword.get(opts, :opaque, false) do
      quote bind_quoted: [types: types] do
        @opaque t() :: %__MODULE__{unquote_splicing(types)}
      end
    else
      quote bind_quoted: [types: types] do
        @type t() :: %__MODULE__{unquote_splicing(types)}
      end
    end
  end

  @doc """
  Registers a plugin for the currently defined struct.

  ## Example

      typedstruct do
        plugin MyPlugin

        field :a_field, String.t()
      end

  For more information on how to define your own plugins, please see
  `TypedStruct.Plugin`. To use a third-party plugin, please refer directly to
  its documentation.
  """
  defmacro plugin(plugin, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :ts_plugins,
        {unquote(plugin), unquote(opts)}
      )

      require unquote(plugin)
      unquote(plugin).init(unquote(opts))
    end
  end

  @doc """
  Defines a field in a typed struct.

  ## Example

      # A field named :example of type String.t()
      field :example, String.t()

  ## Options

    * `default` - sets the default value for the field
    * `enforce` - if set to true, enforces the field and makes its type
      non-nullable
  """
  defmacro field(name, type, opts \\ []) do
    quote do
      TypedStruct.__field__(
        __MODULE__,
        unquote(name),
        unquote(Macro.escape(type)),
        unquote(opts)
      )

      Enum.each(@ts_plugins, fn {plugin, plugin_opts} ->
        if {:field, 3} in plugin.__info__(:functions) do
          Module.eval_quoted(
            __MODULE__,
            plugin.field(
              unquote(name),
              unquote(Macro.escape(type)),
              unquote(opts) ++ plugin_opts
            )
          )
        end
      end)
    end
  end

  @doc false
  def __field__(mod, name, type, opts) when is_atom(name) do
    if mod |> Module.get_attribute(:ts_fields) |> Keyword.has_key?(name) do
      raise ArgumentError, "the field #{inspect(name)} is already set"
    end

    has_default? = Keyword.has_key?(opts, :default)
    enforce_by_default? = Module.get_attribute(mod, :ts_enforce?)

    enforce? =
      if is_nil(opts[:enforce]),
        do: enforce_by_default? && !has_default?,
        else: !!opts[:enforce]

    nullable? = !has_default? && !enforce?

    Module.put_attribute(mod, :ts_fields, {name, opts[:default]})
    Module.put_attribute(mod, :ts_types, {name, type_for(type, nullable?)})
    if enforce?, do: Module.put_attribute(mod, :ts_enforce_keys, name)
  end

  def __field__(_mod, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
  end

  # Makes the type nullable if the key is not enforced.
  defp type_for(type, false), do: type
  defp type_for(type, _), do: quote(do: unquote(type) | nil)
end
