defmodule TypedStructs.TestStruct do
  # Store the bytecode so we can get information from it.
  defmodule Actual do
    use TypedStruct

    typedstruct do
      field :int, integer()
      field :string, String.t()
      field :string_with_default, String.t(), default: "default"
      field :mandatory_int, integer(), enforce: true
    end

    def enforce_keys, do: @enforce_keys
  end

  defmodule Expected do
    defstruct [:int, :string, :string_with_default, :mandatory_int]

    @type t() :: %__MODULE__{
            int: integer() | nil,
            string: String.t() | nil,
            string_with_default: String.t(),
            mandatory_int: integer()
          }
  end
end

defmodule TypedStructs.PublicTestStruct do
  defmodule Actual do
    use TypedStruct

    typedstruct visibility: :public do
      field :int, integer()
      field :string, String.t()
      field :string_with_default, String.t(), default: "default"
      field :mandatory_int, integer(), enforce: true
    end

    def enforce_keys, do: @enforce_keys
  end

  # Define a second struct with the type expected for TestStruct.
  defmodule Expected do
    defstruct [:int, :string, :string_with_default, :mandatory_int]

    @type t() :: %__MODULE__{
            int: integer() | nil,
            string: String.t() | nil,
            string_with_default: String.t(),
            mandatory_int: integer()
          }
  end
end

defmodule TypedStructs.OpaqueTestStruct do
  defmodule Actual do
    use TypedStruct

    typedstruct visibility: :opaque do
      field :int, integer()
    end
  end

  defmodule Expected do
    defstruct [:int]

    @opaque t() :: %__MODULE__{
              int: integer() | nil
            }
  end
end

defmodule TypedStructs.PrivateTestStruct do
  defmodule Actual do
    use TypedStruct

    typedstruct visibility: :private do
      field :int, integer()
    end

    # Needed so that the compiler doesn't remove unused private type t()
    @opaque tt :: t
  end

  defmodule Expected do
    defstruct [:int]

    @typep t :: %__MODULE__{int: integer() | nil}
    @opaque t2 :: t
  end
end

defmodule TypedStructs.Alias do
  defmodule Without do
    use TypedStruct

    typedstruct do
      field :test, TestModule.TestSubModule.t()
    end
  end

  defmodule With do
    use TypedStruct

    typedstruct do
      alias TestModule.TestSubModule

      field :test, TestSubModule.t()
    end
  end
end
