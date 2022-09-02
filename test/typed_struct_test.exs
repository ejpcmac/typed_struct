defmodule TypedStructTest do
  use ExUnit.Case

  ############################################################################
  ##                               Test data                                ##
  ############################################################################

  # Store the bytecode so we can get information from it.
  {:module, _name, bytecodepublic1, _exports} =
    defmodule TestStructPublic1 do
      use TypedStruct

      typedstruct do
        field :int, integer()
        field :string, String.t()
        field :string_with_default, String.t(), default: "default"
        field :mandatory_int, integer(), enforce: true
      end

      def enforce_keys, do: @enforce_keys
    end

  {:module, _name, bytecodepublic2, _exports} =
    defmodule TestStructPublic2 do
      use TypedStruct

      typedstruct visibility: :public do
        field :int, integer()
        field :string, String.t()
        field :string_with_default, String.t(), default: "default"
        field :mandatory_int, integer(), enforce: true
      end

      def enforce_keys, do: @enforce_keys
    end

  {:module, _name, bytecode_opaque1, _exports} =
    defmodule OpaqueTestStruct1 do
      use TypedStruct

      typedstruct opaque: true do
        field :int, integer()
      end
    end

  {:module, _name, bytecode_opaque2, _exports} =
    defmodule OpaqueTestStruct2 do
      use TypedStruct

      typedstruct visibility: :opaque do
        field :int, integer()
      end
    end

  {:module, _name, bytecode_private, _exports} =
    defmodule PrivateTestStruct do
      use TypedStruct

      typedstruct visibility: :private do
        field :int, integer()
      end

      # Needed so that the compiler doesn't remove unused private type t()
      @opaque tt :: t
    end

  defmodule EnforcedTypedStruct do
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

  defmodule TestModule do
    use TypedStruct

    typedstruct module: Struct do
      field :field, term()
    end
  end

  {:module, _name, bytecode_noalias, _exports} =
    defmodule TestStructNoAlias do
      use TypedStruct

      typedstruct do
        field :test, TestModule.TestSubModule.t()
      end
    end

  @bytecode1 bytecodepublic1
  @bytecode2 bytecodepublic2
  @bytecode_opaque1 bytecode_opaque1
  @bytecode_opaque2 bytecode_opaque2
  @bytecode_private bytecode_private
  @bytecode_noalias bytecode_noalias

  # Standard struct name used when comparing generated types.
  @standard_struct_name TypedStructTest.TestStruct

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "generates the struct with its defaults" do
    assert TestStructPublic1.__struct__() == %TestStructPublic1{
             int: nil,
             string: nil,
             string_with_default: "default",
             mandatory_int: nil
           }
  end

  test "enforces keys for fields with `enforce: true`" do
    assert TestStructPublic1.enforce_keys() == [:mandatory_int]
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

  test "does not enforce keys for fields with a default value set to `nil`" do
    refute :with_nil_default in EnforcedTypedStruct.enforce_keys()
  end

  test "generates a type for the struct in default case or if `visibility: :public` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode2, _exports} =
      defmodule TestStruct1 do
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
    type1 =
      @bytecode1
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStructPublic1)

    type2 =
      bytecode2
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStruct1)

    assert type1 == type2

    type3 =
      @bytecode2
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStructPublic2)

    assert type3 == type2
  end

  test "generates an opaque type if `opaque: true` or `visibility: :opaque` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_expected, _exports} =
      defmodule TestStruct2 do
        defstruct [:int]

        @opaque t() :: %__MODULE__{
                  int: integer() | nil
                }
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      @bytecode_opaque1
      |> extract_first_type(:opaque)
      |> standardise(TypedStructTest.OpaqueTestStruct1)

    type2 =
      bytecode_expected
      |> extract_first_type(:opaque)
      |> standardise(TypedStructTest.TestStruct2)

    assert type1 == type2

    type3 =
      @bytecode_opaque2
      |> extract_first_type(:opaque)
      |> standardise(TypedStructTest.OpaqueTestStruct2)

    assert type3 == type2
  end

  test "generates a private type if `visibility: private` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_private_expected, _exports} =
      defmodule TestStruct3 do
        defstruct [:int]

        @typep t :: %__MODULE__{int: integer() | nil}
        @opaque t2 :: t
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      @bytecode_private
      |> extract_first_type(:typep)
      |> standardise(TypedStructTest.PrivateTestStruct)

    type2 =
      bytecode_private_expected
      |> extract_first_type(:typep)
      |> standardise(TypedStructTest.TestStruct3)

    assert type1 == type2
  end

  test "generates the struct in a submodule if `module: ModuleName` is set" do
    assert TestModule.Struct.__struct__() == %TestModule.Struct{field: nil}
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "TypedStruct macros are available only in the typedstruct block" do
    assert_raise CompileError, ~r"undefined function field/2", fn ->
      defmodule ScopeTest do
        use TypedStruct

        typedstruct do
          field :in_scope, term()
        end

        # Let’s try to use field/2 outside the block.
        field :out_of_scope, term()
      end
    end
  end

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

  test "aliases are properly resolved in types" do
    {:module, _name, bytecode_actual, _exports} =
      defmodule TestStructWithAlias do
        use TypedStruct

        typedstruct do
          alias TestModule.TestSubModule

          field :test, TestSubModule.t()
        end
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      @bytecode_noalias
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStructNoAlias)

    type2 =
      bytecode_actual
      |> extract_first_type()
      |> standardise(TypedStructTest.TestStructWithAlias)

    assert type1 == type2
  end

  ############################################################################
  ##                                Helpers                                 ##
  ############################################################################

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword \\ :type) do
    case Code.Typespec.fetch_types(bytecode) do
      {:ok, types} -> Keyword.get(types, type_keyword)
      _ -> nil
    end
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
    do: {:atom, :line, @standard_struct_name}

  defp standardise({type, _, litteral}, _struct),
    do: {type, :line, litteral}

  defp standardise(list, struct) when is_list(list),
    do: Enum.map(list, &standardise(&1, struct))
end
