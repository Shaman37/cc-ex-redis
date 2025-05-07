defmodule Server do
  @moduledoc """
  A basic Redis-like server that responds to PING commands with +PONG\\r\\n.
  Uses Task.Supervisor to support multiple concurrent clients robustly.
  """

  @port 6379
  @task_supervisor Server.TaskSupervisor

  use Application

  @doc """
  Starts the Redis server and a Task.Supervisor for handling client connections.
  """
  def start(_type, _args) do
    {opts, _args, _invalid} =
      OptionParser.parse(System.argv(), switches: [dir: :string, dbfilename: :string])

    dir = Keyword.get(opts, :dir, "/tmp/redis-data")
    dbfilename = Keyword.get(opts, :dbfilename, "dump.rdb")

    children = [
      RDBStore,
      {RDB, RDBConfig.new(dir, dbfilename)},
      {Task.Supervisor, name: @task_supervisor},
      {Task,
       fn ->
         RDB.load()
         listen()
       end}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  # Opens a TCP socket on the configured port and accepts incoming clients.
  # Each client is handled in its own supervised task.
  defp listen() do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  # Accepts new client connections and starts a supervised task for each one.
  defp loop_acceptor(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)

    Task.Supervisor.start_child(@task_supervisor, fn ->
      handle_client(client_socket)
    end)

    loop_acceptor(socket)
  end

  # Handles communication with a single client.
  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        response =
          case RESPCommand.parse(data) do
            %RESPCommand{} = cmd -> RESPCommand.execute(cmd)
            nil -> "- error | invalid command format\r\n"
          end

        :gen_tcp.send(socket, response)
        handle_client(socket)

      {:error, :closed} ->
        :ok
    end
  end
end
