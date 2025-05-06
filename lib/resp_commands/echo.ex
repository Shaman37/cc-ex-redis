defmodule RESPCommand.Echo do
  @moduledoc """
  Handles the ECHO command.
  """

  def execute([arg]), do: "$#{byte_size(arg)}\r\n#{arg}\r\n"
  def execute(_), do: "- error | wrong number of arguments for 'ECHO' command\r\n"
end
