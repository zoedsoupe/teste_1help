defmodule BankWeb.Auth do
  @moduledoc """
  Wrappes Guardian and holds custom auth functions based on it
  """

  use Guardian, otp_app: :bank

  alias Bank.Accounts
  alias Bank.Accounts.User

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user!(id)
    {:ok, resource}
  end

  def login(%{"email" => email} = attrs) do
    [email: email]
    |> Accounts.get_user_by()
    |> case do
      {:ok, %{confirmed?: false}} ->
        {:error, :email_not_confirmed}

      {:ok, user} ->
        user
        |> User.changeset(attrs, [:check_password])
        |> case do
          %{valid?: true} ->
            {:ok, token} =
              %{id: user.id}
              |> encode_and_sign()
              |> Tuple.delete_at(2)

            {:ok, token}

          _ ->
            {:error, :invalid_password}
        end

      _ ->
        {:error, :email_not_registered}
    end
  end

  def get_resource(conn) do
    __MODULE__.Plug.current_resource(conn)
  end

  def get_user_id(conn), do: (conn |> Guardian.Plug.current_claims())["sub"]
end
