defmodule RESPCommand.Info do
  @moduledoc """
  Handles the INFO command.
  """

  def execute([_]) do
    role = RDB.get_role()
    RESPCommand.encode_string("role:#{role}")
  end
  def execute(_), do: "- error | wrong number of arguments for 'INFO' command\r\n"
end
