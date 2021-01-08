defmodule Bank.Transaction do
  @moduledoc """
  Entity that represents users's values exchanges
  """

  use Bank.Changeset, command: true

  @fields ~w(sender_id recipient_id value processing_date)a

  @required_fields @fields

  @exposed_fields ~w(sender_id recipient_id processing_date)a

  @simple_filters ~w(sender_id recipient_id id processing_date)a
  @simple_sortings ~w(sender_id recipient_id id processing_date inserted_at)a

  use Bank.Schema, expose: true, query: true

  schema "transactions" do
    field :processing_date, :naive_datetime
    field :recipient_id, :string
    field :sender_id, :string
    field :value, :integer

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs, commands \\ []) do
    transaction
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> maybe_execute_command(commands, :save_as_integer)
  end

  defp execute_command(changeset, :save_as_integer) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{value: value}} ->
        put_change(changeset, :value, value * 100)

      invalid_changeset ->
        invalid_changeset
    end
  end
end