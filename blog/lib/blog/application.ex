defmodule Blog.Application do
  @moduledoc """
  Application supervisor and startup configuration.

  Starts the OTP application and supervises all runtime processes.
  This is the entry point for the entire Blog application.

  ## Supervised Children

  Started in order:

  1. **BlogWeb.Telemetry**
     - Metrics collection and monitoring
     - Beam VM metrics, Phoenix/Ecto metrics
     - Provides data for Phoenix LiveDashboard
     - See: lib/blog_web/telemetry.ex

  2. **Blog.Repo**
     - Ecto repository
     - Database connection pool
     - Query execution, migrations
     - Configured in config/runtime.exs with DATABASE_URL

  3. **DNSCluster**
     - Distributed Erlang clustering
     - Connects nodes in multi-server deployments
     - Query: Application.get_env(:blog, :dns_cluster_query)
     - Default: :ignore (single-node mode)
     - In distributed environments: Helps nodes discover each other

  4. **Phoenix.PubSub** (name: Blog.PubSub)
     - In-process message broadcasting
     - Real-time updates via topic subscriptions
     - Used for: Comments broadcasting to post viewers
     - Adapter: Default (PG2-based in-process)
     - In distributed environments: Consider adapter: :pg_distributed

  5. **BlogWeb.Endpoint**
     - HTTP server (Bandit on port 4000)
     - WebSocket upgrade handling (for LiveView)
     - Plug pipeline (parsers, session, cookies)
     - Serves routes defined in BlogWeb.Router

  ## Supervision Tree

  Strategy: `:one_for_one`
  - If one child dies, only that child is restarted
  - Other children continue running
  - Suitable for independent services

  Alternative strategies:
  - `:one_for_all` — If one dies, restart all (for tightly coupled)
  - `:rest_for_one` — If one dies, restart it and all started after
  - `:simple_one_for_one` — For dynamic child addition

  Current choice (`:one_for_one`) is correct:
  - Children are mostly independent
  - DB, PubSub, HTTP can restart separately
  - Prevents cascading failures

  ## Startup Order

  Matters for some children:
  1. Telemetry first (other services may emit metrics)
  2. Repo second (before any service querying database)
  3. DNSCluster and PubSub can be parallel
  4. Endpoint last (needs everything ready for connections)

  Current order respects these dependencies.

  ## Config Changes

  The `config_change/3` callback:
  - Called when application configuration changes at runtime
  - Notifies endpoint of configuration updates
  - Used when updating config without restart
  - Return `:ok` to indicate success

  In development: Rarely needed (restart app for config changes)
  In production: Allows live config updates (e.g., feature flags)

  ## Future Enhancements

  ### Additional Services

  When adding features, new children might include:
  - Job queue (Oban) — For async email sending, scheduled tasks
  - Cache (Cachex) — For session storage, user data
  - Rate limiter (ExRateLimiter) — For login attempt limits
  - Task supervisor (Task.Supervisor) — For background work
  - GenServer — For stateful logic (e.g., user sessions)

  Example adding Oban:
  ```elixir
  children = [
    BlogWeb.Telemetry,
    Blog.Repo,
    {DNSCluster, query: ...},
    {Phoenix.PubSub, ...},
    {Oban, otp_app: :blog},  # Job queue
    BlogWeb.Endpoint
  ]
  ```

  ### Distributed Deployment

  For multi-server deployment:
  - Set dns_cluster_query to actual DNS query
  - Change PubSub adapter from :pg to :pg_distributed
  - Deploy with distributed Erlang clustering
  - Env variable: RELEASE_DISTRIBUTION=name (or ip)

  Example:
  ```elixir
  config :blog, DNSCluster,
    query: System.get_env("DNS_CLUSTER_QUERY")
  ```

  ### Health Checks

  Could add health check endpoint:
  - Check database connectivity
  - Check external service dependencies
  - Return 200/503 status
  - Used by load balancers, Kubernetes

  ```elixir
  defmodule Blog.HealthCheck do
    def check do
      case Blog.Repo.query("SELECT 1") do
        {:ok, _} -> :ok
        {:error, _} -> :error
      end
    end
  end
  ```

  ### Metrics and Observability

  Current: BasicMetrics via Telemetry
  Future:
  - Export to Prometheus
  - Dashboards with Grafana
  - Distributed tracing (e.g., Jaeger)
  - Log aggregation (e.g., CloudWatch, ELK)
  - Alert rules on key metrics

  ## Troubleshooting

  Common issues:

  1. **Repo not starting**: DATABASE_URL not set
  2. **Endpoint not starting**: Port 4000 in use
  3. **PubSub errors**: Node name mismatch (distributed)
  4. **Metrics not working**: Telemetry handler registration failed

  Check logs for startup order and errors.

  ## Testing

  Tests inherit the same application:
  - Tests run in same BEAM VM
  - Supervision tree available in test
  - Can start/stop services individually for tests
  - See test_helper.exs for test setup
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BlogWeb.Telemetry,
      Blog.Repo,
      {DNSCluster, query: Application.get_env(:blog, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Blog.PubSub},
      # Start a worker by calling: Blog.Worker.start_link(arg)
      # {Blog.Worker, arg},
      # Start to serve requests, typically the last entry
      BlogWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
