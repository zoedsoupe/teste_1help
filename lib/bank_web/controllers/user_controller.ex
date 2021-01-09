defmodule BankWeb.UserController do
  @moduledoc """
  Manages /users context endpoints
  """

  use BankWeb, :controller

  alias Bank.{Accounts, Changeset, Repo}
  alias Bank.Accounts.Jobs.{ConfirmationEmail, RecoveryEmail, WelcomeEmail}
  alias Bank.Accounts.User

  import Bank.Common

  action_fallback BankWeb.FallbackController

  @accepts ~w(first_name last_name cpf cnpj email mobile new_password new_password_confirmation)a
  def create(_conn, params) do
    params
    |> Map.put("confirmation", %{})
    |> Accounts.create_user()
    |> case do
      {:ok, user} ->
        user
        |> ConfirmationEmail.create_generic_worker()

        fields =
          user
          |> Map.take(User.exposed_fields())

        %{data: fields}
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

  @accepts ~w(user_id)a
  def show(_conn, %{"user_id" => id}) do
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

  def show(_conn, _params), do: {:error, :no_user_id}

  @accepts ~w(user_id)a
  def balance(_conn, %{"user_id" => user_id}) do
    user_id
    |> Accounts.get_user()
    |> case do
      {:ok, user} ->
        field =
          user
          |> Map.take([:balance])
          |> Map.update(:balance, :no_balance, fn old -> old / 100 end)

        %{data: field}
        |> Map.put(:message, :found)
        |> create_response()

      error ->
        error
    end
  end

  def balance(_conn, _params), do: {:error, :not_found}

  @accepts ~w(first_name email cpf cnpj)a
  def list(_conn, params) do
    users =
      params
      |> map_to_keyword()
      |> Accounts.list_users()
      |> Enum.map(&Map.take(&1, User.exposed_fields()))

    %{data: users}
    |> Map.put(:message, :ok)
    |> create_response()
  end

  @accepts ~w(user_id first_name last_name email cpf cnpj new_password new_password_confirmation)a
  def change(_conn, params) do
    with {:ok, user} <- Accounts.get_user(params["user_id"]),
         {:ok, user} <- Accounts.update_user(user, params) do
      fields =
        user
        |> Map.take(User.exposed_fields())

      %{data: fields}
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

  @accepts ~w(user_id password password_confirmation new_password new_password_confirmation)a
  def change_password(_conn, params) do
    with {:ok, user} <- Accounts.get_user(params["user_id"]),
         {:ok, _} <-
           user |> Accounts.update_user(params, [:check_password, :set_password]) do
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
        fields =
          recovery
          |> Repo.preload(:user)
          |> Map.get(:user)
          |> Map.take(User.exposed_fields())

        %{data: fields}
        |> Map.put(:message, :valid)
        |> create_response()

      error ->
        error
    end
  end

  def validate_recovery(_conn, _params), do: {:error, :no_token}

  @accepts ~w(token new_password new_password_confirmation)a
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
