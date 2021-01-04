defmodule Bank.Schema do
  @moduledoc """
  This is a helper module to avoid some of the UUID boilerplate
  """

  import Ecto.Query

  defmacro __using__(opts \\ []) do
    quote do
      use Ecto.Schema
      import Ecto.Query
      import Bank.Schema

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      if unquote(opts[:expose]) do
        @exposed Module.get_attribute(__MODULE__, :exposed_fields, [])
        @sortings Module.get_attribute(__MODULE__, :simple_sortings, [])
        @filters Module.get_attribute(__MODULE__, :simple_filters, [])

        def exposed_fields, do: @exposed

        defp define_columns(query, nil), do: query

        defp define_columns(query) do
          query
          |> select([x], map(x, ^@exposed))
        end
      end

      # Pagination
      defp put_limit(query, nil), do: query
      defp put_limit(query, limit), do: query |> limit(^limit)

      defp put_offset(query, nil), do: query
      defp put_offset(query, offset), do: query |> offset(^offset)

      # Querying

      @doc """
      Returns a query with params
      """
      @spec get_query(list({atom(), any()}) | nil) :: Ecto.Query.t()
      def get_query(params) do
        sort = params[:sort] || [asc: :inserted_at]

        from(x in __MODULE__)
        |> apply_filters(params)
        |> define_columns(params[:field_set])
        |> put_limit(params[:limit])
        |> put_offset(params[:offset])
        |> put_sort(sort)
      end

      # Filtering
      defp apply_filters(query, nil), do: query
      defp apply_filters(query, []), do: query

      defp apply_filters(query, [{field, :invalid} | _rest]) when field in @filters do
        query
        |> where([x], false)
      end

      defp apply_filters(query, [{field, value} | rest]) when field in @filters do
        query
        |> where([x], field(x, ^field) == ^value)
        |> apply_filters(rest)
      end

      defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)

      # Sorting
      defp put_sort(query, [{order, field}]) when field in @sortings do
        query
        |> order_by([a], {^order, ^field})
      end

      defp put_sort(query, _), do: query |> order_by([x], {:asc, x.inserted_at})
    end
  end

  ##### Token functions ######

  def gen_token do
    random =
      :crypto.strong_rand_bytes(64)
      |> Base.encode64(padding: false)
      |> binary_part(0, 64)

    time_based =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.to_iso8601()
      |> Base.encode64(padding: false)

    random
    |> Kernel.<>(time_based)
    |> String.replace(~r/\+/, "")
    |> String.replace(~r/\=/, "")
    |> String.replace(~r/\-/, "")
  end

  @doc """
  returns query
  """
  def get_token_query(token, module) do
    from(x in module)
    |> where([x], x.token == ^token)
  end

  def consume_token!(resource) do
    resource
    |> Ecto.Changeset.change(%{used?: true})
    |> Bank.Repo.update!()
  end

  # --------------------------------------------
end
