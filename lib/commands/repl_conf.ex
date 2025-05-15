defmodule Redis.Command.ReplConf do
  @moduledoc """
  Handles the ECHO command.
  """
  alias Redis.Utility.ResponseEncoder
  alias Redis.Roles.{RoleConfig, MasterData}

  def execute(["listening-port" | _args], socket) do
    RoleConfig.update_data(fn data -> MasterData.add_replica(data, socket) end)

    response = ResponseEncoder.encode_ok()
    :gen_tcp.send(socket, response)
  end

  def execute(arg, socket) when is_list(arg) do
    response = ResponseEncoder.encode_ok()
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'REPLCONF' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
