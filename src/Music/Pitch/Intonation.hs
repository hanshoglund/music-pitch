
{-# LANGUAGE FlexibleContexts #-}

-- | Intonation and tuning.
module Music.Pitch.Intonation (
      Intonation(..),
      Tuning(..),

      intone,
      -- makeBasis,
      synTune,
      -- tetTune,
      pureOctaveWith,

      -- * Specific tunings
      pythagorean,
      quarterCommaMeantone,
      schismaticMeantone,
      fiveToneEqual,
      sevenToneEqual,
      twelveToneEqual,
      nineteenToneEqual,
      thirtyOneToneEqual,
      fiftyThreeToneEqual,

      -- * Specific intonations
      -- standardTuning,
      standardIntonation,
)
where

import Data.Maybe
import Data.Either
import Data.Semigroup
import Data.VectorSpace
import Data.AffineSpace
import Data.Basis
import Control.Monad
import Control.Applicative
import Data.Fixed
import Data.Ratio
import Control.Lens

import Music.Pitch.Absolute
import Music.Pitch.Literal as Intervals
import Music.Pitch.Common.Interval
import Music.Pitch.Common.Pitch

newtype Tuning i = Tuning { getTuning :: i -> Double }

newtype Intonation p = Intonation { getIntonation :: p -> Hertz }

basis_A1 :: Interval
basis_A1 = basisValue Chromatic

basis_d2 :: Interval
basis_d2 = basisValue Diatonic

synTune :: (Interval, Double) -> (Interval, Double) -> Interval -> Double
synTune (i1, i1rat) (i2, i2rat) (view (from interval'') -> (a1, d2)) =
  ((makeA1 (i1, i1rat) (i2, i2rat)) ** (fromIntegral a1)) * ((maked2 (i1, i1rat) (i2, i2rat)) ** (fromIntegral d2))
  where makeA1 = makeBasis basis_A1
        maked2 = makeBasis basis_d2

makeBasis :: Interval -> (Interval, Double) -> (Interval, Double) -> Double
makeBasis i (i1, r1) (i2, r2) = case (convertBasisFloat i i1 i2) of
  Just (x, y) -> (r1 ** x) * (r2 ** y)
  Nothing -> error ("Cannot use intervals " ++ (show i1) ++ " and " ++ (show i2) ++ " as basis pair to represent " ++ (show i))

-- | Turn a tuning into an intonation.
intone :: (Pitch, Hertz) -> Tuning Interval -> Intonation Pitch
intone (b, f) (Tuning t) = Intonation $ int
  where int p = f .+^ (t i) where i = p .-. b
-- More generally:
-- intone :: AffineSpace p => (p, Hertz) -> Tuning (Diff p) -> Intonation p


-- Standard syntonic (meantone) tunings, with P8 = 2

pureOctaveWith :: (Interval, Double) -> Tuning Interval
pureOctaveWith = Tuning . synTune (_P8, 2)

pythagorean :: Tuning Interval
pythagorean = pureOctaveWith (_P5, 3/2)

quarterCommaMeantone :: Tuning Interval
quarterCommaMeantone = pureOctaveWith (_M3, 5/4)

schismaticMeantone :: Tuning Interval
schismaticMeantone = pureOctaveWith (8 *^ _P4, 10)

-- TET tunings, i.e. where P8 = 2 and (some other interval) = 1

tetTune :: Interval -> Tuning Interval
tetTune i = pureOctaveWith (i, 1)

fiveToneEqual :: Tuning Interval
fiveToneEqual = tetTune m2

sevenToneEqual :: Tuning Interval
sevenToneEqual = tetTune _A1

twelveToneEqual :: Tuning Interval
twelveToneEqual = tetTune d2

nineteenToneEqual :: Tuning Interval
nineteenToneEqual = tetTune dd2 where dd2 = d2 ^-^ _A1

thirtyOneToneEqual :: Tuning Interval
thirtyOneToneEqual = tetTune dddd3 where dddd3 = m3 ^-^ (4 *^ _A1)

fiftyThreeToneEqual :: Tuning Interval
fiftyThreeToneEqual = tetTune ddddddd6 where ddddddd6 = 31 *^ _P8 ^-^ 53 *^ _P5 -- (!)

-- | Modern standard intonation, i.e. 12-TET with @a = 440 Hz@.
standardIntonation :: Intonation Pitch
standardIntonation = intone (a, 440) twelveToneEqual

{-
Possible instances for numeric types based on standard intonation.

Not used, the user should choose perform the appropriate conversion for a given
tuning system.

instance IsInterval Double where
  fromInterval i = getTuning twelveToneEqual $ fromInterval i

instance IsInterval Float where
    fromInterval x = realToFrac (fromInterval x :: Double)

instance HasResolution a => IsInterval (Fixed a) where
    fromInterval x = realToFrac (fromInterval x :: Double)

instance Integral a => IsInterval (Ratio a) where
    fromInterval x = realToFrac (fromInterval x :: Double)
-}