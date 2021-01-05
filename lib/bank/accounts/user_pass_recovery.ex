defmodule Bank.Accounts.UserPassRecovery do
  @moduledoc """
  Models password recovery attempts for User entity
  """

  use Bank.Schema
  use Bank.Changeset

  import Ecto.Query

  alias Bank.Accounts.User

  @expiration_seconds 7200

  @type t() :: %__MODULE__{
          id: String.t(),
          token: String.t(),
          user: User.t(),
          user_id: String.t(),
          used?: boolean(),
          expiration: NaiveDateTime.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "user_pass_recoveries" do
    field :token, :string
    field :used?, :boolean, default: false
    field :expiration, :naive_datetime

    belongs_to :user, User

    timestamps()
  end

  @doc """
  Builds a password recover structure for an user
  """
  def build(user) do
    %__MODULE__{}
    |> change(token: gen_token())
    |> change(expiration: expiration())
    |> change(user_id: user.id)
    |> apply_changes()
  end

  defp expiration do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(@expiration_seconds)
    |> NaiveDateTime.truncate(:second)
  end

  @doc """
  Returns a query with params
  """
  @spec get_token_query(list({atom(), any()}) | nil) :: Ecto.Query.t()
  def get_token_query(token) do
    from(pr in __MODULE__)
    |> where([pr], pr.token == ^token)
  end
end
