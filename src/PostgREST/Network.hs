module PostgREST.Network
  ( resolveAddress
  ) where

import           Data.String    (IsString (..))
import qualified Network.Socket as NS

import Protolude

-- | Resolves the socket to an address depending on the socket type. The Show
--   instance of the socket types automatically resolves it to the correct
--   address. Example resolution:
-- -----------------------------------------------------
-- | IPv4         | IPv6             | Unix            |
-- -----------------------------------------------------
-- | 127.0.0.1:80 | [2001:db8::1]:80 | /tmp/pgrst.sock |
-- -----------------------------------------------------
--
-- TODO: Add Doctests.
resolveAddress :: NS.Socket -> IO Text
resolveAddress sock = do
  sn <- NS.getSocketName sock
  return $ fromString $ show sn
