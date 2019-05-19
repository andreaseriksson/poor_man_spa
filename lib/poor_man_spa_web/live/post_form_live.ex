defmodule PoorManSpaWeb.PostFormLive do
  use Phoenix.LiveView

  alias PoorManSpa.Blog
  alias PoorManSpa.Blog.Post
  alias PoorManSpaWeb.Router.Helpers, as: Routes

  def render(assigns) do
    PoorManSpaWeb.PostView.render("live_form.html", assigns)
  end

  def mount(session, socket) do
    changeset = Blog.change_post(%Post{})

    {:ok, assign(socket, conn: socket, changeset: changeset)}
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      Post.changeset(%Post{}, post_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        {:stop,
          socket
          |> put_flash(:info, "post created")
          |> redirect(to: Routes.post_path(PoorManSpaWeb.Endpoint, :show, post))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
