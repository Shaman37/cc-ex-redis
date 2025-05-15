defmodule Redis.Command.Keys do
  @moduledoc "Handles the KEYS command."
  alias Redis.Store
  alias Redis.Utility.ResponseEncoder

  def execute(["*"], socket) do
    response =
      Store.keys()
      |> ResponseEncoder.encode_array()

    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | only '*' pattern is supported for now\r\n"
    :gen_tcp.send(socket, response)
  end
end
