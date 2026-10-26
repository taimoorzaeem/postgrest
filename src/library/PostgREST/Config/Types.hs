-- |
-- Module      : PostgREST.Config.Types
-- Description : PostgREST Configuration Types.
module PostgREST.Config.Types
  ( AppConfig (..)
  , LogLevel (..)
  , OpenAPIMode (..)
  , Verbosity (..)
  , TxEnd (..)
  , defaultPgrstConfig
  )
where

import Jose.Jwk (JwkSet)
import Protolude hiding (Proxy, toList)
import System.Posix.Types (FileMode)

import Data.ByteString qualified as BS
import Data.CaseInsensitive qualified as CI

import PostgREST.Catalog.Identifiers (QualifiedIdentifier (..))
import PostgREST.Config.Database (RoleIsolationLvl, RoleSettings)
import PostgREST.Config.JSPath (JSPath (..), defaultRoleJSPathKey)

data AppConfig = AppConfig
  { configAppSettings :: PgrstConfig [(Text, Text)],
    configClientErrorVerbosity :: PgrstConfig Verbosity,
    configDbAggregates :: PgrstConfig Bool,
    configDbAnonRole :: PgrstConfig (Maybe BS.ByteString),
    configDbChannel :: PgrstConfig Text,
    configDbChannelEnabled :: PgrstConfig Bool,
    configDbExtraSearchPath :: PgrstConfig [Text],
    configDbHoistedTxSettings :: PgrstConfig [Text],
    configDbMaxRows :: PgrstConfig (Maybe Integer),
    configDbPlanEnabled :: PgrstConfig Bool,
    configDbPoolSize :: PgrstConfig Int,
    configDbPoolAcquisitionTimeout :: PgrstConfig Int,
    configDbPoolMaxLifetime :: PgrstConfig Int,
    configDbPoolMaxIdletime :: PgrstConfig Int,
    configDbPoolAutomaticRecovery :: PgrstConfig Bool,
    configDbPreRequest :: PgrstConfig (Maybe QualifiedIdentifier),
    configDbPreparedStatements :: PgrstConfig Bool,
    configDbRootSpec :: PgrstConfig (Maybe QualifiedIdentifier),
    configDbSchemas :: PgrstConfig (NonEmpty Text),
    configDbConfig :: PgrstConfig Bool,
    configDbPreConfig :: PgrstConfig (Maybe QualifiedIdentifier),
    configDbTxAllowOverride :: PgrstConfig Bool,
    configDbTxRollbackAll :: PgrstConfig Bool,
    configDbUri :: PgrstConfig Text,
    configFilePath :: Maybe FilePath,
    configJWKS :: Maybe JwkSet,
    configJwtAudience :: PgrstConfig (Maybe Text),
    configJwtRoleClaimKey :: PgrstConfig JSPath,
    configJwtSecret :: PgrstConfig (Maybe BS.ByteString),
    configJwtSecretIsBase64 :: PgrstConfig Bool,
    configJwtCacheMaxEntries :: PgrstConfig Int,
    configLogLevel :: PgrstConfig LogLevel,
    configLogQuery :: PgrstConfig Bool,
    configOpenApiMode :: PgrstConfig OpenAPIMode,
    configOpenApiSecurityActive :: PgrstConfig Bool,
    configOpenApiServerProxyUri :: PgrstConfig (Maybe Text),
    configServerCorsAllowedOrigins :: PgrstConfig [Text],
    configServerHost :: PgrstConfig Text,
    configServerPort :: PgrstConfig Int,
    configServerReusePort :: PgrstConfig Bool,
    configServerTraceHeader :: PgrstConfig (Maybe (CI.CI BS.ByteString)),
    configServerTimingEnabled :: PgrstConfig Bool,
    configServerUnixSocket :: PgrstConfig (Maybe FilePath),
    configServerUnixSocketMode :: PgrstConfig FileMode,
    configUrlUseLegacyTargetNames :: PgrstConfig Bool,
    configAdminServerHost :: PgrstConfig Text,
    configAdminServerPort :: PgrstConfig (Maybe Int),
    configAdminServerUnixSocket :: PgrstConfig (Maybe FilePath),
    configAdminServerUnixSocketMode :: PgrstConfig FileMode,
    configRoleSettings :: RoleSettings,
    configRoleIsoLvl :: RoleIsolationLvl,
    configInternalSCQuerySleepFst :: PgrstConfig (Maybe Int32),
    configInternalSCQuerySleepSnd :: PgrstConfig (Maybe Int32)
  }

