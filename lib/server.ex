defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """
  @port 6379

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> listen() end}], strategy: :one_for_one)
  end

  # Listen for incoming connections
  defp listen() do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: false, reuseaddr: true])
    {:ok, _client} = :gen_tcp.accept(socket)
  end
end
