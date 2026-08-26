defmodule CaramelKitchenWeb.Plugs.RateLimitTest do
  use CaramelKitchenWeb.ConnCase, async: false

  alias CaramelKitchenWeb.Plugs.RateLimit

  setup do
    # Clear Hammer buckets for a clean state
    # We can't easily clear everything, but we can use a random bucket name
    bucket = "test_api_#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> put_req_header("x-forwarded-for", "192.168.1.#{System.unique_integer([:positive])}")

    {:ok, conn: conn, bucket: bucket}
  end

  test "allows requests under the limit", %{conn: conn, bucket: bucket} do
    opts = RateLimit.init(scale: 60_000, limit: 2, bucket: bucket)

    # First request
    conn1 = RateLimit.call(conn, opts)
    assert conn1.status != 429
    assert !conn1.halted

    # Second request
    conn2 = RateLimit.call(conn, opts)
    assert conn2.status != 429
    assert !conn2.halted
  end

  test "halts and returns 429 when limit is exceeded", %{conn: conn, bucket: bucket} do
    opts = RateLimit.init(scale: 60_000, limit: 2, bucket: bucket)

    # Use up the limit
    RateLimit.call(conn, opts)
    RateLimit.call(conn, opts)

    # Third request should be blocked
    blocked_conn = RateLimit.call(conn, opts)

    assert blocked_conn.status == 429
    assert blocked_conn.halted

    assert blocked_conn.resp_body =~ "rate_limit_exceeded"
    assert get_resp_header(blocked_conn, "x-ratelimit-limit") == ["2"]
    assert get_resp_header(blocked_conn, "retry-after") == ["60"]
  end

  test "uses user_id for authenticated requests", %{bucket: bucket} do
    user = insert(:user)

    conn =
      build_conn()
      |> assign(:current_user, user)

    conn = %{conn | remote_ip: {10, 0, 0, 1}}

    opts = RateLimit.init(scale: 60_000, limit: 1, bucket: bucket)

    # Use up the limit for user
    RateLimit.call(conn, opts)

    # Next request for the SAME user should be blocked
    blocked_conn = RateLimit.call(conn, opts)
    assert blocked_conn.status == 429

    # Request from DIFFERENT user with the same IP should NOT be blocked
    other_user = insert(:user)

    conn_other =
      build_conn()
      |> assign(:current_user, other_user)

    conn_other = %{conn_other | remote_ip: {10, 0, 0, 1}}

    allowed_conn = RateLimit.call(conn_other, opts)
    assert allowed_conn.status != 429
  end
end
