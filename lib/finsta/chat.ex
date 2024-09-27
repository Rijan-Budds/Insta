defmodule Finsta.Chat do
  import Ecto.Query
  alias Finsta.Repo
  alias Finsta.Chat.Message

  def subscribe do
    Phoenix.PubSub.subscribe(Finsta.PubSub, "chat")
  end

  def list_messages do
    Repo.all(from m in Message, preload: [:user])
  end

  def create_message(user, attrs) do
    attrs_with_user_id = Map.put(attrs, :user_id, user.id)

    %Message{}
    |> Message.changeset(attrs_with_user_id)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message_with_user = Repo.preload(message, :user)
        broadcast({:ok, message_with_user}, :new_message)
        {:ok, message_with_user}
      {:error, _} = error ->
        error
    end
  end

  defp broadcast({:ok, message}, event) do
    Phoenix.PubSub.broadcast(Finsta.PubSub, "chat", {event, message})
    {:ok, message}
  end

  defp broadcast(:ok, _event), do: :ok
  defp broadcast({:error, _reason} = error, _event), do: error
end
