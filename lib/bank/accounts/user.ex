defmodule Bank.Accounts.User do
  @moduledoc """
  Entity that execute authenticated actions
  """

  use Bank.Changeset, command: true
  use Bank.Schema, expose: true, query: true

  alias Bank.Accounts.UserConfirmation, as: Confirmation
  alias Bank.Accounts.UserPassRecovery, as: PassRecovery
  alias Bank.Common.Formats

  @fields ~w(balance cnpj confirmed? cpf mobile email first_name last_name password password_confirmation)a

  # cpf and cnpj are also required
  # but the check_constraint/3 will validate both
  # both password and password_confirmation too
  # however maybe_execute_command will validate they
  @required_fields ~w(first_name last_name email mobile)a

  @simple_filters ~w(first_name email cpf cnpj)a
  @simple_sortings ~w(first_name email cpf cnpj inserted_at)a

  @exposed_fields ~w(first_name last_name email)

  @cpf_format Formats.cpf()
  @cnpj_format Formats.cnpj()

  @type t() :: %__MODULE__{
          balance: integer(),
          cnpj: String.t() | nil,
          cpf: String.t() | nil,
          confirmed?: boolean(),
          email: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          mobile: String.t(),
          password_hash: String.t()
        }

  schema "users" do
    field :balance, :integer, default: 0
    field :cnpj, :string
    field :confirmed?, :boolean, default: false
    field :cpf, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :mobile, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string

    has_one :confirmation, Confirmation
    has_one :pass_recovery, PassRecovery

    timestamps()
  end

  @doc false
  def changeset(user, attrs, commands \\ []) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> check_constraint(:users, name: :cpf_or_cnpj, message: "A CPF or CNPJ is required")
    |> remove_whitespaces(:first_name)
    |> remove_whitespaces(:last_name)
    |> capitalize_all_words(:first_name)
    |> capitalize_all_words(:last_name)
    |> remove_whitespaces(:email)
    |> downcase(:email)
    |> validate_email(:email)
    |> validate_phone(:mobile)
    |> validate_length(:password, min: 10)
    |> validate_confirmation(:password)
    |> validate_change(:cpf, &validate_cpf/2)
    |> validate_change(:cnpj, &validate_cnpj/2)
    |> unique_constraint(:cpf)
    |> unique_constraint(:cnpj)
    |> unique_constraint(:email)
    |> maybe_execute_command(commands, :check_password)
    |> maybe_execute_command(commands, :set_password)
  end

  defp is_digit(ch) do
    "0" <= ch && ch <= "9"
  end

  defp cpf_verifying_digit_parse(digits, amount) do
    digit =
      digits
      |> Enum.zip(amount..2)
      |> Enum.reduce(0, fn {d, i}, acc -> d * i + acc end)
      |> rem(11)

    if 11 - digit > 9, do: 0, else: 11 - digit
  end

  defp cnpj_verifying_digit_parse(digits, amount) do
    range =
      amount..2
      |> Enum.to_list()
      |> Kernel.++(Enum.to_list(9..2))

    digit =
      digits
      |> Enum.zip(range)
      |> Enum.reduce(0, fn {d, i}, acc -> d * i + acc end)
      |> rem(11)

    if 11 - digit > 9, do: 0, else: 11 - digit
  end

  defp validate_cpf(_, value) do
    if String.match?(value, @cpf_format) do
      [digits | rest] = String.split(value, "-")

      digits =
        digits
        |> String.split("")
        |> Enum.filter(&is_digit/1)
        |> Enum.map(&String.to_integer/1)

      [first_digit, second_digit] =
        rest
        |> hd()
        |> String.split("")
        |> Enum.filter(&is_digit/1)
        |> Enum.map(&String.to_integer/1)

      first_verifying_digit = cpf_verifying_digit_parse(digits, 10)

      second_verifying_digit =
        digits
        |> Kernel.++([first_digit])
        |> cpf_verifying_digit_parse(11)

      first_digit
      |> Kernel.==(first_verifying_digit)
      |> Kernel.&&(second_digit == second_verifying_digit)
      |> if(do: [], else: [{:cpf, "invalid cpf"}])
    else
      [{:cpf, "invalid cpf format"}]
    end
  end

  defp validate_cnpj(_, value) do
    if String.match?(value, @cnpj_format) do
      [digits | rest] = String.split(value, "-")

      digits =
        digits
        |> String.split("")
        |> Enum.filter(&is_digit/1)
        |> Enum.map(&String.to_integer/1)

      [first_digit, second_digit] =
        rest
        |> hd()
        |> String.split("")
        |> Enum.filter(&is_digit/1)
        |> Enum.map(&String.to_integer/1)

      first_verifying_digit = cnpj_verifying_digit_parse(digits, 5)

      second_verifying_digit =
        digits
        |> Kernel.++([first_digit])
        |> cnpj_verifying_digit_parse(6)

      first_digit
      |> Kernel.==(first_verifying_digit)
      |> Kernel.&&(second_digit == second_verifying_digit)
      |> if(do: [], else: [{:cnpj, "invalid cnpj"}])
    else
      [{:cnpj, "invalid cnpj format"}]
    end
  end

  defp execute_command(changeset, :check_password) do
    changeset
    |> validate_required([:password])
    |> validate_required([:password_confirmation])
    |> case do
      %Ecto.Changeset{valid?: true} ->
        changeset.changes.password
        |> Argon2.verify_pass(changeset.data.password_hash)
        |> case do
          true -> changeset
          false -> changeset |> add_error(:password, "invalid password")
        end

      invalid_changeset ->
        invalid_changeset
    end
  end

  defp execute_command(changeset, :set_password) do
    changeset
    |> validate_required([:password])
    |> validate_required([:password_confirmation])
    |> case do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(pass))

      invalid_changeset ->
        invalid_changeset
    end
  end
end
