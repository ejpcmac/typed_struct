defmodule TypedStruct.Plugin do
  @moduledoc """
  This module defines the plugin interface for TypedStruct.

  ## Rationale

  Sometimes you may want to define helpers on your structs, for all their fields
  or for the struct as a whole. This plugin interface lets you integrate your
  own needs with TypedStruct.

  ## Plugin definition

  A TypedStruct plugin is a module that implements `TypedStruct.Plugin`. Three
  callbacks can be used to inject code at different steps:

    * `c:init/1` lets you inject code where the `TypedStruct.plugin/2` macro is
      called,
    * `c:field/3` lets you inject code on each field definition,
    * `c:after_definition/1` lets you insert code after the struct and its type
      have been defined.

  To provide the maximum flexibility, the last two callbacks are optional and a
  default implementation of `c:init/1` is defined when `use`-ing the module, so
  that you do not have to write it yourself if you do not need it.

  ### Example

  As an example, let’s define a plugin that allows users to add an optional
  description to their structs and fields. This plugin also takes an `upcase`
  option. If set to `true`, all the descriptions are then upcased. It would be
  used this way:

      defmodule MyStruct do
        use TypedStruct

        typedstruct do
          # We import the plugin with the upcase option set to `true`.
          plugin DescribedStruct, upcase: true

          # We can now set a description for the struct.
          description "My struct"

          # We can also set a description on a field.
          field :a_field, String.t(), description: "A field"
          field :second_field, boolean()
        end
      end

  Once compiled, we would optain:

      iex> MyStruct.struct_description()
      "MY STRUCT"
      iex> MyStruct.field_description(:a_field)
      "A FIELD"

  Follows the plugin definition:

      defmodule DescribedStruct do
        use TypedStruct.Plugin

        # The init macro lets you inject code where the plugin macro is called.
        # You can think a bit of it like a `use` but for the scope of the
        # typedstruct block.
        @impl true
        @spec init(keyword()) :: Macro.t()
        defmacro init(opts) do
          quote do
            # Let’s import our custom `description` macro defined below so our
            # users can use it when defining their structs.
            import TypedStructDemoPlugin, only: [description: 1]

            # Let’s also store the upcase option in an attribute so we can
            # access it from the code injected by our `description/1` macro.
            @upcase unquote(opts)[:upcase]
          end
        end

        # This is a public macro our users can call in their typedstruct blocks.
        @spec description(String.t()) :: Macro.t()
        defmacro description(description) do
          quote do
            # Here we simply evaluate the result of __description__/2. We need
            # this indirection to be able to use @upcase after is has been
            # evaluated, but still in the code generation process. This way, we
            # can upcase the strings *at build time* if needed. It’s just a tiny
            # refinement :-)
            Module.eval_quoted(
              __MODULE__,
              TypedStructDemoPlugin.__description__(__MODULE__, unquote(description))
            )
          end
        end

        @spec __description__(module(), String.t()) :: Macro.t()
        def __description__(module, description) do
          # Maybe upcase the description at build time.
          description =
            module
            |> Module.get_attribute(:upcase)
            |> maybe_upcase(description)

          quote do
            # Let’s just generate a constant function that returns the
            # description.
            def struct_description, do: unquote(description)
          end
        end

        # The field callback is called for each field defined in the typedstruct
        # block. You get exactly what the user has passed to the field macro,
        # plus options from every plugin init.
        @impl true
        @spec field(atom(), any(), keyword()) :: Macro.t()
        def field(name, _type, opts) do
          # Same as for the struct description, we want to upcase at build time
          # if necessary. As we do not have access to the module here, we cannot
          # access @upcase. This is not an issue since the option is
          # automatically added to `opts`, in addition to the options passed to
          # the field macro.
          description = maybe_upcase(opts[:upcase], opts[:description] || "")

          quote do
            # We define a clause matching the field name returning its optional
            # description.
            def field_description(unquote(name)), do: unquote(description)
          end
        end

        defp maybe_upcase(true, description), do: String.upcase(description)
        defp maybe_upcase(_, description), do: description

        # The after_definition callback is called after the struct and its type
        # have been defined, at the end of the `typedstruct` block.
        @impl true
        @spec after_definition(opts :: keyword()) :: Macro.t()
        def after_definition(_opts) do
          quote do
            # Here we just clean the @upcase attribute so that it does not
            # pollute our user’s modules.
            Module.delete_attribute(__MODULE__, :upcase)
          end
        end
      end
  """

  @doc """
  Injects code where `TypedStruct.plugin/2` is called.
  """
  @macrocallback init(opts :: keyword()) :: Macro.t()

  @doc """
  Injects code after each field definition.

  `name` and `type` are the exact values passed to the `TypedStruct.field/3`
  macro in the `typedstruct` block. `opts` is the concatenation of the options
  passed to the `field` macro and those from the plugin init.
  """
  @callback field(name :: atom(), type :: any(), opts :: keyword()) ::
              Macro.t()

  @doc """
  Injects code after the struct and its type have been defined.
  """
  @callback after_definition(opts :: keyword()) :: Macro.t()

  # All the callbacks are optional so the user has more flexibility. Only init/1
  # is mandatory but an overrideable default is defined when use-ing the module.
  @optional_callbacks [field: 3, after_definition: 1]

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour TypedStruct.Plugin

      @doc false
      defmacro init(_opts), do: nil
      defoverridable init: 1
    end
  end
end
