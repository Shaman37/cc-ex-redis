defmodule RESPCommand.Psync do
  @moduledoc """
  Handles the ECHO command.
  """

  def execute(arg) when is_list(arg) do
    repl_id = RDB.get_master_data(:master_replid)

    "+FULLRESYNC #{repl_id} 0\r\n"
  end

  def execute(_), do: "- error | wrong number of arguments for 'REPLCONF' command\r\n"
end
