defmodule RESPCommand.ConfigGet do
  @moduledoc "Handles CONFIG GET command"

  def execute([param]) do
    case RDB.get_config_param(param) do
      nil -> "*0\r\n"
      value -> RESPCommand.encode_array([String.downcase(param), value])
    end
  end

  def execute(_), do: "- error | wrong number of arguments for 'CONFIG GET'\r\n"


end
