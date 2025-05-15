defmodule Redis.Utility.ResponseEncoder do
  def encode_pong() do
    "+PONG\r\n"
  end

  def encode_ok() do
    "+OK\r\n"
  end

  def encode_string(nil) do
    "$-1\r\n"
  end

  def encode_string(string) do
    "$#{byte_size(string)}\r\n#{string}\r\n"
  end

  def encode_array(nil) do
    "*0\r\n"
  end

  def encode_array(items) do
    "*#{length(items)}\r\n" <>
      Enum.map_join(items, "", fn item ->
        encode_string(item)
      end)
  end

  def encode_bulk_string(lines) do
    body = Enum.join(lines, "\r\n")
    "$#{byte_size(body)}\r\n#{body}\r\n"
  end

  def encode_fullresync(repl_id) do
    "+FULLRESYNC #{repl_id} 0\r\n"
  end

  def encode_rdb(contents) do
    "$#{byte_size(contents)}\r\n#{contents}"
  end
end
