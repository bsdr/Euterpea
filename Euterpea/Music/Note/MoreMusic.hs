-- This code was automatically generated by lhs2tex --code, from the file 
-- HSoM/MoreMusic.lhs.  (See HSoM/MakeCode.bat.)

module Euterpea.Music.Note.MoreMusic where
import Euterpea.Music.Note.Music
line, chord :: [Music a] -> Music a
line   = foldr (:+:) (rest 0)
chord  = foldr (:=:) (rest 0)

line1, chord1 :: [Music a] -> Music a
line1  = foldr1 (:+:)
chord1 = foldr1 (:=:)
delayM      :: Dur -> Music a -> Music a
delayM d m  = rest d :+: m
 
timesM      :: Int -> Music a -> Music a
timesM 0 m  = rest 0
timesM n m  = m :+: timesM (n-1) m

repeatM    :: Music a -> Music a
repeatM m  = m :+: repeatM m
lineToList                    :: Music a -> [Music a]
lineToList (Prim (Rest 0))    = []
lineToList (n :+: ns)         = n : lineToList ns
lineToList _                  = 
    error "lineToList: argument not created by function line"
invert :: Music Pitch -> Music Pitch
invert m  =
  let l  = lineToList m
      l' = dropWhile (\x -> case x of (Prim (Rest _)) -> True; _ -> False) l
      inv r (Prim (Note d p))  =
                 note d (pitch (2 * absPitch r - absPitch p))
      inv r (Prim (Rest d))    = rest d
   in case l' of []                    -> m
                 (Prim (Note _ p)) : _ -> line (map (inv p) l)
retro, retroInvert, invertRetro :: Music Pitch -> Music Pitch
retro        = line . reverse . lineToList
retroInvert  = retro  . invert
invertRetro  = invert . retro
 
pr1, pr2 :: Pitch -> Music Pitch
pr1 p =  tempo (5/6) 
         (  tempo (4/3)  (  mkLn 1 p qn :+:
                            tempo (3/2) (  mkLn 3 p en  :+:
                                           mkLn 2 p sn  :+:
                                           mkLn 1 p qn     ) :+:
                            mkLn 1 p qn) :+:
            tempo (3/2)  (  mkLn 6 p en))
pr2 p = 
   let  m1   = tempo (5/4) (tempo (3/2) m2 :+: m2)
        m2   = mkLn 3 p en
   in tempo (7/6) (  m1 :+:
                     tempo (5/4) (mkLn 5 p en) :+:
                     m1 :+:
                     tempo (3/2) m2)

mkLn n p d = line $ take n $ repeat $ note d p
pr12  :: Music Pitch
pr12  = pr1 (C,4) :=: pr2 (G,4)
 
(=:=)        :: Dur -> Dur -> Music a -> Music a
old =:= new  =  tempo (new/old)
dur                       :: Music a -> Dur
dur (Prim (Note d _))     = d
dur (Prim (Rest d))       = d
dur (m1 :+: m2)           = dur m1   +   dur m2
dur (m1 :=: m2)           = dur m1 `max` dur m2
dur (Modify (Tempo r) m)  = dur m / r
dur (Modify _ m)          = dur m
revM               :: Music a -> Music a
revM n@(Prim _)    = n
revM (Modify c m)  = Modify c (revM m)
revM (m1 :+: m2)   = revM m2 :+: revM m1
revM (m1 :=: m2)   =  
   let  d1 = dur m1
        d2 = dur m2
   in if d1>d2  then revM m1 :=: (rest (d1-d2) :+: revM m2)
                else (rest (d2-d1) :+: revM m1) :=: revM m2
 
takeM :: Dur -> Music a -> Music a
takeM d m | d <= 0            = rest 0
takeM d (Prim (Note oldD p))  = note (min oldD d) p
takeM d (Prim (Rest oldD))    = rest (min oldD d)
takeM d (m1 :=: m2)           = takeM d m1 :=: takeM d m2
takeM d (m1 :+: m2)           =  let  m'1  = takeM d m1
                                      m'2  = takeM (d - dur m'1) m2
                                 in m'1 :+: m'2
takeM d (Modify (Tempo r) m)  = tempo r (takeM (d*r) m)
takeM d (Modify c m)          = Modify c (takeM d m)
cut = takeM
dropM :: Dur -> Music a -> Music a
dropM d m | d <= 0            = m
dropM d (Prim (Note oldD p))  = note (max (oldD-d) 0) p
dropM d (Prim (Rest oldD))    = rest (max (oldD-d) 0)
dropM d (m1 :=: m2)           = dropM d m1 :=: dropM d m2
dropM d (m1 :+: m2)           =  let  m'1  = dropM d m1
                                      m'2  = dropM (d - dur m1) m2
                                 in m'1 :+: m'2
