defmodule PoorManSpaWeb.Plugs.AssignSession do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil -> put_session(conn, :user_id, generate_user_id())
      _ -> conn
    end
  end

  defp generate_user_id, do: :crypto.strong_rand_bytes(10) |> Base.url_encode64()
end
