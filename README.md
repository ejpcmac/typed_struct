# TypedStruct

[![Build Status](https://travis-ci.com/ejpcmac/typed_struct.svg?branch=develop)](https://travis-ci.com/ejpcmac/typed_struct)
[![hex.pm version](https://img.shields.io/hexpm/v/typed_struct.svg?style=flat)](https://hex.pm/packages/typed_struct)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/typed_struct/)
[![Total Download](https://img.shields.io/hexpm/dt/typed_struct.svg?style=flat)](https://hex.pm/packages/typed_struct)
[![License](https://img.shields.io/hexpm/l/typed_struct.svg?style=flat)](https://github.com/ejpcmac/typed_struct/blob/master/LICENSE.md)

<!-- @moduledoc -->

TypedStruct is a library for defining structs with a type without writing
boilerplate code.

## Rationale

To define a struct in Elixir, you probably want to define three things:

* the struct itself, with default values,
* the list of enforced keys,
* its associated type.

It ends up in something like this:

```elixir
defmodule Person do
  @moduledoc """
  A struct representing a person.
  """

  @enforce_keys [:name]
  defstruct name: nil,
            age: nil,
            happy?: true,
            phone: nil

  @typedoc "A person"
  @type t() :: %__MODULE__{
          name: String.t(),
          age: non_neg_integer() | nil,
          happy?: boolean(),
          phone: String.t() | nil
        }
end
```

In the example above you can notice several points:

* the keys are present in both the `defstruct` and type definition,
* enforced keys must also be written in `@enforce_keys`,
* if a key has no default value and is not enforced, its type should be
  nullable.

If you want to add a field in the struct, you must therefore:

* add the key with its default value in the `defstruct` list,
* add the key with its type in the type definition.

If the field is not optional, you should even add it to `@enforce_keys`. This is
way too much work for lazy people like me, and moreover it can be error-prone.

It would be way better if we could write something like this:

```elixir
defmodule Person do
  @moduledoc """
  A struct representing a person.
  """

  use TypedStruct

  typedstruct do
    @typedoc "A person"

    field :name, String.t(), enforce: true
    field :age, non_neg_integer()
    field :happy?, boolean(), default: true
    field :phone, String.t()
  end
end
```

Thanks to TypedStruct, this is now possible :)

## Usage

### Setup

To use TypedStruct in your project, add this to your Mix dependencies:

```elixir
{:typed_struct, "~> 0.3.0"}
```

If you do not plan to compile modules using TypedStruct at runtime, you can add
`runtime: false` to the dependency tuple as TypedStruct is only used at build
time.

If you want to avoid `mix format` putting parentheses on field definitions,
you can add to your `.formatter.exs`:

```elixir
[
  ...,
  import_deps: [:typed_struct]
]
```

### General usage

To define a typed struct, use
[`TypedStruct`](https://hexdocs.pm/typed_struct/TypedStruct.html), then define
your struct within a `typedstruct` block:

```elixir
defmodule MyStruct do
  # Use TypedStruct to import the typedstruct macro.
  use TypedStruct

  # Define your struct.
  typedstruct do
    # Define each field with the field macro.
    field :a_string, String.t()

    # You can set a default value.
    field :string_with_default, String.t(), default: "default"

    # You can enforce a field.
    field :enforced_field, integer(), enforce: true
  end
end
```

Each field is defined through the
[`field/2`](https://hexdocs.pm/typed_struct/TypedStruct.html#field/2) macro.

### Options

If you want to enforce all the keys by default, you can do:

```elixir
defmodule MyStruct do
  use TypedStruct

  # Enforce keys by default.
  typedstruct enforce: true do
    # This key is enforced.
    field :enforced_by_default, term()

    # You can override the default behaviour.
    field :not_enforced, term(), enforce: false

    # A key with a default value is not enforced.
    field :not_enforced_either, integer(), default: 1
  end
end
```

You can also generate an opaque type for the struct:

```elixir
defmodule MyOpaqueStruct do
  use TypedStruct

  # Generate an opaque type for the struct.
  typedstruct opaque: true do
    field :name, String.t()
  end
end
```

If you often define submodules containing only a struct, you can avoid
boilerplate code:

```elixir
defmodule MyModule do
  use TypedStruct

  # You now have %MyModule.Struct{}.
  typedstruct module: Struct do
    field :field, term()
  end
end
```

### Documentation

To add a `@typedoc` to the struct type, just add the attribute in the
`typedstruct` block:

```elixir
typedstruct do
  @typedoc "A typed struct"

  field :a_string, String.t()
  field :an_int, integer()
end
```

You can also document submodules this way:

```elixir
typedstruct module: MyStruct do
  @moduledoc "A submodule with a typed struct."
  @typedoc "A typed struct in a submodule"

  field :a_string, String.t()
  field :an_int, integer()
end
```

## Plugins

It is possible to extend the scope of TypedStruct by using its plugin interface,
as described in
[`TypedStruct.Plugin`](https://hexdocs.pm/typed_struct/TypedStruct.Plugin.html).
For instance, to automatically generate lenses with the
[Lens](https://github.com/obrok/lens) library, you can use
[`TypedStructLens`](https://github.com/ejpcmac/typed_struct_lens) and do:

```elixir
defmodule MyStruct do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens

    field :a_field, String.t()
    field :other_field, atom()
  end

  @spec change(t()) :: t()
  def change(data) do
    # a_field/0 is generated by TypedStructLens.
    lens = a_field()
    put_in(data, [lens], "Changed")
  end
end
```

### Some available plugins

* [`typed_struct_lens`](https://github.com/ejpcmac/typed_struct_lens) –
    Integration with the [Lens](https://github.com/obrok/lens) library.
* [`typed_struct_legacy_reflection`](https://github.com/ejpcmac/typed_struct_legacy_reflection)
  – Re-enables the legacy reflection functions from TypedStruct 0.1.x.

This list is not meant to be exhaustive, please [search for “typed_struct” on
hex.pm](https://hex.pm/packages?search=typed_struct) for other results. If you
want your plugin to appear here, please open an issue.

## What do I get?

When defining an empty `typedstruct` block:

```elixir
defmodule Example do
  use TypedStruct

  typedstruct do
  end
end
```

you get an empty struct with its module type `t()`:

```elixir
defmodule Example do
  @enforce_keys []
  defstruct []

  @type t() :: %__MODULE__{}
end
```

Each `field` call adds information to the struct, `@enforce_keys` and the type
`t()`.

A field with no options adds the name to the `defstruct` list, with `nil` as
default. The type itself is made nullable:

```elixir
defmodule Example do
  use TypedStruct

  typedstruct do
    field :name, String.t()
  end
end
```

becomes:

```elixir
defmodule Example do
  @enforce_keys []
  defstruct name: nil

  @type t() :: %__MODULE__{
          name: String.t() | nil
        }
end
```

The `default` option adds the default value to the `defstruct`:

```elixir
field :name, String.t(), default: "John Smith"

# Becomes
defstruct name: "John Smith"
```

When set to `true`, the `enforce` option enforces the key by adding it to the
`@enforce_keys` attribute.

```elixir
field :name, String.t(), enforce: true

# Becomes
@enforce_keys [:name]
defstruct name: nil
```

In both cases, the type has no reason to be nullable anymore by default. In one
case the field is filled with its default value and not `nil`, and in the other
case it is enforced. Both options would generate the following type:

```elixir
@type t() :: %__MODULE__{
        name: String.t() # Not nullable
      }
```

Passing `opaque: true` replaces `@type` with `@opaque` in the struct type
specification:

```elixir
typedstruct opaque: true do
  field :name, String.t()
end
```

generates the following type:

```elixir
@opaque t() :: %__MODULE__{
          name: String.t()
        }
```

When passing `module: ModuleName`, the whole `typedstruct` block is wrapped in a
module definition. This way, the following definition:

```elixir
defmodule MyModule do
  use TypedStruct

  typedstruct module: Struct do
    field :field, term()
  end
end
```

becomes:

```elixir
defmodule MyModule do
  defmodule Struct do
    @enforce_keys []
    defstruct field: nil

    @type t() :: %__MODULE__{
            field: term() | nil
          }
  end
end
```

<!-- @moduledoc -->

## Initial roadmap

* [x] Struct definition
* [x] Type definition (with nullable types)
* [x] Default values
* [x] Enforced keys (non-nullable types)
* [x] Plugin API

## Plugin ideas

* [ ] Default value type-checking (is it possible?)
* [ ] Guard generation
* [x] Integration with [Lens](https://github.com/obrok/lens)
* [ ] Integration with [Ecto](https://github.com/elixir-ecto/ecto)

## Related libraries

* [Domo](https://github.com/IvanRublev/Domo): a library to validate structs that
    define a `t()` type, like the one generated by `TypedStruct`.
* [TypedEctoSchema](https://github.com/bamorim/typed_ecto_schema): a library
    that provides a DSL on top of `Ecto.Schema` to achieve the same result as
    `TypedStruct`, with `Ecto`.

## [Contributing](CONTRIBUTING.md)

Before contributing to this project, please read the
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Copyright © 2018-2022 Jean-Philippe Cugnet and Contributors

This project is licensed under the [MIT license](./LICENSE.md).
