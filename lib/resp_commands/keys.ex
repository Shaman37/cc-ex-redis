defmodule RESPCommand.Keys do
  @moduledoc "Handles the KEYS command."

  def execute(["*"]) do
    RDBStore.keys()
    |> RESPCommand.encode_array()
  end

  def execute(_), do: "- error | only '*' pattern is supported for now\r\n"

end
