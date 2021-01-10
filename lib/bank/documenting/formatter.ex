defmodule Bank.Documenting.Formatter do
  @moduledoc """
  Generates the documentation file.
  Its a genserver that is triggered when all the tests finished
  """
  use GenServer

  alias Bank.Documenting.Cache

  @api_name "Bank"
  @result_file Application.compile_env(:bank, Bank.Documenting)[:result_file_path] ||
                 raise("A file path must be defined")

  def init(_config) do
    {:ok, nil}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    if System.get_env("DOC"), do: generate_docs()

    {:noreply, nil}
  end

  def handle_cast(_event, nil) do
    {:noreply, nil}
  end

  defp generate_docs do
    Cache.list()
    |> Enum.sort_by(& &1[:line])
    |> Enum.group_by(& &1[:context])
    |> put_file()
    |> write_intro()
    |> write_summary()
    |> write_topics()
  end

  defp put_file(topics), do: {topics, File.open!(@result_file, [:write, :utf8])}

  defp write_intro({topics, file}) do
    file
    |> puts("# **#{@api_name}**")
    |> puts(
      "![build](https://github.com/zoedsoupe/teste_1help/workflows/build/badge.svg?branch=main)"
    )

    {topics, file}
  end

  defp write_summary({topics, file}) do
    Enum.each(topics, fn {context, actions} ->
      ctx_id = context |> String.downcase() |> id_format()
      context = context |> String.replace(~r/([A-Z])/, " \\1") |> String.trim()
      file |> IO.puts("* [#{context}](##{ctx_id})")

      Enum.each(actions, fn %{name: name} ->
        file |> IO.puts("  * [#{name}](##{ctx_id}-#{name |> id_format()})")
      end)
    end)

    {topics, file}
  end

  defp write_topics({topics, file}) do
    topics
    |> Enum.each(fn {context, actions} ->
      ctx_id = context |> String.downcase()
      context = context |> String.replace(~r/([A-Z])/, " \\1") |> String.trim()
      IO.puts(file, "# #{context}<a id=#{ctx_id}></a>")
      write_topic({actions, file, ctx_id})
    end)
  end

  defp write_topic({actions, file, ctx_id}) do
    actions
    |> Enum.each(fn action ->
      {file, action}
      |> put_header(ctx_id)
      |> put_info()
      |> put_body_params()
      |> put_query_params()
      |> put_exemple()
      |> put_division_line()
    end)
  end

  defp put_header({file, action}, ctx_id) do
    file
    |> puts("## #{action.name}<a id=#{ctx_id}-#{action.name |> id_format()}></a>")
    |> puts(action.description)

    {file, action}
  end

  defp put_info({file, action}) do
    file
    |> puts("### Info")
    |> puts("* __Method:__ #{action.method}")
    |> puts("* __Path:__ #{action.raw_path}")

    {file, action}
  end

  defp put_body_params(tuple), do: put_params(tuple, "body")
  defp put_query_params(tuple), do: put_params(tuple, "query")

  defp put_params({file, action}, origin) do
    descriptions = action.params_descr
    on_nil = action.on_nil

    action
    |> Map.get(:"#{origin}_params")
    |> case do
      map when map == %{} ->
        nil

      params ->
        file
        |> puts("### #{origin |> String.capitalize()} params")
        |> puts("")
        |> puts("|Name|Description|Required?|Default value|Example|")
        |> puts("|-|-|-|-|-|")

        params
        |> Enum.each(fn {k, v} ->
          descr =
            descriptions[k] ||
              raise(
                "Description not set for field '#{k}' of '#{action.method} #{action.raw_path}' documentation"
              )

          {r, default} = on_nil_tuple(on_nil, k)

          file
          |> puts([k, descr, r, default, inspect(v)] |> Enum.reduce("|", &"#{&2}#{&1}|"))
        end)

        file
        |> puts("")
    end

    {file, action}
  end

  defp put_exemple({file, action}) do
    file
    |> puts("### Example request")
    |> puts("```")
    |> IO.write("curl #{curl_headers(action)}")

    file |> puts("-X #{action.method} \\")
    file |> IO.write("     'http://localhost:4000#{action.path}'")

    file
    |> maybe_put_curl_data(action)
    |> puts("```")
    |> put_exemple_response(action)

    {file, action}
  end

  defp put_division_line({file, action}) do
    file |> puts("") |> puts("---") |> puts("")

    {file, action}
  end

  defp curl_headers(%{headers: headers}) do
    headers
    |> Enum.reduce("", fn {k, v}, acc ->
      "#{acc}-H '#{k}: #{v}' \\\n     "
    end)
  end

  defp maybe_put_curl_data(file, %{body_params: params}) when params == %{},
    do: file |> puts("")

  defp maybe_put_curl_data(file, %{body_params: params}) do
    file |> puts("  \\\n     -d '#{params |> Jason.encode!()}'")
  end

  defp put_exemple_response(file, action) do
    file
    |> puts("### Exemple response")
    |> puts("```json")
    |> puts(action.resp_body |> Jason.encode!(pretty: true))
    |> puts("```")
  end

  defp puts(file, text) do
    IO.puts(file, text)
    file
  end

  defp id_format(value), do: String.replace("#{value}", "_", "-")

  defp on_nil_tuple(on_nil, key) do
    on_nil[:"#{key}"]
    |> case do
      nil -> {"optional", nil}
      :error -> {"required", nil}
      value -> {"optional", inspect(value)}
    end
  end
end
