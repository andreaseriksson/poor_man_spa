defmodule PoorManSpa.Blog.Likes do
  use Agent

  def start_link(state \\ MapSet.new()) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @topic inspect(__MODULE__)
  def subscribe do
    Phoenix.PubSub.subscribe(PoorManSpa.PubSub, @topic)
  end

  def notify_subscribers(data, message \\ :likes_updated) do
    Phoenix.PubSub.broadcast(PoorManSpa.PubSub, @topic, {__MODULE__, message})
    data
  end

  def like(id, user_id) do
    get_state()
    |> Enum.member?({id, user_id})
    |> case do
      true -> :ok
      false ->
        Agent.update(__MODULE__, fn state ->
          MapSet.put(MapSet.new(state), {id, user_id})
        end)
        |> notify_subscribers()
    end
  end

  def likes_count do
    get_state()
    |> Enum.reduce(%{}, fn {id, _}, acc ->
      count = Map.get(acc, id, 0)
      Map.put(acc, id, count + 1)
    end)
  end

  defp get_state, do: Agent.get(__MODULE__, & &1)
end
