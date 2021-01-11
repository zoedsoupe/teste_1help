import Config

################################################################################
# LOAD FROM ENV
################################################################################

load_from_env = fn var, default_value when is_binary(var) ->
  case System.get_env(var, default_value) do
    value when is_binary(value) and byte_size(value) >= 1 ->
      value

    _ ->
      raise "CONFIG ERROR: Environment variable #{var} is missing"
  end
end

################################################################################
# END LOAD FROM ENV
################################################################################

if config_env() == :prod do
  secret_key_base = load_from_env.("SECRET_KEY_BASE", nil)

  app_scheme = load_from_env.("SCHEME", "https")
  app_port = String.to_integer(load_from_env.("PORT", "4000"))
  app_hostname = load_from_env.("HOST", "0.0.0.0")

  db_url = load_from_env.("DB_URL", nil)
  pool_size = String.to_integer(load_from_env.("POOL_SIZE", "10"))

  config :bank, Bank.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: db_url,
    pool_size: pool_size,
    ssl: false

  config :bank, BankWeb.Endpoint,
    server: true,
    secret_key_base: secret_key_base,
    http: [:inet6, port: app_port],
    url: [scheme: app_scheme, host: app_hostname, port: app_port]

  # Mailing
  # config :bank, Bank.Mailing,
  #   adapter: Bamboo.SMTPAdapter,
  #   username: "",
  #   password: "",
  #   port: 2525,
  #   server: "",
  #   hostname: ""
end
