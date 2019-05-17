defmodule PoorManSpaWeb.Plugs.RequestFormat do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    [accept_string|_] = get_req_header(conn, "accept")

    case accept_string =~ "javascript" do
      true -> assign(conn, :format, :js)
      _ -> assign(conn, :format, :html)
    end
  end
end
