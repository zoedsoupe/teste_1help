defmodule Bank.AccountsTest do
  use Bank.DataCase

  alias Bank.Accounts

  describe "users" do
    alias Bank.Accounts.User

    @valid_attrs %{
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

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.balance == 42
      assert user.cnpj == "some cnpj"
      assert user.confirmed? == true
      assert user.cpf == "some cpf"
      assert user.email == "some email"
      assert user.first_name == "some first_name"
      assert user.last_name == "some last_name"
      assert user.new_password == "some new_password"
      assert user.new_password_confirmation == "some new_password_confirmation"
      assert user.password == "some password"
      assert user.password_confirmation == "some password_confirmation"
      assert user.password_hash == "some password_hash"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.balance == 43
      assert user.cnpj == "some updated cnpj"
      assert user.confirmed? == false
      assert user.cpf == "some updated cpf"
      assert user.email == "some updated email"
      assert user.first_name == "some updated first_name"
      assert user.last_name == "some updated last_name"
      assert user.new_password == "some updated new_password"
      assert user.new_password_confirmation == "some updated new_password_confirmation"
      assert user.password == "some updated password"
      assert user.password_confirmation == "some updated password_confirmation"
      assert user.password_hash == "some updated password_hash"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end
  end
end
