defmodule Redis.Command.Ping do
  @moduledoc """
  Handles the PING command.
  """
  alias Redis.Utility.ResponseEncoder

  def execute([], socket) do
    response = ResponseEncoder.encode_pong()
    :gen_tcp.send(socket, response)
  end

  def execute([arg], socket) do
    response = ResponseEncoder.encode_string(arg)
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'PING' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
