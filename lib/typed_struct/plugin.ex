defmodule TypedStruct.Plugin do
  @moduledoc """
  This module defines the plugin interface for TypedStruct.
  """

  # TODO: Documentation.

  @macrocallback init(opts :: keyword()) :: Macro.t()

  @callback field(name :: atom(), type :: any(), opts :: keyword()) ::
              Macro.t()

  @callback after_definition(opts :: keyword()) :: Macro.t()

  # All the callbacks are optional so the user has more flexibility.
  @optional_callbacks [init: 1, field: 3, after_definition: 1]
end
