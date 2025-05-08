defmodule RESPCommand do
  @moduledoc """
  Represents a parsed Redis command and dispatches execution.
  """
  alias RESPCommand.{Ping, Echo, Get, Set, ConfigGet, Keys, Info, ReplConf}

  @enforce_keys [:name]
  defstruct [:name, :arguments]

  @type t :: %__MODULE__{
          name: String.t(),
          arguments: list(String.t())
        }

  @doc """
  Parses a RESP-encoded string into a %RESPCommand{}.
  """
  def parse(data) do
    parts =
      data
      |> String.split("\r\n", trim: true)
      |> Enum.drop(1)
      |> Enum.drop_every(2)

    case parts do
      [name] -> %__MODULE__{name: String.upcase(name), arguments: []}
      [name | args] when is_list(args) -> %__MODULE__{name: String.upcase(name), arguments: args}
      _ -> nil
    end
  end

  @doc """
  Dispatches the command to the correct implementation module.
  """
  def execute(%__MODULE__{name: "PING", arguments: args}), do: Ping.execute(args)
  def execute(%__MODULE__{name: "ECHO", arguments: args}), do: Echo.execute(args)
  def execute(%__MODULE__{name: "GET", arguments: args}), do: Get.execute(args)
  def execute(%__MODULE__{name: "SET", arguments: args}), do: Set.execute(args)

  def execute(%__MODULE__{name: "CONFIG", arguments: ["GET", args]}),
    do: ConfigGet.execute([args])

  def execute(%__MODULE__{name: "KEYS", arguments: args}), do: Keys.execute(args)
  def execute(%__MODULE__{name: "INFO", arguments: args}), do: Info.execute(args)
  def execute(%__MODULE__{name: "REPLCONF", arguments: args}), do: ReplConf.execute(args)

  def execute(%__MODULE__{name: name}),
    do: "- error | unknown command '#{String.downcase(name)}'\r\n"

  def encode_string(string) do
    "$#{byte_size(string)}\r\n#{string}\r\n"
  end

  def encode_array(items) do
    "*#{length(items)}\r\n" <>
      Enum.map_join(items, "", fn item ->
        encode_string(item)
      end)
  end

  def encode_bulk(lines) do
    body = Enum.join(lines, "\r\n")
    "$#{byte_size(body)}\r\n#{body}\r\n"
  end
end

# null bulk string
