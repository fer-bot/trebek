defmodule TrebekWeb.Router do
  use TrebekWeb, :router

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TrebekWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug TrebekWeb.AuthPipeline
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    plug TrebekWeb.AuthPipeline
  end

  scope "/", TrebekWeb do
    pipe_through :browser

    get "/", PageController, :home
    live_session :no_auth, on_mount: [TrebekWeb.AuthLive, TrebekWeb.EnsurePresenterAuthLive] do
      live "/room/presenter", RoomLive.PresenterIndex, :index
    end
  end

  scope "/", TrebekWeb do
    pipe_through [:browser, :ensure_auth]

    live_session :default, on_mount: [TrebekWeb.AuthLive, TrebekWeb.EnsureAuthLive] do
      live "/room", RoomLive.Index, :index
      live "/room/:id", RoomLive.Show, :index
      live "/room/:id/manage", RoomLive.Edit, :index
      live "/room/:id/present", RoomLive.Present, :present
    end
  end

  scope "/auth", TrebekWeb do
    pipe_through [:browser]

    get"/", AuthController, :login_guest_page
    post"/", AuthController, :login_guest
    get "/login", AuthController, :index
    post "/login", AuthController, :login
    get "/logout", AuthController, :logout
    get "/register", AuthController, :register_page
    post "/register", AuthController, :register
  end

  # Other scopes may use custom stacks.
  scope "/api", TrebekWeb do
    pipe_through :api

    get "/peers", APIController, :peers
  end

  scope "/api", TrebekWeb do
    pipe_through [:api, :ensure_auth]

    get "/export-response/:room_id", APIController, :export_response
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:trebek, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: TrebekWeb.Telemetry,
        metrics_history: {TrebekWeb.MetricsStorage, :metrics_history, []}

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
