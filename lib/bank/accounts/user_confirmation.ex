defmodule Bank.Accounts.UserConfirmation do
  @moduledoc """
  Holds user email confirmation tokens and its metadata
  """

  use Bank.Schema
  use Bank.Changeset

  import Ecto.Query

  alias Bank.Accounts.User

  @type t() :: %__MODULE__{
          id: String.t(),
          token: String.t(),
          user: User.t(),
          user_id: String.t(),
          used?: boolean(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "user_confirmations" do
    field :token, :string
    field :used?, :boolean, default: false

    belongs_to :user, User

    timestamps()
  end

  def changeset(confirmation, _params) do
    confirmation
    |> change(token: gen_token())
  end

  @doc """
  Returns a query with params
  """
  @spec get_token_query(list({atom(), any()}) | nil) :: Ecto.Query.t()
  def get_token_query(token) do
    from(uc in __MODULE__)
    |> where([uc], uc.token == ^token)
  end
end
