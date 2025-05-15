defmodule Redis.Roles.MasterData do
  @type t() :: %__MODULE__{
          master_replid: String.t(),
          master_repl_offset: integer,
          connected_replicas: integer,
          connected_replicas_sockets: MapSet.t(port())
        }

  @enforce_keys [:master_replid, :master_repl_offset]
  defstruct [
    :master_replid,
    :master_repl_offset,
    :connected_replicas,
    :connected_replicas_sockets
  ]

  def new(replid, repl_offset) do
    %__MODULE__{
      master_replid: replid,
      master_repl_offset: repl_offset,
      connected_replicas: 0,
      connected_replicas_sockets: MapSet.new()
    }
  end

  def add_replica(data, socket) do
    updated_sockets =
      MapSet.put(data.connected_replicas_sockets, socket)

    data
    |> Map.put(:connected_replicas_sockets, updated_sockets)
    |> Map.put(:connected_replicas, MapSet.size(updated_sockets))
  end
end
