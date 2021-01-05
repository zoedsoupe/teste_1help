defmodule BankWeb.Auth.Pipeline do
  @moduledoc """
  Auth pipeline using Guardian
  """
  use Guardian.Plug.Pipeline,
    otp_app: :bank,
    module: BankWeb.Auth,
    error_handler: BankWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
