defmodule RESPCommand.Set do
  @moduledoc "Handles the SET command."

  def execute([key, value]) do
    Store.set(key, value)
    "+OK\r\n"
  end

  def execute(_), do: "(error) wrong number of arguments for 'SET' command\r\n"
end
