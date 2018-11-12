defmodule TypedStructTest do
  use ExUnit.Case

  # Store the bytecode so we can get information from it.
  {:module, _name, bytecode, _exports} =
    defmodule TestStruct do
      use TypedStruct

      typedstruct do
        field :int, integer()
        field :string, String.t()
        field :string_with_default, String.t(), default: "default"
        field :mandatory_int, integer(), enforce: true
      end

      def enforce_keys, do: @enforce_keys
    end

  {:module, _name, bytecode_opaque, _exports} =
    defmodule OpaqueTestStruct do
      use TypedStruct

      typedstruct opaque: true do
        field :int, integer()
      end
    end

  defmodule EnforcedTypedStruct do
    use TypedStruct

    typedstruct enforce: true do
      field :enforced_by_default, term()
      field :not_enforced, term(), enforce: false
      field :with_default, integer(), default: 1
      field :with_false_default, boolean(), default: false
    end

    def enforce_keys, do: @enforce_keys
  end

  @bytecode bytecode
  @bytecode_opaque bytecode_opaque
  # standard struct name used when comparing generated types
  @standard_struct_name TypedStructTest.TestStruct

  ## Standard cases

  test "generates the struct with its defaults" do
    assert TestStruct.__struct__() == %TestStruct{
             int: nil,
             string: nil,
             string_with_default: "default",
             mandatory_int: nil
           }
  end

  test "enforces keys for fields with `enforce: true`" do
    assert TestStruct.enforce_keys() == [:mandatory_int]
  end

  test "enforces keys by default if `enforce: true` is set at top-level" do
    assert :enforced_by_default in EnforcedTypedStruct.enforce_keys()
  end

  test "does not enforce keys for fields explicitely setting `enforce: false" do
    refute :not_enforced in EnforcedTypedStruct.enforce_keys()
  end

  test "does not enforce keys for fields with a default value" do
    refute :with_default in EnforcedTypedStruct.enforce_keys()
  end

  test "does not enforce keys for fields with a default value set to `false`" do
    refute :with_false_default in EnforcedTypedStruct.enforce_keys()
  end

  test "generates a type for the struct" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode2, _exports} =
      defmodule TestStruct2 do
        defstruct [:int, :string, :string_with_default, :mandatory_int]

        @type t() :: %__MODULE__{
                int: integer() | nil,
                string: String.t() | nil,
                string_with_default: String.t(),
                mandatory_int: integer()
              }
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 = @bytecode |> extract_first_type() |> standardise()

    type2 =
      bytecode2
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStruct2)

    assert type1 == type2
  end

  test "generates an type for the struct if `opaque: true` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_expected, _exports} =
      defmodule TestStruct3 do
        defstruct [:int]

        @opaque t() :: %__MODULE__{
                  int: integer() | nil
                }
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      @bytecode_opaque
      |> extract_first_type(:opaque)
      |> standardise(TypedStructTest.OpaqueTestStruct)

    type2 =
      bytecode_expected
      |> extract_first_type(:opaque)
      |> standardise(TypedStructTest.TestStruct3)

    assert type1 == type2
  end

  test "generates a function to get the struct keys" do
    assert TestStruct.__keys__() == [
             :int,
             :string,
             :string_with_default,
             :mandatory_int
           ]
  end

  test "generates a function to get the struct defaults" do
    assert TestStruct.__defaults__() == [
             int: nil,
             string: nil,
             string_with_default: "default",
             mandatory_int: nil
           ]
  end

  test "generates a function to get the struct types" do
    types =
      quote do
        [
          int: integer() | nil,
          string: String.t() | nil,
          string_with_default: String.t(),
          mandatory_int: integer()
        ]
      end

    assert delete_context(TestStruct.__types__()) == delete_context(types)
  end

  ## Problems

  test "the name of a field must be an atom" do
    assert_raise ArgumentError, "a field name must be an atom, got 3", fn ->
      defmodule InvalidStruct do
        use TypedStruct

        typedstruct do
          field 3, integer()
        end
      end
    end
  end

  test "it is not possible to add twice a field with the same name" do
    assert_raise ArgumentError, "the field :name is already set", fn ->
      defmodule InvalidStruct do
        use TypedStruct

        typedstruct do
          field :name, String.t()
          field :name, integer()
        end
      end
    end
  end

  ##
  ## Helpers
  ##

  @elixir_version System.version() |> Version.parse!()
  @min_version Version.parse!("1.7.0-rc")

  # Extracts the first type from a module.
  # NOTE: We define the function differently depending on the Elixir version to
  # avoid compiler warnings.
  if Version.compare(@elixir_version, @min_version) == :lt do
    # API for Elixir 1.6 (TODO: Remove when 1.6 compatibility is dropped.)
    defp extract_first_type(bytecode, type_keyword \\ :type) do
      bytecode
      |> Kernel.Typespec.beam_types()
      |> Keyword.get(type_keyword)
    end
  else
    # API for Elixir 1.7
    defp extract_first_type(bytecode, type_keyword \\ :type) do
      case Code.Typespec.fetch_types(bytecode) do
        {:ok, types} -> Keyword.get(types, type_keyword)
        _ -> nil
      end
    end
  end

  # Standardises a type (removes line numbers and renames the struct
  # to the standard struct name).
  defp standardise(type_info, struct \\ @standard_struct_name)

  defp standardise({name, type, params}, struct) when is_tuple(type),
    do: {name, standardise(type, struct), params}

  defp standardise({:type, _, type, params}, struct),
    do: {:type, :line, type, standardise(params, struct)}

  defp standardise({:remote_type, _, params}, struct),
    do: {:remote_type, :line, standardise(params, struct)}

  defp standardise({:atom, _, struct}, struct),
    do: {:atom, :line, @standard_struct_name}

  defp standardise({type, _, litteral}, _struct),
    do: {type, :line, litteral}

  defp standardise(list, struct) when is_list(list),
    do: Enum.map(list, &standardise(&1, struct))

  # Deletes the context from a quoted expression.
  defp delete_context(list) when is_list(list),
    do: Enum.map(list, &delete_context/1)

  defp delete_context({a, b}),
    do: {delete_context(a), delete_context(b)}

  defp delete_context({fun, _context, args}),
    do: {delete_context(fun), [], delete_context(args)}

  defp delete_context(other), do: other
end
