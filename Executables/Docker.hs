module Main where

import           ConfigV
import qualified GHC.IO.Encoding       as G
import           System.IO
import           System.Exit

main = do
  G.setLocaleEncoding utf8
  G.setFileSystemEncoding utf8
  G.setForeignEncoding utf8  
 
  executeLearning settings (Left csvThresholds)
  actualResults   <- readFile cachedRulesDefaultLoc
  return ()
--  putStrLn actualResults

settings = learnConfig {
        learnTarget = "Datasets/docker-configv/"
      , enableSMT = True
      , enableOrder = True
      , verbose = True
      }

csvThresholds = defaultThresholds {
        smtSupport = 12
      , smtConfidence = 1
      , orderSupport = 12
      , orderConfidence = 1 
      }


