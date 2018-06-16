defmodule TypedStructTest do
  use ExUnit.Case

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
end
