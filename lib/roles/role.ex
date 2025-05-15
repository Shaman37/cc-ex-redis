defmodule Redis.Roles do
  @moduledoc """
  Behaviour for “what children do I bring up for my role?”
  """

  @callback children(port :: integer(), opts :: Keyword.t()) :: [Supervisor.child_spec()]

  defmacro __using__(_) do
    quote do
      @behaviour Redis.Roles
      import Redis.Roles, only: [child_spec: 2, child_spec: 3]
    end
  end

  @doc """
  Helper to build a standard child spec for a fun-based task.
  """
  def child_spec(id, fun, opts \\ []) when is_function(fun, 0) do
    %{
      id: id,
      start: {Task, :start_link, [fun]},
      restart: Keyword.get(opts, :restart, :transient)
    }
  end
end
