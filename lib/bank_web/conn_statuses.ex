defmodule BankWeb.ConnStatuses do
  @moduledoc """
  Holds the relation between response message and status code,
  as well as some functions related to it
  """

  alias Plug.Conn

  @success_messages [
    {201, :created},
    {201, :invited}
  ]

  @error_messages [
    {401, :already_created_account},
    {401, :already_used_token},
    {401, :email_not_confirmed},
    {401, :email_not_registered},
    {401, :expired_token},
    {401, :invalid_password},
    {401, :invalid_token},
    {401, :no_token},
    {403, :forbidden},
    {403, :already_confirmed_email},
    {422, :form_error},
    {422, :param_error},
    {422, :user_not_subscribed}
  ]

  @success_codes @success_messages |> Enum.map(fn {k, v} -> {v, k} end) |> Map.new()
  @error_codes @error_messages |> Enum.map(fn {k, v} -> {v, k} end) |> Map.new()

  def success_code(message), do: @success_codes[message] || 200

  def error_code(message),
    do: @error_codes[message] || raise("No status code for `#{message}` message error")

  def put_status(conn, message, type) do
    conn
    |> Conn.put_status(
      case type do
        :ok -> success_code(message)
        :error -> error_code(message)
      end
    )
  end
end