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
unit dwsMagicExprs;

{$I dws.inc}

interface

uses
   Classes, SysUtils,
   dwsUtils, dwsErrors, dwsStrings, dwsScriptSource, dwsCompilerContext,
   dwsSymbols, dwsExprList, dwsStack, dwsDataContext,
   dwsExprs, dwsFunctions, dwsMethodExprs;

type

   TMagicFuncExpr = class;
   TMagicFuncExprClass = class of TMagicFuncExpr;

   TMagicFuncDoEvalEvent = procedure(const args : TExprBaseListExec; var result : Variant) of object;
   TMagicProcedureDoEvalEvent = procedure(const args : TExprBaseListExec) of object;
   TMagicFuncDoEvalDataEvent = procedure(const args : TExprBaseListExec; var result : IDataContext) of object;
   TMagicFuncDoEvalAsInterfaceEvent = procedure(const args : TExprBaseListExec; var Result : IUnknown) of object;
   TMagicFuncDoEvalAsDynArrayEvent = procedure(const args : TExprBaseListExec; var Result : IScriptDynArray) of object;
   TMagicFuncDoEvalAsIntegerEvent = function(const args : TExprBaseListExec) : Int64 of object;
   TMagicFuncDoEvalAsBooleanEvent = function(const args : TExprBaseListExec) : Boolean of object;
   TMagicFuncDoEvalAsFloatEvent = procedure(const args : TExprBaseListExec; var Result : Double) of object;
   TMagicFuncDoEvalAsStringEvent = procedure(const args : TExprBaseListExec; var Result : String) of object;

   // TInternalMagicFunction
   //
   TInternalMagicFunction = class (TInternalFunction)
      private
         FHelperName : String;

      public
         constructor Create(table: TSymbolTable; const funcName: String;
                            const params : TParamArray; const funcType: String;
                            const flags : TInternalFunctionFlags;
                            compositeSymbol : TCompositeTypeSymbol;
                            const helperName : String); override;
         function MagicFuncExprClass : TMagicFuncExprClass; virtual; abstract;
         procedure Call(exec: TdwsProgramExecution; func: TFuncSymbol); override; final;

         property HelperName : String read FHelperName;
         function QualifiedName : String;
   end;

   // TInternalMagicProcedure
   //
   TInternalMagicProcedure = class(TInternalMagicFunction)
      public
         procedure DoEvalProc(const args : TExprBaseListExec); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;

   // TInternalMagicDataFunction
   //
   TInternalMagicDataFunction = class(TInternalMagicFunction)
      public
         procedure DoEval(const args : TExprBaseListExec; var result : IDataContext); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicDataFunctionClass = class of TInternalMagicDataFunction;

   // TInternalMagicVariantFunction
   //
   TInternalMagicVariantFunction = class(TInternalMagicFunction)
      public
         procedure DoEvalAsVariant(const args : TExprBaseListExec; var result : Variant); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicVariantFunctionClass = class of TInternalMagicVariantFunction;

   // TInternalMagicInterfaceFunction
   //
   TInternalMagicInterfaceFunction = class(TInternalMagicFunction)
      public
         procedure DoEvalAsInterface(const args : TExprBaseListExec; var result : IUnknown); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicInterfaceFunctionClass = class of TInternalMagicInterfaceFunction;

   // TInternalMagicDynArrayFunction
   //
   TInternalMagicDynArrayFunction = class(TInternalMagicFunction)
      public
         procedure DoEvalAsDynArray(const args : TExprBaseListExec; var Result : IScriptDynArray); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicDynArrayFunctionClass = class of TInternalMagicDynArrayFunction;

   // TInternalMagicIntFunction
   //
   TInternalMagicIntFunction = class(TInternalMagicFunction)
      public
         function DoEvalAsInteger(const args : TExprBaseListExec) : Int64; virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicIntFunctionClass = class of TInternalMagicIntFunction;

   // TInternalMagicBoolFunction
   //
   TInternalMagicBoolFunction = class(TInternalMagicFunction)
      public
         function DoEvalAsBoolean(const args : TExprBaseListExec) : Boolean; virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicBoolFunctionClass = class of TInternalMagicBoolFunction;

   // TInternalMagicFloatFunction
   //
   TInternalMagicFloatFunction = class(TInternalMagicFunction)
      public
         procedure DoEvalAsFloat(const args : TExprBaseListExec; var Result : Double); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicFloatFunctionClass = class of TInternalMagicFloatFunction;

   // TInternalMagicStringFunction
   //
   TInternalMagicStringFunction = class(TInternalMagicFunction)
      public
         procedure DoEvalAsString(const args : TExprBaseListExec; var Result : String); virtual; abstract;
         function MagicFuncExprClass : TMagicFuncExprClass; override;
   end;
   TInternalMagicStringFunctionClass = class of TInternalMagicStringFunction;

   // TMagicFuncSymbol
   //
   TMagicFuncSymbol = class sealed (TFuncSymbol)
      private
         FInternalFunction : TInternalMagicFunction;

      public
         destructor Destroy; override;

         procedure Initialize(const msgs : TdwsCompileMessageList); override;
         function IsType : Boolean; override;
         function QualifiedName : String; override;

         property InternalFunction : TInternalMagicFunction read FInternalFunction write FInternalFunction;
   end;

   // TMagicMethodSymbol
   //
   TMagicMethodSymbol = class(TMethodSymbol)
      private
         FInternalFunction : TInternalFunction;
         FOnFastEval : TMethodFastEvalEvent;
         FOnFastEvalInteger : TMethodFastEvalIntegerEvent;
         FOnFastEvalString : TMethodFastEvalStringEvent;
         FOnFastEvalBoolean : TMethodFastEvalBooleanEvent;
         FOnFastEvalFloat : TMethodFastEvalFloatEvent;
         FOnFastEvalNoResult : TMethodFastEvalNoResultEvent;

      public
         destructor Destroy; override;

         procedure Initialize(const msgs : TdwsCompileMessageList); override;
         function IsType : Boolean; override;

         property InternalFunction : TInternalFunction read FInternalFunction write FInternalFunction;
         property OnFastEval : TMethodFastEvalEvent read FOnFastEval write FOnFastEval;
         property OnFastEvalInteger : TMethodFastEvalIntegerEvent read FOnFastEvalInteger write FOnFastEvalInteger;
         property OnFastEvalString : TMethodFastEvalStringEvent read FOnFastEvalString write FOnFastEvalString;
         property OnFastEvalBoolean : TMethodFastEvalBooleanEvent read FOnFastEvalBoolean write FOnFastEvalBoolean;
         property OnFastEvalFloat : TMethodFastEvalFloatEvent read FOnFastEvalFloat write FOnFastEvalFloat;
         property OnFastEvalNoResult : TMethodFastEvalNoResultEvent read FOnFastEvalNoResult write FOnFastEvalNoResult;
   end;

   // TMagicStaticMethodSymbol
   //
   TMagicStaticMethodSymbol = class(TMagicMethodSymbol)
      protected
         function GetInternalFunction : TInternalMagicFunction;
         procedure SetInternalFunction(const val : TInternalMagicFunction);

      public
         property InternalFunction : TInternalMagicFunction read GetInternalFunction write SetInternalFunction;
   end;

   // TMagicFuncExpr
   //
   TMagicFuncExpr = class(TFuncExprBase)
      private
         FInternalFunc : TInternalMagicFunction;

      public
         class function CreateMagicFuncExpr(context : TdwsCompilerContext;
                           const scriptPos : TScriptPos; magicFuncSym : TMagicFuncSymbol) : TMagicFuncExpr;

         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); virtual;

         function ExpectedArg : TParamSymbol; override;

         function IsWritable : Boolean; override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         procedure CompileTimeCheck(context : TdwsCompilerContext); override;

         property InternalFunc : TInternalMagicFunction read FInternalFunc;
   end;

   // TMagicVariantFuncExpr
   //
   TMagicVariantFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // TMagicInterfaceFuncExpr
   //
   TMagicInterfaceFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsInterfaceEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsInterface(exec : TdwsExecution; var Result : IUnknown); override;
   end;

   // TMagicDynArrayFuncExpr
   //
   TMagicDynArrayFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsDynArrayEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsInterface(exec : TdwsExecution; var Result : IUnknown); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   // TMagicProcedureExpr
   //
   TMagicProcedureExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicProcedureDoEvalEvent;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // TMagicDataFuncExpr
   //
   TMagicDataFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalDataEvent;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
   end;

   // Method with a FastCall (raw, low-level evaluation)
   TMagicMethodExpr = class (TMethodExpr)
      private
         FMagicSymbol : TMagicMethodSymbol;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            magicMethod : TMagicMethodSymbol;
                            baseExpr: TTypedExpr);

         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;

   TMagicMethodIntegerExpr = class (TMagicMethodExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TMagicMethodStringExpr = class (TMagicMethodExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;

   TMagicMethodBooleanExpr = class (TMagicMethodExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TMagicMethodFloatExpr = class (TMagicMethodExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   TMagicMethodNoResultExpr = class (TMagicMethodExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // TMagicIntFuncExpr
   //
   TMagicIntFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsIntegerEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // TMagicStringFuncExpr
   //
   TMagicStringFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsStringEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;

   // TMagicFloatFuncExpr
   //
   TMagicFloatFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsFloatEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   // TMagicBoolFuncExpr
   //
   TMagicBoolFuncExpr = class(TMagicFuncExpr)
      private
         FOnEval : TMagicFuncDoEvalAsBooleanEvent;
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            func : TFuncSymbol; internalFunc : TInternalMagicFunction); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // Inc/Dec/Succ/Pred
   TMagicIteratorFuncExpr = class(TMagicFuncExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                            left, right : TTypedExpr); reintroduce;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // result = Inc(left, right)
   TIncVarFuncExpr = class(TMagicIteratorFuncExpr)
      protected
         function DoInc(exec : TdwsExecution) : Int64;
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   // result = Dec(left, right)
   TDecVarFuncExpr = class(TMagicIteratorFuncExpr)
      protected
         function DoDec(exec : TdwsExecution) : Int64;
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   // result = Succ(left, right)
   TSuccFuncExpr = class(TMagicIteratorFuncExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   // result = Pred(left, right)
   TPredFuncExpr = class(TMagicIteratorFuncExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

procedure RegisterInternalInterfaceFunction(InternalFunctionClass: TInternalMagicInterfaceFunctionClass;
      const FuncName: String; const FuncParams: array of String; const funcType : String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
procedure RegisterInternalIntFunction(InternalFunctionClass: TInternalMagicIntFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
procedure RegisterInternalBoolFunction(InternalFunctionClass: TInternalMagicBoolFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
procedure RegisterInternalFloatFunction(InternalFunctionClass: TInternalMagicFloatFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
procedure RegisterInternalStringFunction(InternalFunctionClass: TInternalMagicStringFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses dwsCompilerUtils, dwsCoreExprs;

// RegisterInternalInterfaceFunction
//
procedure RegisterInternalInterfaceFunction(InternalFunctionClass: TInternalMagicInterfaceFunctionClass;
      const FuncName: String; const FuncParams: array of String; const funcType : String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
begin
   RegisterInternalFunction(InternalFunctionClass, FuncName, FuncParams, funcType, flags, helperName);
end;

// RegisterInternalIntFunction
//
procedure RegisterInternalIntFunction(InternalFunctionClass: TInternalMagicIntFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
begin
   RegisterInternalFunction(InternalFunctionClass, FuncName, FuncParams, SYS_INTEGER, flags, helperName);
end;

// RegisterInternalBoolFunction
//
procedure RegisterInternalBoolFunction(InternalFunctionClass: TInternalMagicBoolFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
begin
   RegisterInternalFunction(InternalFunctionClass, FuncName, FuncParams, SYS_BOOLEAN, flags, helperName);
end;

// RegisterInternalFloatFunction
//
procedure RegisterInternalFloatFunction(InternalFunctionClass: TInternalMagicFloatFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
begin
   RegisterInternalFunction(InternalFunctionClass, FuncName, FuncParams, SYS_FLOAT, flags, helperName);
end;

// RegisterInternalStringFunction
//
procedure RegisterInternalStringFunction(InternalFunctionClass: TInternalMagicStringFunctionClass;
      const FuncName: String; const FuncParams: array of String;
      const flags : TInternalFunctionFlags = []; const helperName : String = '');
begin
   RegisterInternalFunction(InternalFunctionClass, FuncName, FuncParams, SYS_STRING, flags, helperName);
end;

// ------------------
// ------------------ TMagicFuncSymbol ------------------
// ------------------

procedure TMagicFuncSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   FInternalParams.Initialize(msgs);
end;

// IsType
//
function TMagicFuncSymbol.IsType : Boolean;
begin
   Result:=False;
end;

// QualifiedName
//
function TMagicFuncSymbol.QualifiedName : String;
begin
   Result := inherited QualifiedName;
   if Result = '' then
      Result := FInternalFunction.QualifiedName;
end;

// Destroy
//
destructor TMagicFuncSymbol.Destroy;
begin
   FInternalFunction.Free;
   FInternalFunction:=nil;
   inherited;
end;

// ------------------
// ------------------ TMagicMethodSymbol ------------------
// ------------------

// Initialize
//
procedure TMagicMethodSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   FInternalParams.Initialize(msgs);
end;

// IsType
//
function TMagicMethodSymbol.IsType : Boolean;
begin
   Result:=False;
end;

// Destroy
//
destructor TMagicMethodSymbol.Destroy;
begin
   FInternalFunction.Free;
   FInternalFunction:=nil;
   inherited;
end;

// ------------------
// ------------------ TInternalMagicFunction ------------------
// ------------------

// Create
//
constructor TInternalMagicFunction.Create(table : TSymbolTable;
      const funcName : String; const params : TParamArray; const funcType : String;
      const flags : TInternalFunctionFlags;
      compositeSymbol : TCompositeTypeSymbol;
      const helperName : String);
var
   sym : TMagicFuncSymbol;
   ssym : TMagicStaticMethodSymbol;
begin
   inherited Create;
   FHelperName := helperName;
   if iffStaticMethod in flags then begin
      ssym:=TMagicStaticMethodSymbol.Generate(table, mkClassMethod, [maStatic],
                                              funcName, params, funcType,
                                              compositeSymbol,
                                              cvPublic, (iffOverloaded in flags));
      ssym.InternalFunction:=Self;
      ssym.IsStateless:=(iffStateLess in flags);
      ssym.IsExternal:=True;
      compositeSymbol.AddMethod(ssym);
      Assert(helperName=''); // unsupported
      Self.FuncSymbol := ssym;
      if iffDeprecated in flags then
         ssym.DeprecatedMessage := MSG_DeprecatedEmptyMsg;
   end else begin
      sym:=TMagicFuncSymbol.Generate(table, funcName, params, funcType);
      sym.params.AddParent(table);
      sym.InternalFunction:=Self;
      sym.IsStateless:=(iffStateLess in flags);
      sym.IsOverloaded:=(iffOverloaded in flags);
      table.AddSymbol(sym);
      Self.FuncSymbol := sym;
      if helperName<>'' then
         CompilerUtils.AddProcHelper(helperName, table, sym, nil);
      if iffDeprecated in flags then
         sym.DeprecatedMessage := MSG_DeprecatedEmptyMsg;
   end;
end;

// Call
//
procedure TInternalMagicFunction.Call(exec: TdwsProgramExecution; func: TFuncSymbol);
begin
   Assert(False);
end;

// QualifiedName
//
function TInternalMagicFunction.QualifiedName : String;
begin
   Result := FuncSymbol.Name;
   if Result = '' then begin
      Assert(FuncSymbol.Params.Count > 0);
      Assert(FHelperName <> '');
      Result := FuncSymbol.Params[0].Typ.Name + '$' + FHelperName;
   end;
end;

// ------------------
// ------------------ TMagicFuncExpr ------------------
// ------------------

// CreateMagicFuncExpr
//
class function TMagicFuncExpr.CreateMagicFuncExpr(context : TdwsCompilerContext;
         const scriptPos : TScriptPos; magicFuncSym : TMagicFuncSymbol) : TMagicFuncExpr;
var
   internalFunc : TInternalMagicFunction;
begin
   internalFunc:=magicFuncSym.InternalFunction;
   Result:=internalFunc.MagicFuncExprClass.Create(context, scriptPos, magicFuncSym, internalFunc);
end;

// Create
//
constructor TMagicFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                  func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(scriptPos, func);
end;

// ExpectedArg
//
function TMagicFuncExpr.ExpectedArg : TParamSymbol;
begin
   if FArgs.Count<FuncSym.Params.Count then
      Result:=(FuncSym.Params[FArgs.Count] as TParamSymbol)
   else Result:=nil;
end;

// IsWritable
//
function TMagicFuncExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// GetDataPtr
//
procedure TMagicFuncExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.DataContext_CreateBase(FResultAddr, Result);
end;

// CompileTimeCheck
//
procedure TMagicFuncExpr.CompileTimeCheck(context : TdwsCompilerContext);
begin
   TMagicFuncSymbol(FuncSym).InternalFunction.CompileTimeCheck(context, Self);
end;

// ------------------
// ------------------ TMagicVariantFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicVariantFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                         func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicVariantFunction).DoEvalAsVariant;
end;

// EvalAsVariant
//
procedure TMagicVariantFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicInterfaceFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicInterfaceFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                           func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicInterfaceFunction).DoEvalAsInterface;
end;

// EvalAsVariant
//
procedure TMagicInterfaceFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   intf : IUnknown;
begin
   EvalAsInterface(exec, intf);
   VarCopySafe(Result, intf);
end;

// EvalAsInterface
//
procedure TMagicInterfaceFuncExpr.EvalAsInterface(exec : TdwsExecution; var Result : IUnknown);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicDynArrayFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicDynArrayFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                          func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval := (internalFunc as TInternalMagicDynArrayFunction).DoEvalAsDynArray;
end;

// EvalAsVariant
//
procedure TMagicDynArrayFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   VarCopySafe(Result, dyn);
end;

// EvalAsInterface
//
procedure TMagicDynArrayFuncExpr.EvalAsInterface(exec : TdwsExecution; var Result : IUnknown);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   Result := dyn;
end;

// EvalAsScriptDynArray
//
procedure TMagicDynArrayFuncExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicDataFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicDataFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                      func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicDataFunction).DoEval;
   InitializeResultAddr(context.Prog as TdwsProgram);
end;

// EvalNoResult
//
procedure TMagicDataFuncExpr.EvalNoResult(exec : TdwsExecution);
var
   buf : IDataContext;
begin
   GetDataPtr(exec, buf);
end;

// EvalAsVariant
//
procedure TMagicDataFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   buf : IDataContext;
begin
   GetDataPtr(exec, buf);
   buf.EvalAsVariant(0, Result);
end;

// GetDataPtr
//
procedure TMagicDataFuncExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      exec.DataContext_CreateBase(FResultAddr, Result);
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicMethodExpr ------------------
// ------------------

// Create
//
constructor TMagicMethodExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                    magicMethod : TMagicMethodSymbol;  baseExpr: TTypedExpr);
begin
   inherited Create(context, scriptPos, magicMethod, baseExpr);
   FMagicSymbol := magicMethod;
end;

// EvalAsVariant
//
procedure TMagicMethodExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      result := FMagicSymbol.OnFastEval(BaseExpr, execRec);
   except
      RaiseScriptError(exec);
   end;
end;

// EvalNoResult
//
procedure TMagicMethodExpr.EvalNoResult(exec : TdwsExecution);
var
   v : Variant;
begin
   EvalAsVariant(exec, v);
end;

// EvalAsInteger
//
function TMagicMethodExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   v : Variant;
begin
   EvalAsVariant(exec, v);
   Result := VariantToInt64(v);
end;

// EvalAsFloat
//
function TMagicMethodExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   v : Variant;
begin
   EvalAsVariant(exec, v);
   Result := VariantToFloat(v);
end;

// EvalAsBoolean
//
function TMagicMethodExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   v : Variant;
begin
   EvalAsVariant(exec, v);
   Result := VariantToBool(v);
end;

// EvalAsString
//
procedure TMagicMethodExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   v : Variant;
begin
   EvalAsVariant(exec, v);
   VariantToString(v, Result);
end;

// ------------------
// ------------------ TMagicMethodIntegerExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMagicMethodIntegerExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   VarCopySafe(result, EvalAsInteger(exec));
end;

// EvalNoResult
//
procedure TMagicMethodIntegerExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsInteger(exec);
end;

// EvalAsInteger
//
function TMagicMethodIntegerExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec := FArgs;
   execRec.Exec := exec;
   execRec.Expr := Self;
   try
      Result := FMagicSymbol.OnFastEvalInteger(BaseExpr, execRec);
   except
      RaiseScriptError(exec);
      Result := 0;
   end;
end;

// ------------------
// ------------------ TMagicMethodStringExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMagicMethodStringExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   s : String;
begin
   EvalAsString(exec, s);
   VarCopySafe(result, s);
end;

// EvalNoResult
//
procedure TMagicMethodStringExpr.EvalNoResult(exec : TdwsExecution);
var
   s : String;
begin
   EvalAsString(exec, s);
end;

// EvalAsString
//
procedure TMagicMethodStringExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec := FArgs;
   execRec.Exec := exec;
   execRec.Expr := Self;
   try
      FMagicSymbol.OnFastEvalString(BaseExpr, execRec, result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicMethodBooleanExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMagicMethodBooleanExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   VarCopySafe(result, EvalAsBoolean(exec));
end;

// EvalNoResult
//
procedure TMagicMethodBooleanExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsBoolean(exec);
end;

// EvalAsBoolean
//
function TMagicMethodBooleanExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec := FArgs;
   execRec.Exec := exec;
   execRec.Expr := Self;
   try
      Result := FMagicSymbol.OnFastEvalBoolean(BaseExpr, execRec);
   except
      RaiseScriptError(exec);
      Result := False;
   end;
end;

// ------------------
// ------------------ TMagicMethodFloatExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMagicMethodFloatExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   VarCopySafe(result, EvalAsFloat(exec));
end;

// EvalNoResult
//
procedure TMagicMethodFloatExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsFloat(exec);
end;

// EvalAsFloat
//
function TMagicMethodFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec := FArgs;
   execRec.Exec := exec;
   execRec.Expr := Self;
   try
      Result := FMagicSymbol.OnFastEvalFloat(BaseExpr, execRec);
   except
      RaiseScriptError(exec);
      Result := 0;
   end;
end;

// ------------------
// ------------------ TMagicMethodNoResultExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMagicMethodNoResultExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   EvalNoResult(exec);
   VarClearSafe(result);
end;

// EvalNoResult
//
procedure TMagicMethodNoResultExpr.EvalNoResult(exec : TdwsExecution);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec := FArgs;
   execRec.Exec := exec;
   execRec.Expr := Self;
   try
      FMagicSymbol.OnFastEvalNoResult(BaseExpr, execRec);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicIntFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicIntFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                     func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicIntFunction).DoEvalAsInteger;
end;

// EvalNoResult
//
procedure TMagicIntFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsInteger(exec);
end;

// EvalAsVariant
//
procedure TMagicIntFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsInteger(exec));
end;

// EvalAsInteger
//
function TMagicIntFuncExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      Result:=FOnEval(execRec);
   except
      RaiseScriptError(exec);
      Result := 0;
   end;
end;

// ------------------
// ------------------ TMagicStringFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicStringFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                        func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval := (internalFunc as TInternalMagicStringFunction).DoEvalAsString;
end;

// EvalNoResult
//
procedure TMagicStringFuncExpr.EvalNoResult(exec : TdwsExecution);
var
   buf : String;
begin
   EvalAsString(exec, buf);
end;

// EvalAsVariant
//
procedure TMagicStringFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   buf : String;
begin
   EvalAsString(exec, buf);
   VarCopySafe(Result, buf);
end;

// EvalAsString
//
procedure TMagicStringFuncExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicFloatFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicFloatFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                       func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicFloatFunction).DoEvalAsFloat;
end;

// EvalNoResult
//
procedure TMagicFloatFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsFloat(exec);
end;

// EvalAsVariant
//
procedure TMagicFloatFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsFloat(exec));
end;

// EvalAsFloat
//
function TMagicFloatFuncExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec, Result);
   except
      RaiseScriptError(exec);
   end;
end;

// ------------------
// ------------------ TMagicBoolFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicBoolFuncExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                      func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicBoolFunction).DoEvalAsBoolean;
end;

// EvalNoResult
//
procedure TMagicBoolFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsBoolean(exec);
end;

// EvalAsVariant
//
procedure TMagicBoolFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsBoolean(exec));
end;

// EvalAsBoolean
//
function TMagicBoolFuncExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      Result:=FOnEval(execRec);
   except
      RaiseScriptError(exec);
      Result := False;
   end;
end;

// ------------------
// ------------------ TMagicProcedureExpr ------------------
// ------------------

// Create
//
constructor TMagicProcedureExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                       func : TFuncSymbol; internalFunc : TInternalMagicFunction);
begin
   inherited Create(context, scriptPos, func, internalFunc);
   FOnEval:=(internalFunc as TInternalMagicProcedure).DoEvalProc;
end;

// EvalNoResult
//
procedure TMagicProcedureExpr.EvalNoResult(exec : TdwsExecution);
var
   execRec : TExprBaseListExec;
begin
   execRec.ListRec:=FArgs;
   execRec.Exec:=exec;
   execRec.Expr:=Self;
   try
      FOnEval(execRec);
   except
      RaiseScriptError(exec);
   end;
end;

// EvalAsVariant
//
procedure TMagicProcedureExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   EvalNoResult(exec);
end;

// ------------------
// ------------------ TMagicIteratorFuncExpr ------------------
// ------------------

// Create
//
constructor TMagicIteratorFuncExpr.Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                                          left, right : TTypedExpr);
begin
   inherited Create(context, aScriptPos, nil, nil);
   FTyp:=left.Typ;
   AddArg(left);
   AddArg(right);
end;

// EvalNoResult
//
procedure TMagicIteratorFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsInteger(exec);
end;

// EvalAsVariant
//
procedure TMagicIteratorFuncExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsInteger(exec));
end;

// ------------------
// ------------------ TIncVarFuncExpr ------------------
// ------------------

// DoInc
//
function TIncVarFuncExpr.DoInc(exec : TdwsExecution) : Int64;
var
   left : TDataExpr;
begin
   left := TDataExpr(FArgs.ExprBase[0]);
   Result := left.DataPtr[exec].IncInteger(0, FArgs.ExprBase[1].EvalAsInteger(exec));
end;

// EvalNoResult
//
procedure TIncVarFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   DoInc(exec);
end;

// EvalAsInteger
//
function TIncVarFuncExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := DoInc(exec);
end;

// ------------------
// ------------------ TDecVarFuncExpr ------------------
// ------------------

// DoDec
//
function TDecVarFuncExpr.DoDec(exec : TdwsExecution) : Int64;
var
   left : TDataExpr;
begin
   left := TDataExpr(FArgs.ExprBase[0]);
   Result := left.DataPtr[exec].IncInteger(0, -FArgs.ExprBase[1].EvalAsInteger(exec));
end;

// EvalNoResult
//
procedure TDecVarFuncExpr.EvalNoResult(exec : TdwsExecution);
begin
   DoDec(exec);
end;

// EvalAsInteger
//
function TDecVarFuncExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := DoDec(exec);
end;

// ------------------
// ------------------ TSuccFuncExpr ------------------
// ------------------

// EvalAsInteger
//
function TSuccFuncExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FArgs.ExprBase[0].EvalAsInteger(exec)+FArgs.ExprBase[1].EvalAsInteger(exec);
end;

// ------------------
// ------------------ TPredFuncExpr ------------------
// ------------------

// EvalAsInteger
//
function TPredFuncExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FArgs.ExprBase[0].EvalAsInteger(exec)-FArgs.ExprBase[1].EvalAsInteger(exec);
end;

// ------------------
// ------------------ TInternalMagicProcedure ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicProcedure.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicProcedureExpr;
end;

// ------------------
// ------------------ TInternalMagicDataFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicDataFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicDataFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicVariantFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicVariantFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicVariantFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicInterfaceFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicInterfaceFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicInterfaceFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicDynArrayFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicDynArrayFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result := TMagicDynArrayFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicIntFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicIntFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicIntFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicBoolFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicBoolFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicBoolFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicFloatFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicFloatFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicFloatFuncExpr;
end;

// ------------------
// ------------------ TInternalMagicStringFunction ------------------
// ------------------

// MagicFuncExprClass
//
function TInternalMagicStringFunction.MagicFuncExprClass : TMagicFuncExprClass;
begin
   Result:=TMagicStringFuncExpr;
end;

// ------------------
// ------------------ TMagicStaticMethodSymbol ------------------
// ------------------

// GetInternalFunction
//
function TMagicStaticMethodSymbol.GetInternalFunction : TInternalMagicFunction;
begin
   Result:=(inherited InternalFunction) as TInternalMagicFunction;
end;

// SetInternalFunction
//
procedure TMagicStaticMethodSymbol.SetInternalFunction(const val : TInternalMagicFunction);
begin
   inherited InternalFunction:=val;
end;

end.
