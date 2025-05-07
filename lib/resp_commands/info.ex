defmodule RESPCommand.Info do
  @moduledoc """
  Handles the INFO command.
  """

  def execute(["replication"]) do
    role = RDB.get_role()

    info =
      case role do
        "master" ->
          replid = RDB.get_master_data(:master_replid)
          offset = RDB.get_master_data(:master_repl_offset)

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

    RESPCommand.encode_bulk(info)
  end

  def execute([_]) do
    role = RDB.get_role()

    RESPCommand.encode_string("role:#{role}")
  end

  def execute(_), do: "- error | wrong number of arguments for 'INFO' command\r\n"
end
