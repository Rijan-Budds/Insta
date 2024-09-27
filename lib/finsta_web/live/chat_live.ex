defmodule FinstaWeb.ChatLive do
  use FinstaWeb, :live_view
  alias Finsta.Chat
  alias Finsta.Repo

  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    if connected?(socket) do
      Chat.subscribe()
    end

    user = Finsta.Accounts.get_user_by_session_token(user_token)

    # Preload user association when listing messages
    messages = Chat.list_messages() |> Repo.preload(:user)

    {:ok, assign(socket, messages: messages, message: "", current_user: user)}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    IO.inspect(message, label: "Message Received")

    user = socket.assigns.current_user

    if String.trim(message) != "" do
      case Chat.create_message(user, %{content: message}) do
        {:ok, _new_message} ->
          IO.puts("Message sent successfully")
          {:noreply, assign(socket, message: "")}
        {:error, _reason} ->
          IO.puts("Failed to send message")
          {:noreply, put_flash(socket, :error, "Failed to send message")}
      end
    else
      IO.puts("Empty message")
      {:noreply, socket}
    end
  end



  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, fn messages -> messages ++ [message] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="chat-container text-black">
      <h2 class="text-black">Chat</h2>
      <div id="chat-messages" phx-update="append" class="text-black">
        <%= for message <- @messages do %>
          <div id={"message-#{message.id}"} class={"message #{if message.user_id == @current_user.id, do: "sent", else: "received"} text-black"}>
            <div class="username text-black"><%= message.user.email || "Unknown User" %></div>
            <div class="content text-black"><%= message.content %></div>
            <div class="timestamp text-black"><%= format_timestamp(message.inserted_at) %></div>
          </div>
        <% end %>
      </div>
    <form phx-submit="send_message" phx-change="update_message" class="message-form">
  <input
    type="text"
    name="message"
    value={@message}
    placeholder="Type a message..."
    phx-debounce="300"
  />
  <button type="submit" class="text-black">Send</button>
</form>

    </div>
    """
  end


  defp format_timestamp(timestamp) do
    timestamp
    |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
  end
end
