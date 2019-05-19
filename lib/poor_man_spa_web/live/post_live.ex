defmodule PoorManSpaWeb.PostLive do
  use Phoenix.LiveView

  alias PoorManSpa.Blog
  alias PoorManSpa.Blog.Likes

  def render(assigns) do
    PoorManSpaWeb.PostView.render("live_posts.html", assigns)
  end

  def mount(session, socket) do
    if connected?(socket), do: Blog.subscribe
    if connected?(socket), do: Likes.subscribe

    user_id = session |> Map.get(:user_id)
    posts = Blog.list_posts()

    {:ok, assign(socket, posts: posts, conn: socket, user_id: user_id, likes: Likes.likes_count())}
  end

  def handle_info({Blog, _}, socket) do
    posts = Blog.list_posts()
    {:noreply, assign(socket, posts: posts)}
  end

  def handle_info({Likes, _}, socket) do
    {:noreply, assign(socket, likes: Likes.likes_count())}
  end

  def handle_event("like", post_id, socket) do
    post_id = String.to_integer(post_id)
    user_id = socket.assigns[:user_id]
    Likes.like(post_id, user_id)

    {:noreply, socket}
  end
end
