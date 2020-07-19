defmodule TypedStruct do
  @moduledoc """
  TypedStruct is a library for defining structs with a type without writing
  boilerplate code.

  ## Rationale

  To define a struct in Elixir, you probably want to define three things:

    * the struct itself, with default values,
    * the list of enforced keys,
    * its associated type.

  It ends up in something like this:

      defmodule Person do
        @moduledoc \"\"\"
        A struct representing a person.
        \"\"\"

        @enforce_keys [:name]
        defstruct name: nil,
                  age: nil,
                  happy?: true,
                  phone: nil

        @typedoc "A person"
        @type t() :: %__MODULE__{
                name: String.t(),
                age: non_neg_integer() | nil,
                happy?: boolean(),
                phone: String.t() | nil
              }
      end

  In the example above you can notice several points:

    * the keys are present in both the `defstruct` and type definition,
    * enforced keys must also be written in `@enforce_keys`,
    * if a key has no default value and is not enforced, its type should be
      nullable.

  If you want to add a field in the struct, you must therefore:

    * add the key with its default value in the `defstruct` list,
    * add the key with its type in the type definition.

  If the field is not optional, you should even add it to `@enforce_keys`. This
  is way too much work for lazy people like me, and moreover it can be
  error-prone.

  It would be way better if we could write something like this:

      defmodule Person do
        @moduledoc \"\"\"
        A struct representing a person.
        \"\"\"

        use TypedStruct

        typedstruct do
          @typedoc "A person"

          field :name, String.t(), enforce: true
          field :age, non_neg_integer()
          field :happy?, boolean(), default: true
          field :phone, String.t()
        end
      end

  Thanks to TypedStruct, this is now possible :)

  ## Usage

  ### Setup

  To use TypedStruct in your project, add this to your Mix dependencies:

      {:typed_struct, "~> #{Mix.Project.config()[:version]}"}

  If you do not plan to compile modules using TypedStruct at runtime, you can
  add `runtime: false` to the dependency tuple as TypedStruct is only used at
  build time.

  If you want to avoid `mix format` putting parentheses on field definitions,
  you can add to your `.formatter.exs`:

      [
        ...,
        import_deps: [:typed_struct]
      ]

  ### General usage

  To define a typed struct, use `TypedStruct`, then define your struct within a
  `typedstruct` block:

      defmodule MyStruct do
        # Use TypedStruct to import the typedstruct macro.
        use TypedStruct

        # Define your struct.
        typedstruct do
          # Define each field with the field macro.
          field :a_string, String.t()

          # You can set a default value.
          field :string_with_default, String.t(), default: "default"

          # You can enforce a field.
          field :enforced_field, integer(), enforce: true
        end
      end

  Each field is defined through the `field/2` macro.

  ### Options

  If you want to enforce all the keys by default, you can do:

      defmodule MyStruct do
        use TypedStruct

        # Enforce keys by default.
        typedstruct enforce: true do
          # This key is enforced.
          field :enforced_by_default, term()

          # You can override the default behaviour.
          field :not_enforced, term(), enforce: false

          # A key with a default value is not enforced.
          field :not_enforced_either, integer(), default: 1
        end
      end

  You can also generate an opaque type for the struct:

      defmodule MyOpaqueStruct do
        use TypedStruct

        # Generate an opaque type for the struct.
        typedstruct opaque: true do
          field :name, String.t()
        end
      end

  If you often define submodules containing only a struct, you can avoid
  boilerplate code:

      defmodule MyModule do
        use TypedStruct

        # You now have %MyModule.Struct{}.
        typedstruct module: Struct do
          field :field, term()
        end
      end

  ### Documentation

  To add a `@typedoc` to the struct type, just add the attribute in the
  `typedstruct` block:

      typedstruct do
        @typedoc "A typed struct"

        field :a_string, String.t()
        field :an_int, integer()
      end

  You can also document submodules this way:

      typedstruct module: MyStruct do
        @moduledoc "A submodule with a typed struct."
        @typedoc "A typed struct in a submodule"

        field :a_string, String.t()
        field :an_int, integer()
      end

  ### Plugins

  It is possible to extend the scope of TypedStruct by using its plugin
  interface, as described in `TypedStruct.Plugin`. For instance, to
  automatically generate lenses with the [Lens](https://github.com/obrok/lens)
  library, you can use
  [`TypedStructLens`](https://github.com/ejpcmac/typed_struct_lens) and do:

      defmodule MyStruct do
        use TypedStruct

        typedstruct do
          plugin TypedStructLens

          field :a_field, String.t()
          field :other_field, atom()
        end

        @spec change(t()) :: t()
        def change(data) do
          # a_field/0 is generated by TypedStructLens.
          lens = a_field()
          put_in(data, [lens], "Changed")
        end
      end

  ## What do I get?

  When defining an empty `typedstruct` block:

      defmodule Example do
        use TypedStruct

        typedstruct do
        end
      end

  you get an empty struct with its module type `t()`:

      defmodule Example do
        @enforce_keys []
        defstruct []

        @type t() :: %__MODULE__{}
      end

  Each `field` call adds information to the struct, `@enforce_keys` and the type
  `t()`.

  A field with no options adds the name to the `defstruct` list, with `nil` as
  default. The type itself is made nullable:

      defmodule Example do
        use TypedStruct

        typedstruct do
          field :name, String.t()
        end
      end

  becomes:

      defmodule Example do
        @enforce_keys []
        defstruct name: nil

        @type t() :: %__MODULE__{
                name: String.t() | nil
              }
      end

  The `default` option adds the default value to the `defstruct`:

      field :name, String.t(), default: "John Smith"

      # Becomes
      defstruct name: "John Smith"

  When set to `true`, the `enforce` option enforces the key by adding it to the
  `@enforce_keys` attribute.

      field :name, String.t(), enforce: true

      # Becomes
      @enforce_keys [:name]
      defstruct name: nil

  In both cases, the type has no reason to be nullable anymore by default. In
  one case the field is filled with its default value and not `nil`, and in the
  other case it is enforced. Both options would generate the following type:

      @type t() :: %__MODULE__{
            name: String.t() # Not nullable
          }

  Passing `opaque: true` replaces `@type` with `@opaque` in the struct type
  specification:

      typedstruct opaque: true do
        field :name, String.t()
      end

  generates the following type:

      @opaque t() :: %__MODULE__{
                name: String.t()
              }

  When passing `module: ModuleName`, the whole `typedstruct` block is wrapped in
  a module definition. This way, the following definition:

      defmodule MyModule do
        use TypedStruct

        typedstruct module: Struct do
          field :field, term()
        end
      end

  becomes:

      defmodule MyModule do
        defmodule Struct do
          @enforce_keys []
          defstruct field: nil

          @type t() :: %__MODULE__{
                  field: term() | nil
                }
        end
      end
  """

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

      # Create a scope to avoid leaks.
      (fn ->
         import TypedStruct
         unquote(block)
       end).()

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
