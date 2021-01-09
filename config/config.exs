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
if Mix.env() == :dev do
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

config :bank,
  mailing_default_from_name: "Bank Live",
  mailing_default_from_email: "noreply@bank.com"

# Guardian
config :bank, BankWeb.Auth,
  issuer: "bank",
  secret_key: "U5Hu+z/iLlr8fz9jsgHSXVc4xd+TciR/aORxebMKGHp4vVB1tnmPBzI+V+IrbUti"

# Documenting
config :bank, Bank.Documenting,
  result_file_path: "README.md",
  default_response_transforms: %{
    inserted_at: "2021-01-04T22:16:56",
    updated_at: "2021-01-04T22:16:56",
    email: "valid@email.com"
  }

# Oban
# Configures Oban
config :bank, Oban,
  repo: Bank.Repo,
  plugins: [{Oban.Plugins.Pruner, max_age: 300}],
  queues: [default: 10, events: 50, media: 20, mailing: 50]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
