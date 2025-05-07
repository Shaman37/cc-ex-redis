defmodule RESPCommand.Echo do
  @moduledoc """
  Handles the ECHO command.
  """

  def execute([arg]), do: RESPCommand.encode_string(arg)
  def execute(_), do: "- error | wrong number of arguments for 'ECHO' command\r\n"
end
