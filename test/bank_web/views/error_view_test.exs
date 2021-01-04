defmodule BankWeb.ErrorViewTest do
  use BankWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(BankWeb.ErrorView, "404.json", []) == %{message: "not_found"}
  end

  test "renders 500.json" do
    assert render(BankWeb.ErrorView, "500.json", []) == %{message: "internal_server_error"}
  end
end
