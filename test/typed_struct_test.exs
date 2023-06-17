defmodule TypedStructTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  ############################################################################
  ##                               Test data                                ##
  ############################################################################

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

  # Standard struct name used when comparing generated types.
  @standard_struct_name TypedStructTest.TestStruct

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "generates the struct with its defaults" do
    assert TypedStructs.TestStruct.Actual.__struct__() ==
             %TypedStructs.TestStruct.Actual{
               int: nil,
               string: nil,
               string_with_default: "default",
               mandatory_int: nil
             }
  end

  test "enforces keys for fields with `enforce: true`" do
    assert TypedStructs.TestStruct.Actual.enforce_keys() == [:mandatory_int]
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

  test "generates a type for the struct in default case" do
    # Define a second struct with the type expected for TestStruct.

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 = standardize_first_type(TypedStructs.TestStruct.Actual)
    type2 = standardize_first_type(TypedStructs.TestStruct.Expected)

    assert type1 == type2
  end

  test "generates a type for the struct if the `visibility: :public` is set" do
    type1 = standardize_first_type(TypedStructs.PublicTestStruct.Actual)
    type2 = standardize_first_type(TypedStructs.PublicTestStruct.Expected)

    assert type1 == type2
  end

  test "generates an opaque type if `visibility: :opaque` is set" do
    type1 =
      standardize_first_type(TypedStructs.OpaqueTestStruct.Actual, :opaque)

    type2 =
      standardize_first_type(TypedStructs.OpaqueTestStruct.Expected, :opaque)

    assert type1 == type2
  end

  test "generates a private type if `visibility: private` is set" do
    type1 =
      standardize_first_type(TypedStructs.PrivateTestStruct.Actual, :typep)

    type2 =
      standardize_first_type(TypedStructs.PrivateTestStruct.Expected, :typep)

    assert type1 == type2
  end

  test "generates the struct in a submodule if `module: ModuleName` is set" do
    assert TestModule.Struct.__struct__() == %TestModule.Struct{field: nil}
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "TypedStruct macros are available only in the typedstruct block" do
    assert_raise CompileError,
                 if(Version.compare(System.version(), "1.14.9") == :lt,
                   do: ~r"undefined function field/2",
                   else: ~r"cannot compile module TypedStructTest.ScopeTest"
                 ),
                 fn ->
                   capture_io(:stderr, fn ->
                     defmodule ScopeTest do
                       use TypedStruct

                       typedstruct do
                         field :in_scope, term()
                       end

                       # Let’s try to use field/2 outside the block.
                       field :out_of_scope, term()
                     end
                   end)
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
    type1 = standardize_first_type(TypedStructs.Alias.Without)
    type2 = standardize_first_type(TypedStructs.Alias.With)

    assert type1 == type2
  end

  ############################################################################
  ##                                Helpers                                 ##
  ############################################################################

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword \\ :type)

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

  defp standardize_first_type(module, type_keyword \\ :type)
       when is_atom(module) do
    extract_first_type(module, type_keyword)
    |> standardise(module)
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
