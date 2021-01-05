Bank.Documenting.start()
ExUnit.start(formatters: [ExUnit.CLIFormatter, KirbyProject.Documenting.Formatter])
Ecto.Adapters.SQL.Sandbox.mode(Bank.Repo, :manual)
