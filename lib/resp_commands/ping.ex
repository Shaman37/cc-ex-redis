defmodule RESPCommand.Ping do
  @moduledoc """
  Handles the PING command.
  """
  def execute([]), do: "+PONG\r\n"
  def execute([arg]), do: RESPCommand.encode_string(arg)
  def execute(_), do: "- error | wrong number of arguments for 'PING' command\r\n"
end
