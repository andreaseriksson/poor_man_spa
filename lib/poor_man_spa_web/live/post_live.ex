defmodule PoorManSpaWeb.PostLive do
  use Phoenix.LiveView

  alias PoorManSpa.Blog

  def render(assigns) do
    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
  end

  def mount(_session, socket) do
    posts = Blog.list_posts()
    {:ok, assign(socket, posts: posts, conn: socket)}
  end
end
