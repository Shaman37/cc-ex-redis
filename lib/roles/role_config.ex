defmodule Redis.Roles.RoleConfig do
  use Agent

  alias Redis.Roles

  @type role :: :master | :replica

  @type t :: %__MODULE__{
          role: role(),
          data: Roles.MasterData.t() | Roles.ReplicaData.t()
        }

  @enforce_keys [:role]
  defstruct [:role, :data]

  def start_link(config) do
    Agent.start_link(fn -> config end, name: __MODULE__)
  end

  def get_role() do
    role = Agent.get(__MODULE__, fn config -> Map.get(config, :role) end)

    case role do
      :master -> "master"
      :replica -> "slave"
    end
  end

  def get_data() do
    Agent.get(__MODULE__, fn config -> Map.get(config, :data) end)
  end

  def get_data_value(key) do
    role_data =
      Agent.get(__MODULE__, fn config -> Map.get(config, :data) end)

    Map.get(role_data, key)
  end

  def update_data(data_fun) do
    Agent.update(__MODULE__, fn config ->
      %Roles.RoleConfig{config | data: data_fun.(config.data)}
    end)
  end

end
