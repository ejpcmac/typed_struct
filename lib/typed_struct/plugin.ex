defmodule TypedStruct.Plugin do
  @moduledoc """
  This module defines the plugin interface for TypedStruct.
  """

  # TODO: Documentation.

  @macrocallback init(opts :: keyword()) :: Macro.t()

  @callback field(name :: atom(), type :: any(), opts :: keyword()) ::
              Macro.t()

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
