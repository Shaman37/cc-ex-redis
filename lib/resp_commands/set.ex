defmodule RESPCommand.Set do
  @moduledoc "Handles the SET command."

  def execute([key, value]) do
    Store.set(key, value)
    "+OK\r\n"
  end

  def execute([key, value, px, px_value]) do
    case {String.upcase(px), Integer.parse(px_value)} do
      {"PX", {expiry, ""}} ->
        Store.set(key, value, expiry)
        "+OK\r\n"

      {"PX", _} ->
        "(error) expiry value must be a valid integer\r\n"

      {invalid, _} ->
        "(error) third argument must be PX, got: #{invalid}\r\n"
    end
  end

  def execute(_), do: "(error) wrong number of arguments for 'SET' command\r\n"
end