dropM d (Modify (Tempo r) m)  = tempo r (dropM (d*r) m)
dropM d (Modify c m)          = Modify c (dropM d m)
removeZeros :: Music a -> Music a
removeZeros (Prim p)      = Prim p
removeZeros (m1 :+: m2)   = 
  let  m'1  = removeZeros m1
       m'2  = removeZeros m2
  in case (m'1,m'2) of
       (Prim (Note 0 p), m)  -> m
       (Prim (Rest 0  ), m)  -> m
       (m, Prim (Note 0 p))  -> m
       (m, Prim (Rest 0  ))  -> m
       (m1, m2)              -> m1 :+: m2
removeZeros (m1 :=: m2)   =
  let  m'1  = removeZeros m1
       m'2  = removeZeros m2
  in case (m'1,m'2) of
       (Prim (Note 0 p), m)  -> m
       (Prim (Rest 0  ), m)  -> m
       (m, Prim (Note 0 p))  -> m
       (m, Prim (Rest 0  ))  -> m
       (m1, m2)              -> m1 :=: m2
removeZeros (Modify c m)  = Modify c (removeZeros m)
type LazyDur = [Dur]
durL :: Music a -> LazyDur
durL m@(Prim _)            =  [dur m]
durL (m1 :+: m2)           =  let d1 = durL m1
                              in d1 ++ map (+(last d1)) (durL m2)
durL (m1 :=: m2)           =  mergeLD (durL m1) (durL m2)
durL (Modify (Tempo r) m)  =  map (/r) (durL m)
durL (Modify _ m)          =  durL m 
mergeLD :: LazyDur -> LazyDur -> LazyDur
mergeLD [] ld = ld
mergeLD ld [] = ld
mergeLD ld1@(d1:ds1) ld2@(d2:ds2) = 
  if d1<d2  then  d1 : mergeLD ds1 ld2
            else  d2 : mergeLD ld1 ds2
minL :: LazyDur -> Dur -> Dur
minL [d]     d' = min d d'
minL (d:ds)  d' = if d < d' then minL ds d' else d'
takeML :: LazyDur -> Music a -> Music a
takeML [] m                     = rest 0
takeML (d:ds) m | d <= 0        = takeML ds m
takeML ld (Prim (Note oldD p))  = note (minL ld oldD) p
takeML ld (Prim (Rest oldD))    = rest (minL ld oldD)
takeML ld (m1 :=: m2)           = takeML ld m1 :=: takeML ld m2
takeML ld (m1 :+: m2)           =  
   let  m'1 = takeML ld m1
        m'2 = takeML (map (\d -> d - dur m'1) ld) m2
   in m'1 :+: m'2
takeML ld (Modify (Tempo r) m)  = tempo r (takeML (map (*r) ld) m)
takeML ld (Modify c m)          = Modify c (takeML ld m)
(/=:)      :: Music a -> Music a -> Music a
m1 /=: m2  = takeML (durL m2) m1 :=: takeML (durL m1) m2
trill :: Int -> Dur -> Music Pitch -> Music Pitch
trill i sDur (Prim (Note tDur p)) =
   if sDur >= tDur  then note tDur p
                    else  note sDur p :+: 
                          trill  (negate i) sDur 
                                 (note (tDur-sDur) (trans i p))
trill i d (Modify (Tempo r) m)  = tempo r (trill i (d*r) m)
trill i d (Modify c m)          = Modify c (trill i d m)
trill _ _ _                     = 
      error "trill: input must be a single note."
trill' :: Int -> Dur -> Music Pitch -> Music Pitch
trill' i sDur m = trill (negate i) sDur (transpose i m)
trilln :: Int -> Int -> Music Pitch -> Music Pitch
trilln i nTimes m = trill i (dur m / fromIntegral nTimes) m
trilln' :: Int -> Int -> Music Pitch -> Music Pitch
trilln' i nTimes m = trilln (negate i) nTimes (transpose i m)
roll  :: Dur -> Music Pitch -> Music Pitch
rolln :: Int -> Music Pitch -> Music Pitch

roll  dur    m = trill  0 dur m
rolln nTimes m = trilln 0 nTimes m
ssfMel :: Music Pitch
ssfMel = line (l1 ++ l2 ++ l3 ++ l4)
  where  l1  = [ trilln 2 5 (bf 6 en), ef 7 en, ef 6 en, ef 7 en ]
         l2  = [ bf 6 sn, c  7 sn, bf 6 sn, g 6 sn, ef 6 en, bf 5 en ]
         l3  = [ ef 6 sn, f 6 sn, g 6 sn, af 6 sn, bf 6 en, ef 7 en ]
         l4  = [ trill 2 tn (bf 6 qn), bf 6 sn, denr ]

