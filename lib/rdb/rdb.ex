defmodule Redis.RDB do
  @moduledoc "Stores configuration values like dir and dbfilename."
  alias Redis.RDB

  use Agent

  @doc """
  Starts the RDB agent with an initial config.
  """
  def start_link(config) do
    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def load() do
    file = Agent.get(__MODULE__, fn config -> RDB.PersistanceConfig.get_db_path(config) end)
    rdb_data = RDB.Parser.parse_file(file)

    if map_size(rdb_data) > 0 do
      log_result(rdb_data)
      Redis.Store.restore(rdb_data[:data])
    end
  end

  def get_contents() do
    empty_rdb64 =
      "UkVESVMwMDEx+glyZWRpcy12ZXIFNy4yLjD6CnJlZGlzLWJpdHPAQPoFY3RpbWXCbQi8ZfoIdXNlZC1tZW3CsMQQAPoIYW9mLWJhc2XAAP/wbjv+wP9aog=="

    {:ok, binary} = Base.decode64(empty_rdb64)

    binary
  end

  def get_config() do
    Agent.get(__MODULE__, fn config -> config end)
  end

  defp log_result(data) do
    redis_version = Map.get(data, :redis_version, "0011")
    IO.puts("Redis RDB Version: #{redis_version}")

    metadata = Map.get(data, :metadata, %{})
    IO.puts("Metadata:")

    IO.puts("Restored #{map_size(data[:data] || %{})} keys into the RDBStore.")
    IO.puts("RDB Checksum: #{Map.get(data, :checksum, "N/A")}")

    Enum.each(metadata, fn {key, value} ->
      IO.puts("  #{key}: #{value}")
    end)
  end
end
