# SPDX-FileCopyrightText: 2025 Jean-Philippe Cugnet <jean-philippe@cugnet.eu>
# SPDX-License-Identifier: MIT

# NOTE: This file emits a warning when compiled, on purpose. To avoid printing
# this warning, it is compiled from a test with captured I/O.
#
# See test "does not create a `@typedoc` if there is none" for more information.
defmodule TypedStruct.TestStruct.NoTypedoc do
  @moduledoc """
  A typed struct with documented fields but no `@typedoc`.
  """
  use TypedStruct

  typedstruct do
    field :a_string, String.t(), doc: "just a series of letters"
    field :an_int, integer(), doc: "some digits"
  end
end
