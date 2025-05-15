defmodule Redis.Command.Psync do
  @moduledoc """
  Handles the PSYNC command.
  """
  alias Redis.Utility.ResponseEncoder
  alias Redis.{Roles, RDB}

  def execute(arg, socket) when is_list(arg) do
    repl_id = Roles.RoleConfig.get_data_value(:master_replid)
    rdb_data = RDB.get_contents()

    response = ResponseEncoder.encode_fullresync(repl_id) <> ResponseEncoder.encode_rdb(rdb_data)

    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'REPLCONF' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
