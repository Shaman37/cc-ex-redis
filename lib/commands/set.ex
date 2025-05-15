defmodule Redis.Command.Set do
  @moduledoc "Handles the SET command."
  alias Redis.{Store, Roles, Utility.ResponseEncoder}

  def execute([key, value], socket) do
    Store.set(key, value)

    role = Roles.RoleConfig.get_role()

    if role == "master" do
      command = ResponseEncoder.encode_array(["SET", key, value])
      Roles.Master.propagate_command(command)
    end

    response = ResponseEncoder.encode_ok()
    :gen_tcp.send(socket, response)
  end

  def execute([key, value, px, px_value], socket) do
    response =
      case {String.upcase(px), Integer.parse(px_value)} do
        {"PX", {expiry, ""}} ->
          Store.set(key, value, expiry)

          role = Roles.RoleConfig.get_role()

          if role == "master" do
            command = ResponseEncoder.encode_array(["SET", key, value, px, px_value])
            Roles.Master.propagate_command(command)
          end

          ResponseEncoder.encode_ok()

        {"PX", _} ->
          "- error | expiry value must be a valid integer\r\n"

        {invalid, _} ->
          "- error | third argument must be PX, got: #{invalid}\r\n"
      end

    :gen_tcp.send(socket, response)
  end

  def execute(_args, socket) do
    response = "- error | wrong number of arguments for 'SET' command\r\n"
    :gen_tcp.send(socket, response)
  end
end
