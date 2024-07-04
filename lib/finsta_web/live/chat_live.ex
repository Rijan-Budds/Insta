defmodule FinstaWeb.ChatLive do
  use FinstaWeb, :live_view
  alias Finsta.Chat
  alias Finsta.Accounts.User

  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    if connected?(socket) do
      Chat.subscribe()
    end

    user = Finsta.Accounts.get_user_by_session_token(user_token)
    messages = Chat.list_messages()
    {:ok, assign(socket, messages: messages, message: "", current_user: user)}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    user = socket.assigns.current_user

    case Chat.create_message(user, %{content: message}) do
      {:ok, _message} ->
        {:noreply, assign(socket, message: "")}
      {:error, reason} ->
        IO.inspect(reason, label: "Error creating message")
        {:noreply, assign(socket, message: "Failed to send message")}
    end
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, fn messages -> [message | messages] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="chat-container">
      <h2>Chat</h2>
      <div id="chat-messages" phx-update="prepend">
        <%= for message <- @messages do %>
          <div id={"message-#{message.id}"} class="message">
            <span class="username"><%= message.user.username %>:</span>
            <span class="timestamp"><%= format_timestamp(message.inserted_at) %></span>
            <span class="content"><%= message.content %></span>
          </div>
        <% end %>
      </div>
      <form phx-submit="send_message">
        <input type="text" name="message" value={@message} placeholder="Type a message..." />
        <button type="submit">Send</button>
      </form>
    </div>
    """
  end

  defp format_timestamp(timestamp) do
    # Ensure Timex is included in your dependencies
    timestamp
    |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
  end
end
