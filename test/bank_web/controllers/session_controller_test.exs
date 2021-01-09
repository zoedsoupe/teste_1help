defmodule BankWeb.SessionTest do
  use BankWeb.ConnCase, async: true

  use Bank.Documenting

  alias Bank.Accounts

  default_descriptions(%{
    email: "User account email",
    password: "Current password, required to access this action",
    password_confirmation: "Current password confirmation"
  })

  doc_field_transformations(%{
    email: "mdsp@server.com",
    password: "Somepass123",
    password_confirmation: "Somepass123"
  })

  describe "login" do
    @create_attrs %{
      email: "mdsp@gmail.com",
      cpf: "115.966.130-84",
      mobile: "(22)12345-6789",
      first_name: "Kirby",
      last_name: "Josias",
      new_password: "password12",
      new_password_confirmation: "password12",
      confirmed?: true
    }

    @login %{
      email: "mdsp@gmail.com",
      password: "password12",
      password_confirmation: "password12"
    }

    @wrong_password %{
      email: "mdsp@gmail.com",
      password: "password1234",
      password_confirmation: "password1234"
    }

    @user_not_exists %{
      email: "mario@gmail.com",
      password: "password12",
      password_confirmation: "password12"
    }

    def fixture(:user) do
      {:ok, user} = Accounts.create_user(@create_attrs)
      user
    end

    setup [:create_user]

    test "login with a valid data", %{conn: conn} do
      conn =
        conn
        |> post(Routes.session_path(conn, :create), @login)
        |> doc(
          "Returns token for this api",
          resp_trans: %{token: "veryLongToken"},
          params_descr: [email: "Account email", password: "Account password"],
          on_nil: [email: :error, password: :error, password_confirmation: :error]
        )

      %{"message" => message} = json_response(conn, 200)
      assert message == "login_success"
    end

    test "login with a wrong password", %{conn: conn} do
      conn =
        conn
        |> post(Routes.session_path(conn, :create), @wrong_password)

      %{"message" => message} = json_response(conn, 401)
      assert message == "invalid_password"
    end

    test "login with an invalid user", %{conn: conn} do
      conn =
        conn
        |> post(Routes.session_path(conn, :create), @user_not_exists)

      %{"message" => message} = json_response(conn, 401)
      assert message == "email_not_registered"
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
