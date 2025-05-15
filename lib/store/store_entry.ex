defmodule StoreEntry do
  @moduledoc """
  Encapsulates a stored value along with its expiry timestamp
  and the time unit used for measuring that expiry.
  """

  @type t :: %__MODULE__{
          value: any(),
          expiry: non_neg_integer() | :infinity,
          expiry_type: :second | :millisecond
        }

  @enforce_keys [:value]
  defstruct [
    :value,
    :expiry,
    :expiry_type
  ]
end
