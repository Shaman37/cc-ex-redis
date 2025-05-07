defmodule RESPCommand.Get do
  @moduledoc "Handles the GET command."

  def execute([key]) do
    case RDBStore.get(key) do
      nil -> "$-1\r\n"
      value -> "$#{byte_size(value)}\r\n#{value}\r\n"
    end
  end

  def execute(_), do: "- error | wrong number of arguments for 'GET' command\r\n"
end
