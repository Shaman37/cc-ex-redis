defmodule RDBConfig do
  @enforce_keys [:dir, :dbfilename, :role]
  defstruct [:dir, :dbfilename, :role]

  @type t :: %__MODULE__{
          dir: String.t(),
          dbfilename: String.t(),
          role: String.t()
        }

  @doc """
    Helper function to create a new 'RDBConfig' struct
  """
  def new(dir, filename, role) when is_binary(dir) and is_binary(filename) do
    %__MODULE__{dir: dir, dbfilename: filename, role: role}
  end

  @doc """
    Helper function to return the full rdb path
  """
  def get_db_path(%__MODULE__{dir: dir, dbfilename: filename, role: _}) do
    Path.join(dir, filename)
  end
end
