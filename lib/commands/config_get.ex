defmodule Redis.Command.ConfigGet do
  @moduledoc "Handles CONFIG GET command"

  alias Redis.Utility.ResponseEncoder
  alias Redis.RDB

  def execute([param_key], socket) do
    persistance_config = RDB.get_config()
    value = [param_key, Map.get(persistance_config, String.to_atom(param_key))]

    response = ResponseEncoder.encode_array(value)
    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'CONFIG GET'\r\n"
    :gen_tcp.send(socket, response)
  end
end
