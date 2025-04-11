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

import Data.Maybe            (fromJust)
import Data.Time.Clock       (UTCTime, nominalDiffTimeToSeconds)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import GHC.Num               (integerFromInt)

import PostgREST.Auth.Types (AuthResult (..))
import PostgREST.Error      (Error (..))

import Protolude

newtype JwtCacheState = JwtCacheState
  { jwtCacheIORef :: I.IORef (C.LRU ByteString AuthResult)
  }

-- | Initialize JwtCacheState
init :: Int -> IO JwtCacheState
init configJwtCacheMaxEntries = do
  cache <-I.newIORef $  C.newLRU (Just $ integerFromInt configJwtCacheMaxEntries)
  return $ JwtCacheState cache

-- | Used to retrieve and insert JWT to JWT Cache
lookupJwtCache :: JwtCacheState -> ByteString -> Int -> IO (Either Error AuthResult) -> UTCTime -> IO (Either Error AuthResult)
lookupJwtCache JwtCacheState{jwtCacheIORef} token maxLifetime parseJwt utc = do
  -- get cache from IORef
  jwtCache <- I.readIORef jwtCacheIORef

  -- lookup key = token
  let (jwtCache', maybeVal) = C.lookup token jwtCache

  -- check cache value otherwise parse jwt
  authResult <- maybe parseJwt (pure . Right) maybeVal

  -- get updated authResult
  authResult' <- case (authResult, maybeVal) of

    (Right res, Nothing) -> do -- cache miss

        -- add expiry from max lifetime config to jwt claims
        let res' = addExpToClaims res maxLifetime utc
        -- insert new cache entry
            jwtCache'' = C.insert token res' jwtCache'
        -- update IORef
        I.writeIORef jwtCacheIORef jwtCache''

        return $ Right res'

    (parseJwt', Just res)        -> -- cache hit
        -- check exp claim of lookedup result
        if isExpClaimExpired res utc == True then do
            -- if expired, remove from cache
            let (jwtCache'',_) = C.delete token jwtCache'
            -- update IORef
            I.writeIORef jwtCacheIORef jwtCache''
            return parseJwt'
        else
            return $ Right res -- use the result

    _                            -> return authResult -- parsing failed, we fail later

  return authResult'

-- Add the exp claim to result by using maxLifetime
addExpToClaims :: AuthResult -> Int -> UTCTime -> AuthResult
addExpToClaims res maxLifetime utc =
  let 
    now = (floor . nominalDiffTimeToSeconds . utcTimeToPOSIXSeconds) utc :: Int
    newExp = now + maxLifetime
    authClaims' = KM.insert "exp" (JSON.Number $ Sci.scientific (integerFromInt newExp) 0) (authClaims res)
  in
    res{authClaims=authClaims'}

-- check if exp claim is expired when looked up from cache
isExpClaimExpired :: AuthResult -> UTCTime -> Bool
isExpClaimExpired res utc =
  let
    now = (floor . nominalDiffTimeToSeconds . utcTimeToPOSIXSeconds) utc :: Int
    -- we can use fromJust, because "exp" claim is inserted in all entries
    expireJSON = fromJust $ KM.lookup "exp" (authClaims res)
    sciToInt = fromMaybe 0 . Sci.toBoundedInteger
  in
    case expireJSON of
      JSON.Number expiredAt -> if (sciToInt expiredAt - now) > 0 then False else True
      _ -> True -- impossible case; we will always have "exp" as JSON.Number

