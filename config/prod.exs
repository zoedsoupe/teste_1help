use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

config :bank, Bank.Endpoint, server: true
