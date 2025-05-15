defmodule Redis.Command do
  @moduledoc """
  Represents a parsed Redis command and dispatches execution.
  """
  alias Redis.Command.{Ping, Echo, Get, Set, ConfigGet, Keys, Info, ReplConf, Psync}

  @enforce_keys [:name]
  defstruct [:name, :arguments]

  @type t :: %__MODULE__{
          name: String.t(),
          arguments: list(String.t())
        }

  @doc """
  Parses a RESP-encoded string into a %RESPCommand{}.
  """
  def new(data) do
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
  def execute(%__MODULE__{name: "PING", arguments: args}, socket) do
    Ping.execute(args, socket)
  end

  def execute(%__MODULE__{name: "ECHO", arguments: args}, socket) do
    Echo.execute(args, socket)
  end

  def execute(%__MODULE__{name: "GET", arguments: args}, socket) do
    Get.execute(args, socket)
  end

  def execute(%__MODULE__{name: "SET", arguments: args}, socket) do
    Set.execute(args, socket)
  end

  def execute(%__MODULE__{name: "CONFIG", arguments: ["GET", args]}, socket) do
    ConfigGet.execute([args], socket)
  end

  def execute(%__MODULE__{name: "KEYS", arguments: args}, socket) do
    Keys.execute(args, socket)
  end

  def execute(%__MODULE__{name: "INFO", arguments: args}, socket) do
    Info.execute(args, socket)
  end

  def execute(%__MODULE__{name: "REPLCONF", arguments: args}, socket) do
    ReplConf.execute(args, socket)
  end

  def execute(%__MODULE__{name: "PSYNC", arguments: args}, socket) do
    Psync.execute(args, socket)
  end

  def execute(%__MODULE__{name: name}, socket) do
    response = "- error | unknown command '#{String.downcase(name)}'\r\n"
    :gen_tcp.send(socket, response)
  end
end
