defmodule PoorManSpaWeb.PostLive do
  use Phoenix.LiveView

  def render(assigns) do
    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, message: "Hello World!")}
  end
end
