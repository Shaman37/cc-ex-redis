defmodule RESPCommand.ReplConf do
  @moduledoc """
  Handles the ECHO command.
  """

  def execute(arg) when is_list(arg), do: "+OK\r\n"
  def execute(_), do: "- error | wrong number of arguments for 'REPLCONF' command\r\n"
end
