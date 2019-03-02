defmodule TypedStruct.PluginTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule TestPlugin do
    @behaviour TypedStruct.Plugin

    @impl true
    def field(mod, name, _type, _opts) do
      Module.put_attribute(
        mod,
        :plugin_fields,
        {name, String.length(Atom.to_string(name))}
      )
    end
  end

  defmodule StructWithPlugin do
    use TypedStruct
    Module.put_attribute(__MODULE__, :plugin_attribute, "foo")

    Module.register_attribute(__MODULE__, :plugin_fields, accumulate: true)

    typedstruct do
      plugin(TestPlugin)
      field :int, integer()
      field :string, String.t()
      field :string_with_default, String.t(), default: "default"
      field :mandatory_int, integer(), enforce: true
    end

    def test_plugin_method do
      "Got test plugin method"
    end

    def plugin_fields do
      @plugin_fields
    end
  end

  defmodule StructWithPluginsOpt do
    use TypedStruct
    Module.put_attribute(__MODULE__, :plugin_attribute, "foo")

    Module.register_attribute(__MODULE__, :plugin_fields, accumulate: true)

    typedstruct plugins: [TestPlugin] do
      field :int, integer()
      field :string, String.t()
      field :string_with_default, String.t(), default: "default"
      field :mandatory_int, integer(), enforce: true
    end

    def test_plugin_method do
      "Got test plugin method"
    end

    def plugin_fields do
      @plugin_fields
    end
  end

  describe "StruthWithPlugin" do
    test "plugin_after macro works" do
      assert StructWithPlugin.test_plugin_method() == "Got test plugin method"
    end

    test "plugin field method is called" do
      assert StructWithPlugin.plugin_fields() == [
               mandatory_int: 13,
               string_with_default: 19,
               string: 6,
               int: 3
             ]
    end
  end

  describe "StructWithPluginOpts" do
    test "plugin_after macro works " do
      assert StructWithPluginsOpt.test_plugin_method() ==
               "Got test plugin method"
    end

    test "plugin field method is called" do
      assert StructWithPluginsOpt.plugin_fields() == [
               mandatory_int: 13,
               string_with_default: 19,
               string: 6,
               int: 3
             ]
    end
  end
end
