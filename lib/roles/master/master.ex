defmodule Redis.Roles.Master do
  use Redis.Roles

  @impl true
  def children(_port, _opts) do
    []
  end
end
