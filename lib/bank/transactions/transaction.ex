defmodule Bank.Transactions.Transaction do
  @moduledoc """
  Entity that represents users's values exchanges
  """

  use Bank.Changeset, command: true

  @fields ~w(sender_id recipient_id amount)a

  @required_fields @fields

  @exposed_fields ~w(sender_id recipient_id processing_date value id)a

  @simple_filters ~w(sender_id recipient_id id processing_date)a
  @simple_sortings ~w(sender_id recipient_id id processing_date inserted_at)a

  use Bank.Schema, expose: true, query: true

  schema "transactions" do
    field :processing_date, :naive_datetime
    field :recipient_id, :binary_id
    field :sender_id, :binary_id
    field :amount, :float, virtual: true
    field :value, :integer

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs, commands \\ []) do
    transaction
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> maybe_execute_command(commands, :save_as_integer)
    |> maybe_execute_command(commands, :set_process_date)
  end

  defp execute_command(changeset, :set_process_date) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        put_change(
          changeset,
          :processing_date,
          NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        )

      invalid_changeset ->
        invalid_changeset
    end
  end

  defp execute_command(changeset, :save_as_integer) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{amount: amount}} ->
        put_change(changeset, :value, round(amount * 100))

      invalid_changeset ->
        invalid_changeset
    end
  end
end
