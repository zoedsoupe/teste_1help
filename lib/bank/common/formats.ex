defmodule Bank.Common.Formats do
  @moduledoc """
  Our common place for regexes
  """

  @cpf_format ~r/^\d{3}\.\d{3}\.\d{3}\-\d{2}$/
  @cnpj_format ~r/^\d{2}\.\d{3}\.\d{3}\/\d{4}\-\d{2}$/
  @mobile_format ~r/^\(\d{2}\)\d{5}-\d{4}$/
  @email_format ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  def cpf, do: @cpf_format
  def cnpj, do: @cnpj_format
  def mobile, do: @mobile_format
  def email, do: @email_format
end
