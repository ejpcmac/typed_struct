defmodule TypedRecordTest do
  use ExUnit.Case

  import TypedStructs

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "generates the record with its defaults" do
    require TypedRecord.Record.Actual
    assert TypedRecord.Record.Actual.user() == {:user, 1, nil, "def", :hi}
  end

  test "generates a type for the record in default case" do
    type1 = standardize_first_type(TypedRecord.Record.Actual)
    type2 = standardize_first_type(TypedRecord.Record.Expected)

    assert type1 == type2
  end

  test "generates a type for the record in default case with a record tag" do
    type1 = standardize_first_type(TypedRecord.Public.Actual)
    type2 = standardize_first_type(TypedRecord.Public.Expected)

    assert type1 == type2
  end

  test "generates a type for the record with the `visibility: :public`" do
    type1 = standardize_first_type(TypedRecord.VisibilityPublic.Actual)
    type2 = standardize_first_type(TypedRecord.VisibilityPublic.Expected)

    assert type1 == type2
  end

  test "generates an opaque type if `visibility: :opaque` is set" do
    type1 = standardize_first_type(TypedRecord.VisibilityOpaque.Actual, :opaque)
    type2 = standardize_first_type(TypedRecord.VisibilityOpaque.Expected, :opaque)

    assert type1 == type2
  end

  test "generates a private type if `visibility: private` is set" do
    type1 = standardize_first_type(TypedRecord.VisibilityPrivate.Actual, :typep)
    type2 = standardize_first_type(TypedRecord.VisibilityPrivate.Expected, :typep)

    assert type1 == type2
  end

  test "generates the struct in a submodule if `module: ModuleName` is set" do
    require TypedRecord.TestRecModule.Rec
    assert TypedRecord.TestRecModule.Rec.user() == {:user, 1}
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "Typedrecord field's name is not an atom" do
    assert_raise(
      ArgumentError,
      "a field name must be an atom, got \"one\"",
      fn ->
        defmodule TestRecordBadKeyType do
          use TypedStruct

          typedrecord :user do
            field "one", integer(), default: 1
            field :two, String.t()
            field :three, atom(), default: :hi
          end
        end
      end
    )
  end

  test "Typedrecord missing record name" do
    assert_raise CompileError,
                 if(Version.compare(System.version(), "1.14.9") == :lt,
                   do: ~r"undefined function typedrecord/1",
                   else: ~r"cannot compile module TypedRecordTest.ScopeTest"
                 ),
                 fn ->
                   ExUnit.CaptureIO.capture_io(:stderr, fn ->
                     defmodule ScopeTest do
                       use TypedStruct

                       typedrecord do
                         field :in_scope, term()
                       end
                     end
                   end)
                 end
  end

  test "it is not possible to add twice a field with the same name" do
    assert_raise ArgumentError, "the field :name is already set", fn ->
      defmodule InvalidStruct do
        use TypedStruct

        typedrecord :user do
          field :name, String.t()
          field :name, integer()
        end
      end
    end
  end
end
