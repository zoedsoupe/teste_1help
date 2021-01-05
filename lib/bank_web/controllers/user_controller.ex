defmodule BankWeb.UserController do
  @moduledoc """
  Manages /users context endpoints
  """

  use BankWeb, :controller

  alias Bank.{Accounts, Changeset, Repo}
  alias Bank.Accounts.Jobs.{ConfirmationEmail, RecoveryEmail, WelcomeEmail}
  alias Bank.Accounts.User

  import Bank.Common
  import BankWeb.Common

  action_fallback BankWeb.FallbackController

  @accepts ~w(first_name last_name cpf cnpj email mobile password password_confirmation)a
  def create(_conn, params) do
    params
    |> Map.put("confirmation", %{})
    |> Accounts.create_user()
    |> case do
      {:ok, user} ->
        user
        |> ConfirmationEmail.create_generic_worker()

        user
        |> Map.take(User.exposed_fields())
        |> Map.new(fn data -> {:data, data} end)
        |> Map.put(:message, :created)
        |> create_response()

      {:error, changeset} ->
        changeset
        |> Changeset.default_error_response()
    end
  end

  @accepts ~w(email)a
  def resend_confirmation_email(_conn, params) do
    with {:ok, user} <- Accounts.get_user_by(email: params["email"]),
         %{confirmed?: false} <- user do
      user
      |> ConfirmationEmail.create_generic_worker()

      {:ok, :success}
    else
      {:error, :not_found} ->
        {:error, :email_not_registered}

      %{confirmed?: true} ->
        {:error, :already_confirmed_email}
    end
  end

  @accepts ~w(id)a
  def show(_conn, %{"id" => id}) do
    id
    |> Accounts.get_user()
    |> case do
      {:ok, user} ->
        user
        |> Map.take(User.exposed_fields())
        |> Map.new(fn data -> {:data, data} end)
        |> Map.put(:message, :found)
        |> create_response()

      error ->
        error
    end
  end

  def show(_conn, _params), do: {:error, :no_id}

  @accepts ~w(first_name email cpf cnpj)a
  def list(_conn, params) do
    params
    |> map_to_keyword()
    |> Accounts.list_users()
    |> create_response_data_map()
    |> Map.put(:message, :ok)
    |> create_response()
  end

  @accepts ~w(id first_name last_name email cpf cnpj password password_confirmation)a
  def change(_conn, params) do
    with {:ok, _user} <- Accounts.get_user(params["id"]),
         {:ok, user} <- Accounts.update_user(params["id"], params) do
      user
      |> Map.take(User.exposed_fields())
      |> create_response_data_map()
      |> Map.put(:message, :updated)
      |> create_response()
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, changeset} ->
        changeset
        |> Changeset.default_error_response()
    end
  end

  @accepts ~w(token)a
  def confirm_email(_conn, %{"token" => token}) do
    token
    |> Accounts.get_confirmation()
    |> case do
      {:ok, confirmation} ->
        confirmation |> consume_confirmation_token()

      error ->
        error
    end
  end

  def confirm_email(_conn, _params), do: {:error, :no_token}

  @accepts ~w(id password password_confirmation)a
  def change_password(_conn, params) do
    with {:ok, _user} <- Accounts.get_user(params["id"]),
         {:ok, _} <-
           params["id"] |> Accounts.update_user(params, [:check_password, :set_password]) do
      create_response(%{message: :password_changed})
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, changeset} ->
        {:error, change_pass_error_response(changeset)}
    end
  end

  @accepts ~w(email)a
  def create_recovery(_conn, params) do
    with {:ok, user} <- Accounts.get_user_by(email: params["email"]),
         {:ok, recovery} <- Accounts.create_password_recovery(user) do
      recovery
      |> RecoveryEmail.create_worker()

      create_response(%{message: :recovery_attempt_created})
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, changeset} ->
        changeset
        |> Changeset.default_error_response()
    end
  end

  @accepts ~w(token)a
  def validate_recovery(_conn, %{"token" => token}) do
    token
    |> Accounts.get_password_recovery()
    |> case do
      {:ok, recovery} ->
        recovery
        |> Repo.preload(:user)
        |> Map.get(:user)
        |> Map.take(User.exposed_fields())
        |> create_response_data_map()
        |> Map.put(:message, :valid)
        |> create_response()

      error ->
        error
    end
  end

  def validate_recovery(_conn, _params), do: {:error, :no_token}

  @accepts ~w(token password password_confirmation)a
  def recover_password(_conn, %{"token" => token} = params) do
    token
    |> Accounts.get_password_recovery()
    |> case do
      {:ok, recovery} ->
        consume_recovery_token(recovery, params)

      error ->
        error
    end
  end

  def recover_password(_conn, _params), do: {:error, :no_token}

  defp consume_recovery_token(recovery, params) do
    Repo.transaction(fn ->
      recovery
      |> Accounts.consume_token!()

      recovery.user
      |> Accounts.update_user(params, [:set_password])
      |> case do
        {:ok, _} ->
          :password_changed

        {:error, changeset} ->
          change_pass_error_response(changeset)
          |> Repo.rollback()
      end
    end)
  end

  defp consume_confirmation_token(confirmation) do
    Repo.transaction(fn ->
      confirmation
      |> Accounts.consume_token!()

      confirmation.user
      |> WelcomeEmail.create_generic_worker()

      confirmation.user
      |> Accounts.update_user(%{confirmed?: true})
      |> case do
        {:ok, _} ->
          :email_confirmed

        {:error, changeset} ->
          raise inspect(changeset.errors)
      end
    end)
  end

  defp change_pass_error_response(changeset) do
    errors =
      changeset
      |> Changeset.group_form_errors()

    pass_errors = errors[:password]

    if pass_errors && "invalid password" in pass_errors,
      do: %{message: :invalid_password},
      else: %{message: :form_error, details: errors}
  end

  defp create_response(res), do: {:ok, res}
end
