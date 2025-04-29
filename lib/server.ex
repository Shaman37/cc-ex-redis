defmodule Server do
  @moduledoc """
  Implementation of a Redis server.
  """

  @port 6379

  use Application

  @doc """
  Starts the Redis server application and supervises the listener task.
  """
  @spec start(:normal | :ignore | {:error, term()}, list()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> listen() end}], strategy: :one_for_one)
  end

  # Opens a TCP socket on the configured port and accepts a single client connection.
  @spec listen() :: :ok
  defp listen() do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: false, reuseaddr: true])
    {:ok, client_socket} = :gen_tcp.accept(socket)

    loop_client_handle(client_socket)
  end

  # Continuously reads from the given client socket and responds with "+PONG\\r\\n".
  # Terminates gracefully when the client disconnects.
  @spec loop_client_handle(:gen_tcp.socket()) :: :ok
  defp loop_client_handle(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, _data} ->
        :gen_tcp.send(socket, "+PONG\r\n")
        loop_client_handle(socket)

      {:error, :closed} ->
        :ok
    end
  end
end
