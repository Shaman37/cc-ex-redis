defmodule RDBParser do
  @moduledoc """
  A Redis RDB v11 binary parser that supports a single database.

  This module parses:
    - The header section (magic bytes + version)
    - Metadata entries (e.g., redis-ver, redis-bits)
    - Key-value entries with optional expirations
    - The 8-byte CRC64 checksum at the end of the file

  All string encodings (`0b00` to `0b11`) are supported.
  """

  @doc """
  Parses the RDB file at the given `file_path`.

  Returns a map with:
    - `:metadata` — Redis server metadata (e.g., version)
    - `:data` — parsed keys and values, with optional expiries
    - `:checksum` — final 8-byte CRC64 checksum as a hex string
  """
  def parse_db(file_path) do
    result = %{}

    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, binary} -> parse(binary, result)
        {:error, _reason} -> result
      end
    else
      result
    end
  end

  # ---- HEADER SECTION ----
  # Matches the RDB header: "REDIS" + 4-byte version
  defp parse(<<"REDIS", version::binary-size(4), rest::binary>>, acc) do
    acc = Map.put(acc, :redis_version, to_string(version))

    parse(rest, acc)
  end

  # ---- METADATA SECTION ----
  # Parses a metadata subsection (0xFA), extracting key and value strings
  defp parse(<<0xFA, data::binary>>, acc) do
    {key, rest} = parse_string(data)
    {value, rest} = parse_string(rest)

    acc = add_metadata_entry(acc, key, value)

    parse(rest, acc)
  end

  # ---- DATABASE SECTION | DB Selection ----
  # Selects a database (0xFE); we ignore index and assume one DB only
  defp parse(<<0xFE, _db_index, data::binary>>, acc) do
    parse(data, acc)
  end

  # ---- DATABASE SECTION | Hash Table Sizes ----
  # Parses hash table sizes (0xFB); we ignore the values
  defp parse(<<0xFB, _data_table_size::integer, _expires_table_size::integer, rest::binary>>, acc) do
    parse(rest, acc)
  end

  # ---- DATABASE SECTION | Expire in seconds ----
  # Stores a temporary expiry in seconds (0xFD)
  defp parse(<<0xFD, expiry::little-unsigned-integer-size(32), data::binary>>, acc) do
    acc = set_data_entry_expiry(acc, expiry, :s)

    parse(data, acc)
  end

  # ---- DATABASE SECTION | Expire in milliseconds ----
  # Stores a temporary expiry in milliseconds (0xFC)
  defp parse(<<0xFC, expiry::little-unsigned-integer-size(64), data::binary>>, acc) do
    acc = set_data_entry_expiry(acc, expiry, :ms)

    parse(data, acc)
  end

  # ---- DATABASE SECTION | Key-Value pair (string type) ----
  # Parses a string key-value pair (type 0x00)
  defp parse(<<0x00, data::binary>>, acc) do
    {key, rest} = parse_string(data)
    {value, rest} = parse_string(rest)

    acc = add_data_entry(acc, key, value)

    parse(rest, acc)
  end

  # ---- EOF SECTION ----
  # Parses the EOF marker (0xFF) and stores the 8-byte checksum
  defp parse(<<0xFF, checksum::binary-size(8)>>, acc) do
    Map.put(acc, :checksum, Base.encode16(checksum))
  end

  # ---- Fallbacks ----
  defp parse(<<_tag, data::binary>>, acc), do: parse(data, acc)
  defp parse(<<>>, acc), do: acc

  # Decodes a string using Redis size-encoding rules
  defp parse_string(<<prefix, data::binary>>) do
    encoding_flag = Bitwise.bsr(prefix, 6)

    parse_size_encoded_value(encoding_flag, prefix, data)
  end

  # 6-bit size encoding (0b00): size is lower 6 bits of prefix
  defp parse_size_encoded_value(0b00, prefix, data) do
    size = Bitwise.band(prefix, 0b0011_1111)
    <<str::binary-size(size), remaining_data::binary>> = data

    {str, remaining_data}
  end

  # 14-bit size encoding (0b01): size is (6 bits << 8) + next byte
  defp parse_size_encoded_value(0b01, prefix, data) do
    <<next, string_data::binary>> = data
    size = Bitwise.bsl(Bitwise.band(prefix, 0b0011_1111), 8) + next
    <<str::binary-size(size), remaining_data::binary>> = string_data

    {str, remaining_data}
  end

  # 32-bit size encoding (0b10): size is next 4 bytes, big-endian
  defp parse_size_encoded_value(0b10, _, data) do
    <<b1, b2, b3, b4, string_data::binary>> = data
    size = :binary.decode_unsigned(<<b1, b2, b3, b4>>, :big)
    <<str::binary-size(size), remaining_data::binary>> = string_data

    {str, remaining_data}
  end

  # Special string encodings (0b11): integers or compressed (LZF unsupported)
  defp parse_size_encoded_value(0b11, prefix, rest) do
    case prefix do
      0xC0 ->
        <<int, rest2::binary>> = rest
        {Integer.to_string(int), rest2}

      0xC1 ->
        <<int::little-signed-integer-size(16), rest2::binary>> = rest
        {Integer.to_string(int), rest2}

      0xC2 ->
        <<int::little-signed-integer-size(32), rest2::binary>> = rest
        {Integer.to_string(int), rest2}

      0xC3 ->
        throw("LZF-compressed strings not supported")

      _ ->
        throw("Unknown special string encoding: #{inspect(prefix)}")
    end
  end

  # Adds a key-value pair to the metadata map
  defp add_metadata_entry(acc, key, value) do
    Map.update(acc, :metadata, %{key => value}, fn metadata -> Map.put(metadata, key, value) end)
  end

  # Temporarily stores an expiry and its type in the accumulator
  defp set_data_entry_expiry(acc, expiry, type) do
    acc
    |> Map.put(:_expiry, expiry)
    |> Map.put(:_expiry_type, type)
  end

  # Adds a key-value pair to the data map, applying expiry if present
  defp add_data_entry(acc, key, value) do
    expiry = Map.get(acc, :_expiry, :infinity)
    expiry_type = Map.get(acc, :_expiry_type, :ms)

    entry = %{value: value, expiry: expiry, expiry_type: expiry_type}

    acc
    |> Map.update(:data, %{key => entry}, fn data ->
      Map.put(data, key, entry)
    end)
    |> Map.drop([:_expiry, :_expiry_type])
  end
end
