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
{    The Initial Developer of the Original Code is Matthias            }
{    Ackermann. For other initial contributors, see contributors.txt   }
{    Subsequent portions Copyright Creative IT.                        }
{                                                                      }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsVariantFunctions;

{$I dws.inc}

interface

uses
   Classes, Variants, SysUtils,
   dwsFunctions, dwsExprs, dwsSymbols, dwsUtils, dwsExprList, dwsCompilerContext,
   dwsMagicExprs, dwsUnitSymbols, dwsXPlatform, dwsStrings;

type
   TVarClearFunc = class(TInternalMagicProcedure)
      procedure DoEvalProc(const args : TExprBaseListExec); override;
   end;

   TVarIsNullFunc = class(TInternalMagicBoolFunction)
      function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; override;
   end;

   TVarIsEmptyFunc = class(TInternalMagicBoolFunction)
      function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; override;
   end;

   TVarIsClearFunc = class(TInternalMagicBoolFunction)
      function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; override;
   end;

   TVarIsArrayFunc = class(TInternalMagicBoolFunction)
      function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; override;
   end;

   TVarIsStrFunc = class(TInternalMagicBoolFunction)
      function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; override;
   end;

   TVarTypeFunc = class(TInternalMagicIntFunction)
      function DoEvalAsInteger(const args : TExprBaseListExec) : Int64; override;
   end;

   TVarAsTypeFunc = class(TInternalMagicVariantFunction)
      procedure DoEvalAsVariant(const args : TExprBaseListExec; var result : Variant); override;
   end;

   TVarToStrFunc = class(TInternalMagicStringFunction)
      procedure DoEvalAsString(const args : TExprBaseListExec; var Result : String); override;
      procedure CompileTimeCheck(context : TdwsCompilerContext; expr : TFuncExprBase); override;
   end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

var
   vUnassigned : Variant;

{ TVarClearFunc }

procedure TVarClearFunc.DoEvalProc(const args : TExprBaseListExec);
begin
   args.ExprBase[0].AssignValue(args.Exec, vUnassigned);
end;

{ TVarIsNullFunc }

function TVarIsNullFunc.DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean;
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   Result:=VarIsNull(v);
end;

{ TVarIsEmptyFunc }

function TVarIsEmptyFunc.DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean;
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   Result:=VarIsEmpty(v);
end;

{ TVarIsClearFunc }

function TVarIsClearFunc.DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean;

   function CheckUnknown(const unk : IUnknown) : Boolean;
   var
      nullable : INullable;
   begin
      if unk.QueryInterface(INullable, nullable) = S_OK then
         Result := not nullable.IsDefined
      else Result := False;
   end;

var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   case VarType(v) of
      varEmpty : Result := True;
      varUnknown : begin
         if TVarData(v).VUnknown <> nil then
            Result := CheckUnknown(IUnknown(TVarData(v).VUnknown))
         else Result := False;
      end;
   else
      Result := VarIsClear(v);
   end;
end;

{ TVarIsArrayFunc }

function TVarIsArrayFunc.DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean;
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   Result:=VarIsArray(v);
end;

{ TVarIsStrFunc }

function TVarIsStrFunc.DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean;
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   Result:=VarIsStr(v);
end;

{ TVarTypeFunc }

function TVarTypeFunc.DoEvalAsInteger(const args : TExprBaseListExec) : Int64;
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   Result:=VarType(v);
end;

{ TVarAsTypeFunc }

procedure TVarAsTypeFunc.DoEvalAsVariant(const args : TExprBaseListExec; var result : Variant);
var
   v : Variant;
begin
   args.EvalAsVariant(0, v);
   VarCopySafe(result, VarAsType(v, args.AsInteger[1]));
end;

{ TVarToStrFunc }

// DoEvalAsString
//
procedure TVarToStrFunc.DoEvalAsString(const args : TExprBaseListExec; var Result : String);
var
   v : Variant;
begin
   args.ExprBase[0].EvalAsVariant(args.Exec, v);
   VariantToString(v, Result);
end;

// CompileTimeCheck
//
procedure TVarToStrFunc.CompileTimeCheck(context : TdwsCompilerContext; expr : TFuncExprBase);
begin
   if expr.GetArgType(0).IsOfType(context.TypString) then
      context.Msgs.AddCompilerHint(expr.ScriptPos, CPH_RedundantFunctionCall);
end;

{ InitVariants }

procedure InitVariants(systemTable : TSystemSymbolTable; unitSyms : TUnitMainSymbols;
                       unitTable : TSymbolTable);
type
   TVarTypeRec = packed record n : String; v : Word; end;
const
   cVarTypes : array [0..24] of TVarTypeRec = (
      (n:'Empty'; v:varEmpty),         (n:'Null'; v:varNull),
      (n:'Smallint'; v:varSmallint),   (n:'Integer'; v:varInteger),
      (n:'Single'; v:varSingle),       (n:'Double'; v:varDouble),
      (n:'Currency'; v:varCurrency),   (n:'Date'; v:varDate),
      (n:'OleStr'; v:varOleStr),       (n:'Dispatch'; v:varDispatch),
      (n:'Error'; v:varError),         (n:'Boolean'; v:varBoolean),
      (n:'Variant'; v:varVariant),     (n:'Unknown'; v:varUnknown),
      (n:'ShortInt'; v:varShortInt),   (n:'Byte'; v:varByte),
      (n:'Word'; v:varWord),           (n:'LongWord'; v:varLongWord),
      (n:'Int64'; v:varInt64),         (n:'StrArg'; v:varStrArg),
      {$ifdef FPC}
      (n:'String'; v:varString),
      {$else}
      (n:'String'; v:varUString),
      {$endif}
      (n:'Any'; v:varAny),             (n:'TypeMask'; v:varTypeMask),
      (n:'Array'; v:varArray),         (n:'ByRef'; v:varByRef) );
var
   i : Integer;
   E : TTypeSymbol;
begin
   E := TEnumerationSymbol.Create('TVarType', systemTable.TypInteger, enumClassic);
   UnitTable.AddSymbol(E);
   for i:=Low(cVarTypes) to High(cVarTypes) do
      UnitTable.AddSymbol(TElementSymbol.Create('var'+cVarTypes[i].n, E, cVarTypes[i].v, True));
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

   RegisterInternalSymbolsProc(InitVariants);

   RegisterInternalFunction(TVarClearFunc, 'VarClear', ['@v', 'Variant'], '', [iffOverloaded]);
   RegisterInternalBoolFunction(TVarIsNullFunc, 'VarIsNull', ['v', 'Variant']);
   RegisterInternalBoolFunction(TVarIsEmptyFunc, 'VarIsEmpty', ['v', 'Variant']);
   RegisterInternalBoolFunction(TVarIsClearFunc, 'VarIsClear', ['v', 'Variant']);
   RegisterInternalBoolFunction(TVarIsArrayFunc, 'VarIsArray', ['v', 'Variant']);
   RegisterInternalBoolFunction(TVarIsStrFunc, 'VarIsStr', ['v', 'Variant']);
   RegisterInternalFunction(TVarTypeFunc, 'VarType', ['v', 'Variant'], 'TVarType');
   RegisterInternalFunction(TVarAsTypeFunc, 'VarAsType', ['v', 'Variant', 'VarType', 'TVarType'], 'Variant');
   RegisterInternalStringFunction(TVarToStrFunc, 'VarToStr', ['v', 'Variant']);

end.

