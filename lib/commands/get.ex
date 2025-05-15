defmodule Redis.Command.Get do
  @moduledoc "Handles the GET command."
  alias Redis.Utility.ResponseEncoder
  alias Redis.Store

  def execute([key], socket) do
    value = Store.get(key)

    response = ResponseEncoder.encode_string(value)
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'GET' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
