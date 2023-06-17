defmodule TypedStruct.PluginTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  ############################################################################
  ##                               Test data                                ##
  ############################################################################

  defmodule TestPlugin do
    @moduledoc """
    A TypedStruct plugin for test purpose.
    """
    use TypedStruct.Plugin

    # We define here a function just for the purpose of making it available in
    # the typedstruct block when using the plugin.
    def function_from_plugin, do: true

    @impl true
    defmacro init(opts) do
      quote do
        # Import function_from_plugin/0 for scope tests.
        import TestPlugin, only: [function_from_plugin: 0]

        Module.register_attribute(
          __MODULE__,
          :test_field_list,
          accumulate: true
        )

        # Define a function to test code injection in the module.
        def function_defined_by_the_plugin, do: true

        # Make the options inspectable.
        def plugin_init_options, do: unquote(opts)
      end
    end

    @impl true
    def field(name, _type, opts, _env) do
      quote do
        # Keep a list of the fields on which it has been called.
        Module.put_attribute(__MODULE__, :test_field_list, unquote(name))

        # Define a function to test code injection in the module.
        def function_defined_by_the_plugin_for(unquote(name)), do: unquote(name)

        # Make the options inspectable by field.
        def options_for(unquote(name)), do: unquote(opts)
      end
    end

    @impl true
    def after_definition(opts) do
      quote do
        # Define a function to test code injection in the module.
        def function_defined_by_the_plugin_after_definition, do: true

        # Make the options inspectable.
        def plugin_after_definition_options, do: unquote(opts)

        # Make the list of fields built by our field/4 callback inspectable.
        def test_field_list, do: @test_field_list

        # If @enforce_keys is valid, it means the struct has been defined by
        # TypedStruct before calling after_definition/1.
        def should_contain_enforced_keys, do: @enforce_keys
      end
    end
  end

  defmodule TestStruct do
    @moduledoc """
    A test struct using our test plugin.
    """
    use TypedStruct

    typedstruct do
      plugin TestPlugin, global: :global_value

      field :a_field, atom(), local: :local_value
      field :another_field, String.t(), enforce: true

      # This is ugly to define something else in the typedstruct block, but
      # let’s use it to check if the plugin’s init/1 macro make code available
      # to use here.
      def call_function_from_plugin, do: function_from_plugin()
    end
  end

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "all callbacks are optional to define" do
    defmodule EmptyPlugin do
      use TypedStruct.Plugin
    end
  end

  test "quoted code in init/1 is available in the typedstruct block" do
    assert TestStruct.call_function_from_plugin()
  end

  test "init/1 can inject code in the compiled module" do
    assert TestStruct.function_defined_by_the_plugin()
  end

  test "init/1 is called with the options passed to plugin/2" do
    assert TestStruct.plugin_init_options() == [global: :global_value]
  end

  test "field/4 is called on each field declaration" do
    assert TestStruct.test_field_list() == [:another_field, :a_field]
  end

  test "field/4 can inject code in the compiled module" do
    assert TestStruct.function_defined_by_the_plugin_for(:a_field) == :a_field
  end

  test "field/4 is called with both local and global options" do
    assert TestStruct.options_for(:a_field) == [
             local: :local_value,
             global: :global_value
           ]

    assert TestStruct.options_for(:another_field) == [
             enforce: true,
             global: :global_value
           ]
  end

  test "after_definition/1 is called after the struct has been defined" do
    assert TestStruct.should_contain_enforced_keys() == [:another_field]
  end

  test "after_definition/1 is called with the options passed to plugin/2" do
    assert TestStruct.plugin_after_definition_options() == [
             global: :global_value
           ]
  end

  test "after_definition/1 can inject code in the compiled module" do
    assert TestStruct.function_defined_by_the_plugin_after_definition()
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "the code inserted by init/1 is scoped to the typedstruct block" do
    assert_raise CompileError,
                 if(Version.compare(System.version(), "1.14.9") == :lt,
                   do: ~r"undefined function function_from_plugin/0",
                   else:
                     ~r"cannot compile module TypedStruct.PluginTest.UseImportedFunctionOutsideOfBlock"
                 ),
                 fn ->
                   capture_io(:stderr, fn ->
                     defmodule UseImportedFunctionOutsideOfBlock do
                       use TypedStruct

                       typedstruct do
                         # TestPlugin.init/1 imports function_from_plugin/0.
                         plugin TestPlugin
                       end

                       # function_from_plugin/0 must not be available here.
                       def call_function_from_plugin, do: function_from_plugin()
                     end
                   end)
                 end
  end

  test "defining field/3 emits a deprecation warning" do
    assert capture_io(:stderr, fn ->
             defmodule PluginWithField3 do
               use TypedStruct.Plugin

               def field(_name, _type, _opts), do: nil
             end
           end) =~ "PluginWithField3 defines field/3, which is deprecated."
  end

  test "defining both field/3 and field/4 emits a compilation warning" do
    assert capture_io(:stderr, fn ->
             defmodule PluginWithField3And4 do
               use TypedStruct.Plugin

               def field(_name, _type, _opts), do: nil
               def field(_name, _type, _opts, _env), do: nil
             end
           end) =~ "PluginWithField3And4 defines both field/3 and field/4"
  end
end
