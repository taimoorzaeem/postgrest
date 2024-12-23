{-|
Module      : PostgREST.Sentry
Description : Send logs to Sentry using SentryService
-}
{-# LANGUAGE LambdaCase #-}
module PostgREST.Sentry
  ( init
  , logObsWithSentry
  )
  where

import qualified Data.Text              as T
import qualified System.Log.Raven       as Sentry
import qualified System.Log.Raven.Types as SentryType

import System.Log.Raven.Types                 (SentryService (..))
import System.Log.Raven.Transport.HttpConduit (sendRecord)

import PostgREST.Observation (Observation (..), observationMessage)

import Protolude

init :: Maybe Text -> IO SentryService
init (Just dsn) = Sentry.initRaven (T.unpack dsn) identity sendRecord Sentry.stderrFallback 
init Nothing    = Sentry.disabledRaven


-- currently, we only send critical and error logs to sentry
logObsWithSentry :: SentryService -> Observation -> IO ()
logObsWithSentry sentry = \case
  obs@(AdminStartObs _ _)           -> sentryLog sentry obs $ SentryType.Custom "Startup"
  obs@(AppStartObs _)               -> sentryLog sentry obs $ SentryType.Custom "Startup"
  obs@ExitDBNoRecoveryObs           -> sentryLog sentry obs SentryType.Fatal
  obs@(ExitDBFatalError _ _)        -> sentryLog sentry obs SentryType.Fatal
  obs@(SchemaCacheErrorObs _)       -> sentryLog sentry obs SentryType.Error
  obs@(DBListenFail _ _)            -> sentryLog sentry obs SentryType.Error
  obs@(ConfigReadErrorObs _)        -> sentryLog sentry obs SentryType.Error
  obs@(QueryRoleSettingsErrorObs _) -> sentryLog sentry obs SentryType.Error
  _                                 -> pure ()


sentryLog :: SentryService -> Observation -> SentryType.SentryLevel -> IO ()
sentryLog sentry obs lvl = Sentry.register sentry "postgrest.logger" lvl ("Sentry: " <> obsMsgToString obs) identity
    where
      obsMsgToString = T.unpack . observationMessage
