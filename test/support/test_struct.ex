# SPDX-FileCopyrightText: 2018, 2020, 2025 Jean-Philippe Cugnet <jean-philippe@cugnet.eu>
# SPDX-FileCopyrightText: 2018 Marcin Górnik <marcin.gornik@gmail.com>
# SPDX-FileCopyrightText: 2022 Phil Chen <06fahchen@gmail.com>
# SPDX-FileCopyrightText: 2023 Serge Aleynikov <saleyn@gmail.com>
#
# SPDX-License-Identifier: MIT

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

  defmodule WithParameter do
    @moduledoc """
    A struct with a parameterised type.
    """
    use TypedStruct

    typedstruct do
      parameter :t1
      parameter :t2

      field :field_t1, t1
      field :field_t2, t2
      field :enforced_field_t1, t1, enforce: true
    end

    defmodule Expected do
      @moduledoc """
      `WithParameter` but defined manually.
      """

      @enforce_keys [:enforced_field_t1]
      defstruct [:field_t1, :field_t2, :enforced_field_t1]

      @type t(t1, t2) :: %__MODULE__{
              field_t1: t1 | nil,
              field_t2: t2 | nil,
              enforced_field_t1: t1
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

  defmodule SimpleTypedoc do
    @moduledoc """
    A typed struct with a `@typedoc`.
    """
    use TypedStruct

    @typedoc "A typed struct"
    typedstruct do
      field :field, term()
    end
  end

  defmodule DetailedTypedoc do
    @moduledoc """
    A typed struct with a `@typedoc`.
    """
    use TypedStruct

    @typedoc "A typed struct"
    typedstruct do
      field :a_string, String.t(), doc: "just a series of letters"
      field :an_int, integer(), doc: "some digits"
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
