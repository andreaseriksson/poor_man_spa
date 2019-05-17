defmodule PoorManSpaWeb.PostLive do
  use Phoenix.LiveView

  alias PoorManSpa.Blog

  def render(assigns) do
    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket), do: Blog.subscribe

    posts = Blog.list_posts()
    {:ok, assign(socket, posts: posts, conn: socket)}
  end

  def handle_info({Blog, _}, socket) do
    posts = Blog.list_posts()
    {:noreply, assign(socket, posts: posts, conn: socket)}
  end
end
