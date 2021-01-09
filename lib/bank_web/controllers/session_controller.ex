defmodule BankWeb.SessionController do
  @moduledoc """
  Manages session creation and removal
  """
  use BankWeb, :controller

  alias BankWeb.Auth

  action_fallback BankWeb.FallbackController

  @accepts [:email, :password, :password_confirmation]
  @doc "Creates a session if password matches"
  @spec create(Plug.Conn.t(), map()) :: {:ok, map()} | {:error, any()}
  def create(_conn, params) do
    case Auth.login(params) do
      {:ok, data} -> {:ok, %{message: :login_success, data: %{token: data}}}
      error -> error
    end
  end
end
