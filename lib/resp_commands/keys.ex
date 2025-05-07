defmodule RESPCommand.Keys do
  @moduledoc "Handles the KEYS command."

  def execute(["*"]) do
    RDBStore.keys()
    |> encode_array()
  end

  def execute(_), do: "- error | only '*' pattern is supported for now\r\n"

  defp encode_array(keys) do
    "*#{length(keys)}\r\n" <>
      Enum.map_join(keys, "", fn key ->
        "$#{byte_size(key)}\r\n#{key}\r\n"
      end)
  end
end
