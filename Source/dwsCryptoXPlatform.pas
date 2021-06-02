{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    Copyright Creative IT.                                            }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsCryptoXPlatform;

{$I dws.inc}
{$R-}

//
// This unit should concentrate all cryptographic cross-platform aspects,
// cross-Delphi versions, ifdefs and other conditionals
//
// no ifdefs in the main code.

{$WARN SYMBOL_PLATFORM OFF}

interface

procedure CryptographicRandom(buf : Pointer; nb : Integer); overload;
function CryptographicRandom(nb : Integer) : AnsiString; overload;
function CryptographicToken(bitStrength : Integer = 0) : String;
function ProcessUniqueRandom : String;

// only encodes 6 bits of each bytes using URI-safe base 64 alphabet
function DigestToSimplifiedBase64(digest : PByte; size : Integer) : String;
// only encodes 5.8 bits of each bytes (using 62 alphanumeric characters)
function DigestToSimplifiedBase62(digest : PByte; size : Integer) : String;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses
   dwsXPlatform,
   Windows, wcrypt2;

const
   cCryptographicTokenDefaultBitStrength = 120;

var
   vProcessUniqueRandom : String;

procedure GenerateUniqueRandom;
var
   buf : String;
begin
   // 6 bits per character, 42 characters, 252 bits of random
   buf:=CryptographicToken(6*42);
   Pointer(buf):=InterlockedCompareExchangePointer(Pointer(vProcessUniqueRandom),
                                                   Pointer(buf), nil);
end;

function ProcessUniqueRandom : String;
begin
   if vProcessUniqueRandom='' then
      GenerateUniqueRandom;
   Result:=vProcessUniqueRandom;
end;

var
   hProv : THandle;
   hProvLock : TMultiReadSingleWrite;
   vXorShiftSeedMask : UInt64;

procedure CryptographicRandom(buf : Pointer; nb : Integer);

   function XorShift(var seed : UInt64) : Cardinal; inline;
   var
      buf : UInt64;
   begin
      buf:=seed xor (seed shl 13);
      buf:=buf xor (buf shr 17);
      buf:=buf xor (buf shl 5);
      seed:=buf;
      Result:=seed and $FFFFFFFF;
   end;

var
   i : Integer;
   seed : UInt64;
   p : PCardinal;
begin
   if nb <= 0 then Exit;

   hProvLock.BeginWrite;
   try
      if hProv=0 then begin
         if not CryptAcquireContext(@hProv, nil, MS_ENHANCED_PROV, PROV_RSA_FULL,
                                    CRYPT_VERIFYCONTEXT) then begin
            CryptAcquireContext(@hProv, nil, MS_ENHANCED_PROV, PROV_RSA_FULL,
                                CRYPT_NEWKEYSET + CRYPT_VERIFYCONTEXT);
         end;
         CryptGenRandom(hProv, SizeOf(vXorShiftSeedMask), @vXorShiftSeedMask);
      end;
      CryptGenRandom(hProv, nb, buf);
   finally
      hProvLock.EndWrite;
   end;

   // further muddy things, in case Windows generator is later found vulnerable,
   // this will protect us from "generic" exploits
   seed := RDTSC xor vXorShiftSeedMask;
   p := buf;
   for i:=0 to (nb div 4)-1 do begin
      p^:=p^ xor XorShift(seed);
      Inc(p);
   end;
end;

// CryptographicRandom
//
function CryptographicRandom(nb : Integer) : AnsiString;
begin
   SetLength(Result, nb);
   CryptographicRandom(Pointer(Result), nb);
end;

const
   // uri-safe base64 table (RFC 4648)
   cBase64Chars : AnsiString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

// DigestToSimplifiedBase64
//
function DigestToSimplifiedBase64(digest : PByte; size : Integer) : String;
var
   i : Integer;
begin
   SetLength(Result, size);
   for i := 0 to size-1 do
      PChar(Pointer(Result))[i] := Char(cBase64Chars[(digest[i] and 63)+1]);
end;

// DigestToSimplifiedBase62
//
function DigestToSimplifiedBase62(digest : PByte; size : Integer) : String;
var
   i : Integer;
begin
   SetLength(Result, size);
   for i := 0 to size-1 do
      PChar(Pointer(Result))[i] := Char(cBase64Chars[((digest[i]*62) shr 8)+1]);
end;

// CryptographicToken
//
function CryptographicToken(bitStrength : Integer = 0) : String;
var
   n : Integer;
   rand : AnsiString;
begin
   if bitStrength <= 0 then
      bitStrength := cCryptographicTokenDefaultBitStrength;
   // 6 bits per character
   n:=bitStrength div 6;
   if n*6<bitStrength then
      Inc(n);
   rand := CryptographicRandom(n);
   Result := DigestToSimplifiedBase64(Pointer(rand), n);
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

   hProvLock := TMultiReadSingleWrite.Create;

finalization

   hProvLock.Free;
   hProvLock:=nil;
   if hProv>0 then
      CryptReleaseContext(hProv, 0);

end.
