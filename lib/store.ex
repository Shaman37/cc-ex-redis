defmodule Store do
  @moduledoc """
  An in-memory key-value store backed by an Agent.
  Used to persist values across client connections.
  """

  use Agent

  @doc """
  Starts the Store agent with an empty map.
  Should be added to the supervision tree.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stores a key-value pair in the store.
  """
  def set(key, value) do
    Agent.update(__MODULE__, fn store -> Map.put(store, key, value) end)
  end

   @doc """
  Retrieves a value for the given key.
  Returns nil if the key is not found.
  """
  def get(key) do
    Agent.get(__MODULE__, fn store -> Map.get(store, key) end)
  end
end