starsAndStripes :: Music Pitch
starsAndStripes = instrument Flute ssfMel
grace :: Int -> Rational -> Music Pitch -> Music Pitch
grace n r (Prim (Note d p))  =
      note (r*d) (trans n p) :+: note ((1-r)*d) p
grace n r _                  = 
      error "grace: can only add a grace note to a note"
grace2 ::  Int -> Rational -> 
           Music Pitch -> Music Pitch -> Music Pitch
grace2 n r (Prim (Note d1 p1)) (Prim (Note d2 p2)) =
      note (d1-r*d2) p1 :+: note (r*d2) (trans n p2) :+: note d2 p2
grace2 _ _ _ _  = 
      error "grace2: can only add a grace note to a note"
data PercussionSound =
        AcousticBassDrum  -- MIDI Key 35
     |  BassDrum1         -- MIDI Key 36
     |  SideStick         -- ...
     |  AcousticSnare  | HandClap      | ElectricSnare  | LowFloorTom
     |  ClosedHiHat    | HighFloorTom  | PedalHiHat     | LowTom
     |  OpenHiHat      | LowMidTom     | HiMidTom       | CrashCymbal1
     |  HighTom        | RideCymbal1   | ChineseCymbal  | RideBell
     |  Tambourine     | SplashCymbal  | Cowbell        | CrashCymbal2
     |  Vibraslap      | RideCymbal2   | HiBongo        | LowBongo
     |  MuteHiConga    | OpenHiConga   | LowConga       | HighTimbale
     |  LowTimbale     | HighAgogo     | LowAgogo       | Cabasa
     |  Maracas        | ShortWhistle  | LongWhistle    | ShortGuiro
     |  LongGuiro      | Claves        | HiWoodBlock    | LowWoodBlock
     |  MuteCuica      | OpenCuica     | MuteTriangle
     |  OpenTriangle      -- MIDI Key 82
   deriving (Show,Eq,Ord,Enum)

perc :: PercussionSound -> Dur -> Music Pitch
perc ps dur = note dur (pitch (fromEnum ps + 35))
funkGroove
  =  let  p1  = perc LowTom         qn
          p2  = perc AcousticSnare  en
     in  tempo 3 $ instrument Percussion $ takeM 8 $ repeatM
         (  (  p1 :+: qnr :+: p2 :+: qnr :+: p2 :+:
               p1 :+: p1 :+: qnr :+: p2 :+: enr)
            :=: roll en (perc ClosedHiHat 2) )
pMap               :: (a -> b) -> Primitive a -> Primitive b
pMap f (Note d x)  = Note d (f x)
pMap f (Rest d)    = Rest d
mMap                 :: (a -> b) -> Music a -> Music b
mMap f (Prim p)      = Prim (pMap f p)
mMap f (m1 :+: m2)   = mMap f m1 :+: mMap f m2
mMap f (m1 :=: m2)   = mMap f m1 :=: mMap f m2
mMap f (Modify c m)  = Modify c (mMap f m)
type Volume = Int
addVolume    :: Volume -> Music Pitch -> Music (Pitch,Volume)
addVolume v  = mMap (\p -> (p,v))
data NoteAttribute = 
        Volume  Int   -- MIDI convention: 0=min, 127=max
     |  Fingering Integer
     |  Dynamics String
     |  Params [Double]
   deriving (Eq, Show)
mFold ::  (Primitive a -> b) -> (b->b->b) -> (b->b->b) -> 
          (Control -> b -> b) -> Music a -> b
mFold f (+:) (=:) g m =
  let rec = mFold f (+:) (=:) g
  in case m of
       Prim p      -> f p
       m1 :+: m2   -> rec m1 +: rec m2
       m1 :=: m2   -> rec m1 =: rec m2
       Modify c m  -> g c (rec m)
rep ::  (Music a -> Music a) -> (Music a -> Music a) -> Int 
        -> Music a -> Music a
rep f g 0 m  = rest 0
rep f g n m  = m :=: g (rep f g (n-1) (f m))
run       = rep (transpose 5) (delayM tn) 8 (c 4 tn)
cascade   = rep (transpose 4) (delayM en) 8 run
cascades  = rep  id           (delayM sn) 2 cascade
final = cascades :+: revM cascades
run'       = rep (delayM tn) (transpose 5) 8 (c 4 tn)
cascade'   = rep (delayM en) (transpose 4) 8 run'
cascades'  = rep (delayM sn)  id           2 cascade'
final'     = cascades' :+: revM cascades'
