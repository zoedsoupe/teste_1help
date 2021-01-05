defmodule Bank.Documenting.Transformations do
  @moduledoc """
  Transformation for documentation elements
  """

  @default_header_transforms %{
    "Content-type" => "application/json",
    "Authorization" => "Bearer VeryLongTokenJIUzUxMiIsInR5"
  }

  def default_header_transforms, do: @default_header_transforms

  def determinize_id({k, _}), do: {k, k |> pseudo_random_id()}

  def pseudo_random_id(key) do
    key
    |> pseudo_random_string(16)
    |> String.slice(0, 36)
    |> String.downcase()
    |> String.graphemes()
    |> List.insert_at(8, "-")
    |> List.insert_at(13, "-")
    |> List.insert_at(18, "-")
    |> List.insert_at(23, "-")
    |> List.to_string()
  end

  def pseudo_random_string(seed, numeric_basis) do
    :crypto.hash(:sha, seed)
    |> :crypto.bytes_to_integer()
    |> Integer.to_string(numeric_basis)
  end
end
