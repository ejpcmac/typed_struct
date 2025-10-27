# SPDX-FileCopyrightText: 2018, 2020, 2022, 2025 Jean-Philippe Cugnet <jean-philippe@cugnet.eu>
# SPDX-FileCopyrightText: 2018 Marcin Górnik <marcin.gornik@gmail.com>
#
# SPDX-License-Identifier: MIT

defmodule TypedStructTest do
  use ExUnit.Case

  alias TypedStruct.TestStruct

  import ExUnit.CaptureIO

  ############################################################################
  ##                             Standard cases                             ##
  ############################################################################

  test "generates the struct with its defaults" do
    assert TestStruct.BaseFeatures.__struct__() == %TestStruct.BaseFeatures{
             int: nil,
             string: nil,
             string_with_default: "default",
             mandatory_int: nil
           }
  end

  test "enforces keys for fields with `enforce: true`" do
    assert TestStruct.BaseFeatures.enforce_keys() == [:mandatory_int]
  end

  test "enforces keys by default if `enforce: true` is set at top-level" do
    assert :enforced_by_default in TestStruct.Enforced.enforce_keys()
  end

  test "does not enforce keys for fields explicitly setting `enforce: false" do
    refute :not_enforced in TestStruct.Enforced.enforce_keys()
  end

  test "does not enforce keys for fields with a default value" do
    refute :with_default in TestStruct.Enforced.enforce_keys()
  end

  test "does not enforce keys for fields with a default value set to `false`" do
    refute :with_false_default in TestStruct.Enforced.enforce_keys()
  end

  test "does not enforce keys for fields with a default value set to `nil`" do
    refute :with_nil_default in TestStruct.Enforced.enforce_keys()
  end

  test "generates a type for the struct" do
    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      TestStruct.BaseFeatures
      |> extract_first_type()
      |> standardise(TestStruct.BaseFeatures)

    type2 =
      TestStruct.BaseFeatures.Expected
      |> extract_first_type()
      |> standardise(TestStruct.BaseFeatures.Expected)

    assert type1 == type2
  end

  test "generates an opaque type if `opaque: true` is set" do
    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      TestStruct.Opaque
      |> extract_first_type(:opaque)
      |> standardise(TestStruct.Opaque)

    type2 =
      TestStruct.Opaque.Expected
      |> extract_first_type(:opaque)
      |> standardise(TestStruct.Opaque.Expected)

    assert type1 == type2
  end

  test "generates the struct in a submodule if `module: ModuleName` is set" do
    # credo:disable-for-next-line Credo.Check.Design.AliasUsage
    assert TestStruct.AsSubmodule.Struct.__struct__() ==
             %TestStruct.AsSubmodule.Struct{
               field: nil
             }
  end

  ############################################################################
  ##                                Problems                                ##
  ############################################################################

  test "TypedStruct macros are available only in the typedstruct block" do
    assert capture_io(:stderr, fn ->
             assert_raise CompileError, fn ->
               defmodule ScopeTest do
                 use TypedStruct

                 typedstruct do
                   field :in_scope, term()
                 end

                 # Let’s try to use field/2 outside the block.
                 field :out_of_scope, term()
               end
             end
           end) =~ "undefined function field/2"
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

  test "the type of a field must be a type" do
    assert_raise ArgumentError,
                 "a field must have a type, got [default: 1]",
                 fn ->
                   defmodule InvalidStruct do
                     use TypedStruct

                     typedstruct do
                       field :name, default: 1
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
    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      TestStruct.Alias.With
      |> extract_first_type()
      |> standardise(TestStruct.Alias.With)

    type2 =
      TestStruct.Alias.Without
      |> extract_first_type()
      |> standardise(TestStruct.Alias.Without)

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

  defp standardise({:type, _, type, params}, struct),
    do: {:type, :line, type, standardise(params, struct)}

  defp standardise({:remote_type, _, params}, struct),
    do: {:remote_type, :line, standardise(params, struct)}

  defp standardise({:atom, _, struct}, struct),
    do: {:atom, :line, TestStruct}

  defp standardise({name, type, params}, struct) when is_tuple(type),
    do: {name, standardise(type, struct), params}

  defp standardise({type, _, literal}, _struct),
    do: {type, :line, literal}

  defp standardise(list, struct) when is_list(list),
    do: Enum.map(list, &standardise(&1, struct))
end
