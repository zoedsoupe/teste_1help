defmodule BankWeb.SuccessView do
  use BankWeb, :view

  def render("success.json", %{body: body}) do
    body
  end
end
