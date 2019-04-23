defmodule TypedStruct.Plugin do
  @moduledoc """
  A plugin can be created to extend the usage of TypedStruct. It works by passing all the args and
  options from `TypedStruct.field/3` to the `c:field/4` callback.

  ## Example
        defmodule TestPlugin do
          @behaviour TypedStruct.Plugin

          @impl true
          def field(mod, name, _type, _opts) do
            #this attribute needs to already be defined on `mod` with Module.register_attribute/3
            attr_item = {name, String.length(Atom.to_string(name))}
            Module.put_attribute( mod, :plugin_fields, attr_item)
          end
        end
  """

  @doc """
  Called for each `TypedStruct.field/3` call.

  The result of this call is discarded. Implementors should use `Module.put_attribute/3` in order to
  create local state to be used in other functions.

  All arguments are the same as `TypedStruct.field/3` with the exception of `mod`,  which is the
  name of the module where the function is being called.
  """
  @callback field(mod :: module, name :: atom, type :: any, opts :: keyword) ::
              no_return
end
