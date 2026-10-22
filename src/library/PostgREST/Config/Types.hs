-- |
-- Module      : PostgREST.Config.Types
-- Description : PostgREST Configuration Types.
module PostgREST.Config.Types
  ( AppConfig (..)
  , LogLevel (..)
  , OpenAPIMode (..)
  , Verbosity (..)
  )
where

import Jose.Jwk (JwkSet)
import Protolude hiding (Proxy, toList)
import System.Posix.Types (FileMode)

import Data.ByteString qualified as BS
import Data.CaseInsensitive qualified as CI

import PostgREST.Catalog.Identifiers (QualifiedIdentifier (..))
import PostgREST.Config.Database (RoleIsolationLvl, RoleSettings)
import PostgREST.Config.JSPath (JSPath (..))

data AppConfig = AppConfig
  { configAppSettings :: [(Text, Text)],
    configClientErrorVerbosity :: Verbosity,
    configDbAggregates :: Bool,
    configDbAnonRole :: Maybe BS.ByteString,
    configDbChannel :: Text,
    configDbChannelEnabled :: Bool,
    configDbExtraSearchPath :: [Text],
    configDbHoistedTxSettings :: [Text],
    configDbMaxRows :: Maybe Integer,
    configDbPlanEnabled :: Bool,
    configDbPoolSize :: Int,
    configDbPoolAcquisitionTimeout :: Int,
    configDbPoolMaxLifetime :: Int,
    configDbPoolMaxIdletime :: Int,
    configDbPoolAutomaticRecovery :: Bool,
    configDbPreRequest :: Maybe QualifiedIdentifier,
    configDbPreparedStatements :: Bool,
    configDbRootSpec :: Maybe QualifiedIdentifier,
    configDbSchemas :: NonEmpty Text,
    configDbConfig :: Bool,
    configDbPreConfig :: Maybe QualifiedIdentifier,
    configDbTxAllowOverride :: Bool,
    configDbTxRollbackAll :: Bool,
    configDbUri :: Text,
    configFilePath :: Maybe FilePath,
    configJWKS :: Maybe JwkSet,
    configJwtAudience :: Maybe Text,
    configJwtRoleClaimKey :: JSPath,
    configJwtSecret :: Maybe BS.ByteString,
    configJwtSecretIsBase64 :: Bool,
    configJwtCacheMaxEntries :: Int,
    configLogLevel :: LogLevel,
    configLogQuery :: Bool,
    configOpenApiMode :: OpenAPIMode,
    configOpenApiSecurityActive :: Bool,
    configOpenApiServerProxyUri :: Maybe Text,
    configServerCorsAllowedOrigins :: [Text],
    configServerHost :: Text,
    configServerPort :: Int,
    configServerReusePort :: Bool,
    configServerTraceHeader :: Maybe (CI.CI BS.ByteString),
    configServerTimingEnabled :: Bool,
    configServerUnixSocket :: Maybe FilePath,
    configServerUnixSocketMode :: FileMode,
    configUrlUseLegacyTargetNames :: Bool,
    configAdminServerHost :: Text,
    configAdminServerPort :: Maybe Int,
    configAdminServerUnixSocket :: Maybe FilePath,
    configAdminServerUnixSocketMode :: FileMode,
    configRoleSettings :: RoleSettings,
    configRoleIsoLvl :: RoleIsolationLvl,
    configInternalSCQuerySleepFst :: Maybe Int32,
    configInternalSCQuerySleepSnd :: Maybe Int32
  }

data LogLevel = LogCrit | LogError | LogWarn | LogInfo | LogDebug
  deriving (Eq, Ord)

data Verbosity
  = Minimal
  | Verbose

data OpenAPIMode = OAFollowPriv | OAIgnorePriv | OADisabled
  deriving (Eq)
