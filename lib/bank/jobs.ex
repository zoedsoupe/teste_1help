defmodule Bank.Jobs.Worker do
  @moduledoc """
  Extension of Oban.Worker
  """

  defmacro __using__(opts \\ []) do
    quote do
      use Oban.Worker, unquote(opts)
      import Bank.Common.Wrapping

      def create_generic_worker(resource) do
        %{id: resource.id}
        |> __MODULE__.new()
        |> Oban.insert()
      end

      def create_generic_worker(resource),
        do: resource |> create_generic_worker() |> ok_unwrap()
    end
  end
end
