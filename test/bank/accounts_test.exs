defmodule Bank.AccountsTest do
  use Bank.DataCase

  alias Bank.Accounts

  import Bank.Factory

  describe "users" do
    alias Bank.Accounts.User

    @valid_attrs %{
      balance: 42,
      cnpj: "23.658.356/0001-12",
      confirmed?: true,
      mobile: "(22)12345-6789",
      email: "x@gmail.com",
      first_name: "some first_name",
      last_name: "some last_name",
      password: "12345678910",
      password_confirmation: "12345678910"
    }
    @update_attrs %{
      balance: 43,
      cnpj: "84.366.626/0001-06",
      mobile: "(22)12345-9876",
      email: "y@gmail.com",
      first_name: "some updated first_name",
      last_name: "some updated last_name",
      password: "12345678911",
      password_confirmation: "12345678911"
    }
    @invalid_attrs %{
      balance: nil,
      cnpj: nil,
      cpf: nil,
      mobile: nil,
      email: nil,
      first_name: nil,
      last_name: nil,
      password: nil,
      password_confirmation: nil
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      users = insert_list(8, :user)

      found_users = Accounts.list_users()

      assert is_list(Accounts.list_users(found_users))
      assert length(users) == length(found_users)
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()

      found_user = Accounts.get_user!(user.id)

      assert found_user.balance == user.balance
      assert found_user.cnpj == user.cnpj
      assert found_user.email == user.email
      assert found_user.first_name == user.first_name
      assert found_user.last_name == user.last_name
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.balance == 42
      assert user.cnpj == "23.658.356/0001-12"
      assert user.email == "x@gmail.com"
      assert user.first_name == "Some First_name"
      assert user.last_name == "Some Last_name"
      assert user.password_hash != "some password_hash"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.balance == 43
      assert user.cnpj == "84.366.626/0001-06"
      assert user.email == "y@gmail.com"
      assert user.first_name == "Some Updated First_name"
      assert user.last_name == "Some Updated Last_name"
      assert user.password_hash != "some updated password_hash"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)

      found_user = Accounts.get_user!(user.id)

      assert found_user.balance == user.balance
      assert found_user.cnpj == user.cnpj
      assert found_user.email == user.email
      assert found_user.first_name == user.first_name
      assert found_user.last_name == user.last_name
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end
  end
end
