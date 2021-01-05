defmodule Bank.Common do
  @moduledoc """
  Common functions for the application
  """

  def merge_from_child(parent, child, keys) do
    parent
    |> Map.delete(child)
    |> Map.merge(Map.take(child, keys))
  end

  def apply_if(value, condition, function, args \\ []) do
    if condition, do: apply(function, [value | args]), else: value
  end

  def apply_unless(value, condition, function, args \\ []) do
    if condition, do: value, else: apply(function, [value | args])
  end

  def map_to_keyword(map) do
    map
    |> Enum.map(fn {k, v} ->
      k = apply_if(k, is_binary(k), &String.to_atom/1)
      {k, v}
    end)
  end

  def atomize_map(map) do
    map
    |> map_to_keyword()
    |> Map.new()
  end

  def remove_accents(string),
    do: string |> String.normalize(:nfd) |> String.replace(~r/[^A-z\s]/u, "")

  def recursive_atom_keys(%_{} = struct),
    do: struct |> Map.from_struct() |> recursive_atom_keys()

  def recursive_atom_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} ->
      case is_binary(k) do
        true ->
          {String.to_atom(k), recursive_atom_keys(v)}

        false ->
          {k, recursive_atom_keys(v)}
      end
    end)
    |> Enum.into(%{})
  end

  def recursive_atom_keys(other), do: other

  def invert_tuples(enumerable), do: enumerable |> Enum.map(fn {k, v} -> {v, k} end)
end
