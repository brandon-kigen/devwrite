defmodule BlogWeb.Telemetry do
  @moduledoc """
  Application metrics and telemetry collection.

  Collects data on:
  - HTTP request metrics (latency, throughput)
  - Database query metrics (query time, queue time, decode time)
  - Erlang VM metrics (memory, process queues)

  Data can be exported to:
  - Console (development)
  - Prometheus (monitoring)
  - Datadog, New Relic, etc. (via reporters)

  ## Architecture

  1. **Telemetry Events** emitted by:
     - Phoenix (request start/stop)
     - Ecto (query execution)
     - VM (periodic measurements)

  2. **Metrics** (this module) aggregate events into:
     - Summary (min, max, mean, etc.)
     - Counter (increments)
     - Gauge (current value)
     - Distribution (percentiles)

  3. **Reporters** (configured separately) export metrics:
     - Telemetry.Metrics.ConsoleReporter (to stdout)
     - Prometheus exporter (for scraping)
     - Custom reporters for external services

  ## Phoenix Metrics

  ### Endpoint Metrics
  - `phoenix.endpoint.start.system_time` — Request starts
  - `phoenix.endpoint.stop.duration` — Request duration
  - Unit: milliseconds
  - Used for: Overall request latency

  ### Router Metrics
  - `phoenix.router_dispatch.start.system_time` — Route match time
  - `phoenix.router_dispatch.stop.duration` — Handler execution time
  - Tags: `:route` (which route handler)
  - Unit: milliseconds
  - Used for: Which routes are slow

  ### Socket Metrics (LiveView)
  - `phoenix.socket_connected.duration` — WebSocket connection time
  - `phoenix.socket_drain.count` — Messages batched per send
  - Unit: milliseconds
  - Used for: LiveView connection performance

  ### Channel Metrics
  - `phoenix.channel_joined.duration` — Channel join time
  - `phoenix.channel_handled_in.duration` — Message handling time
  - Tags: `:event` (which event type)
  - Unit: milliseconds
  - Used for: Real-time message latency

  ## Database Metrics

  Collected from Ecto queries:

  - **query_time** — Time executing query on database
    - Measures: SQL execution only
    - Not affected by: Network, decoding

  - **queue_time** — Time waiting for connection from pool
    - High = Pool exhausted (too few connections)
    - Fix: Increase pool_size in config

  - **decode_time** — Time parsing database response
    - High = Large result sets
    - Fix: Return fewer columns, use pagination

  - **idle_time** — Time connection idle before query
    - High = Good (means pool is healthy)
    - Low = Pool pressure

  - **total_time** — Sum of all above
    - Overall query latency

  All measured in milliseconds.

  ## VM Metrics

  Erlang/OTP runtime metrics:

  - **vm.memory.total** — Total memory used
    - Unit: kilobytes
    - Increasing = Possible memory leak
    - Monitor for: Gradual growth

  - **vm.total_run_queue_lengths.cpu** — Processes waiting for CPU
    - High = CPU saturated
    - Fix: Horizontal scaling

  - **vm.total_run_queue_lengths.io** — Processes waiting for I/O
    - High = I/O bottleneck (DB, network)
    - Fix: Optimize queries, add caching

  - **vm.total_run_queue_lengths.total** — Sum of above
    - Overall VM queue depth

  ## Telemetry Events Emitted

  Not all events have metrics configured (yet):

  ```
  [:phoenix, :endpoint, :start]          — Request starts
  [:phoenix, :endpoint, :stop]           — Request ends
  [:phoenix, :router_dispatch, :start]   — Handler starts
  [:phoenix, :router_dispatch, :stop]    — Handler ends
  [:phoenix, :socket_connected]          — WebSocket connected
  [:blog, :repo, :query, :start]         — Query starts
  [:blog, :repo, :query, :stop]          — Query ends
  ```

  To add a metric:
  1. Identify the event name
  2. Add entry to `metrics()` function
  3. Specify aggregation (summary, count, etc.)
  4. Run app to collect data

  Example:
  ```elixir
  summary("phoenix.live_view.mount.duration",
    unit: {:native, :millisecond},
    tags: [:view]
  ),
  ```

  ## Periodic Measurements

  Currently: Empty

  Periodic measurements run every 10 seconds:
  ```elixir
  defp periodic_measurements do
    [
      {BlogWeb, :count_users, []},
      {Blog, :post_view_count, []}
    ]
  end
  ```

  Then define functions:
  ```elixir
  def count_users do
    :telemetry.execute(
      [:blog, :users, :total],
      %{count: Blog.Accounts.user_count()},
      %{}
    )
  end
  ```

  Use for: Custom application metrics (user count, post count, etc.)

  ## Using Metrics in Development

  ### Console Reporter
  Enable to see metrics printed to stdout:

  ```elixir
  # In config/dev.exs:
  config :telemetry_metrics, :reporters, [
    {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
  ]
  ```

  Then start app:
  ```
  iex -S mix phx.server
  ```

  Metrics printed every 10 seconds.

  ### Phoenix LiveDashboard
  Visit http://localhost:4000/dev/dashboard:
  - Requests — HTTP request metrics
  - Memory — VM memory usage
  - Processes — Running processes
  - Sockets — LiveView connections
  - Ports — Port listeners
  - Applications — Supervision tree
  - ETS — Table usage
  - Metrics — All metrics (if reporter enabled)

  ## Using Metrics in Production

  ### Prometheus Export
  Add dependency:
  ```
  {:telemetry_metrics_prometheus_core, "~> 0.4"}
  ```

  Configure reporter:
  ```elixir
  config :blog, BlogWeb.Telemetry,
    reporters: [TelemetryMetricsPrometheus]
  ```

  Metrics available at: GET /metrics (Prometheus format)

  ### Third-Party Services
  Datadog exporter:
  ```
  {:telemetry_metrics_datadog, "~> 0.4"}
  ```

  New Relic exporter:
  ```
  {:telemetry_metrics_new_relic, "~> 0.4"}
  ```

  Honeycomb exporter:
  ```
  {:telemetry_metrics_honeycomb, "~> 0.4"}
  ```

  ## Alerts and Monitoring

  Once metrics collected, set up alerts:
  - Request latency > 500ms — Slow requests
  - DB queue time > 100ms — Pool exhaustion
  - Memory growth > 1GB — Memory leak
  - CPU queue > 10 — CPU saturation
  - Error rate > 1% — Bug or incident

  Use: Prometheus alerting, monitoring dashboard, PagerDuty integration

  ## Performance Optimization Using Metrics

  1. **Identify slow endpoints**
     - Sort phoenix.router_dispatch.stop by duration
     - Focus on high-traffic slow routes

  2. **Identify slow queries**
     - Look at blog.repo.query.total_time
     - Check which tags have high times
     - Add indexes for slow queries

  3. **Identify connection pool pressure**
     - High blog.repo.query.queue_time = too few connections
     - Increase pool_size in config

  4. **Identify memory leaks**
     - Plot vm.memory.total over time
     - Should be stable; rising = leak
     - Use observer to find leak source

  5. **Identify CPU saturation**
     - High vm.total_run_queue_lengths.cpu = need more nodes
     - Horizontal scaling via load balancer

  ## Logging vs. Metrics

  Metrics are different from logs:

  | Aspect | Metrics | Logs |
  |--------|---------|------|
  | Volume | Summarized (one per 10s) | Every event |
  | Storage | Compact, queryable | Large, full-text |
  | Use | Trends, alerts | Debugging |
  | Example | "avg latency 45ms" | "Request took 85ms" |

  Both needed for complete observability.

  ## Custom Metrics

  To add application-specific metrics:

  1. Emit event when something happens:
  ```elixir
  # In Blog.Posts context:
  def create_post(attrs) do
    result = ...
    :telemetry.execute([:blog, :post, :created], %{count: 1}, %{})
    result
  end
  ```

  2. Add metric definition:
  ```elixir
  counter("blog.post.created"),
  ```

  3. Metrics available immediately in dashboard.

  Examples:
  - User registrations per minute
  - Posts created per hour
  - Comments per post
  - Like count distribution
  - Page views per post (if added to Post schema)
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("blog.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("blog.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("blog.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("blog.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("blog.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {BlogWeb, :count_users, []}
    ]
  end
end
