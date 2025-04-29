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
    children = [
      {Task.Supervisor, name: @task_supervisor},
      {Task, fn -> listen() end}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  # Opens a TCP socket on the configured port and accepts incoming clients.
  # Each client is handled in its own supervised task.
  defp listen() do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: false, reuseaddr: true])
    accept_loop(socket)
  end


  # Accepts new client connections and starts a supervised task for each one.
  defp accept_loop(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)

    Task.Supervisor.start_child(@task_supervisor, fn ->
      handle_client(client_socket)
    end)

    accept_loop(socket)
  end


  # Handles communication with a single client.
  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, _data} ->
        :gen_tcp.send(socket, "+PONG\r\n")
        handle_client(socket)

      {:error, :closed} ->
        :ok
    end
  end
end
