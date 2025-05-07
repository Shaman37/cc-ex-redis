defmodule RESPCommand.Info do
  @moduledoc """
  Handles the INFO command.
  """

  def execute([_]), do: RESPCommand.encode_string("role:master")
  def execute(_), do: "- error | wrong number of arguments for 'INFO' command\r\n"
end
