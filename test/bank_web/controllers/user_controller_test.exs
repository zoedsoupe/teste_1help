defmodule BankWeb.UserControllerTest do
  use BankWeb.ConnCase, async: true

  use Bank.Documenting
  use Bamboo.Test
  use Oban.Testing, repo: Bank.Repo

  import Bank.Factory
  import Bank.Common.Wrapping
  import Ecto.Changeset
  import Ecto.Query

  alias Bank.{Accounts, Repo}
  alias Bank.Accounts.UserPassRecovery
  alias Bank.Accounts.Jobs.{ConfirmationEmail, RecoveryEmail, WelcomeEmail}

  default_descriptions(%{
    first_name: "First name of the user",
    last_name: "Last name of the user",
    email: "Account e-mail",
    mobile: "Account mobile",
    balance: "Bank's account amount",
    password: "Current password, required to access this action",
    password_confirmation: "Current password confirmation",
    new_password: "New password to be set to that account",
    new_password_confirmation: "New password confirmation",
    confirmed?: "Defines if user email is confirmed",
    token: "A token sent by email to authenticate this action",
    cpf: "Account CPF",
    cnpj: "Account CNPJ"
  })

  doc_field_transformations(%{
    token: "VeryLongToken",
    mobile: "(dd)12345-6789",
    cnpj: "123.456.789/0001-12",
    cpf: "123.456.789-10",
    password: "Somepass123",
    password_confirmation: "Somepass123",
    new_password: "NewPass123",
    new_password_confirmation: "NewPass123",
    name: "Zoey Pessanha",
    balance: "999999.99",
    email: "valid@email.com"
  })

  describe "users" do
    @valid_attrs %{
      cnpj: "23.658.356/0001-12",
      confirmed?: true,
      mobile: "(22)12345-6789",
      email: "x@gmail.com",
      first_name: "some first_name",
      last_name: "some last_name",
      new_password: "12345678910",
      new_password_confirmation: "12345678910"
    }

    @updated_attrs %{
      email: "new@email.com",
      first_name: "some updated first_name",
      last_name: "some updated last_name",
      mobile: "(22)52431-9999",
      cpf: "783.728.680-42",
      password: "Somepass123",
      password_confirmation: "Somepass123",
      new_password: "NewPass123",
      new_password_confirmation: "NewPass123",
      balance: 54,
      confirmed?: false
    }

    @invalid_attrs %{
      email: nil,
      first_name: nil,
      last_name: nil,
      cnpj: nil,
      mobile: nil,
      balance: nil,
      password: nil,
      password_confirmation: nil,
      new_password: nil,
      new_password_confirmation: nil
    }

    test "POST /users with valid data creates an user", ctx do
      conn =
        post(ctx.conn, "/api/v1/users", @valid_attrs)
        |> doc(
          "Creates a new account",
          on_nil: [
            email: :error,
            first_name: :error,
            last_name: :error,
            cpf: :error,
            cnpj: :error,
            mobile: :error,
            password: :error,
            password_confirmation: :error,
            new_password: :error,
            new_password_confirmation: :error
          ]
        )

      %{"message" => message, "data" => user} = conn |> Map.get(:resp_body) |> Jason.decode!()

      ConfirmationEmail.perform(%{"id" => user["id"]})

      assert conn.status == 201
      assert message == "created"

      assert user["first_name"] == "Some First_name"
      assert user["last_name"] == "Some Last_name"
      assert user["email"] == @valid_attrs.email

      complete_user = user["id"] |> Accounts.get_user!()

      # Ensure a password was set
      refute nil == complete_user.password_hash
      refute complete_user.confirmed?

      assert_enqueued(worker: ConfirmationEmail, args: %{id: user["id"]})
      assert_email_delivered_with(to: [nil: user["email"]])
    end

    test "POST /users with invalid data returns error changeset", ctx do
      conn = post(ctx.conn, "/api/v1/users", @invalid_attrs)

      %{"details" => details} = conn |> Map.get(:resp_body) |> Jason.decode!()

      assert conn.status == 422
      assert details["first_name"] == ["can't be blank"]
      assert details["last_name"] == ["can't be blank"]
      assert details["email"] == ["can't be blank"]

      assert_no_emails_delivered()
    end

    @tag auth: true
    test "PUT /users/:id with valid data updates the user", ctx do
      %{id: id, password_hash: hash} = ctx.user

      conn =
        put(ctx.conn, "/api/v1/users/#{id}", @updated_attrs)
        |> doc(
          "Basic user edition that they can do to themself",
          field_trans: %{email: "new@email.com"}
        )

      %{"message" => message, "data" => updated_user} =
        conn |> Map.get(:resp_body) |> Jason.decode!()

      assert conn.status == 200
      assert message == "updated"

      assert updated_user["first_name"] == "Some Updated First_name"
      assert updated_user["last_name"] == "Some Updated Last_name"
      assert updated_user["email"] == @updated_attrs.email

      complete_user = id |> Accounts.get_user!()

      # ensure that didn't affected restrict values
      assert complete_user.confirmed?
      assert complete_user.password_hash == hash
    end
  end

  @tag auth: true
  test "PUT /users/:id with invalid data returns error changeset", ctx do
    %{id: user_id} = ctx.user

    conn = put(ctx.conn, "/api/v1/users/#{user_id}", @invalid_attrs)

    %{"details" => errors} = conn |> Map.get(:resp_body) |> Jason.decode!()

    assert conn.status == 422

    assert conn.status == 422
    assert errors["first_name"] == ["can't be blank"]
    assert errors["email"] == ["can't be blank"]
    assert errors["last_name"] == ["can't be blank"]
  end

  @tag auth: true
  test "PUT /users/:id/change-password changes their password", ctx do
    user = ctx.user

    conn =
      ctx.conn
      |> put("/api/v1/users/#{user.id}/change-password", %{
        password: "12345678910",
        password_confirmation: "12345678910",
        new_password: @updated_attrs.new_password,
        new_password_confirmation: @updated_attrs.new_password_confirmation
      })
      |> doc(
        "Changes user password",
        on_nil: [
          password: :error,
          password_confirmation: :error,
          new_password: :error,
          new_password_confirmation: :error
        ],
        field_trans: %{new_password: "NewPass123!", new_password_confirmation: "NewPass123!"}
      )

    %{"message" => message} = conn |> get_resp_body()

    assert conn.status == 200
    assert message == "password_changed"

    {:ok, _} =
      BankWeb.Auth.login(%{
        "email" => user.email,
        "password" => @updated_attrs.new_password,
        "password_confirmation" => @updated_attrs.new_password_confirmation
      })
  end

  test "PUT /users/:id/change-password with wrong current pass returns fail", ctx do
    # Should explicitelly create user to be able to give it a password
    user = insert(:user, confirmed?: true)

    {_, token, _} = user |> BankWeb.Auth.encode_and_sign()

    conn =
      ctx.conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/v1/users/#{user.id}/change-password", %{
        password: "wrongpass123",
        password_confirmation: "wrongpass123",
        new_password: "Newpass321",
        new_password_confirmation: "Newpass321"
      })

    %{"message" => message} = conn |> get_resp_body()

    assert conn.status == 401
    assert message == "invalid_password"

    {:error, _} =
      BankWeb.Auth.login(%{
        "email" => user.email,
        "password" => "Newpass321",
        "password_confirmation" => "Newpass321"
      })
  end

  test "password recovery works properly", ctx do
    %{id: user_id} = user = insert(:user, confirmed?: true)

    %{"message" => "recovery_attempt_created"} =
      post(ctx.conn, "/api/v1/users/recover-password", %{email: user.email})
      |> doc(
        "Creates password recovery attempt",
        on_nil: [email: :error]
      )
      |> get_resp_body()

    %{token: token} =
      from(pr in UserPassRecovery)
      |> where([pr], pr.user_id == ^user_id)
      |> Repo.all()
      |> hd()

    RecoveryEmail.perform(%{"token" => token})

    assert_enqueued(worker: RecoveryEmail)

    # token validation returns user when token is valid

    conn =
      ctx.conn
      |> get("/api/v1/users/recover-password?token=#{token}")
      |> doc(
        "Validates token and returns user data if valid",
        on_nil: [token: :error]
      )

    %{"message" => "valid", "data" => %{"id" => ^user_id}} = conn |> get_resp_body

    assert conn.status == 200

    # token validation fail  when token is invalid

    conn = ctx.conn |> get("/api/v1/users/recover-password?token=invalid_token")

    %{"message" => "invalid_token"} = conn |> get_resp_body
    assert conn.status == 401

    # fails when token is expired

    recovery =
      token
      |> Accounts.get_password_recovery()
      |> ok_unwrap()
      |> change(%{
        expiration:
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(-7200)
          |> NaiveDateTime.truncate(:second)
      })
      |> Repo.update!()

    conn = ctx.conn |> get("/api/v1/users/recover-password?token=#{token}")

    %{"message" => "expired_token"} = conn |> get_resp_body
    assert conn.status == 401

    recovery
    |> change(%{
      expiration:
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(7200)
        |> NaiveDateTime.truncate(:second)
    })
    |> Repo.update!()

    # Recovery attempt fails with wrong token

    conn =
      put(ctx.conn, "/api/v1/users/recover-password", %{
        new_password: "new-pass12",
        new_password_confirmation: "new-pass12",
        token: "invalid-token"
      })

    %{"message" => "invalid_token"} = conn |> get_resp_body
    assert conn.status == 401

    # Recovery attempt changes password succeeds with correct token

    new_pass = "new-pass12"

    conn =
      put(ctx.conn, "/api/v1/users/recover-password", %{
        new_password: new_pass,
        new_password_confirmation: new_pass,
        token: token
      })
      |> doc(
        "Sets new password for user",
        on_nil: [new_password: :error, new_password_confirmation: :error, token: :error],
        field_trans: %{new_password: "NewPass123!", new_password_confirmation: "NewPass123!"}
      )

    %{"message" => "password_changed"} = conn |> get_resp_body
    assert conn.status == 200

    {:ok, _} =
      BankWeb.Auth.login(%{
        "email" => user.email,
        "password" => new_pass,
        "password_confirmation" => new_pass
      })

    # fails if token was already used
    conn =
      put(ctx.conn, "/api/v1/users/recover-password", %{
        new_password: "new-pass12",
        new_password_confirmation: "new-pass12",
        token: token
      })

    %{"message" => "already_used_token"} = conn |> get_resp_body
    assert conn.status == 401
  end

  test "/users/resend-confirmation-email sends confirmation email again", ctx do
    %{id: id, email: email} = insert(:user)

    conn =
      post(ctx.conn, "/api/v1/users/resend-confirmation-email", %{email: email})
      |> doc(
        "Sends new confirmation email",
        on_nil: [email: :error]
      )

    ConfirmationEmail.perform(%{"id" => id})

    assert conn.status == 200
    assert_enqueued(worker: ConfirmationEmail, args: %{id: id})
    assert_email_delivered_with(to: [nil: email])
  end

  test "/users/resend-confirmation-email to unregistered email returns error", ctx do
    conn = post(ctx.conn, "/api/v1/users/resend-confirmation-email", %{email: "asdf@email.com"})

    assert conn.status == 401
    assert "email_not_registered" == (conn |> Map.get(:resp_body) |> Jason.decode!())["message"]
    refute_enqueued(worker: ConfirmationEmail)
    assert_no_emails_delivered()
  end

  test "/users/resend-confirmation-email to alredy_confirmed email returns error", ctx do
    %{email: email} = insert(:user, confirmed?: true)

    conn = post(ctx.conn, "/api/v1/users/resend-confirmation-email", %{email: email})

    assert conn.status == 403

    assert "already_confirmed_email" ==
             (conn |> Map.get(:resp_body) |> Jason.decode!())["message"]

    refute_enqueued(worker: ConfirmationEmail)
    assert_no_emails_delivered()
  end

  test "/users/confirmation-email with valid params activates account", ctx do
    confirmation = insert(:confirmation)

    %{id: id, confirmation: %{token: token}} = insert(:user, confirmation: confirmation)

    conn =
      get(ctx.conn, "/api/v1/users/confirm-email?token=#{token}")
      |> doc(
        "Activates the account related to given token",
        on_nil: [token: :error]
      )

    user = id |> Accounts.get_user!() |> Repo.preload(:confirmation)
    WelcomeEmail.perform(%{"id" => id})

    assert conn.status == 200
    assert user.confirmed?
    assert user.confirmation.used?
    assert_enqueued(worker: WelcomeEmail, args: %{id: id})
    assert_email_delivered_with(to: [nil: user.email])
  end

  test "/users/confirmation-email with invalid token returns error", ctx do
    conn = get(ctx.conn, "/api/v1/users/confirm-email?token=invalidtoken")

    assert conn.status == 401
    assert "invalid_token" = conn |> get_resp_message()
    refute_enqueued(worker: WelcomeEmail)
    assert_no_emails_delivered()
  end

  test "/users/confirmation-email with already used token returns fail", ctx do
    confirmation = insert(:confirmation, used?: true)

    %{confirmation: confirmation} = insert(:user, confirmation: confirmation)

    Accounts.consume_token!(confirmation)

    conn = get(ctx.conn, "/api/v1/users/confirm-email?token=#{confirmation.token}")

    assert conn.status == 401
    assert "already_created_account" = conn |> get_resp_message()
  end
end
