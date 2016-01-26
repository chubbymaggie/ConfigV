{-# LANGUAGE TupleSections #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings#-}

module IntRel where

import Types
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Data.List as L
import qualified Data.Map as M
import Data.Maybe

import Debug.Trace

-- I haven't found a nice package for SMTLIB format in haskell yet, its out there tho, im sure

instance Attribute IntRelRule where
  -- | this has the problem that order is important
  --   (foo,bar,==) is different than (bar,foo,==)
  learn ts =
    let
      ts' = pairs $ filter couldBeInt ts
      rules = foldl (\rs p -> rs ++ findeqRules p) [] ts'
    in
      rules

  check rs f = 
    let
     relevantRules = filter (hasRuleFor f) (rs)
     fRules = learn f 
     diff = relevantRules L.\\ fRules
    in
     if null diff then Nothing else Just ("ERROR on Int relations\n"++ (show diff))
  
  merge curr new = L.nub $ foldl removeConflicts [] $ L.union curr new


hasRuleFor :: [IRLine] -> IntRelRule -> Bool
hasRuleFor ls r = 
  let
    x = elem (l1 r) (map keyword ls) && elem (l2 r) (map keyword ls)
  in
    --trace (show x ++ "  "++ (show r)) x
    x

removeConflicts :: [IntRelRule] -> IntRelRule -> [IntRelRule]
removeConflicts rs r = 
  if isJust $ L.find (sameKeyRel r) rs then L.delete r rs else r:rs
-- | remove rules with mathcing keys, but diff formulas
sameKeyRel :: IntRelRule -> IntRelRule -> Bool
sameKeyRel r1 r2 = 
   id (
    (l1 r1) == (l1 r2) && (l2 r1) == (l2 r2) && (formula r1) /= (formula r2) 
   )

findeqRules :: (IRLine,IRLine) -> [IntRelRule]
findeqRules (l1,l2) = 
  let
    getI = read . T.unpack . value 
    i1 = getI l1 :: Int  
    i2 = getI l2 :: Int  
    makeR f = if f i1 i2 then [IntRelRule {formula = (f),l1=keyword l1, l2=keyword l2}] else []
  in
    makeR (==) ++ makeR (<=) ++ makeR (>=)

-- only for comparators! careful!
instance Eq (Int -> Int -> Bool) where
  (==) f1 f2 = 
    (f1 1 1) == (f2 1 1) &&
    (f1 0 1) == (f2 0 1) &&
    (f1 1 0) == (f2 1 0)

instance Eq IntRelRule where
  (==) r1 r2 = 
    (formula r1) == (formula r2) && 
    (l1 r1) == (l1 r2) &&
    (l2 r1) == (l2 r2)
 
couldBeInt :: IRLine -> Bool
couldBeInt IRLine{..} =
  (p $ cint configType ) == 1

pairs :: [IRLine]  -> [(IRLine, IRLine)]
pairs [] = []
pairs (l:ls) = filter (\(l1,l2) -> (keyword l1/=keyword l2)) $ map (l,) ls ++ pairs ls

traceMe s x = trace (s ++ (show $ filter (\r -> "innodb_flush_log_at_trx_commit" == (l2 r) && "port" == (l1 r)) x)) x