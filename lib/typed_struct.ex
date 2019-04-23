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

        @typedoc "A person"
        typedstruct do
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
  add `runtime: false` to the dependency tuple as TypedStruct is only used
  during compilation.

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

  ### Documentation

  To add a `@typedoc` to the struct type, just add the attribute above the
  `typedstruct` block:

      @typedoc "A typed struct"
      typedstruct do
        field :a_string, String.t()
        field :an_int, integer()
      end

  ### Reflexion

  To enable the use of information defined by TypedStruct by other modules, each
  typed struct defines three functions:

    * `__keys__/0` - returns the keys of the struct
    * `__defaults__/0` - returns the default value for each field
    * `__types__/0` - returns the quoted type for each field

  For instance:

      iex(1)> defmodule Demo do
      ...(1)>   use TypedStruct
      ...(1)>
      ...(1)>   typedstruct do
      ...(1)>     field :a_field, String.t()
      ...(1)>     field :with_default, integer(), default: 7
      ...(1)>   end
      ...(1)> end
      {:module, Demo,
      <<70, 79, 82, 49, 0, 0, 8, 60, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 0, 241,
        0, 0, 0, 24, 11, 69, 108, 105, 120, 105, 114, 46, 68, 101, 109, 111, 8, 95,
        95, 105, 110, 102, 111, 95, 95, 9, 102, ...>>, {:__types__, 0}}
      iex(2)> Demo.__keys__()
      [:a_field, :with_default]
      iex(3)> Demo.__defaults__()
      [a_field: nil, with_default: 7]
      iex(4)> Demo.__types__()
      [
        a_field: {:|, [],
        [
          {{:., [line: 5],
            [{:__aliases__, [line: 5, counter: -576460752303422524], [:String]}, :t]},
            [line: 5], []},
          nil
        ]},
        with_default: {:integer, [line: 6], []}
      ]

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

      # Becomes

      @opaque t() :: %__MODULE__{
                name: String.t()
              }
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
    * `opaque` - if set to true, creates an opaque type for the struct
    * `plugins` - Set to a list of modules that implement `TypedStruct.Plugin` behaviour.  `[]` by
      default
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

  This is the same as writing:

      defmodule MyStruct do
        use TypedStruct

        typedstruct enforce: true do
          field :field_one, String.t(), enforce: false
          field :field_two, integer()
          field :field_three, boolean()
          field :field_four, atom(), default: :hey
        end
      end
  """
  defmacro typedstruct(opts \\ [], do: block) do
    plugins = Keyword.get(opts, :plugins, [])

    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :types, accumulate: true)
      Module.register_attribute(__MODULE__, :keys_to_enforce, accumulate: true)
      Module.register_attribute(__MODULE__, :plugins, accumulate: true)
      Module.put_attribute(__MODULE__, :enforce?, unquote(!!opts[:enforce]))

      import TypedStruct
      TypedStruct.__require_plugins__(__MODULE__, unquote(plugins))

      unquote(block)

      @enforce_keys @keys_to_enforce
      defstruct @fields

      TypedStruct.__type__(@types, unquote(opts))

      def __keys__, do: @fields |> Keyword.keys() |> Enum.reverse()
      def __defaults__, do: Enum.reverse(@fields)
      def __types__, do: Enum.reverse(@types)
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
    end
  end

  @doc """
  Adds a plugin to a typed struct. `plugin` should be a module that implements the
  `TypedStruct.Plugin` behaviour.
  ## Example
      plugin SomePlugin

  """
  defmacro plugin(plugin) do
    quote do
      require unquote(plugin)
      Module.put_attribute(__MODULE__, :plugins, unquote(plugin))
    end
  end

  defmacro __require_plugins__(mod, plugins) do
    Enum.map(plugins, fn plugin ->
      quote do
        require unquote(plugin)
        Module.put_attribute(unquote(mod), :plugins, unquote(plugin))
      end
    end)
  end

  defmacro __plugin_before_macros__(plugins, mod, opts) do
    Enum.map(plugins, fn plugin ->
      quote do
        unquote(plugin).before_fields_processed(unquote(mod), unquote(opts))
      end
    end)
  end

  defmacro __plugin_after_macros__(plugins, mod, opts) do
    Enum.map(plugins, fn plugin ->
      quote do
        unquote(plugin).after_fields_processed(unquote(mod), unquote(opts))
      end
    end)
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

    enforce? =
      if is_nil(opts[:enforce]),
        do: Module.get_attribute(mod, :enforce?) && is_nil(default),
        else: !!opts[:enforce]

    nullable? = !default && !enforce?

    Module.put_attribute(mod, :fields, {name, default})
    Module.put_attribute(mod, :types, {name, type_for(type, nullable?)})
    if enforce?, do: Module.put_attribute(mod, :keys_to_enforce, name)

    Enum.each(Module.get_attribute(mod, :plugins), fn plugin ->
      plugin.field(mod, name, type, opts)
    end)
  end

  def __field__(_mod, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
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

  ##
  ## Helpers
  ##

  # Makes the type nullable if the key is not enforced.
  defp type_for(type, false), do: type
  defp type_for(type, _), do: quote(do: unquote(type) | nil)
end
