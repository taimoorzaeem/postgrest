{-|
Module      : PostgREST.Auth.JwtCache
Description : PostgREST Jwt Authentication Result Cache.

This module provides functions to deal with the JWT cache
-}
{-# LANGUAGE NamedFieldPuns #-}
module PostgREST.Auth.JwtCache
  ( init
  , JwtCacheState
  , lookupJwtCache
  ) where

import qualified Data.Aeson        as JSON
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Cache.LRU    as C
import qualified Data.IORef        as I
import qualified Data.Scientific   as Sci

import Data.Time.Clock       (UTCTime, nominalDiffTimeToSeconds)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import System.Clock          (TimeSpec (..))

import PostgREST.Auth.Types (AuthResult (..))
import PostgREST.Error      (Error (..))

import Protolude

newtype JwtCacheState = JwtCacheState
  { jwtCacheIORef :: I.IORef (C.LRU ByteString AuthResult)
  }

-- | Initialize JwtCacheState
init :: Int -> IO JwtCacheState
init configJwtCacheMaxEntries = do
  cache <- C.newLRU (Just configJwtCacheMaxEntries)
  return $ JwtCacheState <$> (I.newIORef cache)

-- | Used to retrieve and insert JWT to JWT Cache
lookupJwtCache :: JwtCacheState -> ByteString -> Int -> IO (Either Error AuthResult) -> UTCTime -> IO (Either Error AuthResult)
lookupJwtCache jwtCacheState token maxLifetime parseJwt utc = do
  -- get cache from IORef
  jwtCache <- I.readIORef (jwtCacheIORef jwtCacheState)

  -- lookup key = token
  (jwtCache', maybeVal) <- C.lookup token jwtCache

  -- check cache value otherwise parse jwt
  authResult <- maybe parseJwt (pure . Right) maybeVal

  -- get updated authResult
  authResult' <- case (authResult, maybeVal) of

    (Right res, Nothing) -> do -- cache miss

      -- add expiry from max lifetime config to jwt claims
      res' <- addExpiryToResultClaims res maxLifetime
      
      -- insert new cache entry
      jwtCache'' <- C.insert token res jwtCache'

      -- update IORef
      I.writeIORef jwtCacheIORef jwtCache''

      return (Right res')

    (_, Just res)        -> do -- cache hit
      
      -- check exp claim, if expired then we can't use it, so remove it from cache

  return authResult

-- Used to extract JWT exp claim and add to JWT Cache
getTimeSpec :: AuthResult -> Int -> UTCTime -> TimeSpec
getTimeSpec res maxLifetime utc = do
  let expireJSON = KM.lookup "exp" (authClaims res)
      utcToSecs = floor . nominalDiffTimeToSeconds . utcTimeToPOSIXSeconds
      sciToInt = fromMaybe 0 . Sci.toBoundedInteger
  case expireJSON of
    Just (JSON.Number seconds) -> TimeSpec (sciToInt seconds - utcToSecs utc) 0
    _                          -> TimeSpec (fromIntegral maxLifetime :: Int64) 0
