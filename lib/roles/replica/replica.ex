defmodule Redis.Roles.Replica do
  use Redis.Roles

  alias Redis.Utility.ResponseEncoder

  @impl true
  def children(port, opts) do
    {host, master_port} =
      opts
      |> Keyword.get(:replicaof, "")
      |> String.split()
      |> then(fn [h, p] -> {h, String.to_integer(p)} end)

    [
      child_spec(
        :replica_task,
        fn -> connect_to_master(host, master_port, port) end
      )
    ]
  end

  defp connect_to_master(host, master_port, port) do
    host_charlist = String.to_charlist(host)

    case :gen_tcp.connect(host_charlist, master_port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.send(socket, ResponseEncoder.encode_array(["PING"]))
        {:ok, _} = :gen_tcp.recv(socket, 0)

        :gen_tcp.send(
          socket,
          ResponseEncoder.encode_array(["REPLCONF", "listening-port", "#{port}"])
        )
        {:ok, _} = :gen_tcp.recv(socket, 0)

        :gen_tcp.send(socket, ResponseEncoder.encode_array(["REPLCONF", "capa", "psync2"]))
        {:ok, _} = :gen_tcp.recv(socket, 0)

        :gen_tcp.send(socket, ResponseEncoder.encode_array(["PSYNC", "?", "-1"]))
        {:ok, _} = :gen_tcp.recv(socket, 0)

      {:error, reason} ->
        IO.puts("Failed to connect to master: #{inspect(reason)}")
    end
  end
end
