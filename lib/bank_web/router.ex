defmodule BankWeb.Router do
  use BankWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_as_user do
    plug :accepts, ["json"]
    plug BankWeb.Auth.Pipeline
  end

  scope "/api/v1", BankWeb do
    pipe_through :api

    post "/login", SessionController, :create

    scope "/users" do
      post "/", UserController, :create
      post "/recover-password", UserController, :create_recovery
      post "/resend-confirmation-email", UserController, :resend_confirmation_email

      get "/confirm-email", UserController, :confirm_email
      get "/recover-password", UserController, :validate_recovery

      put "/recover-password", UserController, :recover_password
    end
  end

  scope "/api/v1", BankWeb do
    pipe_through :api_as_user

    scope "/users" do
      scope "/" do
        get "/", UserController, :list
        get "/:user_id", UserController, :show
        get "/:user_id/balance", UserController, :balance

        put "/:user_id/change-password", UserController, :change_password
        put "/:user_id", UserController, :change
      end
    end

    scope "/transactions" do
      scope "/" do
        get "/", TransactionController, :list
        get "/:transaction_id", TransactionController, :show

        post "/", TransactionController, :create

        delete "/:transaction_id", TransactionController, :delete
      end
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: BankWeb.Telemetry
    end
  end
end
