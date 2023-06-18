defmodule TypedStructTest do
  use ExUnit.Case

  import TypedStructs
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

end
