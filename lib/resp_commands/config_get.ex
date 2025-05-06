defmodule RESPCommand.ConfigGet do
  @moduledoc "Handles CONFIG GET command"

  def execute([param]) do
    case RDBConfig.get(param) do
      nil -> "*0\r\n"
      value -> encode_array([String.downcase(param), value])
    end
  end

  def execute(_), do: "- error | wrong number of arguments for 'CONFIG GET'\r\n"

  defp encode_array(items) do
    "*#{length(items)}\r\n" <>
      Enum.map_join(items, "", fn item ->
        "$#{byte_size(item)}\r\n#{item}\r\n"
      end)
  end
end
