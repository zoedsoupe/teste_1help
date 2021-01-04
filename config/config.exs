# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bank,
  ecto_repos: [Bank.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :bank, BankWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OrBd2a0fDrfuHkYprTerljuYWcFxr3O+MwVYcLIQVck9XTRMwDKOEig9CFH9h83D",
  render_errors: [view: BankWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Bank.PubSub,
  live_view: [signing_salt: "/+XhTad/"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Git Hooks
if Mix.env() != :prod do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format"},
          {:cmd, "mix compile --warning-as-errors"},
          {:cmd, "mix credo --strict"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test"}
        ]
      ]
    ]
end

# Mailing
config :bank, Bank.Mailing,
  adapter: Bamboo.LocalAdapter,
  open_email_in_browser_url: "http://localhost:4000/sent_emails"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
