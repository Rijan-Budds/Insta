defmodule Finsta.Chat do
  import Ecto.Query
  alias Finsta.Repo
  alias Finsta.Chat.Message

  def subscribe do
    Phoenix.PubSub.subscribe(Finsta.PubSub, "chat")
  end

  def list_messages do
    Repo.all(
      from m in Message,
      preload: [:user]
    )
  end

  def create_message(user, attrs) do
    attrs_with_user_id = Map.put(attrs, :user_id, user.id)

    %Message{}
    |> Message.changeset(attrs_with_user_id)
    |> Repo.insert()
    |> broadcast(:new_message)
  end

  defp broadcast({:ok, message}, event) do
    Phoenix.PubSub.broadcast(Finsta.PubSub, "chat", {event, message})
    {:ok, message}
  end

  defp broadcast({:error, _reason} = error, _event), do: error
end
