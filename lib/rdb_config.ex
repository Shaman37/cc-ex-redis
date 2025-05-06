defmodule RDBConfig do
  @moduledoc "Stores configuration values like dir and dbfilename."

  use Agent

  def start_link(initial_rdb_config) do
    Agent.start_link(fn -> initial_rdb_config end, name: __MODULE__)
  end

  def get(param) do
    key = String.to_atom(param)
    Agent.get(__MODULE__, fn rdb_config -> Map.get(rdb_config, key) end)
  end
end
