defmodule RDB do
  @moduledoc "Stores configuration values like dir and dbfilename."
  use Agent

  @enforce_keys [:dir, :dbfilename]
  defstruct [:dir, :dbfilename]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t()
        }

  @doc """
    Helper function to create a new 'RDBConfig' struct
  """
  def new_config(dir, filename) when is_binary(dir) and is_binary(filename) do
    %__MODULE__{dir: dir, dbfilename: filename}
  end

  @doc """
    Helper function to return the full rdb path
  """
  def get_db_path(%__MODULE__{dir: dir, dbfilename: filename}) do
    Path.join(dir, filename)
  end

  @doc """
  Starts the RDB agent with an initial config.
  """
  def start_link(config) do
    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def load() do
    file = Agent.get(__MODULE__, fn config -> get_db_path(config) end)
    rdb_data = RDBParser.parse_db(file)

    redis_version = Map.get(rdb_data, :redis_version, "0011")
    IO.puts("Redis RDB Version: #{redis_version}")

    metadata = Map.get(rdb_data, :metadata, %{})
    IO.puts("Metadata:")

    IO.puts("Restored #{map_size(rdb_data[:data] || %{})} keys into the store.")
    IO.puts("RDB Checksum: #{Map.get(rdb_data, :checksum, "N/A")}")

    Enum.each(metadata, fn {key, value} ->
      IO.puts("  #{key}: #{value}")
    end)

    case Map.get(rdb_data, :data) do
      nil -> IO.puts("No data section found in RDB file.")
      data -> Store.restore(data)
    end
  end

  def get_config_param(param) do
    key = String.to_atom(param)
    Agent.get(__MODULE__, fn config -> Map.get(config, key) end)
  end
end
