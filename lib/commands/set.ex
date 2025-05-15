defmodule Redis.Command.Set do
  @moduledoc "Handles the SET command."
  alias Redis.Store
  alias Redis.Utility.ResponseEncoder

  def execute([key, value], socket) do
    Store.set(key, value)
    response = ResponseEncoder.encode_ok()
    :gen_tcp.send(socket, response)
  end

  def execute([key, value, px, px_value], socket) do
    response =
      case {String.upcase(px), Integer.parse(px_value)} do
        {"PX", {expiry, ""}} ->
          Store.set(key, value, expiry)
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
