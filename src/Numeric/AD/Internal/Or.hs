{-# LANGUAGE CPP #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE DataKinds #-}
#if __GLASGOW_HASKELL__ >= 707
{-# LANGUAGE DeriveDataTypeable #-}
#endif
{-# OPTIONS_HADDOCK not-home #-}

-----------------------------------------------------------------------------
-- |
-- Copyright   :  (c) Edward Kmett 2014
-- License     :  BSD3
-- Maintainer  :  ekmett@gmail.com
-- Stability   :  experimental
-- Portability :  GHC only
--
-----------------------------------------------------------------------------

module Numeric.AD.Internal.Or
  ( Or(..)
  , Chosen(..)
  , chosen
  , unary
  , binary
  ) where

import Control.Applicative
import Data.Number.Erf
#if __GLASGOW_HASKELL__ >= 707
import Data.Typeable
#endif
import Numeric.AD.Mode

#ifdef HLINT
#endif

------------------------------------------------------------------------------
-- On
------------------------------------------------------------------------------

chosen :: (a -> r) -> (b -> r) -> Or a b s -> r
chosen f _ (L a) = f a
chosen _ g (R b) = g b

unary :: (a -> a) -> (b -> b) -> Or a b s -> Or a b s
unary f _ (L a) = L (f a)
unary _ g (R a) = R (g a)

binary :: (a -> a -> a) -> (b -> b -> b) -> Or a b s -> Or a b s -> Or a b s
binary f _ (L a) (L b) = L (f a b)
binary _ g (R a) (R b) = R (g a b)
binary _ _ _ _ = impossible

class Chosen s where
  choose :: a -> b -> Or a b s

instance Chosen False where
  choose x _ = L x

instance Chosen True where
  choose _ x = R x

-- | The choice between two AD modes is an AD mode in its own right
data Or a b (s :: Bool) where
  L :: a -> Or a b False
  R :: b -> Or a b True
#if __GLASGOW_HASKELL__ >= 707
  deriving Typeable
#endif

impossible :: a
impossible = error "Numeric.AD.Internal.Or: impossible case"

instance (Eq a, Eq b) => Eq (Or a b s) where
  L a == L b = a == b
  R a == R b = a == b
  _ == _ = impossible

instance (Ord a, Ord b) => Ord (Or a b s) where
  L a `compare` L b = compare a b
  R a `compare` R b = compare a b
  _ `compare` _ = impossible

instance (Enum a, Enum b, Chosen s) => Enum (Or a b s) where
  pred = unary pred pred
  succ = unary succ succ
  toEnum i = choose (toEnum i) (toEnum i)
  fromEnum = chosen fromEnum fromEnum
  enumFrom (L a) = L <$> enumFrom a
  enumFrom (R a) = R <$> enumFrom a
  enumFromThen (L a) (L b) = L <$> enumFromThen a b
  enumFromThen (R a) (R b) = R <$> enumFromThen a b
  enumFromThen _     _     = impossible
  enumFromTo (L a) (L b) = L <$> enumFromTo a b
  enumFromTo (R a) (R b) = R <$> enumFromTo a b
  enumFromTo _     _     = impossible
  enumFromThenTo (L a) (L b) (L c) = L <$> enumFromThenTo a b c
  enumFromThenTo (R a) (R b) (R c) = R <$> enumFromThenTo a b c
  enumFromThenTo _     _     _     = impossible

instance (Bounded a, Bounded b, Chosen s) => Bounded (Or a b s) where
  maxBound = choose maxBound maxBound
  minBound = choose minBound minBound

instance (Num a, Num b, Chosen s) => Num (Or a b s) where
  (+) = binary (+) (+)
  (-) = binary (-) (-)
  (*) = binary (*) (*)
  negate = unary negate negate
  abs = unary abs abs
  signum = unary signum signum
  fromInteger = choose <$> fromInteger <*> fromInteger

instance (Real a, Real b, Chosen s) => Real (Or a b s) where
  toRational = chosen toRational toRational

instance (Fractional a, Fractional b, Chosen s) => Fractional (Or a b s) where
  (/) = binary (/) (/)
  recip = unary recip recip
  fromRational = choose <$> fromRational <*> fromRational

instance (RealFrac a, RealFrac b, Chosen s) => RealFrac (Or a b s) where
  properFraction (L a) = case properFraction a of
    (b, c) -> (b, L c)
  properFraction (R a) = case properFraction a of
    (b, c) -> (b, R c)
  truncate = chosen truncate truncate
  round = chosen round round
  ceiling = chosen ceiling ceiling
  floor = chosen floor floor

instance (Floating a, Floating b, Chosen s) => Floating (Or a b s) where
  pi = choose pi pi
  exp = unary exp exp
  sqrt = unary sqrt sqrt
  log = unary log log
  (**) = binary (**) (**)
  logBase = binary logBase logBase
  sin = unary sin sin
  tan = unary tan tan
  cos = unary cos cos
  asin = unary asin asin
  atan = unary atan atan
  acos = unary acos acos
  sinh = unary sinh sinh
  tanh = unary tanh tanh
  cosh = unary cosh cosh
  asinh = unary asinh asinh
  atanh = unary atanh atanh
  acosh = unary acosh acosh

instance (Erf a, Erf b, Chosen s) => Erf (Or a b s) where
  erf = unary erf erf
  erfc = unary erfc erfc
  erfcx = unary erfcx erfcx
  normcdf = unary normcdf normcdf

instance (InvErf a, InvErf b, Chosen s) => InvErf (Or a b s) where
  inverf = unary inverf inverf
  inverfc = unary inverfc inverfc
  invnormcdf = unary invnormcdf invnormcdf

instance (RealFloat a, RealFloat b, Chosen s) => RealFloat (Or a b s) where
  floatRadix = chosen floatRadix floatRadix
  floatDigits = chosen floatDigits floatDigits
  floatRange = chosen floatRange floatRange
  decodeFloat = chosen decodeFloat decodeFloat
  encodeFloat i j = choose (encodeFloat i j) (encodeFloat i j)
  exponent = chosen exponent exponent
  significand = unary significand significand
  scaleFloat = unary <$> scaleFloat <*> scaleFloat
  isNaN = chosen isNaN isNaN
  isInfinite = chosen isInfinite isInfinite
  isDenormalized = chosen isDenormalized isDenormalized
  isNegativeZero = chosen isNegativeZero isNegativeZero
  isIEEE = chosen isIEEE isIEEE
  atan2 = binary atan2 atan2

type instance Scalar (Or a b s) = Scalar a

instance (Mode a, Mode b, Chosen s, Scalar a ~ Scalar b) => Mode (Or a b s) where
  auto = choose <$> auto <*> auto
  isKnownConstant = chosen isKnownConstant isKnownConstant
  isKnownZero = chosen isKnownZero isKnownZero
  x *^ L a = L (x *^ a)
  x *^ R a = R (x *^ a)
  L a ^* x = L (a ^* x)
  R a ^* x = R (a ^* x)
  L a ^/ x = L (a ^/ x)
  R a ^/ x = R (a ^/ x)
  zero = choose zero zero
