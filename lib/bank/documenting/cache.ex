defmodule Bank.Documenting.Cache do
  @moduledoc """
  A genserver that caches the data of modules that will be documented.
  The cached data is used at the end of the tests by Documenting.Formatter
  """

  use GenServer

  alias Bank.Documenting.Transformations

  def start_link(_) do
    {:ok, _} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_config) do
    {:ok, []}
  end

  defmacro doc(conn, description, opts \\ []) do
    if System.get_env("DOC") do
      [
        bind_quoted: [
          conn: conn,
          description: description,
          opts: opts,
          cache: __MODULE__,
          context: __CALLER__.module() |> get_context(),
          controller: __CALLER__.module() |> get_controller,
          line: __CALLER__.line()
        ]
      ]
      |> quote do
        params_descr =
          (opts[:params_descr] || [])
          |> Enum.into(@__default_descriptions__)
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
          |> Map.new()

        resp_trans =
          @__default_resp_transforms__
          |> Map.merge(opts[:field_trans] || %{})
          |> Map.merge(opts[:resp_trans] || %{})
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
          |> Map.new()

        param_trans =
          @__default_param_transforms__
          |> Map.merge(opts[:field_trans] || %{})
          |> Map.merge(opts[:param_trans] || %{})
          |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
          |> Map.new()

        opts =
          [
            context: context,
            line: line,
            controller: controller,
            params_descr: params_descr,
            resp_trans: resp_trans,
            param_trans: param_trans
          ] ++ opts

        GenServer.cast(cache, {:add, conn, description, opts})

        conn
      end
    else
      conn
    end
  end

  def get_context(module) do
    module
    |> Module.get_attribute(:__doc_context__)
    |> case do
      nil -> module |> Module.split() |> List.last() |> String.replace("Test", "")
      context when is_binary(context) -> context
    end
  end

  def list, do: GenServer.call(__MODULE__, :list)

  def handle_cast({:add, conn, description, opts}, state) do
    element = %{
      name: conn.private.phoenix_action,
      description: description,
      method: conn.method,
      body_params: proper_params(:body, conn, opts),
      query_params: proper_params(:query, conn, opts),
      raw_path: raw_path(conn),
      path: proper_path(conn, opts),
      resp_body: proper_response(conn, opts),
      headers: proper_headers(conn, opts),
      context: opts[:context],
      line: opts[:line],
      params_descr: opts[:params_descr],
      on_nil: opts[:on_nil] || []
    }

    {:noreply, state ++ [element]}
  end

  def handle_cast(_event, nil) do
    {:noreply, nil}
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  defp get_controller(module) do
    module
    |> Module.get_attribute(:__doc_controller__)
    |> case do
      nil -> :"Elixir.BankWeb.#{get_context(module)}Controller"
      controller when is_atom(controller) -> controller
    end
  end

  defp proper_params(origin, conn, opts) do
    params = conn |> Map.get(:"#{origin}_params")

    params =
      conn.private.phoenix_action
      |> opts[:controller].action_params()
      |> case do
        :any -> params
        accepted -> params |> Map.take(accepted)
      end

    params
    |> Enum.filter(fn {k, _} -> String.match?(k, ~r/.*_?id$/) end)
    |> Enum.map(&Transformations.determinize_id/1)
    |> Enum.into(params)
    |> Enum.map(fn {k, v} -> maybe_transform(opts[:param_trans], k, v) end)
    |> Map.new()
  end

  defp proper_headers(%{req_headers: headers}, opts) do
    functions =
      opts[:header_transforms]
      |> case do
        nil -> %{}
        map -> map
      end
      |> Enum.into(Transformations.default_header_transforms())

    headers
    |> Enum.map(fn {k, v} -> {k |> :string.titlecase(), v} end)
    |> Enum.map(fn {k, v} -> maybe_transform(functions, k, v) end)
  end

  defp proper_path(%{request_path: path, path_params: params} = conn, opts) do
    params
    |> Enum.find(fn {k, _} -> String.match?(k, ~r/.*_?id$/) end)
    |> case do
      {k, v} -> path |> String.replace(v, Transformations.pseudo_random_id(k))
      nil -> path
    end
    |> Kernel.<>(proper_query_string(conn, opts))
  end

  defp proper_query_string(%{query_params: query_p}, _) when query_p == %{}, do: ""

  defp proper_query_string(conn, opts) do
    proper_params(:query, conn, opts)
    |> URI.encode_query()
    |> (&"?#{&1}").()
  end

  defp proper_response(%{resp_body: json}, opts) do
    resp = json |> Jason.decode!()

    case resp["data"] do
      nil ->
        resp

      data ->
        %{resp | "data" => suit_data(data, opts[:resp_trans])}
    end
  end

  defp suit_data(data, transforms) do
    case data do
      data when is_map(data) ->
        data
        |> Enum.filter(fn {k, _} -> String.match?(k, ~r/^id|.*_id$/) end)
        |> Enum.map(&Transformations.determinize_id/1)
        |> Enum.into(data)
        |> Enum.map(fn {k, v} -> maybe_transform(transforms, k, v) end)
        |> Map.new()

      data when is_list(data) ->
        data
        |> Enum.map(&suit_data(&1, transforms))
    end
  end

  defp raw_path(conn) do
    conn.path_params
    |> Map.to_list()
    |> case do
      [] -> conn.request_path
      [{key, value}] -> conn.request_path |> String.replace(value, ":#{key}")
    end
  end

  defp maybe_transform(functions, k, v) do
    functions[k]
    |> case do
      nil -> {k, v}
      func when is_function(func) -> {k, func.({k, v})}
      default_value -> {k, default_value}
    end
  end
end
