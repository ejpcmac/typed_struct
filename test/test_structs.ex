defmodule TypedStructs do
  ############################################################################
  ##                                Helpers                                 ##
  ############################################################################

  def standardize_first_type(module, type_keyword \\ :type)
       when is_atom(module) do
    extract_first_type(module, type_keyword)
    |> standardise(module)
  end

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword)

  defp extract_first_type(bytecode, type_keyword) when is_binary(bytecode) do
    case Code.Typespec.fetch_types(bytecode) do
      {:ok, types} -> Keyword.get(types, type_keyword)
      _ -> nil
    end
  end

  defp extract_first_type(module, type_keyword) when is_atom(module) do
    {_, bytecode, _} = :code.get_object_code(module)
    extract_first_type(bytecode, type_keyword)
  end

  # Standardises a type (removes line numbers and renames the struct to the
  # standard struct name).
  defp standardise(type_info, struct)

  defp standardise({name, type, params}, struct) when is_tuple(type),
    do: {name, standardise(type, struct), params}

  defp standardise({:type, _, type, params}, struct),
    do: {:type, :line, type, standardise(params, struct)}

  defp standardise({:remote_type, _, params}, struct),
    do: {:remote_type, :line, standardise(params, struct)}

  defp standardise({:atom, _, struct}, struct),
    do: {:atom, :line, Placeholder}

  defp standardise({type, _, litteral}, _struct),
    do: {type, :line, litteral}

  defp standardise(list, struct) when is_list(list),
    do: Enum.map(list, &standardise(&1, struct))


  ############################################################################
  ##                                Helpers                                 ##
  ############################################################################

#  defp standardize_first_type(module, type_keyword \\ :type)
#       when is_atom(module) do
#    extract_first_type(module, type_keyword)
#    |> standardise(module)
#  end
#
#  # Extracts the first type from a module.
#  defp extract_first_type(bytecode, type_keyword)
#
#  defp extract_first_type(bytecode, type_keyword) when is_binary(bytecode) do
#    case Code.Typespec.fetch_types(bytecode) do
#      {:ok, types} -> Keyword.get(types, type_keyword)
#      _ -> nil
#    end
#  end
#
#  defp extract_first_type(module, type_keyword) when is_atom(module) do
#    {_, bytecode, _} = :code.get_object_code(module)
#    extract_first_type(bytecode, type_keyword)
#  end
#
#  # Standardises a type (removes line numbers and renames the struct to the
#  # standard struct name).
#  defp standardise(type_info, struct)
#
#  defp standardise({name, type, params}, struct) when is_tuple(type),
#    do: {name, standardise(type, struct), params}
#
#  defp standardise({:type, _, :union, list}, struct) when is_list(list) do
#    list =
#      Enum.map(list, &standardise(&1, struct))
#      |> Enum.filter(&(&1 != nil and &1 != []))
#
#    case list do
#      [one] -> standardise(one, struct)
#      _ -> {:type, :line, list}
#    end
#  end
#
#  defp standardise({:type, _, :union, [value, nil]}, struct),
#    do: {:type, :line, standardise(value, struct)}
#
#  defp standardise({:type, _, type, params}, struct),
#    do: {:type, :line, type, standardise(params, struct)}
#
#  defp standardise({:remote_type, _, params}, struct),
#    do: {:remote_type, :line, standardise(params, struct)}
#
#  defp standardise({:atom, _, struct}, struct),
#    do: {:atom, :line, TypedRecord.Record.Actual}
#
#  defp standardise({type, _, litteral}, _struct),
#    do: {type, :line, litteral}
#
#  defp standardise(list, struct) when is_list(list),
#    do: Enum.map(list, &standardise(&1, struct))
end

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
