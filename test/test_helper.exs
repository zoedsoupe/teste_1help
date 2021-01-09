Bank.Documenting.start()
ExUnit.start(formatters: [ExUnit.CLIFormatter, Bank.Documenting.Formatter])
Ecto.Adapters.SQL.Sandbox.mode(Bank.Repo, :manual)
