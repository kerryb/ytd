# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ytd
  use SiteEncrypt.Phoenix

  @impl Phoenix.Endpoint
  def init(_key, config) do
    {:ok, SiteEncrypt.Phoenix.configure_https(config)}
  end

  @impl SiteEncrypt
  def certification do
    SiteEncrypt.configure(
      client: :native,
      domains: ["ytd.kerryb.org", "www.ytd.kerryb.org", "beta.ytd.kerryb.org"],
      emails: ["kerryjbuckley@gmail.com"],
      db_folder: System.get_env("SITE_ENCRYPT_DB", Path.join("tmp", "site_encrypt_db")),
      directory_url:
        case System.get_env("CERT_MODE", "local") do
          "local" -> {:internal, port: Application.get_env(:ytd, :internal_acme_port, 4002)}
          "staging" -> "https://acme-staging-v02.api.letsencrypt.org/directory"
          "production" -> "https://acme-v02.api.letsencrypt.org/directory"
        end
    )
  end

  if Application.get_env(:ytd, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_ytd_key",
    signing_salt: "kFsSXZ68"
  ]

  socket("/socket", YTDWeb.UserSocket,
    websocket: true,
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :ytd,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :ytd)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(YTDWeb.Router)
end
