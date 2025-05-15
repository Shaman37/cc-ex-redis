defmodule Redis.Command.Info do
  @moduledoc """
  Handles the INFO command.
  """
  alias Redis.Utility.ResponseEncoder
  alias Redis.Roles

  def execute(["replication"], socket) do
    role = Roles.RoleConfig.get_role()

    info =
      case role do
        "master" ->
          replid = Roles.RoleConfig.get_data_value(:master_replid)
          offset = Roles.RoleConfig.get_data_value(:master_repl_offset)

          [
            "role:#{role}",
            "master_replid:#{replid}",
            "master_repl_offset:#{offset}"
          ]

        "slave" ->
          [
            "role:#{role}"
          ]
      end

    response = ResponseEncoder.encode_bulk_string(info)
    :gen_tcp.send(socket, response)
  end

  def execute([_], socket) do
    role = Roles.RoleConfig.get_role()

    response = ResponseEncoder.encode_string("role:#{role}")
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'INFO' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
