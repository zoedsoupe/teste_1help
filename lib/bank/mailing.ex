defmodule Bank.Mailing do
  @moduledoc """
  Public interface for email creation and sending
  """

  use Bamboo.Mailer, otp_app: :bank
  import Bamboo.Email

  alias __MODULE__.Email
  alias Bank.Repo

  def send_single_mail(params, cmds \\ []), do: send_email(params, [:one | cmds])
  def send_mass_mail(params, cmds \\ []), do: send_email(params, [:group | cmds])

  defp send_email(params, cmds) do
    %Email{}
    |> Email.changeset(params, cmds)
    |> Repo.insert()
    |> case do
      {:ok, params} ->
        params |> build_email() |> deliver_later()
        {:ok, params}

      error ->
        error
    end
  end

  def build_email(params) do
    [
      to: params |> Map.get(:to_email),
      from: {params.from_name, params.from_email},
      subject: params.subject,
      html_body: params.html_body,
      bcc: params.bcc
    ]
    |> new_email()
  end

  def get_email(id) do
    Repo.get(Email, id)
    |> case do
      nil -> {:error, :not_found}
      email -> {:ok, email}
    end
  end

  def list_emails(params \\ []) do
    params
    |> Email.get_query()
    |> Repo.all()
  end
end
