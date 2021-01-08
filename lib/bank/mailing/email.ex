defmodule Bank.Mailing.Email do
  @moduledoc """
  This structure maps an email in the mailing context

  This is not persisted, but I use embedded_schema so
  we can use Ecto.Changeset manage field alterations

  It holds new/1 and edit/2 functions as a boilerplate to
  changeset/2 to avoid exposing the validation logic
  """

  use Bank.Changeset, command: true

  import Bank.Common

  alias Bank.Accounts.User
  alias Bank.Common.Formats

  @fields [
    :user_id,
    :subject,
    :from_email,
    :from_name,
    :to_email,
    :template,
    :assigns,
    :message
  ]

  @required_fields [:subject, :from_email, :from_name, :template]
  @email_format Formats.email()

  @simple_filters [
    :user_id,
    :subject,
    :template,
    :to_email,
    :from_email,
    :from_name
  ]
  @simple_sortings [:inserted_at]

  @default_from_email Application.compile_env(:bank, :mailing_default_from_email)
  @default_from_name Application.compile_env(:bank, :mailing_default_from_name)
  @domain Application.compile_env(:bank, :server_domain)
  @templates_path "priv/email_templates/"

  use Bank.Schema, expose: true, query: true

  @typedoc """
  The data-structure representing an email
  - `subject` (Email subject);
  - `html_body` (Email body in HTML);
  - `from_email` (Email sender email);
  - `from_name` (Email sender name);
  - `domain_name` (Sender domain name);
  - `template` (Email body EEx template);
  - `assigns` (Template assigns);
  """
  @type t() :: %__MODULE__{
          subject: String.t() | nil,
          template: String.t() | nil,
          assigns: map() | nil,
          html_body: String.t() | nil,
          from_email: String.t(),
          from_name: String.t(),
          to_email: String.t() | nil,
          bcc: list() | nil
        }

  schema "emails" do
    field :subject, :string
    field :template, :string
    field :assigns, :map
    field :html_body, :string, virtual: true
    field :from_email, :string, default: @default_from_email
    field :from_name, :string, default: @default_from_name
    field :to_email, :string
    field :bcc, {:array, :string}
    field :message, :string

    belongs_to :user, User

    timestamps()
  end

  def changeset(email, attrs, cmds) do
    email
    |> cast(attrs, @fields)
    |> maybe_execute_command(cmds, :communication)
    |> put_body()
    |> validate_required(@required_fields)
    |> maybe_execute_command(cmds, :one)
    |> validate_format(:from_email, @email_format)
    |> validate_format(:to_email, @email_format)
    |> validate_length(:html_body, min: 8)
  end

  @doc "Boilerplate over the changeset"
  def new(params, cmds) do
    %__MODULE__{}
    |> changeset(params, cmds)
    |> case do
      %Ecto.Changeset{valid?: true} = cs ->
        {:ok,
         cs
         |> apply_changes()}

      cs ->
        {:error, cs}
    end
  end

  defp execute_command(changeset, :communication) do
    changeset
    |> validate_required([:message])
    |> assign_message()
  end

  defp execute_command(changeset, :one) do
    changeset
    |> validate_required([:to_email])
    |> assign_message()
  end

  # Exclusive functions

  defp assign_message(%{valid?: false} = changeset), do: changeset

  defp assign_message(changeset) do
    assigns =
      changeset
      |> get_field(:assigns)
      |> case do
        nil -> %{}
        assigns -> assigns
      end
      |> Map.put(:message, get_field(changeset, :message))

    put_change(changeset, :assigns, assigns)
  end

  defp put_body(%{valid?: false} = changeset), do: changeset

  defp put_body(changeset) do
    html =
      changeset
      |> get_field(:template)
      |> template_path()
      |> EEx.eval_file(assigns: prepare_assigns(changeset))

    put_change(changeset, :html_body, html)
  end

  defp template_path(name), do: "#{@templates_path}#{name}.html.eex"

  defp prepare_assigns(changeset) do
    changeset
    |> get_change(:assigns, %{})
    |> atomize_map()
    |> Map.put(:domain, @domain)
  end
end
