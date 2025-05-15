defmodule Redis do
  @moduledoc """
  Entry point for our Redis-like server. Parses CLI options,
  sets up the supervision tree based on the role (master or replica),
  loads the RDB file, and starts the TCP listener. If configured as a replica,
  also kicks off the PSYNC handshake to replicate from a master.
  """

  use Application

  alias Redis.Roles.{RoleConfig, MasterData, ReplicaData}
  alias Redis.{RDB, Store}

  @task_sup Redis.TaskSupervisor

  @impl true
  def start(_type, _args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(System.argv(),
        switches: [
          port: :integer,
          dir: :string,
          dbfilename: :string,
          replicaof: :string
        ]
      )

    port = Keyword.get(opts, :port, 6379)
    dir = Keyword.get(opts, :dir, "/tmp/redis-data")
    dbfilename = Keyword.get(opts, :dbfilename, "dump.rdb")

    role_atom =
      case Keyword.get(opts, :replicaof) do
        nil -> :master
        "" -> :master
        _ -> :replica
      end

    role_data =
      case role_atom do
        :master -> MasterData.new("8371b4fb1155b71f4a04d3e1bc3e18c4a990aeeb", 0)
        :replica -> ReplicaData.new()
      end

    base_children = [
      {RoleConfig, %RoleConfig{role: role_atom, data: role_data}},
      Store,
      {RDB, RDB.PersistanceConfig.new(dir, dbfilename)},
      {Task.Supervisor, name: @task_sup},
      {Task,
       fn ->
         RDB.load()
         listen(port)
       end}
    ]

    children = base_children ++ role_module(role_atom).children(port, opts)

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp role_module(:master), do: Redis.Roles.Master
  defp role_module(:replica), do: Redis.Roles.Replica

  # --------------------------------
  # TCP listener & client handling -
  # --------------------------------

  defp listen(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  defp loop_acceptor(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    Task.Supervisor.start_child(@task_sup, fn ->
      handle_client(client_socket)
    end)

    loop_acceptor(listen_socket)
  end

  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        command = Redis.Command.new(data)

        case command do
          nil -> :gen_tcp.send(socket, "- error | invalid command format\r\n")
          _ -> Redis.Command.execute(command, socket)
        end

        handle_client(socket)

      {:error, :closed} ->
        :ok
    end
  end
end
