defmodule Redis.Roles.Master do
  use Redis.Roles

  alias Redis.Roles.RoleConfig

  @impl true
  def children(_port, _opts) do
    []
  end

  def propagate_command(command) do
    replica_sockets = RoleConfig.get_data().connected_replicas_sockets

    replica_sockets
    |> Enum.each(fn socket -> :gen_tcp.send(socket, command) end)
  end
end
