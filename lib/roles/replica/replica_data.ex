defmodule Redis.Roles.ReplicaData do
  @type t() :: %__MODULE__{
          master_host: String.t(),
          master_port: Integer
        }

  defstruct [:master_host, :master_port]

  def new() do
    %__MODULE__{}
  end
end
