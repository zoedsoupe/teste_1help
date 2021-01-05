defmodule Bank.Documenting do
  @moduledoc """
  Holds the context, that generates documentation to the API from tests
  """

  def start(_ \\ []) do
    [__MODULE__.Cache]
    |> Supervisor.start_link(strategy: :one_for_all)
  end

  defmacro doc_context(context) when is_binary(context) do
    quote do: @__doc_context__(unquote(context))
  end

  defmacro default_descriptions(descriptions) do
    quote do: @__default_descriptions__(unquote(descriptions))
  end

  defmacro doc_controller(controller) do
    quote do
      case unquote(controller) do
        controller when is_atom(controller) ->
          Module.put_attribute(__MODULE__, :__doc_controller__, controller)

        value ->
          raise "Must use module as argument, got: #{inspect(value)}"
      end
    end
  end

  defmacro doc_resp_transformations(functions) do
    quote bind_quoted: [functions: functions] do
      @__default_resp_transforms__ functions
                                   |> Enum.into(@__default_resp_transforms__)
    end
  end

  defmacro doc_param_transformations(functions) do
    quote bind_quoted: [functions: functions] do
      @__default_param_transforms__ functions
                                    |> Enum.into(@__default_param_transforms__)
    end
  end

  defmacro doc_field_transformations(functions) do
    quote bind_quoted: [functions: functions] do
      @__default_resp_transforms__ functions
                                   |> Enum.into(@__default_resp_transforms__)

      @__default_param_transforms__ functions
                                    |> Enum.into(@__default_param_transforms__)
    end
  end

  defmacro doc_context(context),
    do: raise("Context expected to be of type String, got: #{inspect(context)}")

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      import unquote(__MODULE__.Cache)

      Module.put_attribute(__MODULE__, :__default_descriptions__, %{})

      @__default_resp_transforms__ Application.compile_env(:bank, unquote(__MODULE__), %{})[
                                     :default_response_transforms
                                   ] || %{}

      @__default_param_transforms__ Application.compile_env(:bank, unquote(__MODULE__), %{})[
                                      :default_param_transforms
                                    ] || %{}
    end
  end
end
