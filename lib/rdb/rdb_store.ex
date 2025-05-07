defmodule RDBStore do
  @moduledoc """
  An in-memory key-value store backed by an Agent.
  Used to persist values across client connections.
  """

  use Agent

  @enforce_keys [:dir, :dbfilename]
  defstruct [:dir, :dbfilename]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t()
        }
  @doc """
  Starts the Store agent with an empty map.
  Should be added to the supervision tree.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stores a key-value pair in the RDBStore.
  """
  def set(key, value, expiry \\ :infinity) do
    expires_at =
      if expiry == :infinity, do: :infinity, else: System.system_time(:millisecond) + expiry

    Agent.update(__MODULE__, fn store ->
      Map.put(store, key, {value, expires_at, :millisecond})
    end)
  end

  @doc """
  Retrieves a value for the given key.
  Returns nil if the key is not found.
  """
  def get(key) do
    case Agent.get(__MODULE__, fn store -> Map.get(store, key) end) do
      nil ->
        nil

      {value, :infinity, _type} ->
        value

      {value, expiry, type} ->
        now_ms = System.system_time(type)
        if now_ms > expiry, do: nil, else: value
    end
  end

  def restore(data) do
    Enum.each(data, fn {key, %{value: value, expiry: expiry, expiry_type: expiry_type}} ->
      Agent.update(__MODULE__, fn store -> Map.put(store, key, {value, expiry, expiry_type}) end)
    end)
  end

  def keys() do
    Agent.get(__MODULE__, fn store -> Map.keys(store) end)
  end
end
