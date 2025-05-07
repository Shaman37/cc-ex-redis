defmodule RDBConfig do
  @enforce_keys [:dir, :dbfilename]
  defstruct [:dir, :dbfilename]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t()
        }

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