data PgrstConfig a = PgrstConfig
  { pcFileName :: Text,
    pcFileNameAlias :: Maybe Text,
    pcEnvName :: Text,
    pcDbName :: Maybe Text,
    pcValue :: a
  }

-- | Default PostgREST Config which gets overridden during parse time
defaultPgrstConfig :: AppConfig
defaultPgrstConfig = AppConfig
  { configAppSettings = PgrstConfig {
      pcFileName = "app.settings",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_APP_SETTINGS",
      pcDbName = Nothing,
      pcValue = []
    },
    configClientErrorVerbosity = PgrstConfig {
      pcFileName = "client-error-verbosity",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_CLIENT_ERROR_VERBOSITY",
      pcDbName = Just "pgrst.client_error_verbosity",
      pcValue = Verbose
    },
    configDbAggregates = PgrstConfig {
      pcFileName = "db-aggregates-enabled",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_AGGREGATES_ENABLED",
      pcDbName = Just "pgrst.db_aggregates_enabled",
      pcValue = False
    },
    configDbAnonRole = PgrstConfig {
      pcFileName = "db-anon-role",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_AGGREGATES_ENABLED",
      pcDbName = Just "pgrst.db_anon_role",
      pcValue = Nothing
    },
    configDbChannel = PgrstConfig {
      pcFileName = "db-channel",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_CHANNEL",
      pcDbName = Just "db_channel",
      pcValue = "pgrst"
    },
    configDbChannelEnabled = PgrstConfig {
      pcFileName = "db-channel-enabled",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_CHANNEL_ENABLED",
      pcDbName = Just "db_channel_enabled",
      pcValue = True
    },
    configDbExtraSearchPath = PgrstConfig {
      pcFileName = "db-extra-search-path",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_EXTRA_SEARCH_PATH",
      pcDbName = Just "pgrst.db_extra_search_path",
      pcValue = ["public"]
    },
    configDbHoistedTxSettings = PgrstConfig {
      pcFileName = "db-hoisted-tx-settings",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_HOISTED_TX_SETTINGS",
      pcDbName = Just "pgrst.db_hoisted_tx_settings",
      pcValue = ["default_transaction_isolation", "plan_filter.statement_cost_limit", "statement_timeout"]
    },
    configDbMaxRows = PgrstConfig {
      pcFileName = "db-max-rows",
      pcFileNameAlias = Just "max-rows",
      pcEnvName = "PGRST_DB_MAX_ROWS",
      pcDbName = Just "pgrst.db_max_rows",
      pcValue = Nothing
    },
    configDbPlanEnabled = PgrstConfig {
      pcFileName = "db-plan-enabled",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_PLAN_ENABLED",
      pcDbName = Just "pgrst.db_plan_enabled",
      pcValue = False
    },
    configDbPoolSize = PgrstConfig {
      pcFileName = "db-pool",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_POOL",
      pcDbName = Nothing,
      pcValue = 10
    },
    configDbPoolAcquisitionTimeout = PgrstConfig {
      pcFileName = "db-pool-acquisition-timeout",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_POOL_ACQUISITION_TIMEOUT",
      pcDbName = Nothing,
      pcValue = 10
    },
    configDbPoolMaxLifetime = PgrstConfig {
      pcFileName = "db-pool-max-lifetime",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_POOL_MAX_LIFETIME",
      pcDbName = Nothing,
      pcValue = 1800
    },
    configDbPoolMaxIdletime = PgrstConfig {
      pcFileName = "db-pool-max-idletime",
      pcFileNameAlias = Just "db-pool-timeout",
      pcEnvName = "PGRST_DB_POOL_MAX_IDLETIME",
      pcDbName = Nothing,
      pcValue = 30
    },
    configDbPoolAutomaticRecovery = PgrstConfig {
      pcFileName = "db-pool-automatic-recovery",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_POOL_AUTOMATIC_RECOVERY",
      pcDbName = Nothing,
      pcValue = True
    },
    configDbPreRequest = PgrstConfig {
      pcFileName = "db-pre-request",
      pcFileNameAlias = Just "pre-request",
      pcEnvName = "PGRST_DB_PRE_REQUEST",
      pcDbName = Just "pgrst.db_pre_request",
      pcValue = Nothing
    },
    configDbPreparedStatements = PgrstConfig {
      pcFileName = "db-prepared-statements",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_PREPARED_STATEMENTS",
      pcDbName = Just "pgrst.db_prepared_statments",
      pcValue = True
    },
    configDbRootSpec = PgrstConfig {
      pcFileName = "db-root-spec",
      pcFileNameAlias = Just "root-spec",
      pcEnvName = "PGRST_DB_ROOT_SPEC",
      pcDbName = Just "pgrst.db_root_spec",
      pcValue = Nothing
    },
    configDbSchemas = PgrstConfig {
      pcFileName = "db-schemas",
      pcFileNameAlias = Just "db-schema",
      pcEnvName = "PGRST_DB_SCHEMAS",
      pcDbName = Just "pgrst.db_schemas",
      pcValue = "public"
    },
    configDbConfig = PgrstConfig {
      pcFileName = "db-config",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_CONFIG",
      pcDbName = Nothing,
      pcValue = True
    },
    configDbPreConfig = PgrstConfig {
      pcFileName = "db-pre-config",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_PRE_CONFIG",
      pcDbName = Just "pgrst.db_pre_config",
      pcValue = Nothing
    },
    configDbTxEnd = PgrstConfig {
      pcFileName = "db-tx-end",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_TX_END",
      pcDbName = Just "pgrst.db_tx_end",
      pcValue = TxCommit
    },
    configDbUri = PgrstConfig {
      pcFileName = "db-uri",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_DB_URI",
      pcDbName = Nothing,
      pcValue = "postgresql://"
    },
    configFilePath = Nothing,
    configJWKS = Nothing,
    configJwtAudience = PgrstConfig {
      pcFileName = "jwt-aud",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_JWT_AUD",
      pcDbName = Just "pgrst.jwt_aud",
      pcValue = Nothing
    },
    configJwtRoleClaimKey = PgrstConfig {
      pcFileName = "jwt-role-claim-key",
      pcFileNameAlias = Just "role-claim-key",
      pcEnvName = "PGRST_JWT_ROLE_CLAIM_KEY",
      pcDbName = Just "pgrst.jwt_role_claim_key",
      pcValue = defaultRoleJSPathKey
    },
    configJwtSecret = PgrstConfig {
      pcFileName = "jwt-secret",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_JWT_SECRET",
      pcDbName = Just "pgrst.jwt_secret",
      pcValue = Nothing
    },
    configJwtSecretIsBase64 = PgrstConfig {
      pcFileName = "jwt-secret-is-base64",
      pcFileNameAlias = Just "secret-is-base64",
      pcEnvName = "PGRST_JWT_SECRET_IS_BASE64",
      pcDbName = Just "pgrst.jwt_secret_is_base64",
      pcValue = False
    },
    configJwtCacheMaxEntries = PgrstConfig {
      pcFileName = "jwt-cache-max-entries",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_JWT_CACHE_MAX_ENTRIES",
      pcDbName = Just "pgrst.jwt_cache_max_entries",
      pcValue = 1000
    },
    configLogLevel = PgrstConfig {
      pcFileName = "log-level",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_LOG_LEVEL",
      pcDbName = Nothing,
      pcValue = LogError
    },
    configLogQuery = PgrstConfig {
      pcFileName = "log-query",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_LOG_QUERY",
      pcDbName = Nothing,
      pcValue = False
    },
    configOpenApiMode = PgrstConfig {
      pcFileName = "openapi-mode",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_OPENAPI_MODE",
      pcDbName = Just "pgrst.openapi_mode",
      pcValue = OAFollowPriv
    },
    configOpenApiSecurityActive = PgrstConfig {
      pcFileName = "openapi-security-active",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_OPENAPI_SECURITY_ACTIVE",
      pcDbName = Just "pgrst.openapi_security_active",
      pcValue = False
    },
    configOpenApiServerProxyUri = PgrstConfig {
      pcFileName = "openapi-server-proxy-uri",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_OPENAPI_SERVER_PROXY_URI",
      pcDbName = Just "pgrst.openapi_server_proxy_uri",
      pcValue = Nothing
    },
    configServerCorsAllowedOrigins = PgrstConfig {
      pcFileName = "server-cors-allowed-origins",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_CORS_ALLOWED_ORIGINS",
      pcDbName = Just "pgrst.server_cors_allowed_origins",
      pcValue = []
    },
    configServerHost = PgrstConfig {
      pcFileName = "server-host",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_HOST",
      pcDbName = Nothing,
      pcValue = "!4"
    },
    configServerPort = PgrstConfig {
      pcFileName = "server-port",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_PORT",
      pcDbName = Nothing,
      pcValue = 3000
    },
    configServerReusePort = PgrstConfig {
      pcFileName = "server-reuseport",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_REUSEPORT",
      pcDbName = Nothing,
      pcValue = False
    },
    configServerTraceHeader = PgrstConfig {
      pcFileName = "server-trace-header",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_TRACE_HEADER",
      pcDbName = Just "pgrst.server_trace_header",
      pcValue = Nothing
    },
    configServerTimingEnabled = PgrstConfig {
      pcFileName = "server-timing-enabled",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_TIMING_ENABLED",
      pcDbName = Just "pgrst.server_timing_enabled",
      pcValue = False
    },
    configServerUnixSocket = PgrstConfig {
      pcFileName = "server-unix-socket",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_UNIX_SOCKET",
      pcDbName = Nothing,
      pcValue = Nothing
    },
    configServerUnixSocketMode = PgrstConfig {
      pcFileName = "server-unix-socket-mode",
      pcFileNameAlias = Nothing,
      pcEnvName = "PGRST_SERVER_UNIX_SOCKET_MODE",
      pcDbName = Nothing,
      pcValue = 0o660
    },
    configUrlUseLegacyTargetNames = PgrstConfig Bool,
    configAdminServerHost = PgrstConfig Text,
    configAdminServerPort = PgrstConfig (Maybe Int),
    configAdminServerUnixSocket = PgrstConfig (Maybe FilePath),
    configAdminServerUnixSocketMode = PgrstConfig FileMode,
    configRoleSettings = mempty,
    configRoleIsoLvl = mempty,
    configInternalSCQuerySleepFst = PgrstConfig (Maybe Int32),
    configInternalSCQuerySleepSnd = PgrstConfig (Maybe Int32)
  }
  }

data LogLevel = LogCrit | LogError | LogWarn | LogInfo | LogDebug
  deriving (Eq, Ord)

data Verbosity
  = Minimal
  | Verbose

data OpenAPIMode = OAFollowPriv | OAIgnorePriv | OADisabled
  deriving (Eq)

data TxEnd
  = TxCommit
  | TxCommitAllowOverride
  | TxRollback
  | TxRollbackAllowOverride
  deriving Eq
