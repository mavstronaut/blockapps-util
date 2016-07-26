
module Blockchain.Util where

import Data.Bits
import qualified Data.ByteString as B
import qualified Data.NibbleString as N
import Data.ByteString.Internal
import Data.Char
import Data.List
import Data.Word
import Numeric

import Blockchain.ExtWord

showHex4::Word256->String
showHex4 i = replicate (4 - length rawOutput) '0' ++ rawOutput
    where rawOutput = showHex i ""

showHexU::Integer->[Char]
showHexU = map toUpper . flip showHex ""

nibbleString2ByteString::N.NibbleString->B.ByteString
nibbleString2ByteString (N.EvenNibbleString s) = s
nibbleString2ByteString (N.OddNibbleString c s) = c `B.cons` s

byteString2NibbleString::B.ByteString->N.NibbleString
byteString2NibbleString = N.EvenNibbleString

--I hate this, it is an ugly way to create an Integer from its component bytes.
--There should be an easier way....
--See http://stackoverflow.com/questions/25854311/efficient-packing-bytes-into-integers
byteString2Integer::B.ByteString->Integer
byteString2Integer x = bytes2Integer $ B.unpack x

bytes2Integer::[Word8]->Integer
bytes2Integer [] = 0
bytes2Integer (byte:rest) = fromIntegral byte `shift` (8 * length rest) + bytes2Integer rest

integer2Bytes::Integer->[Word8]
integer2Bytes 0 = []
integer2Bytes x = integer2Bytes (x `shiftR` 8) ++ [fromInteger (x .&. 255)]

--integer2Bytes1 is integer2Bytes, but with the extra condition that the output be of length 1 or more.
integer2Bytes1::Integer->[Word8]
integer2Bytes1 0 = [0]
integer2Bytes1 x = integer2Bytes x

padZeros::Int->String->String
padZeros n s = replicate (n - length s) '0' ++ s

tab::String->String
tab [] = []
tab ('\n':rest) = '\n':' ':' ':' ':' ':tab rest
tab (c:rest) = c:tab rest

showWord8::Word8->Char
showWord8 c | c >= 32 && c < 127 = w2c c
showWord8 _ = '?'

showMem::Int->[Word8]->String
showMem _ x | length x > 1000 = " mem size greater than 1000 bytes"
showMem _ [] = "" 
showMem p (v1:v2:v3:v4:v5:v6:v7:v8:rest) = 
    padZeros 4 (showHex p "") ++ " " 
             ++ [showWord8 v1] ++ [showWord8 v2] ++ [showWord8 v3] ++ [showWord8 v4]
             ++ [showWord8 v5] ++ [showWord8 v6] ++ [showWord8 v7] ++ [showWord8 v8] ++ " "
             ++ padZeros 2 (showHex v1 "") ++ " " ++ padZeros 2 (showHex v2 "") ++ " " ++ padZeros 2 (showHex v3 "") ++ " " ++ padZeros 2 (showHex v4 "") ++ " "
             ++ padZeros 2 (showHex v5 "") ++ " " ++ padZeros 2 (showHex v6 "") ++ " " ++ padZeros 2 (showHex v7 "") ++ " " ++ padZeros 2 (showHex v8 "") ++ "\n"
             ++ showMem (p+8) rest
showMem p x = padZeros 4 (showHex p "") ++ " " ++ (showWord8 <$> x) ++ " " ++ intercalate " " (padZeros 2 <$> flip showHex "" <$> x)

showMem'::Int->[Word8]->[String]
showMem' _ [] = []
showMem' p (v01:v02:v03:v04:v05:v06:v07:v08:v09:v10:v11:v12:v13:v14:v15:v16:v17:v18:v19:v20:v21:v22:v23:v24:v25:v26:v27:v28:v29:v30:v31:v32:rest) =
	[] : (
	padZeros 2 (showHex v01 "") ++ padZeros 2 (showHex v02 "") ++ padZeros 2 (showHex v03 "") ++ padZeros 2 (showHex v04 "") ++
	padZeros 2 (showHex v05 "") ++ padZeros 2 (showHex v06 "") ++ padZeros 2 (showHex v07 "") ++ padZeros 2 (showHex v08 "") ++ 
	padZeros 2 (showHex v09 "") ++ padZeros 2 (showHex v10 "") ++ padZeros 2 (showHex v11 "") ++ padZeros 2 (showHex v12 "") ++
	padZeros 2 (showHex v13 "") ++ padZeros 2 (showHex v14 "") ++ padZeros 2 (showHex v15 "") ++ padZeros 2 (showHex v16 "") ++
	padZeros 2 (showHex v17 "") ++ padZeros 2 (showHex v18 "") ++ padZeros 2 (showHex v19 "") ++ padZeros 2 (showHex v20 "") ++
	padZeros 2 (showHex v21 "") ++ padZeros 2 (showHex v22 "") ++ padZeros 2 (showHex v23 "") ++ padZeros 2 (showHex v24 "") ++ 
	padZeros 2 (showHex v25 "") ++ padZeros 2 (showHex v26 "") ++ padZeros 2 (showHex v27 "") ++ padZeros 2 (showHex v28 "") ++
	padZeros 2 (showHex v29 "") ++ padZeros 2 (showHex v30 "") ++ padZeros 2 (showHex v31 "") ++ padZeros 2 (showHex v32 "") 
	)
            : (showMem' (p+32) rest)
showMem' p x = [intercalate "" (padZeros 2 <$> flip showHex "" <$> x)]

safeTake::Word256->B.ByteString->B.ByteString
safeTake i _ | i > 0x7fffffffffffffff = error "error in call to safeTake: string too long"
safeTake i s | i > fromIntegral (B.length s) = s `B.append` B.replicate (fromIntegral i - B.length s) 0
safeTake i s = B.take (fromIntegral i) s

safeDrop::Word256->B.ByteString->B.ByteString
safeDrop i s | i > fromIntegral (B.length s) = B.empty
safeDrop i _ | i > 0x7fffffffffffffff = error "error in call to safeDrop: string too long"
safeDrop i s = B.drop (fromIntegral i) s


isContiguous::(Eq a, Num a)=>[a]->Bool
isContiguous [] = True
isContiguous [_] = True
isContiguous (x:y:rest) | y == x + 1 = isContiguous $ y:rest
isContiguous _ = False
