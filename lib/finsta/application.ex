defmodule Finsta.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FinstaWeb.Telemetry,
      # Start the Ecto repository
      Finsta.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Finsta.PubSub},
      # Start Finch
      {Finch, name: Finsta.Finch},
      # Start the Endpoint (http/https)
      FinstaWeb.Endpoint
      # Start a worker by calling: Finsta.Worker.start_link(arg)
      # {Finsta.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Finsta.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinstaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
