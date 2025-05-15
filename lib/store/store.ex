defmodule Redis.Store do
  @moduledoc """
  An in-memory key-value store backed by a GenServer..
  Used to persist values across client connections.
  """

  use GenServer

  # --------------
  # - Public API -
  # --------------

  @doc "Start the store; accepts `name:` and `table:` opts."
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def set(key, value, expiry \\ :infinity) do
    GenServer.call(__MODULE__, {:set, key, value, expiry})
  end

  def keys() do
    GenServer.call(__MODULE__, {:keys})
  end

  def restore(data) do
    GenServer.call(__MODULE__, {:restore, data})
  end

  # --------------
  # - OTP Callbacks -
  # --------------

  @impl true
  def init(_arg) do
    store =
      :ets.new(
        :redis_store,
        [
          :named_table,
          :set,
          :public,
          read_concurrency: true,
          write_concurrency: true
        ]
      )

    {:ok, store}
  end

  @impl true
  def handle_call({:set, key, value, expiry}, _from, store) do
    expires_at =
      case expiry do
        :infinity ->
          :infinity

        ms when is_integer(ms) and ms >= 0 ->
          System.system_time(:millisecond) + ms
      end

    entry = %StoreEntry{
      value: value,
      expiry: expires_at,
      expiry_type: :millisecond
    }

    :ets.insert(store, {key, entry})
    {:reply, :ok, store}
  end

  @impl true
  def handle_call({:get, key}, _from, store) do
    case :ets.lookup(store, key) do
      [{^key, %StoreEntry{value: value, expiry: :infinity}}] ->
        {:reply, value, store}

      [{^key, %StoreEntry{value: value, expiry: expires_at, expiry_type: type}}] ->
        now = System.system_time(type)

        if now > expires_at do
          :ets.delete(store, key)
          {:reply, nil, store}
        else
          {:reply, value, store}
        end

      [] ->
        {:reply, nil, store}
    end
  end

  @impl true
  def handle_call({:keys}, _from, store) do
    now = System.system_time(:millisecond)

    keys =
      store
      |> :ets.tab2list()
      |> Enum.filter(fn
        {_key, %StoreEntry{expiry: :infinity}} -> true
        {_key, %StoreEntry{expiry: expiry}} -> expiry > now
      end)
      |> Enum.map(fn {key, _entry} -> key end)

    {:reply, keys, store}
  end

  @impl true
  def handle_call({:restore, data}, _from, store) do
    Enum.each(data, fn {key, %{value: value, expiry: expiry, expiry_type: expiry_type}} ->
      now = System.system_time(expiry_type)

      if expiry == :infinity or now <= expiry do
        entry = %StoreEntry{value: value, expiry: expiry, expiry_type: expiry_type}
        :ets.insert(store, {key, entry})
      end
    end)

    {:reply, :ok, store}
  end
end
