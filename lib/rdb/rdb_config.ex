defmodule RDBConfig do
  @enforce_keys [:dir, :dbfilename, :role]
  defstruct [:dir, :dbfilename, :role, :master_replication_data]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t(),
          role: String.t(),
          master_replication_data: RDBMasterReplicationData.t()
        }

  @doc """
    Helper function to create a new 'RDBConfig' struct
  """
  def new(dir, filename, role) when is_binary(dir) and is_binary(filename) do
    config = %__MODULE__{dir: dir, dbfilename: filename, role: role}

    case role do
      "master" ->
        replication_data = RDBMasterReplicationData.new("8371b4fb1155b71f4a04d3e1bc3e18c4a990aeeb", 0)
        %__MODULE__{config | master_replication_data: replication_data}
      "slave" -> config
    end
  end

  @doc """
    Helper function to return the full rdb path
  """
  def get_db_path(%__MODULE__{dir: dir, dbfilename: filename, role: _}) do
    Path.join(dir, filename)
  end
end
