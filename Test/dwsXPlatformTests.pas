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
{    Copyright Eric Grange / Creative IT                               }
{                                                                      }
{**********************************************************************}
unit dwsXPlatformTests;

{$I dws.inc}

interface

uses
   Classes, SysUtils,
   {$ifdef FPC}
   fpcunit, testutils, testregistry
   {$else}
   TestFrameWork, TestUtils
   {$endif}
   ;

type

   {$ifdef FPC}
   TTestCase = class (fpcunit.TTestCase)
      public
         procedure CheckEquals(const expected, actual: String; const msg: String = ''); overload;
         procedure CheckEquals(const expected, actual: UnicodeString; const msg: String = ''); overload;
         procedure CheckEquals(const expected : String; const actual: UnicodeString; const msg: String = ''); overload;
         procedure CheckEquals(const expected : String; const actual: Variant; const msg: String = ''); overload;
   end;

   ETestFailure = class (Exception);
   {$else}
   TTestCase = class(TestFrameWork.TTestCase)
      public
         procedure CheckEquals(const expected, actual: RawByteString; const msg: String = ''); overload;
         procedure CheckEquals(const expected : String; const actual: RawByteString; const msg: String = ''); overload;
         procedure CheckEquals(const expected : String; const actual: Variant; const msg: String = ''); overload;
   end;
   ETestFailure = TestFrameWork.ETestFailure;
   {$endif}

   TTestCaseClass = class of TTestCase;

procedure RegisterTest(const testName : String; aTest : TTestCaseClass);

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

// RegisterTest
//
procedure RegisterTest(const testName : String; aTest : TTestCaseClass);
begin
   {$ifdef FPC}
   if Length(testName) = 0 then ; // just to disable warning about it not being used
   testregistry.RegisterTest(aTest);
   {$else}
   TestFrameWork.RegisterTest(testName, aTest.Suite);
   {$endif}
end;

// CheckEquals
//
{$ifdef FPC}
procedure TTestCase.CheckEquals(const expected, actual: String; const msg: String = '');
begin
   AssertTrue(msg + ComparisonMsg(expected, actual),
              (expected = actual));
end;
procedure TTestCase.CheckEquals(const expected, actual: UnicodeString; const msg: String = '');
begin
   AssertTrue(msg + ComparisonMsg(String(expected), String(actual)),
              UnicodeCompareStr(expected, actual) = 0);
end;
procedure TTestCase.CheckEquals(const expected : String; const actual: UnicodeString; const msg: String = '');
begin
   AssertTrue(msg + ComparisonMsg(expected, String(actual)),
              UnicodeCompareStr(UnicodeString(expected), actual) = 0);
end;
procedure TTestCase.CheckEquals(const expected : String; const actual: Variant; const msg: String = '');
begin
   AssertTrue(msg + ComparisonMsg(expected, actual),
              AnsiCompareStr(expected, actual) = 0);
end;

{$else}

procedure TTestCase.CheckEquals(const expected, actual: RawByteString; const msg: String);
begin
   OnCheckCalled;
   if (expected <> actual) then
      FailNotEquals(String(expected), String(actual), msg, CallerAddr);
end;

procedure TTestCase.CheckEquals(const expected : String; const actual: RawByteString; const msg: String);
begin
   OnCheckCalled;
   if (expected <> String(actual)) then
      FailNotEquals(String(expected), String(actual), msg, CallerAddr);
end;

procedure TTestCase.CheckEquals(const expected : String; const actual: Variant; const msg: String);
begin
   OnCheckCalled;
   if (expected <> actual) then
      FailNotEquals(String(expected), String(actual), msg, CallerAddr);
end;

{$endif}

end.

