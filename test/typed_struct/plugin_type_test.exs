defmodule TypedStruct.PluginEnvTest do
  @moduledoc """
  Test the the env argument in the field/4 plugin callback.
  """

  use ExUnit.Case

  ############################################################################
  ##                               Test data                                ##
  ############################################################################

  defmodule TestPlugin do
    use TypedStruct.Plugin

    @impl true
    def field(name, type, _opts, env) do
      module = module_from_type(type, env)

      quote do
        def get_meaning_of_life(unquote(name)) do
          unquote(module).meaning_of_life()
        end
      end
    end

    defp module_from_type(type_ast, env) do
      {_ast, module} =
        Macro.prewalk(type_ast, nil, fn
          {:__aliases__, _meta, _list} = ast, nil ->
            mod = Macro.expand(ast, env)
            {ast, mod}

          ast, acc ->
            {ast, acc}
        end)

      module
    end
  end

  defmodule TestDependency do
    def meaning_of_life, do: 42
  end

  defmodule TestModule do
    alias TestDependency, as: FirstDependency
    use TypedStruct

    typedstruct do
      plugin TestPlugin
      alias TestDependency, as: SecondDependency
      field :first, FirstDependency.t()
      field :second, SecondDependency.t()
    end
  end

  ############################################################################
  ##                                 Tests                                  ##
  ############################################################################

  test "The field/4 env includes aliases made prior to typedstruct call" do
    assert TestModule.get_meaning_of_life(:first) == 42
  end

  test "The field/4 env includes aliases made within typedstruct call" do
    assert TestModule.get_meaning_of_life(:second) == 42
  end
end
