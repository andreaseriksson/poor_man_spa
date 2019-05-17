defmodule PoorManSpa.Repo do
  use Ecto.Repo,
    otp_app: :poor_man_spa,
    adapter: Ecto.Adapters.Postgres
end
