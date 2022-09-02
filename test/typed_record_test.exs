defmodule TypedRecordTest do
  use ExUnit.Case

  ############################################################################
  ##                               Test data                                ##
  ############################################################################

  # Store the bytecode so we can get information from it.
  {:module, _name, bytecodepublic1, _exports} =
    defmodule TestStructPublic1 do
      use TypedStruct

      typedrecord :user do
        field :one, integer(), default: 1
        field :two, String.t()
        field :three, String.t(), default: "def"
        field :four, atom(), default: :hi
      end
    end

  {:module, _name, bytecodepublic2, _exports} =
    defmodule TestStructPublic2 do
      use TypedStruct

      typedrecord :user, tag: User do
        field :one, integer(), default: 1
        field :two, String.t()
        field :three, String.t(), default: "def"
        field :four, atom(), default: :hi
      end
    end

  {:module, _name, bytecodepublic3, _exports} =
    defmodule TestStructPublic3 do
      use TypedStruct

      typedrecord :user, visibility: :public do
        field :one, integer(), default: 1
        field :two, String.t()
        field :three, String.t(), default: "def"
        field :four, atom(), default: :hi
      end
    end

  {:module, _name, bytecode_opaque1, _exports} =
    defmodule OpaqueTestStruct1 do
      use TypedStruct

      typedrecord :user, opaque: true do
        field :int, integer()
      end
    end

  {:module, _name, bytecode_opaque2, _exports} =
    defmodule OpaqueTestStruct2 do
      use TypedStruct

      typedrecord :user, visibility: :opaque do
        field :int, integer()
      end
    end

  {:module, _name, bytecode_private, _exports} =
    defmodule PrivateTestStruct do
      use TypedStruct

      typedrecord :user, visibility: :private do
        field :int, integer()
      end

      # Needed so that the compiler doesn't remove unused private type t()
      @opaque tt :: user
    end

  defmodule TestRecModule do
    use TypedStruct

    typedrecord :user, module: Rec do
      field :field, integer(), default: 1
    end
  end

  @bytecode1 bytecodepublic1
  @bytecode2 bytecodepublic2
  @bytecode3 bytecodepublic3
  @bytecode_opaque1 bytecode_opaque1
  @bytecode_opaque2 bytecode_opaque2
  @bytecode_private bytecode_private

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "generates the record with its defaults" do
    require TypedRecordTest.TestStructPublic1
    assert TestStructPublic1.user() == {:user, 1, nil, "def", :hi}
  end

  test "generates a type for the record in default case or if `visibility: :public` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode1, _exports} =
      defmodule TestRecord1 do
        require Record
        Record.defrecord(:user, one: 1, two: nil, three: "def", four: :hi)

        @type user() :: {:user, integer, String.t(), String.t(), atom}
      end

    type0 = extract_first_type(bytecode1)
    type1 = extract_first_type(@bytecode1)

    assert type0 == type1

    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode2, _exports} =
      defmodule TestRecordTag do
        require Record
        Record.defrecord(:user, User, one: 1, two: nil, three: "def", four: :hi)

        @type user() :: {User, integer, String.t(), String.t(), atom}
      end

    type1 = extract_first_type(bytecode2)
    type2 = extract_first_type(@bytecode2)

    assert type1 == type2

    type3 = extract_first_type(@bytecode3)

    assert type0 == type3
  end

  test "generates an opaque type if `opaque: true` or `visibility: :opaque` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_expected, _exports} =
      defmodule TestRecord2 do
        require Record
        Record.defrecord(:user, int: 1)

        @opaque user() :: {:user, integer}
      end

    type1 = extract_first_type(@bytecode_opaque1, :opaque)
    type2 = extract_first_type(bytecode_expected, :opaque)

    assert type1 == type2

    type3 = extract_first_type(@bytecode_opaque2, :opaque)

    assert type3 == type2
  end

  test "generates a private type if `visibility: private` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_private_expected, _exports} =
      defmodule TestRecord3 do
        require Record
        Record.defrecord(:user, int: 1)

        @typep user() :: {:user, integer}
        @opaque t2 :: user
      end

    type1 = extract_first_type(@bytecode_private, :typep)
    type2 = extract_first_type(bytecode_private_expected, :typep)

    assert type1 == type2
  end

  test "generates the struct in a submodule if `module: ModuleName` is set" do
    require TestRecModule.Rec
    assert TestRecModule.Rec.user() == {:user, 1}
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "Typedrecord missing record name" do
    assert_raise CompileError, ~r"undefined function typedrecord/1", fn ->
      defmodule ScopeTest do
        use TypedStruct

        typedrecord do
          field :in_scope, term()
        end
      end
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

  ############################################################################
  ##                                Helpers                                 ##
  ############################################################################

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword \\ :type) do
    case Code.Typespec.fetch_types(bytecode) do
      {:ok, types} -> Keyword.get(types, type_keyword) |> standardise
      _ -> nil
    end
  end

  # Standardises a type (removes line numbers and renames the struct to the
  # standard struct name).
  defp standardise(type_info)

  defp standardise({name, tp, params}) when is_tuple(tp),
    do: {name, standardise(tp), params}

  defp standardise({:type, _, :union, list}) when is_list(list) do
    list =
      Enum.map(list, &standardise(&1))
      |> Enum.filter(&(&1 != nil and &1 != []))

    case list do
      [one] -> standardise(one)
      _ -> {:type, :line, list}
    end
  end

  defp standardise({:type, _, :union, [value, nil]}),
    do: {:type, :line, standardise(value)}

  defp standardise({:type, _, type, params}),
    do: {:type, :line, type, standardise(params)}

  defp standardise({:remote_type, _, params}),
    do: {:remote_type, :line, standardise(params)}

  defp standardise({:atom, _, value}), do: value

  defp standardise({type, _, litteral}),
    do: {type, :line, standardise(litteral)}

  defp standardise(type) when is_atom(type), do: type

  defp standardise(list) when is_list(list),
    do: for(i <- list, i != [], do: standardise(i))
end
