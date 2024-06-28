alias Finsta.Repo
alias Finsta.Accounts

# Define your default user attributes
default_user_attrs = %{
  email: "rijanshakya123@gmail.com",
  password: "Rijan/1234",
  password_confirmation: "Rijan/1234"
}

# Create the default user
case Accounts.create_user(default_user_attrs) do
  {:ok, user} -> IO.puts("Default user created: #{user.email}")
  {:error, changeset} -> IO.inspect(changeset.errors)
end
