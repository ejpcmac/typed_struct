defmodule TypedRecord.Record do
  defmodule Actual do
    use TypedStruct

    typedrecord :user do
      field :one, integer(), default: 1
      field :two, String.t()
      field :three, String.t(), default: "def"
      field :four, atom(), default: :hi
    end
  end

  defmodule Expected do
    require Record
    Record.defrecord(:user, one: 1, two: nil, three: "def", four: :hi)

    @type user() :: {:user, integer(), String.t() | nil, String.t(), atom()}
  end
end

defmodule TypedRecord.Public do
  defmodule Actual do
    use TypedStruct

    typedrecord :user, tag: User do
      field :one, integer(), default: 1
      field :two, String.t()
      field :three, String.t(), default: "def"
      field :four, atom(), default: :hi
    end
  end

  defmodule Expected do
    require Record
    Record.defrecord(:user, User, one: 1, two: nil, three: "def", four: :hi)

    @type user() :: {User, integer(), String.t() | nil, String.t(), atom()}
  end
end

defmodule TypedRecord.VisibilityPublic do
  defmodule Actual do
    use TypedStruct

    typedrecord :user, visibility: :public do
      field :one, integer(), default: 1
      field :two, String.t()
      field :three, String.t(), default: "def"
      field :four, atom(), default: :hi
    end
  end

  defmodule Expected do
    require Record
    Record.defrecord(:user, one: 1, two: nil, three: "def", four: :hi)

    @type user() :: {:user, integer(), String.t() | nil, String.t(), atom()}
  end
end

defmodule TypedRecord.VisibilityOpaque do
  defmodule Actual do
    use TypedStruct

    typedrecord :user, visibility: :opaque do
      field :int, integer()
    end
  end

  defmodule Expected do
    require Record
    Record.defrecord(:user, int: 1)

    @opaque user() :: {:user, integer()|nil}
  end
end

defmodule TypedRecord.VisibilityPrivate do
  defmodule Actual do
    use TypedStruct

    typedrecord :user, visibility: :private do
      field :int, integer()
    end

    # Needed so that the compiler doesn't remove unused private type t()
    @opaque tt() :: user()
  end

  defmodule Expected do
    require Record
    Record.defrecord(:user, int: 1)

    @typep user() :: {:user, integer()|nil}
    @opaque tt() :: user()
  end
end

defmodule TypedRecord.TestRecModule do
  use TypedStruct

  typedrecord :user, module: Rec do
    field :field, integer(), default: 1
  end
end
