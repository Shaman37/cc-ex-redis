defmodule Redis.Command.Echo do
  @moduledoc """
  Handles the ECHO command.
  """

  alias Redis.Utility.ResponseEncoder

  def execute([arg], socket) do
    response = ResponseEncoder.encode_string(arg)
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'ECHO' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
