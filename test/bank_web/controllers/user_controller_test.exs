defmodule BankWeb.UserControllerTest do
  use BankWeb.ConnCase

  alias Bank.Accounts
  alias Bank.Accounts.User

  @create_attrs %{
    balance: 42,
    cnpj: "some cnpj",
    confirmed?: true,
    cpf: "some cpf",
    email: "some email",
    first_name: "some first_name",
    last_name: "some last_name",
    new_password: "some new_password",
    new_password_confirmation: "some new_password_confirmation",
    password: "some password",
    password_confirmation: "some password_confirmation",
    password_hash: "some password_hash"
  }
  @update_attrs %{
    balance: 43,
    cnpj: "some updated cnpj",
    confirmed?: false,
    cpf: "some updated cpf",
    email: "some updated email",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    new_password: "some updated new_password",
    new_password_confirmation: "some updated new_password_confirmation",
    password: "some updated password",
    password_confirmation: "some updated password_confirmation",
    password_hash: "some updated password_hash"
  }
  @invalid_attrs %{
    balance: nil,
    cnpj: nil,
    confirmed?: nil,
    cpf: nil,
    email: nil,
    first_name: nil,
    last_name: nil,
    new_password: nil,
    new_password_confirmation: nil,
    password: nil,
    password_confirmation: nil,
    password_hash: nil
  }

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => id,
               "balance" => 42,
               "cnpj" => "some cnpj",
               "confirmed?" => true,
               "cpf" => "some cpf",
               "email" => "some email",
               "first_name" => "some first_name",
               "last_name" => "some last_name",
               "new_password" => "some new_password",
               "new_password_confirmation" => "some new_password_confirmation",
               "password" => "some password",
               "password_confirmation" => "some password_confirmation",
               "password_hash" => "some password_hash"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => id,
               "balance" => 43,
               "cnpj" => "some updated cnpj",
               "confirmed?" => false,
               "cpf" => "some updated cpf",
               "email" => "some updated email",
               "first_name" => "some updated first_name",
               "last_name" => "some updated last_name",
               "new_password" => "some updated new_password",
               "new_password_confirmation" => "some updated new_password_confirmation",
               "password" => "some updated password",
               "password_confirmation" => "some updated password_confirmation",
               "password_hash" => "some updated password_hash"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    %{user: user}
  end
end
