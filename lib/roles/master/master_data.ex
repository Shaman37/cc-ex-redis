defmodule Redis.Roles.MasterData do
  @type t() :: %__MODULE__{
          master_replid: String.t(),
          master_repl_offset: Integer,
          connected_replicas: Integer,
        }

  @enforce_keys [:master_replid, :master_repl_offset]
  defstruct [:master_replid, :master_repl_offset, :connected_replicas]

  def new(replid, repl_offset) do
    %__MODULE__{master_replid: replid, master_repl_offset: repl_offset}
  end
end
