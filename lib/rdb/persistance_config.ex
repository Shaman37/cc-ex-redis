defmodule Redis.RDB.PersistanceConfig do
  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t()
        }

  @enforce_keys [:dir, :dbfilename]
  defstruct [:dir, :dbfilename]

  @doc """
    Helper function to create a new 'RDBConfig' struct
  """
  def new(dir, filename) when is_binary(dir) and is_binary(filename) do
    %__MODULE__{dir: dir, dbfilename: filename}
  end

  @doc """
    Helper function to return the full rdb path
  """
  def get_db_path(%__MODULE__{dir: dir, dbfilename: filename}) do
    Path.join(dir, filename)
  end
end
