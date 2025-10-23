defmodule TypedStruct.TestStruct do
  @moduledoc """
  A collection of test structs.

  Each submodule defines a struct defined with TypedStruct. In the relevant
  cases, they also feature an `Expected` submodule that defines the same struct
  manually for comparison purpose.
  """

  defmodule BaseFeatures do
    @moduledoc """
    A struct using the base features of `TypedStruct`.
    """
    use TypedStruct

    typedstruct do
      field :int, integer()
      field :string, String.t()
      field :string_with_default, String.t(), default: "default"
      field :mandatory_int, integer(), enforce: true
    end

    def enforce_keys, do: @enforce_keys

    defmodule Expected do
      @moduledoc """
      `BaseFeatures` but defined manually.
      """
      defstruct [:int, :string, :string_with_default, :mandatory_int]

      @type t() :: %__MODULE__{
              int: integer() | nil,
              string: String.t() | nil,
              string_with_default: String.t(),
              mandatory_int: integer()
            }
    end
  end

  defmodule Enforced do
    @moduledoc """
    A struct whose fields are enforced by default.
    """
    use TypedStruct

    typedstruct enforce: true do
      field :enforced_by_default, term()
      field :not_enforced, term(), enforce: false
      field :with_default, integer(), default: 1
      field :with_false_default, boolean(), default: false
      field :with_nil_default, term(), default: nil
    end

    def enforce_keys, do: @enforce_keys
  end

  defmodule Opaque do
    @moduledoc """
    A struct whose type is opaque.
    """
    use TypedStruct

    typedstruct opaque: true do
      field :int, integer()
    end

    defmodule Expected do
      @moduledoc """
      `Opaque` but defined manually.
      """
      defstruct [:int]

      @opaque t() :: %__MODULE__{
                int: integer() | nil
              }
    end
  end

  defmodule AsSubmodule do
    @moduledoc """
    A struct defined as a submodule.
    """
    use TypedStruct

    typedstruct module: Struct do
      field :field, term()
    end
  end

  defmodule Alias do
    @moduledoc """
    Structs for testing the use of aliases in types.
    """

    defmodule Without do
      @moduledoc """
      A struct whose type does not contain an alias.
      """
      use TypedStruct

      typedstruct do
        # credo:disable-for-next-line Credo.Check.Design.AliasUsage
        field :test, TypedStruct.TestStruct.Opaque.t()
      end
    end

    defmodule With do
      @moduledoc """
      A struct whose type contains an alias.
      """
      use TypedStruct

      typedstruct do
        alias TypedStruct.TestStruct.Opaque

        field :test, Opaque.t()
      end
    end
  end
end
