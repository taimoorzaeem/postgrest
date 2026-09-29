"Test PostgREST logs and observations"

import re
import signal
import time
import pytest
import requests

from config import SECRET
from util import (
    jwtauthheader,
    relativeSeconds,
)
from postgrest import (
    Admin,
    freeport,
    reset_statement_timeout,
    run,
    set_statement_timeout,
    wait_until_exit,
)


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_log_level(level, defaultenv, snapshot_log):
    "log_level should filter request logging"

    env = {**defaultenv, "PGRST_LOG_LEVEL": level}

    # any token to test 500 response for "Server lacks JWT secret"
    claim = {"role": "postgrest_test_author"}
    headers = jwtauthheader(claim, SECRET)

    with run(env=env, no_startup_stdout=False, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/", headers=headers)
        assert response.status_code == 500

        response = postgrest.session.get("/unknown")
        assert response.status_code == 404

        response = postgrest.session.get("/")
        assert response.status_code == 200

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_log_query(level, defaultenv, snapshot_log):
    "log_query=true should log the SQL query according to the log_level"

    env = {
        **defaultenv,
        "PGRST_LOG_LEVEL": level,
        "PGRST_LOG_QUERY": "true",
    }

    with run(env=env, no_startup_stdout=False, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/")
        assert response.status_code == 200

        response = postgrest.session.get("/projects")
        assert response.status_code == 200

        response = postgrest.session.get(
            "/projects", headers={"Prefer": "count=estimated"}
        )
        assert response.status_code == 200

        response = postgrest.session.get(
            "/projects", headers={"Prefer": "count=planned"}
        )
        assert response.status_code == 200

        response = postgrest.session.get("/infinite_recursion")
        assert response.status_code == 500

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_log_query_with_db_pre_request(level, defaultenv, snapshot_log):

    pre_req_env = {
        **defaultenv,
        "PGRST_LOG_LEVEL": level,
        "PGRST_LOG_QUERY": "true",
        "PGRST_DB_PRE_REQUEST": "do_nothing",
    }

    with run(env=pre_req_env, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/projects")
        assert response.status_code == 200

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
@pytest.mark.parametrize("log_query", ["false", "true"])
def test_schema_cache_log_query(level, log_query, defaultenv, snapshot_log):
    "Schema cache SQL queries follow log-query and log-level"
    env = {
        **defaultenv,
        "PGRST_LOG_LEVEL": level,
        "PGRST_LOG_QUERY": log_query,
    }

    with run(
        env=env, no_startup_stdout=False, wait_for=None, use_libfaketime=True
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_log_lacks_role_with_empty_anon_role(defaultenv, snapshot_log):
    "Requests are logged without a role when db-anon-role is empty."

    env = {
        **defaultenv,
        "PGRST_DB_CONFIG": "false",
        "PGRST_DB_ANON_ROLE": "",
    }

    with run(env=env, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/projects")
        assert response.status_code == 401

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_log_postgrest_version(defaultenv, snapshot_log):
    "Should show the PostgREST version in the logs"
    with run(
        env=defaultenv, no_startup_stdout=False, use_libfaketime=True
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize(
    "host", ["127.0.0.1", "::1", None], ids=["IPv4", "IPv6", "Unix"]
)
def test_log_postgrest_host_and_port(host, defaultenv, snapshot_log):
    "PostgREST should output the host and port it is bound to."

    # We run postgrest on unix socket when host and port are set to None
    is_unix = host is None
    port = None if is_unix else freeport()

    with run(
        env=defaultenv,
        host=host,
        port=port,
        no_startup_stdout=False,
        use_libfaketime=True,
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize(
    "host", ["127.0.0.1", "::1", None], ids=["IPv4", "IPv6", "Unix"]
)
def test_log_postgrest_admin_server_host_and_port(host, defaultenv, snapshot_log):
    "PostgREST should log the admin server host and port"

    # We run admin server on unix socket when host and admin_port are set to None
    is_unix = host is None
    port = None if is_unix else freeport()
    admin_port = None if is_unix else freeport(used_ports=[port])

    with run(
        env=defaultenv,
        host=host,
        port=port,
        admin_port=admin_port,
        no_startup_stdout=False,
        wait_for=Admin.ready,
        use_libfaketime=True,
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_log_error_when_schema_cache_load_error_on_startup_to_stderr(
    defaultenv, snapshot_log
):
    "Should log the 503 error message when there is an error loading schema cache on startup"

    env = {
        **defaultenv,
        "PGRST_INTERNAL_SCHEMA_CACHE_QUERY_SLEEP_BEFORE_QUERIES": "1000",
        "PGRST_DB_SCHEMAS": "non_existent_schema_aaaa",
    }

    with run(env=env, wait_for=None, use_libfaketime=True) as postgrest:
        postgrest.wait_until_scache_starts_loading()

        # First call should fail with connection refused
        with pytest.raises(requests.ConnectionError):
            postgrest.session.get("/projects")

        # Next call should return 503
        time.sleep(1)
        response = postgrest.session.get("/projects")
        assert response.status_code == 503

        output_start = postgrest.read_stdout_raw()
        assert output_start == snapshot_log


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_log_pool_req_observation(level, defaultenv, snapshot_log):
    "PostgREST should log PoolRequest and PoolRequestFullfilled observation when log-level=debug"

    env = {**defaultenv, "PGRST_LOG_LEVEL": level, "PGRST_JWT_SECRET": SECRET}

    headers = jwtauthheader({"role": "postgrest_test_author"}, SECRET)

    with run(env=env, use_libfaketime=True) as postgrest:

        postgrest.session.get("/authors_only", headers=headers)
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_log_listener_connection_errors(defaultenv, snapshot_log):
    "The logs should show the listener connection error message in a single line"

    env = {
        **defaultenv,
        "PGHOST": "no_host",
        "PGRST_DB_CHANNEL_ENABLED": "true",
    }

    with run(
        env=env, no_startup_stdout=False, wait_for=None, use_libfaketime=True
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_log_listener_connection_start(defaultenv, snapshot_log):
    "The logs should show the listener connection start message in a single line"

    env = {
        **defaultenv,
        "PGRST_DB_CHANNEL_ENABLED": "true",
    }

    with run(
        env=env, no_startup_stdout=False, wait_for=Admin.ready, use_libfaketime=True
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_db_error_logging_to_stderr(level, defaultenv, metapostgrest, snapshot_log):
    "verify that DB errors are logged to stderr"

    role = "timeout_authenticator"
    set_statement_timeout(metapostgrest, role, 500)

    env = {
        **defaultenv,
        "PGUSER": role,
        "PGRST_DB_ANON_ROLE": role,
        "PGRST_LOG_LEVEL": level,
    }

    with run(env=env, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/rpc/sleep?seconds=1")
        assert response.status_code == 500

        # ensure the message appears on the logs
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log

    reset_statement_timeout(metapostgrest, role)


def test_schema_cache_query_sleep_logs(defaultenv):
    """Schema cache sleep should be reflected in the logged query duration."""

    env = {
        **defaultenv,
        "PGRST_INTERNAL_SCHEMA_CACHE_QUERY_SLEEP": "1000",
    }
    log_pattern = re.compile(r"Schema cache queried in ([\d.]+) milliseconds")

    with run(env=env, wait_max_seconds=3, no_startup_stdout=False) as postgrest:
        observed_ms = None
        collected = []

        lines = postgrest.read_stdout(nlines=10)
        collected.extend(lines)
        for line in lines:
            match = log_pattern.search(line)
            if match:
                observed_ms = float(match.group(1))
                break

        assert observed_ms is not None
        assert 1000 < observed_ms < 2000


@pytest.mark.parametrize("level", ["crit", "error", "warn", "info", "debug"])
def test_schema_cache_query_timings_log(level, defaultenv, snapshot_log):
    "Schema cache query timings should be logged on log-level=debug."

    env = {
        **defaultenv,
        "PGRST_LOG_LEVEL": level,
    }

    with run(env=env, no_startup_stdout=False, use_libfaketime=True) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_empty_schema_cache_log_contains_jwt_role(defaultenv, snapshot_log):
    "Requests are logged with the role when the schema cache is empty on startup"

    env = {
        **defaultenv,
        "PGRST_DB_SCHEMAS": "non_existent_schema_aaaa",
        "PGRST_JWT_SECRET": SECRET,
    }
    headers = jwtauthheader({"role": "postgrest_test_author"}, SECRET)

    with run(env=env, wait_for=None, use_libfaketime=True) as postgrest:
        postgrest.wait_until_scache_starts_loading()

        response = postgrest.session.get("/authors_only", headers=headers)
        assert response.status_code == 503

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_expired_jwt_log_lacks_role(defaultenv, snapshot_log):
    "Expired JWT requests are logged without a role."

    env = {**defaultenv, "PGRST_JWT_SECRET": SECRET}
    headers = jwtauthheader({"exp": relativeSeconds(-35)}, SECRET)

    with run(env=env, use_libfaketime=True) as postgrest:
        response = postgrest.session.get("/authors_only", headers=headers)
        assert response.status_code == 401

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_schema_cache_error_observation(defaultenv, snapshot_log):
    "schema cache error observation should be logged with invalid db-schemas or db-extra-search-path"

    env = {
        **defaultenv,
        "PGRST_DB_EXTRA_SEARCH_PATH": "x",
    }

    with run(
        env=env, no_startup_stdout=False, wait_for=None, use_libfaketime=True
    ) as postgrest:
        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_invalid_rpc_method_log_contains_role(defaultenv, snapshot_log):
    "Invalid RPC method requests are logged with the anonymous role."

    with run(env=defaultenv, use_libfaketime=True) as postgrest:
        response = postgrest.session.put("/rpc/sleep")
        assert response.status_code == 405

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log


def test_pgrst_log_503_client_error_to_stderr(defaultenv, snapshot_log):
    "PostgREST should log 503 errors to stderr"

    env = {
        **defaultenv,
        "PGAPPNAME": "test-io",
    }

    with run(env=env, no_startup_stdout=False, use_libfaketime=True) as postgrest:

        postgrest.session.get("/rpc/terminate_pgrst?appname=test-io")

        output = postgrest.read_stdout_raw()

        assert output == snapshot_log


def test_termination_unix_signal_logging(defaultenv, snapshot_log):
    "Server logs when handling termination unix signals."

    with run(
        env=defaultenv, no_startup_stdout=False, use_libfaketime=True
    ) as postgrest:
        postgrest.process.send_signal(signal.SIGTERM)
        lines = postgrest.read_stdout_raw()
        wait_until_exit(postgrest)

        assert lines == snapshot_log


def test_options_request_logs_but_cors_preflight_does_not(defaultenv, snapshot_log):
    "Plain OPTIONS requests should be logged, but CORS preflight requests should not."

    env = {
        **defaultenv,
        "PGRST_LOG_LEVEL": "info",
        "PGRST_SERVER_CORS_ALLOWED_ORIGINS": "http://example.com",
    }
    preflight_headers = {
        "Origin": "http://example.com",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "Content-Type",
    }

    with run(env=env, use_libfaketime=True) as postgrest:
        response = postgrest.session.options("/projects")
        assert response.status_code == 200

        response = postgrest.session.options("/projects", headers=preflight_headers)
        assert response.status_code == 200
        assert response.headers["Access-Control-Allow-Origin"] == "http://example.com"

        output = postgrest.read_stdout_raw()
        assert output == snapshot_log
