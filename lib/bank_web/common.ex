defmodule BankWeb.Common do
  @moduledoc """
  Holds common functions to be used across the Web context
  """

  def create_response_data_map(value) do
    value
    |> Map.new(fn data -> {:data, data} end)
  end
end
