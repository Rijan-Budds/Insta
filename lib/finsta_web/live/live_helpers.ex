defmodule FinstaWeb.LiveHelpers do
  import Phoenix.Component

  alias Finsta.Accounts

  def on_mount(:assign_current_user, _params, session, socket) do
    {:cont, assign_new(socket, :current_user, fn ->
      Accounts.get_user_by_session_token(session["user_token"])
    end)}
  end
end
