defmodule Bank.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Bank.Common.Wrapping

  alias Bank.Accounts.User
  alias Bank.Accounts.UserConfirmation, as: Confirmation
  alias Bank.Accounts.UserPassRecovery, as: PassRecovery
  alias Bank.Repo
  alias Ecto.Changeset

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(params \\ []) do
    params
    |> User.get_query()
    |> Repo.all()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id) do
    Repo.get(User, id)
    |> case do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_by(params) do
    params
    |> User.get_query()
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs, [:set_password])
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs, commands \\ []) do
    user
    |> User.changeset(attrs, commands)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @spec get_confirmation(list()) :: {:ok, Confirmation.t()} | {:error, atom()}
  def get_confirmation(token) do
    token
    |> Confirmation.get_token_query()
    |> Repo.one()
    |> case do
      %{used?: true} ->
        {:error, :already_created_account}

      nil ->
        {:error, :invalid_token}

      attempt ->
        attempt
        |> Repo.preload(:user)
        |> ok_wrap()
    end
  end

  @doc """
  Creates an UserPassRecovery
  """
  @spec create_password_recovery(User.t()) ::
          {:ok, PassRecovery.t()} | {:error, Ecto.Changeset.t()}
  def create_password_recovery(user) do
    user
    |> PassRecovery.build()
    |> Repo.insert()
  end

  @spec get_password_recovery(list()) :: {:ok, PassRecovery.t()} | {:error, atom()}
  def get_password_recovery(token) do
    token
    |> PassRecovery.get_token_query()
    |> Repo.one()
    |> case do
      %{used?: true} ->
        {:error, :already_used_token}

      nil ->
        {:error, :invalid_token}

      attempt ->
        if attempt.expiration > NaiveDateTime.utc_now() do
          attempt
          |> Repo.preload(:user)
          |> ok_wrap()
        else
          {:error, :expired_token}
        end
    end
  end

  def consume_token!(resource) do
    resource
    |> Changeset.change(%{used?: true})
    |> Repo.update!()
  end

  @doc """
  Decrease user balance for transaction
  """
  def withdraw(id, [{:amount, amount}]) do
    case get_user(id) do
      {:ok, user} ->
        user
        |> update_user(%{balance: user.balance - amount})

      error ->
        error
    end
  end

  @doc """
  Increase user balance for transaction
  """
  def deposit(id, [{:amount, amount}]) do
    case get_user(id) do
      {:ok, user} ->
        user
        |> update_user(%{balance: user.balance + amount})

      error ->
        error
    end
  end
end
