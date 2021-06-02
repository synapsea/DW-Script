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
unit dwsSymbols;

{$I dws.inc}

interface

uses SysUtils, Classes, System.Math, TypInfo,
   dwsErrors, dwsUtils, dwsDateTime, dwsScriptSource, dwsSpecialKeywords,
   dwsTokenTypes, dwsStack, dwsDataContext, dwsArrayMethodKinds
   {$ifdef FPC},LazUTF8{$endif};

type

   IScriptObj = interface;
   IScriptObjInterface = interface;
   IScriptDynArray = interface;
   IScriptAssociativeArray = interface;
   IExecutable = interface;

   PIScriptObj = ^IScriptObj;

   TdwsExecution = class;
   TExprBase = class;
   TSymbol = class;
   TBaseSymbol = class;
   TDataSymbol = class;
   TClassSymbol = class;
   TCompositeTypeSymbol = class;
   TStructuredTypeSymbol = class;
   TMethodSymbol = class;
   TFieldSymbol = class;
   TTypeSymbol = class;
   TParamSymbol = class;
   THelperSymbol = class;
   TOperatorSymbol = class;
   TPropertySymbol = class;
   TSymbolTable = class;
   TUnSortedSymbolTable = class;
   TdwsRuntimeMessageList = class;
   EScriptError = class;
   EScriptErrorClass = class of EScriptError;
   TFuncSymbol = class;
   TdwsBaseSymbolsContext = class;
   TPseudoMethodSymbol = class;

   TdwsExprLocation = record
      Expr : TExprBase;
      Prog : TObject;
      function Line : Integer; inline;
      function SourceName : String; inline;
      function Location : String;
   end;
   TdwsExprLocationArray = array of TdwsExprLocation;

   // Interface for external debuggers
   IDebugger = interface
      ['{8D534D14-4C6B-11D5-8DCB-0000216D9E86}']
      procedure StartDebug(exec : TdwsExecution);
      procedure DoDebug(exec : TdwsExecution; expr : TExprBase);
      procedure StopDebug(exec : TdwsExecution);
      procedure EnterFunc(exec : TdwsExecution; funcExpr : TExprBase);
      procedure LeaveFunc(exec : TdwsExecution; funcExpr : TExprBase);
      function  LastDebugStepExpr : TExprBase;
      procedure DebugMessage(const msg : String);
      procedure NotifyException(exec : TdwsExecution; const exceptObj : IScriptObj);
   end;

   TProgramState = (psUndefined, psReadyToRun, psRunning, psRunningStopped, psTerminated);

   // Attached and owned by its program execution
   IdwsEnvironment = interface (IGetSelf)
      ['{CCAA438D-76F4-49C2-A3A2-82445BC2976A}']
   end;

   IdwsExecution = interface (dwsUtils.IGetSelf)
      ['{8F2D1D7E-9954-4391-B919-86EF1EE21C8C}']
      function GetMsgs : TdwsRuntimeMessageList;
      function  GetDebugger : IDebugger;
      procedure SetDebugger(const aDebugger : IDebugger);
      function GetExecutionObject : TdwsExecution;
      function GetUserObject : TObject;
      procedure SetUserObject(const value : TObject);
      function GetStack : TStack;
      function GetProgramState : TProgramState;
      function GetSleeping : Boolean;

      function GetCallStack : TdwsExprLocationArray;
      function GetLastScriptErrorExpr : TExprBase;

      procedure SuspendDebug;
      procedure ResumeDebug;

      function GetEnvironment : IdwsEnvironment;
      procedure SetEnvironment(const env : IdwsEnvironment);

      property ProgramState : TProgramState read GetProgramState;
      property Sleeping : Boolean read GetSleeping;
      property Stack : TStack read GetStack;
      property Msgs : TdwsRuntimeMessageList read GetMsgs;
      property Debugger : IDebugger read GetDebugger write SetDebugger;
      property ExecutionObject : TdwsExecution read GetExecutionObject;
      property UserObject : TObject read GetUserObject write SetUserObject;
      property Environment : IdwsEnvironment read GetEnvironment write SetEnvironment;
   end;

   ISpecializationContext = interface (IGetSelf)
      ['{88E5D42F-5E6E-4DFC-B32E-258333B5A6E7}']
      function Specialize(sym : TSymbol) : TSymbol;
      function SpecializeType(typ : TTypeSymbol) : TTypeSymbol;
      function SpecializeDataSymbol(ds : TDataSymbol) : TDataSymbol;
      function SpecializeField(fld : TFieldSymbol) : TFieldSymbol;
      procedure SpecializeTable(source, destination : TSymbolTable);
      function SpecializeExecutable(const exec : IExecutable) : IExecutable;

      procedure RegisterSpecialization(generic, specialized : TSymbol);

      function  SpecializedObject(obj : TRefCountedObject) : TRefCountedObject;
      procedure RegisterSpecializedObject(generic, specialized : TRefCountedObject);

      procedure RegisterInternalType(sym : TSymbol);

      procedure AddCompilerHint(const msg : String);
      procedure AddCompilerError(const msg : String);
      procedure AddCompilerErrorFmt(const msgFmt : String; const params : array of const); overload;
      procedure AddCompilerErrorFmt(const aScriptPos : TScriptPos; const msgFmt : String;
                                    const params : array of const); overload;

      function Name : String;
      function Parameters : TUnSortedSymbolTable;
      function Values : TUnSortedSymbolTable;
      function UnitSymbol : TSymbol;
      function Msgs : TdwsCompileMessageList;
      function Optimize : Boolean;
      function BaseSymbols : TdwsBaseSymbolsContext;

      procedure EnterComposite(sym : TCompositeTypeSymbol);
      procedure LeaveComposite;
      function  CompositeSymbol : TCompositeTypeSymbol;

      procedure EnterFunction(funcSym : TFuncSymbol);
      procedure LeaveFunction;
      function  FuncSymbol : TFuncSymbol;
   end;

   TRuntimeErrorMessage = class(TErrorMessage)
      private
         FCallStack : TdwsExprLocationArray;

      public
         function AsInfo: String; override;

         property CallStack : TdwsExprLocationArray read FCallStack;
   end;

   // TdwsRuntimeMessageList
   //
   TdwsRuntimeMessageList = class (TdwsMessageList)
      public
         procedure AddRuntimeError(const Text: String); overload;
         procedure AddRuntimeError(e : Exception); overload;
         procedure AddRuntimeError(const scriptPos : TScriptPos; const Text: String;
                                   const callStack : TdwsExprLocationArray); overload;
   end;

   TExecutionStatusResult = (esrNone, esrExit, esrBreak, esrContinue);

   TExprBaseProc = procedure (expr : TExprBase) of object;
   TExprBaseEnumeratorProc = procedure (parent, expr : TExprBase; var abort : Boolean) of object;

   // Is thrown by "raise" statements in script code
   EScriptException = class(Exception)
      private
         FExceptObj : IScriptObj;
         FScriptPos : TScriptPos;
         FScriptCallStack : TdwsExprLocationArray;

      public
         constructor Create(const msgString : String; const anExceptionObj : IScriptObj;
                            const aScriptPos: TScriptPos); overload;

         property ExceptionObj : IScriptObj read FExceptObj;
         property ScriptPos : TScriptPos read FScriptPos write FScriptPos;
         property ScriptCallStack : TdwsExprLocationArray read FScriptCallStack write FScriptCallStack;
   end;

   // Is thrown by failed Assert() statements in script code
   EScriptAssertionFailed = class(EScriptException)
   end;
   // Base class for all Exprs

   { TExprBase }

   TExprBaseClass = class of TExprBase;

   TExprBase = class (TRefCountedObject)
      protected
         function GetSubExpr(i : Integer) : TExprBase; virtual;
         function GetSubExprCount : Integer; virtual;

         function  GetIsConstant : Boolean; virtual;

      public
         function  IsConstant : Boolean; inline;

         function  Eval(exec : TdwsExecution) : Variant; deprecated 'Use appropriate EvalAsXxx instead';
         function  EvalAsInteger(exec : TdwsExecution) : Int64; virtual; abstract;
         function  EvalAsBoolean(exec : TdwsExecution) : Boolean; virtual; abstract;
         function  EvalAsFloat(exec : TdwsExecution) : Double; virtual; abstract;
         procedure EvalAsString(exec : TdwsExecution; var result : String); overload; virtual; abstract;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); overload; virtual; abstract;
         procedure EvalAsInterface(exec : TdwsExecution; var result : IUnknown); virtual; abstract;
         procedure EvalAsScriptObj(exec : TdwsExecution; var result : IScriptObj); virtual; abstract;
         procedure EvalAsScriptObjInterface(exec : TdwsExecution; var result : IScriptObjInterface); virtual; abstract;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); virtual; abstract;
         procedure EvalAsScriptAssociativeArray(exec : TdwsExecution; var result : IScriptAssociativeArray); virtual; abstract;
         procedure EvalNoResult(exec : TdwsExecution); virtual;

         procedure EvalAsSafeScriptObj(exec : TdwsExecution; var result : IScriptObj); overload;
         function  EvalAsSafeScriptObj(exec : TdwsExecution) : IScriptObj; overload; inline;

         procedure AssignValue(exec : TdwsExecution; const value : Variant); virtual; abstract;
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); virtual; abstract;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); virtual; abstract;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); virtual; abstract;
         procedure AssignValueAsString(exec : TdwsExecution; const value : String); virtual; abstract;
         procedure AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj); virtual; abstract;
         procedure AssignValueAsScriptDynArray(exec : TdwsExecution; const value : IScriptDynArray); virtual; abstract;

         property SubExpr[i : Integer] : TExprBase read GetSubExpr;
         property SubExprCount : Integer read GetSubExprCount;

         function ScriptPos : TScriptPos; virtual; abstract;
         function ScriptLocation(prog : TObject) : String; virtual; abstract;

         function FuncSymQualifiedName :String; virtual;
         class function CallStackToString(const callStack : TdwsExprLocationArray) : String; static;

         // returns True if aborted
         function RecursiveEnumerateSubExprs(const callback : TExprBaseEnumeratorProc) : Boolean;
         function ReferencesVariable(varSymbol : TDataSymbol) : Boolean; virtual;
         function IndexOfSubExpr(expr : TExprBase) : Integer;

         procedure RaiseScriptError(exec : TdwsExecution; e : EScriptError); overload;
         procedure RaiseScriptError(exec : TdwsExecution); overload;
         procedure RaiseScriptError(exec : TdwsExecution; const msg : String); overload;
         procedure RaiseScriptError(exec : TdwsExecution; exceptClass : EScriptErrorClass; const msg : String); overload;
         procedure RaiseScriptError(exec : TdwsExecution; exceptClass : EScriptErrorClass; const msg : String;
                                    const args : array of const); overload;

         procedure RaiseObjectNotInstantiated(exec : TdwsExecution);
         procedure RaiseObjectAlreadyDestroyed(exec : TdwsExecution);

         function  Specialize(const context : ISpecializationContext) : TExprBase; virtual;
   end;

   // All functions callable from the script implement this interface
   IExecutable = interface (IGetSelf)
      ['{8D534D18-4C6B-11D5-8DCB-0000216D9E86}']
      procedure InitSymbol(symbol : TSymbol; const msgs : TdwsCompileMessageList);
      procedure InitExpression(expr : TExprBase);
      function SubExpr(i : Integer) : TExprBase;
      function SubExprCount : Integer;
      function Specialize(const context : ISpecializationContext) : IExecutable;
   end;

   IBooleanEvalable = interface (IExecutable)
      ['{C984224C-92FC-41EF-845A-CE5CA0F8C77D}']
      function EvalAsBoolean(exec : TdwsExecution) : Boolean;
   end;

   IStringEvalable = interface (IExecutable)
      ['{6D0552ED-6FBD-4BC7-AADA-8D8F8DBDF29B}']
      procedure EvalAsString(exec : TdwsExecution; var Result : String);
   end;

   TAddrGeneratorSign = (agsPositive, agsNegative);

   // TAddrGenerator
   //
   TAddrGeneratorRec = record
      private
         FLevel : SmallInt;
         FSign : TAddrGeneratorSign;

      public
         DataSize : Integer;

         class function CreatePositive(aLevel : SmallInt; anInitialSize : Integer = 0) : TAddrGeneratorRec; static;
         class function CreateNegative(aLevel : SmallInt) : TAddrGeneratorRec; static;

         function GetStackAddr(size : Integer) : Integer;

         property Level : SmallInt read FLevel;
   end;
   TAddrGenerator = ^TAddrGeneratorRec;

   TdwsVisibility = (cvMagic, cvPrivate, cvProtected, cvPublic, cvPublished);
   TdwsVisibilities = set of TdwsVisibility;

   // TSymbol
   //
   // Named item in the script
   TSymbol = class (TRefCountedObject)
      private
         FName : String;

      protected
         FTyp : TTypeSymbol;
         FSize : Integer;

         function SafeGetCaption : String;
         function GetCaption : String; virtual;
         function GetDescription : String; virtual;
         function GetAsFuncSymbol : TFuncSymbol; virtual;
         function GetIsGeneric : Boolean; virtual;

      public
         constructor Create(const aName : String; aType : TTypeSymbol);

         procedure Initialize(const msgs : TdwsCompileMessageList); virtual;
         function  BaseType : TTypeSymbol; virtual;
         procedure SetName(const newName : String; force : Boolean = False);

         class function IsBaseType : Boolean; virtual;
         function IsType : Boolean; virtual;
         function IsPointerType : Boolean; virtual;
         function AsFuncSymbol : TFuncSymbol; overload;
         function AsFuncSymbol(var funcSym : TFuncSymbol) : Boolean; overload;
         function IsGeneric : Boolean;

         function QualifiedName : String; virtual;

         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; virtual;

         function Specialize(const context : ISpecializationContext) : TSymbol; virtual;

         property Caption : String read SafeGetCaption;
         property Description : String read GetDescription;
         property Name : String read FName;
         property Typ : TTypeSymbol read FTyp write FTyp;
         property Size : Integer read FSize;
   end;

   TSymbolClass = class of TSymbol;

   // return True to abort
   TSymbolEnumerationCallback = function (symbol : TSymbol) : Boolean of object;

   THelperSymbolEnumerationCallback = function (helper : THelperSymbol) : Boolean of object;

   TOperatorSymbolEnumerationCallback = function (opSym : TOperatorSymbol) : Boolean of object;

   TSymbolTableFlag = (stfSorted,
                       stfHasChildTables, stfHasHelpers,
                       stfHasLocalOperators, stfHasParentOperators, stfHasOperators);
   TSymbolTableFlags = set of TSymbolTableFlag;

   TSimpleSymbolList = TSimpleList<TSymbol>;

   // A table of symbols connected to other symboltables (property Parents)
   TSymbolTable = class (TRefCountedObject)
      private
         FAddrGenerator : TAddrGenerator;
         FSymbols : TTightList;
         FParents : TTightList;
         FFlags : TSymbolTableFlags;

         function GetParentCount : Integer;
         function GetParents(Index: Integer) : TSymbolTable; inline;

      protected
         function GetSymbol(Index: Integer): TSymbol; inline;
         function GetCount : Integer; inline;

         procedure SortSymbols(minIndex, maxIndex : Integer);

      public
         constructor Create(parent : TSymbolTable = nil; addrGenerator : TAddrGenerator = nil);
         destructor Destroy; override;

         procedure InsertParent(index : Integer; parent : TSymbolTable); virtual;
         function RemoveParent(parent : TSymbolTable) : Integer; virtual;
         function IndexOfParent(parent : TSymbolTable) : Integer;
         procedure MoveParent(curIndex, newIndex : Integer);
         procedure ClearParents; virtual;
         procedure AddParent(parent : TSymbolTable);

         function AddSymbol(sym : TSymbol): Integer;
         function AddSymbolDirect(sym : TSymbol) : Integer;
         function FindLocal(const aName : String; ofClass : TSymbolClass = nil) : TSymbol; virtual;
         function FindTypeLocal(const aName : String) : TTypeSymbol;
         function FindSymbolAtStackAddr(const stackAddr, level : Integer) : TDataSymbol;
         function Remove(sym : TSymbol): Integer;
         procedure Clear;

         procedure TransferSymbolsTo(destTable : TSymbolTable);

         function FindSymbol(const aName : String; minVisibility : TdwsVisibility;
                             ofClass : TSymbolClass = nil) : TSymbol; virtual;
         function FindTypeSymbol(const aName : String; minVisibility : TdwsVisibility) : TTypeSymbol;

         // returns True if aborted
         function EnumerateLocalSymbolsOfName(const aName : String;
                              const callback : TSymbolEnumerationCallback) : Boolean; virtual;
         function EnumerateSymbolsOfNameInScope(const aName : String;
                              const callback : TSymbolEnumerationCallback) : Boolean; virtual;

         function EnumerateLocalHelpers(helpedType : TTypeSymbol;
                              const callback : THelperSymbolEnumerationCallback) : Boolean; virtual;
         function EnumerateHelpers(helpedType : TTypeSymbol;
                              const callback : THelperSymbolEnumerationCallback) : Boolean; virtual;

         function EnumerateLocalOperatorsFor(aToken : TTokenType; aLeftType, aRightType : TTypeSymbol;
                                             const callback : TOperatorSymbolEnumerationCallback) : Boolean; virtual;
         function EnumerateOperatorsFor(aToken : TTokenType; aLeftType, aRightType : TTypeSymbol;
                                        const callback : TOperatorSymbolEnumerationCallback) : Boolean; virtual;
         function FindImplicitCastOperatorFor(fromType, toType : TTypeSymbol) : TOperatorSymbol; virtual;
         function HasSameLocalOperator(anOpSym : TOperatorSymbol) : Boolean; virtual;
         function HasOperators : Boolean; inline;

         procedure CollectPublishedSymbols(symbolList : TSimpleSymbolList); virtual;

         function HasChildTables : Boolean; inline;
         function HasClass(const aClass : TSymbolClass) : Boolean;
         function HasSymbol(sym : TSymbol) : Boolean;
         function HasMethods : Boolean;
         class function IsUnitTable : Boolean; virtual;

         procedure Initialize(const msgs : TdwsCompileMessageList); virtual;

         property AddrGenerator : TAddrGenerator read FAddrGenerator;
         property Count : Integer read GetCount;
         property Symbols[x : Integer] : TSymbol read GetSymbol; default;
         property ParentCount : Integer read GetParentCount;
         property Parents[Index : Integer] : TSymbolTable read GetParents;

         type
            TSymbolTableEnumerator = record
               Index : Integer;
               Table : TSymbolTable;
               function MoveNext : Boolean;
               function GetCurrent : TSymbol;
               property Current : TSymbol read GetCurrent;
            end;
         function GetEnumerator : TSymbolTableEnumerator;
   end;

   TSymbolTableClass = class of TSymbolTable;

   // TUnSortedSymbolTable
   //
   TUnSortedSymbolTable = class (TSymbolTable)
      public
         function FindLocal(const aName : String; ofClass : TSymbolClass = nil) : TSymbol; override;
         function IndexOf(sym : TSymbol) : Integer;
   end;

   // TConditionsSymbolTable
   //
   TConditionsSymbolTable = class (TUnSortedSymbolTable)
   end;

   // TParamsSymbolTable
   //
   TParamsSymbolTable = class (TUnSortedSymbolTable)
      protected
         function GetSymbol(x : Integer) : TParamSymbol;

      public
         function Description(skip : Integer) : String;

         property Symbols[x : Integer] : TParamSymbol read GetSymbol; default;
   end;

   // TExpressionSymbolTable
   //
   TExpressionSymbolTable = class (TSymbolTable)
   end;

   // A resource string (hybrid between a constant and a function)
   TResourceStringSymbol = class sealed (TSymbol)
      private
         FValue : String;
         FIndex : Integer;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;

      public
         constructor Create(const aName, aValue : String);

         property Value : String read FValue;
         property Index : Integer read FIndex write FIndex;
   end;

   TResourceStringSymbolList = class(TSimpleList<TResourceStringSymbol>)
      public
         procedure ComputeIndexes;
   end;

   // All Symbols containing a value
   TValueSymbol = class (TSymbol)
      protected
         function GetCaption : String; override;
         function GetDescription : String; override;

      public
         constructor Create(const aName : String; aType : TTypeSymbol);
   end;

   // named constant: const x = 123;
   TConstSymbol = class (TValueSymbol)
      protected
         FData : TData;
         FDeprecatedMessage : String;

         function GetCaption : String; override;
         function GetDescription : String; override;
         function GetIsDeprecated : Boolean; inline;

      public
         constructor CreateValue(const name : String; typ : TTypeSymbol; const value : Variant); overload;
         constructor CreateData(const name : String; typ : TTypeSymbol; const data : TData); overload;

         procedure Initialize(const msgs : TdwsCompileMessageList); override;

         property Data : TData read FData;

         property DeprecatedMessage : String read FDeprecatedMessage write FDeprecatedMessage;
         property IsDeprecated : Boolean read GetIsDeprecated;
   end;
   TConstSymbolClass = class of TConstSymbol;

   // variable: var x: Integer;
   TDataSymbol = class (TValueSymbol)
      protected
         FExternalName : String;
         FStackAddr : Integer;
         FLevel : SmallInt;
         FUsedBySubLevel : Boolean;

         function GetDescription : String; override;
         function GetExternalName : String;

      public
         procedure AllocateStackAddr(generator : TAddrGenerator);

         function HasExternalName : Boolean;
         function IsWritable : Boolean; virtual;

         property ExternalName : String read GetExternalName write FExternalName;
         property Level : SmallInt read FLevel write FLevel;
         property UsedBySubLevel : Boolean read FUsedBySubLevel write FUsedBySubLevel;
         property StackAddr: Integer read FStackAddr write FStackAddr;
   end;

   TScriptDataSymbolPurpose = (
      sdspGeneral,         // general purpose / unspecified use case
      sdspLoopIterator     // iterator variable in a for loop
   );

   // used for script engine internal purposes
   TScriptDataSymbol = class sealed (TDataSymbol)
      private
         FPurpose : TScriptDataSymbolPurpose;

      public
         constructor Create(const aName : String; aType : TTypeSymbol; aPurpose : TScriptDataSymbolPurpose = sdspGeneral);
         function Specialize(const context : ISpecializationContext) : TSymbol; override;

         property Purpose : TScriptDataSymbolPurpose read FPurpose write FPurpose;
   end;

   // used for variables
   TVarDataSymbol = class sealed (TDataSymbol)
      public
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
   end;

   TParamSymbolSemantics = ( pssCopy, pssConst, pssVar, pssLazy );
   TParamSymbolOption = ( psoForbidImplicitCasts );
   TParamSymbolOptions = set of TParamSymbolOption;

   // parameter: procedure P(x: Integer);
   TParamSymbol = class (TDataSymbol)
      private
         FOptions : TParamSymbolOptions;

      protected
         function GetDescription : String; override;

      public
         constructor Create(const aName : String; aType : TTypeSymbol; options : TParamSymbolOptions = []);

         function Clone : TParamSymbol; virtual;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function SameParam(other : TParamSymbol) : Boolean; virtual;
         function Semantics : TParamSymbolSemantics; virtual;
         function ForbidImplicitCasts : Boolean;
   end;

   THasParamSymbolMethod = function (param : TParamSymbol) : Boolean of object;
   TAddParamSymbolMethod = procedure (param : TParamSymbol) of object;

   TParamSymbolWithDefaultValue = class sealed (TParamSymbol)
      private
         FDefaultValue : TData;

      protected
         function GetDescription : String; override;

      public
         constructor Create(const aName : String; aType : TTypeSymbol;
                            const data : TData; options : TParamSymbolOptions = []);

         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function SameParam(other : TParamSymbol) : Boolean; override;

         property DefaultValue : TData read FDefaultValue;
   end;

   // const/var parameter: procedure P(const/var x: Integer)
   TByRefParamSymbol = class(TParamSymbol)
      public
         constructor Create(const Name: String; Typ: TTypeSymbol);
         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
   end;

   // lazy parameter: procedure P(lazy x: Integer)
   TLazyParamSymbol = class sealed (TParamSymbol)
      public
         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function Semantics : TParamSymbolSemantics; override;
   end;

   // const parameter: procedure P(const(ref) x: Integer)
   TConstByRefParamSymbol = class sealed (TByRefParamSymbol)
      public
         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function IsWritable : Boolean; override;
         function Semantics : TParamSymbolSemantics; override;
   end;

   // const parameter: procedure P(const(copy) x: Integer)
   TConstByValueParamSymbol = class (TParamSymbol)
      public
         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function IsWritable : Boolean; override;
         function Semantics : TParamSymbolSemantics; override;
   end;

   // var parameter: procedure P(var x: Integer)
   TVarParamSymbol = class sealed (TByRefParamSymbol)
      public
         function Clone : TParamSymbol; override;
         function Specialize(const context : ISpecializationContext) : TSymbol; override;
         function Semantics : TParamSymbolSemantics; override;
   end;

   TTypeSymbolClass = class of TTypeSymbol;
   TTypeSymbols = array of TTypeSymbol;

   // Base class for all types
   TTypeSymbol = class(TSymbol)
      private
         FDeprecatedMessage : String;

      protected
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; virtual;

         function GetIsDeprecated : Boolean; inline;

      public
         procedure InitData(const data : TData; offset : Integer); virtual;
         procedure InitDataContext(const data : IDataContext); inline;
         procedure InitVariant(var v : Variant); virtual;
         function DynamicInitialization : Boolean; virtual;

         function IsType : Boolean; override;
         function BaseType : TTypeSymbol; override;
         function UnAliasedType : TTypeSymbol; virtual;
         function UnAliasedTypeIs(const typeSymbolClass : TTypeSymbolClass) : Boolean; inline;
         function IsOfType(typSym : TTypeSymbol) : Boolean;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; virtual;
         function CanExpectAnyFuncSymbol : Boolean; virtual;
         function IsCompatibleWithAnyFuncSymbol : Boolean; virtual;

         function DistanceTo(typeSym : TTypeSymbol) : Integer; virtual;
         // doesn't treat aliases of a type as the the same type,
         // but identical declarations are
         function SameType(typSym : TTypeSymbol) : Boolean; virtual;
         function HasMetaSymbol : Boolean; virtual;
         function IsForwarded : Boolean; virtual;
         function AssignsAsDataExpr : Boolean; virtual;

         function Specialize(const context : ISpecializationContext) : TSymbol; override; final;
         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; virtual;

         property DeprecatedMessage : String read FDeprecatedMessage write FDeprecatedMessage;
         property IsDeprecated : Boolean read GetIsDeprecated;
   end;

   TAnyTypeSymbol = class sealed (TTypeSymbol)
      public
         function  IsCompatible(typSym : TTypeSymbol) : Boolean; override;
   end;

   TFuncKind = (fkFunction, fkProcedure,
                fkConstructor, fkDestructor, fkMethod,
                fkLambda);

   // Record used for TFuncSymbol.Generate
   PParamRec = ^TParamRec;
   TParamRec = record
      ParamName : String;
      ParamType : String;
      IsVarParam : Boolean;
      IsConstParam : Boolean;
      HasDefaultValue : Boolean;
      Options : TParamSymbolOptions;
      DefaultValue : TData;
   end;
   TParamArray = array of TParamRec;

   // Condition, as part of contracts
   TConditionSymbol = class (TSymbol)
      private
         FScriptPos : TScriptPos;
         FCondition : IBooleanEvalable;
         FMessage : IStringEvalable;

      protected

      public
         constructor Create(const aScriptPos: TScriptPos; const cond : IBooleanEvalable; const msg : IStringEvalable);

         property ScriptPos : TScriptPos read FScriptPos write FScriptPos;
         property Condition : IBooleanEvalable read FCondition write FCondition;
         property Message : IStringEvalable read FMessage write FMessage;
   end;
   TConditionSymbolClass = class of TConditionSymbol;

   TPreConditionSymbol = class (TConditionSymbol)
      private

      protected

      public

   end;

   TPostConditionSymbol = class (TConditionSymbol)
      private

      protected

      public

   end;

   TClassInvariantSymbol = class (TConditionSymbol)
      private

      protected

      public

   end;

   TResultSymbol = class(TDataSymbol)
   end;

   TFuncSymbolFlag = (fsfStateless, fsfExternal, fsfType, fsfOverloaded, fsfLambda,
                      fsfInline, fsfProperty, fsfExport,
                      fsfOfObject, fsfReferenceTo, fsfAsync);
   TFuncSymbolFlags = set of TFuncSymbolFlag;

   // A script function / procedure: procedure X(param: Integer);
   TFuncSymbol = class (TTypeSymbol)
      protected
         FAddrGenerator : TAddrGeneratorRec;
         FExecutable : IExecutable;
         FInternalParams : TSymbolTable;
         FForwardPosition : PScriptPos;
         FParams : TParamsSymbolTable;
         FResult : TDataSymbol;
         FConditions : TConditionsSymbolTable;
         FFlags : TFuncSymbolFlags;
         FKind : TFuncKind;
         FExternalName : String;
         FExternalConvention: TTokenType;

         procedure SetType(const value : TTypeSymbol);

         function GetCaption : String; override;
         function GetDescription : String; override;
         function GetLevel : SmallInt; inline;
         function GetParamSize : Integer; inline;

         function GetIsStateless : Boolean; inline;
         procedure SetIsStateless(const val : Boolean); inline;
         function GetIsExternal : Boolean; inline;
         procedure SetIsExternal(const val : Boolean); inline;
         function GetIsExport : Boolean; inline;
         procedure SetIsExport(const val : Boolean); inline;
         function GetIsProperty : Boolean; inline;
         procedure SetIsProperty(const val : Boolean); inline;
         function GetIsOverloaded : Boolean; inline;
         procedure SetIsOverloaded(const val : Boolean); inline;
         function GetIsLambda : Boolean; inline;
         procedure SetIsLambda(const val : Boolean); inline;
         function GetIsOfObject : Boolean; inline;
         procedure SetIsOfObject(const val : Boolean); inline;
         function GetIsReferenceTo : Boolean; inline;
         procedure SetIsReferenceTo(const val : Boolean); inline;
         function GetIsAsync : Boolean; inline;
         procedure SetIsAsync(const val : Boolean); inline;

         function GetDeclarationPosition : TScriptPos; virtual;
         procedure SetDeclarationPosition(const val : TScriptPos); virtual;
         function GetImplementationPosition : TScriptPos; virtual;
         procedure SetImplementationPosition(const val : TScriptPos); virtual;

         function GetExternalName : String;

         function GetSourceSubExpr(i : Integer) : TExprBase;
         function GetSourceSubExprCount : Integer;

         function  DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

         procedure InternalSpecialize(destination : TFuncSymbol; const context : ISpecializationContext);

      public
         constructor Create(const name : String; funcKind : TFuncKind; funcLevel : SmallInt);
         destructor Destroy; override;

         constructor Generate(table : TSymbolTable; const funcName : String;
                              const funcParams : TParamArray; const funcType : String);
         function  IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function  IsType : Boolean; override;
         procedure SetIsType;
         function  GetAsFuncSymbol : TFuncSymbol; override;
         procedure SetInline;
         procedure AddParam(param : TParamSymbol);
         procedure AddParams(params : TParamsSymbolTable);
         function  HasParam(param : TParamSymbol) : Boolean;
         procedure GenerateParams(Table: TSymbolTable; const FuncParams: TParamArray);
         function  GetParamType(idx : Integer) : TTypeSymbol;
         function  ParamTypeForbidsImplicitCasts(idx : Integer) : Boolean;
         procedure Initialize(const msgs : TdwsCompileMessageList); override;
         procedure InitData(const data : TData; offset : Integer); override;
         procedure AddCondition(cond : TConditionSymbol);

         function  IsValidOverloadOf(other : TFuncSymbol) : Boolean;
         function  IsSameOverloadOf(other : TFuncSymbol) : Boolean; virtual;
         function  SameType(typSym : TTypeSymbol) : Boolean; override;

         function  ParamsDescription : String; virtual;

         procedure SetForwardedPos(const aScriptPos: TScriptPos);
         procedure ClearIsForwarded;

         property SubExpr[i : Integer] : TExprBase read GetSourceSubExpr;
         property SubExprCount : Integer read GetSourceSubExprCount;

         property Executable : IExecutable read FExecutable write FExecutable;
         property IsDeprecated : Boolean read GetIsDeprecated;
         property IsStateless : Boolean read GetIsStateless write SetIsStateless;
         function IsForwarded : Boolean; override;
         property IsOverloaded : Boolean read GetIsOverloaded write SetIsOverloaded;
         property IsExternal : Boolean read GetIsExternal write SetIsExternal;
         property IsExport : Boolean read GetIsExport write SetIsExport;
         property IsProperty : Boolean read GetIsProperty write SetIsProperty;
         property IsOfObject : Boolean read GetIsOfObject write SetIsOfObject;
         property IsReferenceTo : Boolean read GetIsReferenceTo write SetIsReferenceTo;
         property IsAsync : Boolean read GetIsAsync write SetIsAsync;
         property Kind : TFuncKind read FKind write FKind;
         property ExternalName : String read GetExternalName write FExternalName;
         function HasExternalName : Boolean;
         property ExternalConvention: TTokenType read FExternalConvention write FExternalConvention;
         property IsLambda : Boolean read GetIsLambda write SetIsLambda;
         property Level : SmallInt read GetLevel;
         property InternalParams : TSymbolTable read FInternalParams;
         property Params : TParamsSymbolTable read FParams;
         property ParamSize : Integer read FAddrGenerator.DataSize;
         property Result : TDataSymbol read FResult;
         property Typ : TTypeSymbol read FTyp write SetType;
         property Conditions : TConditionsSymbolTable read FConditions;

         property DeclarationPosition : TScriptPos read GetDeclarationPosition write SetDeclarationPosition;
         property ImplementationPosition : TScriptPos read GetImplementationPosition write SetImplementationPosition;
   end;

   // referring list of function symbols
   TFuncSymbolList = class(TSimpleList<TFuncSymbol>)
      public
         function ContainsChildMethodOf(methSym : TMethodSymbol) : Boolean;
   end;

   TAnyFuncSymbol = class(TFuncSymbol)
      public
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsCompatibleWithAnyFuncSymbol : Boolean; override;

         procedure Initialize(const msgs : TdwsCompileMessageList); override;
   end;

   TSourceFuncSymbol = class sealed (TFuncSymbol)
      private
         FDeclarationPosition : TScriptPos;
         FImplementationPosition : TScriptPos;

      protected
         function GetDeclarationPosition : TScriptPos; override;
         procedure SetDeclarationPosition(const val : TScriptPos); override;
         function GetImplementationPosition : TScriptPos; override;
         procedure SetImplementationPosition(const val : TScriptPos); override;

      public
         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         property SubExpr;
         property SubExprCount;
   end;

   // TSelfSymbol
   //
   TSelfSymbol = class sealed (TDataSymbol)
   end;

   TMethodKind = ( mkProcedure, mkFunction, mkConstructor, mkDestructor, mkMethod,
                   mkClassProcedure, mkClassFunction, mkClassMethod );
   TMethodAttribute = ( maVirtual, maOverride, maReintroduce, maAbstract,
                        maOverlap, maClassMethod, maFinal, maDefault, maInterfaced,
                        maStatic, maIgnoreMissingImplementation );
   TMethodAttributes = set of TMethodAttribute;

   // A method of a script class: TMyClass = class procedure X(param: String); end;
   TMethodSymbol = class (TFuncSymbol)
      private
         FStructSymbol : TCompositeTypeSymbol;
         FParentMeth : TMethodSymbol;
         FSelfSym : TDataSymbol;
         FVMTIndex : Integer;
         FVisibility : TdwsVisibility;
         FAttributes : TMethodAttributes;

      protected
         function GetIsClassMethod : Boolean;

         function GetIsOverride : Boolean; inline;
         procedure SetIsOverride(const val : Boolean); inline;
         function GetIsOverlap : Boolean; inline;
         procedure SetIsOverlap(const val : Boolean); inline;
         function GetIsVirtual : Boolean; inline;
         procedure SetIsVirtual(const val : Boolean);
         function GetIsAbstract : Boolean; inline;
         procedure SetIsAbstract(const val : Boolean); inline;
         function GetIsFinal : Boolean; inline;
         function GetIsInterfaced : Boolean; inline;
         procedure SetIsInterfaced(const val : Boolean); inline;
         function GetIsDefault : Boolean; inline;
         procedure SetIsDefault(const val : Boolean); inline;
         function GetIsStatic : Boolean; inline;
         function GetIgnoreMissingImplementation : Boolean;
         procedure SetIgnoreMissingImplementation(const val : Boolean);

         function GetCaption : String; override;
         function GetDescription : String; override;

         function GetRootParentMeth : TMethodSymbol;

      public
         constructor Create(const Name: String; FuncKind: TFuncKind; aStructSymbol : TCompositeTypeSymbol;
                            aVisibility : TdwsVisibility; isClassMethod : Boolean;
                            funcLevel : Integer = 1); virtual;
         constructor Generate(Table: TSymbolTable; MethKind: TMethodKind;
                              const Attributes: TMethodAttributes; const MethName: String;
                              const MethParams: TParamArray; const MethType: String;
                              Cls: TCompositeTypeSymbol; aVisibility : TdwsVisibility;
                              overloaded : Boolean);

         procedure SetOverride(meth: TMethodSymbol);
         procedure SetOverlap(meth: TMethodSymbol);
         procedure SetIsFinal;
         procedure SetIsStatic;
         procedure InitData(const data : TData; offset : Integer); override;
         function QualifiedName : String; override;
         function ParamsDescription : String; override;
         function HasConditions : Boolean;
         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; override;
         function IsSameOverloadOf(other : TFuncSymbol) : Boolean; override;

         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         property StructSymbol : TCompositeTypeSymbol read FStructSymbol;
         property VMTIndex : Integer read FVMTIndex;

         property IsDefault : Boolean read GetIsDefault write SetIsDefault;
         property IsAbstract : Boolean read GetIsAbstract write SetIsAbstract;
         property IsVirtual : Boolean read GetIsVirtual write SetIsVirtual;
         property IsOverride : Boolean read GetIsOverride;
         property IsInterfaced : Boolean read GetIsInterfaced write SetIsInterfaced;
         property IsFinal : Boolean read GetIsFinal;
         property IsOverlap : Boolean read GetIsOverlap;
         property IsClassMethod : Boolean read GetIsClassMethod;
         property IsStatic : Boolean read GetIsStatic;
         property ParentMeth : TMethodSymbol read FParentMeth;
         property RootParentMeth : TMethodSymbol read GetRootParentMeth;
         property SelfSym : TDataSymbol read FSelfSym;
         property Visibility : TdwsVisibility read FVisibility;
         property IgnoreMissingImplementation : Boolean read GetIgnoreMissingImplementation write SetIgnoreMissingImplementation;
   end;

   TMethodSymbolClass = class of TMethodSymbol;

   TMethodSymbolArray = array of TMethodSymbol;

   TSourceMethodSymbol = class (TMethodSymbol)
      private
         FDeclarationPosition : TScriptPos;
         FImplementationPosition : TScriptPos;

      protected
         function GetDeclarationPosition : TScriptPos; override;
         procedure SetDeclarationPosition(const val : TScriptPos); override;
         function GetImplementationPosition : TScriptPos; override;
         procedure SetImplementationPosition(const val : TScriptPos); override;

      public
         property SubExpr;
         property SubExprCount;
   end;

   TAliasMethodSymbol = class sealed (TSourceMethodSymbol)
      private
         FAlias : TFuncSymbol;

      protected
         function GetDeclarationPosition : TScriptPos; override;
         function GetImplementationPosition : TScriptPos; override;

      public
         function IsPointerType : Boolean; override;

         function ParamsDescription : String; override;

         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         property Alias : TFuncSymbol read FAlias write FAlias;
   end;

   TOperatorSymbol = class sealed (TSymbol)
      private
         FToken : TTokenType;
         FParams : TTypeSymbols;
         FUsesSym : TFuncSymbol;
         FOperatorExprClass : TExprBaseClass;
         FAssignExprClass : TExprBaseClass;

      protected
         function GetCaption : String; override;

      public
         constructor Create(const aTokenType : TTokenType);

         procedure AddParam(p : TTypeSymbol);

         property Token : TTokenType read FToken write FToken;
         property Params : TTypeSymbols read FParams;
         property UsesSym : TFuncSymbol read FUsesSym write FUsesSym;
         property OperatorExprClass : TExprBaseClass read FOperatorExprClass write FOperatorExprClass;
         property AssignExprClass : TExprBaseClass read FAssignExprClass write FAssignExprClass;
   end;

   // type x = TMyType;
   TAliasSymbol = class sealed (TTypeSymbol)
      protected
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;
         function GetAsFuncSymbol : TFuncSymbol; override;
         function GetDescription : String; override;

      public
         function BaseType : TTypeSymbol; override;
         function UnAliasedType : TTypeSymbol; override;
         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsPointerType : Boolean; override;
   end;

   // integer/String/float/boolean/variant
   TBaseSymbol = class(TTypeSymbol)
      public
         constructor Create(const name : String);

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         class function IsBaseType : Boolean; override;

         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;
   end;

   TBaseIntegerSymbol = class (TBaseSymbol)
      public
         constructor Create;

         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
   end;

   TBaseFloatSymbol = class (TBaseSymbol)
      public
         constructor Create;

         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;
   end;

   TBaseStringSymbol = class (TBaseSymbol)
      private
         FLengthPseudoSymbol : TPseudoMethodSymbol;
         FHighPseudoSymbol : TPseudoMethodSymbol;
         FLowPseudoSymbol : TPseudoMethodSymbol;

         function InitPseudoSymbol(var p : TPseudoMethodSymbol; sk : TSpecialKeywordKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;

      public
         constructor Create;
         destructor Destroy; override;

         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;

         function LengthPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; inline;
         function HighPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; inline;
         function LowPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; inline;
   end;

   TBaseBooleanSymbol = class (TBaseSymbol)
      public
         constructor Create;

         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;
   end;

   TBaseVariantSymbol = class (TBaseSymbol)
      public
         constructor Create(const name : String = '');

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         procedure InitData(const data : TData; offset : Integer); override;
         procedure InitVariant(var v : Variant); override;
         function SupportsEmptyParam : Boolean; virtual;
   end;

   TTypeWithPseudoMethodsSymbol = class;

   TPseudoMethodSymbol = class sealed (TFuncSymbol)
      private
         FOwnerTyp : TTypeSymbol;

      public
         constructor Create(owner : TTypeSymbol; const name : String; funcKind : TFuncKind; funcLevel : SmallInt);

         property OwnerTyp : TTypeSymbol read FOwnerTyp write FOwnerTyp;
   end;

   TTypeWithPseudoMethodsSymbol = class abstract (TTypeSymbol)
      private
         FPseudoMethods : array [TArrayMethodKind] of TPseudoMethodSymbol;

      protected
         function InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; virtual;

      public
         destructor Destroy; override;

         function PseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;

   end;

   TEnumerationSymbol = class;
   TElementSymbol = class;

   TSetOfSymbol = class sealed (TTypeWithPseudoMethodsSymbol)
      private
         FMinValue : Integer;
         FCountValue : Integer;

      protected
         function GetMaxValue : Integer; inline;

         function InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; override;

      public
         constructor Create(const name : String; indexType : TTypeSymbol;
                            aMin, aMax : Integer);

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         procedure InitData(const data : TData; offset : Integer); override;

         function AssignsAsDataExpr : Boolean; override;

         function ValueToOffsetMask(value : Integer; var mask : Int64) : Integer; inline;
         function ValueToByteOffsetMask(value : Integer; var mask : Byte) : Integer; inline;

         function ElementByValue(value : Integer) : TElementSymbol;

         property MinValue : Integer read FMinValue write FMinValue;
         property MaxValue : Integer read GetMaxValue;
         property CountValue : Integer read FCountValue write FCountValue;
   end;

   TArraySymbol = class abstract (TTypeWithPseudoMethodsSymbol)
      private
         FIndexType : TTypeSymbol;
         FSortFunctionType : TFuncSymbol;
         FMapFunctionType : TFuncSymbol;
         FFilterFunctionType : TFuncSymbol;

      protected
         function ElementSize : Integer;

         function InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; override;

      public
         constructor Create(const name : String; elementType, indexType : TTypeSymbol);
         destructor Destroy; override;

         function DynamicInitialization : Boolean; override;

         function AssignsAsDataExpr : Boolean; override;

         function SortFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol; virtual;
         function MapFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol; virtual;
         function FilterFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol; virtual;

         property IndexType : TTypeSymbol read FIndexType write FIndexType;
   end;

   TInitDataProc = procedure (typ : TTypeSymbol; var result : Variant);

   // array of FTyp
   TDynamicArraySymbol = class sealed (TArraySymbol)
      protected
         function GetCaption : String; override;
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

      protected
         function InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; override;

      public
         constructor Create(const name : String; elementType, indexType : TTypeSymbol);
         procedure InitData(const Data: TData; Offset: Integer); override;
         procedure InitVariant(var v : Variant); override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsPointerType : Boolean; override;
         function SameType(typSym : TTypeSymbol) : Boolean; override;
         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         class procedure SetInitDynamicArrayProc(const aProc : TInitDataProc);
   end;

   // array [FLowBound..FHighBound] of FTyp
   TStaticArraySymbol = class (TArraySymbol)
      private
         FHighBound : Integer;
         FLowBound : Integer;
         FElementCount : Integer;

      protected
         function GetCaption : String; override;
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

      public
         constructor Create(const name : String; elementType, indexType : TTypeSymbol;
                            lowBound, highBound : Integer);

         procedure InitData(const Data: TData; Offset: Integer); override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function SameType(typSym : TTypeSymbol) : Boolean; override;
         procedure AddElement;
         function IsEmptyArray : Boolean;

         property HighBound : Integer read FHighBound;
         property LowBound : Integer read FLowBound;
         property ElementCount : Integer read FElementCount;
   end;

   // static array whose bounds are contextual
   TOpenArraySymbol = class sealed (TStaticArraySymbol)
      protected
         function GetCaption : String; override;

      public
         constructor Create(const name : String; elementType, indexType : TTypeSymbol);
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
   end;

   // associative array aka dictionary
   TAssociativeArraySymbol = class sealed (TTypeWithPseudoMethodsSymbol)
      private
         FKeyType : TTypeSymbol;
         FKeyArrayType : TDynamicArraySymbol;

      protected
         function GetCaption : String; override;
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

         function InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol; override;

      public
         constructor Create(const name : String; elementType, keyType : TTypeSymbol);
         destructor Destroy; override;

         procedure InitData(const Data: TData; Offset: Integer); override;
         procedure InitVariant(var v : Variant); override;
         function DynamicInitialization : Boolean; override;

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsPointerType : Boolean; override;
         function SameType(typSym : TTypeSymbol) : Boolean; override;

         function KeysArrayType(baseSymbols : TdwsBaseSymbolsContext) : TDynamicArraySymbol; virtual;

         function KeyAndElementSizeAreBaseTypesOfSizeOne : Boolean; inline;

         property KeyType : TTypeSymbol read FKeyType;

         class procedure SetInitAssociativeArrayProc(const aProc : TInitDataProc);
   end;

   // TMembersSymbolTable
   //
   TMembersSymbolTable = class (TSymbolTable)
      private
         FOwner : TCompositeTypeSymbol;


      public
         procedure AddParent(parent : TMembersSymbolTable);

         function FindSymbol(const aName : String; minVisibility : TdwsVisibility; ofClass : TSymbolClass = nil) : TSymbol; override;
         function FindSymbolFromScope(const aName : String; scopeSym : TCompositeTypeSymbol) : TSymbol; reintroduce;

         function VisibilityFromScope(scopeSym : TCompositeTypeSymbol) : TdwsVisibility;
         function Visibilities : TdwsVisibilities;

         property Owner : TCompositeTypeSymbol read FOwner write FOwner;
   end;

   TStructuredTypeMetaSymbol = class;

   // Const attached to a class
   TClassConstSymbol = class sealed (TConstSymbol)
      protected
         FOwnerSymbol : TCompositeTypeSymbol;
         FVisibility : TdwsVisibility;

      public
         function QualifiedName : String; override;
         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; override;

         property OwnerSymbol : TCompositeTypeSymbol read FOwnerSymbol write FOwnerSymbol;
         property Visibility : TdwsVisibility read FVisibility write FVisibility;
   end;

   // Var attached to a class
   TClassVarSymbol = class sealed (TDataSymbol)
      protected
         FOwnerSymbol : TCompositeTypeSymbol;
         FVisibility : TdwsVisibility;

      public
         constructor Create(const aName : String; aType : TTypeSymbol; aVisibility :  TdwsVisibility);

         function QualifiedName : String; override;
         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; override;

         property OwnerSymbol : TCompositeTypeSymbol read FOwnerSymbol write FOwnerSymbol;
         property Visibility : TdwsVisibility read FVisibility write FVisibility;
   end;

   // type symbol with members
   TCompositeTypeSymbol = class(TTypeSymbol)
      private
         FUnitSymbol : TSymbol;
         FParent : TCompositeTypeSymbol;
         FMembers : TMembersSymbolTable;
         FDefaultProperty : TPropertySymbol;
         FFirstField : TFieldSymbol;

      protected
         function CreateMembersTable(addrGenerator : TAddrGenerator) : TMembersSymbolTable; virtual;

         function GetIsStatic : Boolean; virtual;
         function GetIsExternal : Boolean; virtual;
         function GetIsExternalRooted : Boolean; virtual;
         function GetExternalName : String; virtual;
         function GetIsPartial : Boolean; virtual;
         function GetIsImmutable : Boolean; virtual;

         procedure CheckMethodsImplemented(const msgs : TdwsCompileMessageList);

         function PrepareFirstField : TFieldSymbol;

         function GetMetaSymbol : TStructuredTypeMetaSymbol; virtual; abstract;

         function GetIsGeneric : Boolean; override;

         procedure SpecializeMembers(destination : TCompositeTypeSymbol;
                                     const context : ISpecializationContext);

      public
         constructor Create(const name : String; aUnit : TSymbol);
         destructor Destroy; override;

         procedure AddConst(sym : TClassConstSymbol); overload;
         procedure AddConst(sym : TClassConstSymbol; visibility : TdwsVisibility); overload;
         procedure AddClassVar(sym : TClassVarSymbol);
         procedure AddProperty(propSym : TPropertySymbol);
         procedure AddMethod(methSym : TMethodSymbol); virtual;
         procedure AddField(fieldSym : TFieldSymbol); virtual;

         function FieldAtOffset(offset : Integer) : TFieldSymbol; virtual;

         function AllowVirtualMembers : Boolean; virtual;
         function AllowOverloads : Boolean; virtual;
         function AllowDefaultProperty : Boolean; virtual; abstract;
         function AllowFields : Boolean; virtual;
         function AllowAnonymousMethods : Boolean; virtual;

         function FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol; virtual;

         function MembersVisibilities : TdwsVisibilities;

         function CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol; virtual; abstract;
         function CreateAnonymousMethod(aFuncKind : TFuncKind; aVisibility : TdwsVisibility;
                                        isClassMethod : Boolean) : TMethodSymbol; virtual; abstract;

         function FirstField : TFieldSymbol; inline;

         function ExternalRoot : TCompositeTypeSymbol;

         property UnitSymbol : TSymbol read FUnitSymbol;
         property Parent : TCompositeTypeSymbol read FParent;
         property Members : TMembersSymbolTable read FMembers;
         property DefaultProperty : TPropertySymbol read FDefaultProperty write FDefaultProperty;
         property MetaSymbol : TStructuredTypeMetaSymbol read GetMetaSymbol;

         property IsStatic : Boolean read GetIsStatic;
         property IsPartial : Boolean read GetIsPartial;
         property IsExternal : Boolean read GetIsExternal;
         property IsExternalRooted : Boolean read GetIsExternalRooted;
         property ExternalName : String read GetExternalName;
         property IsImmutable : Boolean read GetIsImmutable;
   end;

   // class, record, interface
   TStructuredTypeSymbol = class(TCompositeTypeSymbol)
      private
         FMetaSymbol : TStructuredTypeMetaSymbol;
         FForwardPosition : PScriptPos;
         FExternalName : String;

      protected
         function GetIsExternal : Boolean; override;
         function GetExternalName : String; override;

         function GetMetaSymbol : TStructuredTypeMetaSymbol; override;

         procedure DoInheritFrom(ancestor : TStructuredTypeSymbol);

      public
         destructor Destroy; override;

         function DuckTypedMatchingMethod(methSym : TMethodSymbol; visibility : TdwsVisibility) : TMethodSymbol; virtual;

         function NthParentOf(structType : TCompositeTypeSymbol) : Integer;
         function DistanceTo(typeSym : TTypeSymbol) : Integer; override;
         function FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol; override;
         function AllowDefaultProperty : Boolean; override;

         procedure SetForwardedPos(const aScriptPos: TScriptPos);
         procedure ClearIsForwarded;

         function IsForwarded : Boolean; override;
         property ExternalName : String read GetExternalName write FExternalName;

         property MetaSymbol : TStructuredTypeMetaSymbol read FMetaSymbol;
   end;

   // class of, record of
   TStructuredTypeMetaSymbol = class (TTypeSymbol)
      public
         constructor Create(const name : String; typ : TStructuredTypeSymbol);

         procedure InitData(const Data: TData; Offset: Integer); override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;

         function StructSymbol : TStructuredTypeSymbol; inline;

         function Parent : TStructuredTypeMetaSymbol;
   end;

   // field of a script object
   TFieldSymbol = class sealed (TValueSymbol)
      protected
         FStructSymbol : TCompositeTypeSymbol;
         FOffset : Integer;
         FVisibility : TdwsVisibility;
         FDefaultValue : TData;
         FDefaultExpr : TExprBase;
         FExternalName : String;
         FNextField : TFieldSymbol;

         function GetExternalName : String;

      public
         constructor Create(const name : String; typ : TTypeSymbol;
                            aVisibility : TdwsVisibility);
         destructor Destroy; override;

         function QualifiedName : String; override;
         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; override;
         function HasExternalName : Boolean; inline;

         procedure InitData(const data : TData; structOffset : Integer);

         property StructSymbol : TCompositeTypeSymbol read FStructSymbol;
         property Offset : Integer read FOffset;
         property Visibility : TdwsVisibility read FVisibility write FVisibility;
         property DefaultValue : TData read FDefaultValue write FDefaultValue;
         property DefaultExpr : TExprBase read FDefaultExpr write FDefaultExpr;
         property ExternalName : String read GetExternalName write FExternalName;
         property NextField : TFieldSymbol read FNextField write FNextField;
   end;

   TRecordSymbolFlag = (
      rsfDynamic,                // indicates some fields have non-constant initialization expressions (for anonymous records)
      rsfFullyDefined,           // set when the declaration is complete
      rsfImmutable,              // immutable record, cannot be altered at runtime
      rsfExternal,               // external record
      rsfDynamicInitialization   // contains fields that require dynamic initialization (dynamic arrays...)
      );
   TRecordSymbolFlags = set of TRecordSymbolFlag;

   // record member1: Integer; member2: Integer end;
   TRecordSymbol = class sealed (TStructuredTypeSymbol)
      private
         FFlags : TRecordSymbolFlags;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;

         function GetIsDynamic : Boolean; inline;
         procedure SetIsDynamic(const val : Boolean);
         function GetIsImmutable : Boolean; override;
         procedure SetIsImmutable(const val : Boolean);
         function GetIsFullyDefined : Boolean; inline;
         procedure SetIsFullyDefined(const val : Boolean);
         function GetIsExternal : Boolean; override;

      public
         constructor Create(const name : String; aUnit : TSymbol);

         procedure AddField(fieldSym : TFieldSymbol); override;
         procedure AddMethod(methSym : TMethodSymbol); override;
         procedure Initialize(const msgs : TdwsCompileMessageList); override;

         function AllowFields : Boolean; override;

         function CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol; override;
         function CreateAnonymousMethod(aFuncKind : TFuncKind; aVisibility : TdwsVisibility;
                                        isClassMethod : Boolean) : TMethodSymbol; override;

         procedure InitData(const data : TData; offset : Integer); override;
         function DynamicInitialization : Boolean; override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function AssignsAsDataExpr : Boolean; override;

         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         property IsDynamic : Boolean read GetIsDynamic write SetIsDynamic;
         property IsImmutable : Boolean read GetIsImmutable write SetIsImmutable;
         property IsFullyDefined : Boolean read GetIsFullyDefined write SetIsFullyDefined;

         procedure SetIsExternal;
   end;

   // interface
   TInterfaceSymbol = class sealed (TStructuredTypeSymbol)
      private
         FMethodCount : Integer;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;
         function  DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

      public
         constructor Create(const name : String; aUnit : TSymbol);

         procedure InheritFrom(ancestor : TInterfaceSymbol);

         procedure AddMethod(methSym : TMethodSymbol); override;

         procedure InitData(const Data: TData; Offset: Integer); override;
         procedure Initialize(const msgs : TdwsCompileMessageList); override;
         function  IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function  IsPointerType : Boolean; override;

         function  SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         function CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol; override;
         function CreateAnonymousMethod(aFuncKind : TFuncKind; aVisibility : TdwsVisibility;
                                        isClassMethod : Boolean) : TMethodSymbol; override;

         function Parent : TInterfaceSymbol; inline;
         property MethodCount : Integer read FMethodCount;
   end;

   // property X: Integer read FReadSym write FWriteSym;
   TPropertySymbol = class sealed (TValueSymbol)
      private
         FOwnerSymbol : TCompositeTypeSymbol;
         FReadSym : TSymbol;
         FWriteSym : TSymbol;
         FArrayIndices : TParamsSymbolTable;
         FIndexSym : TTypeSymbol;
         FIndexValue: TData;
         FDefaultSym : TConstSymbol;
         FVisibility : TdwsVisibility;
         FDeprecatedMessage : String;
         FExternalName : String;
         FUserDescription : String;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;
         function GetIsDefault: Boolean;
         function GetArrayIndices : TParamsSymbolTable;
         procedure AddParam(Param : TParamSymbol);
         function GetIsDeprecated : Boolean; inline;
         function GetExternalName : String;

      public
         constructor Create(const name : String; typ : TTypeSymbol; aVisibility : TdwsVisibility;
                            aArrayIndices : TParamsSymbolTable);
         destructor Destroy; override;

         procedure GenerateParams(Table: TSymbolTable; const FuncParams: TParamArray);
         procedure SetIndex(const data : TData; Sym: TTypeSymbol);
         function GetArrayIndicesDescription: String;
         function QualifiedName : String; override;
         function IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean; override;
         function HasArrayIndices : Boolean;

         function Specialize(const context : ISpecializationContext) : TSymbol; override;

         property OwnerSymbol : TCompositeTypeSymbol read FOwnerSymbol;
         property Visibility : TdwsVisibility read FVisibility write FVisibility;
         property ArrayIndices : TParamsSymbolTable read GetArrayIndices;
         property ReadSym : TSymbol read FReadSym write FReadSym;
         property WriteSym : TSymbol read FWriteSym write FWriteSym;
         property IsDefault : Boolean read GetIsDefault;
         property IndexValue : TData read FIndexValue;
         property IndexSym : TTypeSymbol read FIndexSym;
         property DefaultSym : TConstSymbol read FDefaultSym write FDefaultSym;
         property DeprecatedMessage : String read FDeprecatedMessage write FDeprecatedMessage;
         property IsDeprecated : Boolean read GetIsDeprecated;
         property ExternalName : String read GetExternalName write FExternalName;
         property UserDescription : String read FUserDescription write FUserDescription;
   end;

   // class operator X (params) uses method;
   TClassOperatorSymbol = class sealed (TSymbol)
      private
         FCompositeSymbol : TCompositeTypeSymbol;
         FTokenType : TTokenType;
         FUsesSym : TMethodSymbol;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;

      public
         constructor Create(tokenType : TTokenType);
         function QualifiedName : String; override;

         property CompositeSymbol : TCompositeTypeSymbol read FCompositeSymbol write FCompositeSymbol;
         property TokenType : TTokenType read FTokenType write FTokenType;
         property UsesSym : TMethodSymbol read FUsesSym write FUsesSym;
   end;

   // type X = class of TMyClass;
   TClassOfSymbol = class sealed (TStructuredTypeMetaSymbol)
      protected
         function GetCaption : String; override;
         function GetDescription : String; override;
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

      public
         constructor Create(const name : String; typ : TClassSymbol);

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function SameType(typSym : TTypeSymbol) : Boolean; override;
         function TypClassSymbol : TClassSymbol; inline;
   end;

   // A resolved interface (attached to a class symbol)
   TResolvedInterface = record
      IntfSymbol : TInterfaceSymbol;
      VMT : TMethodSymbolArray;
   end;

   TResolvedInterfaces = class (TSimpleHash<TResolvedInterface>)
      protected
         function SameItem(const item1, item2 : TResolvedInterface) : Boolean; override;
         function GetItemHashCode(const item1 : TResolvedInterface) : Cardinal; override;
   end;

   TObjectDestroyEvent = procedure (ExternalObject: TObject) of object;

   TClassSymbolFlag = (
      // requirement or declarations flags
      csfExplicitAbstract, // class that was explicity marked as abstract
      csfSealed,           // class that cannot be sublclasses
      csfStatic,           // class that cannot have instances
      csfExternal,         // class exposed but not implemented in script
      csfPartial,          // class whose declaration and implementation spans multiple units
      csfInternal,         // class for internal use which cannot be subclassed or constructed from script
      // script engine flags
      csfAbstract,         // class was marked abstract or has abstract methods
      csfNoVirtualMembers, // class does not have virtual members
      csfNoOverloads,
      csfHasOwnMethods,
      csfHasOwnFields,
      csfExternalRooted,
      csfInitialized,
      csfAttribute
   );
   TClassSymbolFlags = set of TClassSymbolFlag;

   // type X = class ... end;
   TClassSymbol = class sealed (TStructuredTypeSymbol)
      private
         FFlags : TClassSymbolFlags;
         FOperators : TTightList;
         FScriptInstanceSize : Integer;
         FOnObjectDestroy : TObjectDestroyEvent;
         FVirtualMethodTable : TMethodSymbolArray;
         FInterfaces : TResolvedInterfaces;

      protected
         function GetDescription : String; override;
         function GetIsExplicitAbstract : Boolean; inline;
         procedure SetIsExplicitAbstract(const val : Boolean); inline;
         function GetIsAbstract : Boolean; inline;
         function GetIsSealed : Boolean; inline;
         procedure SetIsSealed(const val : Boolean); inline;
         function GetIsStatic : Boolean; override;
         procedure SetIsStatic(const val : Boolean); inline;
         function GetIsExternal : Boolean; override;
         procedure SetIsExternal(const val : Boolean); inline;
         function GetIsExternalRooted : Boolean; override;
         function GetIsPartial : Boolean; override;
         function GetIsAttribute : Boolean; inline;
         procedure SetIsAttribute(const val : Boolean); inline;
         function GetIsInternal : Boolean; inline;
         procedure SetIsInternal(const val : Boolean); inline;

         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

         function  ProcessOverriddenInterfaceCallback(const item : TResolvedInterface) : TSimpleHashAction;
         procedure ProcessOverriddenInterfaces;
         function  ProcessOverriddenInterface(const ancestorResolved : TResolvedInterface) : Boolean; // True if added

      public
         constructor Create(const name : String; aUnit : TSymbol);
         destructor Destroy; override;

         procedure AddField(fieldSym : TFieldSymbol); override;
         procedure AddMethod(methSym : TMethodSymbol); override;
         procedure AddOperator(Sym: TClassOperatorSymbol);

         function  AddInterface(intfSym : TInterfaceSymbol; visibility : TdwsVisibility;
                                var missingMethod : TMethodSymbol) : Boolean; // True if added
         function  ResolveInterface(intfSym : TInterfaceSymbol; var resolved : TResolvedInterface) : Boolean;
         function  ImplementsInterface(intfSym : TInterfaceSymbol) : Boolean;
         procedure SetIsPartial; inline;
         procedure SetNoVirtualMembers; inline;
         procedure SetNoOverloads; inline;

         function  FieldAtOffset(offset : Integer) : TFieldSymbol; override;
         procedure InheritFrom(ancestorClassSym : TClassSymbol);
         procedure InitData(const Data: TData; Offset: Integer); override;
         procedure Initialize(const msgs : TdwsCompileMessageList); override;
         function  IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function  IsPointerType : Boolean; override;
         function  HasMetaSymbol : Boolean; override;

         function CommonAncestor(otherClass : TTypeSymbol) : TClassSymbol;

         function VMTMethod(index : Integer) : TMethodSymbol;
         function VMTCount : Integer;

         function FindClassOperatorStrict(tokenType : TTokenType; paramType : TSymbol; recursive : Boolean) : TClassOperatorSymbol;
         function FindClassOperator(tokenType : TTokenType; paramType : TTypeSymbol) : TClassOperatorSymbol;

         function FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol; override;

         procedure CollectPublishedSymbols(symbolList : TSimpleSymbolList);

         function AllowVirtualMembers : Boolean; override;
         function AllowOverloads : Boolean; override;
         function AllowFields : Boolean; override;
         function AllowAnonymousMethods : Boolean; override;

         function CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol; override;
         function CreateAnonymousMethod(aFuncKind : TFuncKind; aVisibility : TdwsVisibility;
                                        isClassMethod : Boolean) : TMethodSymbol; override;

         class function VisibilityToString(visibility : TdwsVisibility) : String; static;

         function SpecializeType(const context : ISpecializationContext) : TTypeSymbol; override;

         function Parent : TClassSymbol; inline;
         property ScriptInstanceSize : Integer read FScriptInstanceSize;
         property Interfaces : TResolvedInterfaces read FInterfaces;
         property Flags : TClassSymbolFlags read FFlags;

         property IsExplicitAbstract : Boolean read GetIsExplicitAbstract write SetIsExplicitAbstract;
         property IsAbstract : Boolean read GetIsAbstract;
         property IsSealed : Boolean read GetIsSealed write SetIsSealed;
         property IsStatic : Boolean read GetIsStatic write SetIsStatic;
         property IsExternal : Boolean read GetIsExternal write SetIsExternal;
         property IsInternal : Boolean read GetIsInternal write SetIsInternal;
         property IsPartial : Boolean read GetIsPartial;
         property IsAttribute : Boolean read GetIsAttribute write SetIsAttribute;

         function IsPureStatic : Boolean;

         property OnObjectDestroy : TObjectDestroyEvent read FOnObjectDestroy write FOnObjectDestroy;
   end;

   // class or type helper
   THelperSymbol = class sealed (TCompositeTypeSymbol)
      private
         FForType : TTypeSymbol;
         FUnAliasedForType : TTypeSymbol;
         FMetaForType : TStructuredTypeMetaSymbol;
         FPriority : Integer;
         FStrict : Boolean;

      protected
         function GetMetaSymbol : TStructuredTypeMetaSymbol; override;

      public
         constructor Create(const name : String; aUnit : TSymbol;
                            aForType : TTypeSymbol; priority : Integer);

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsType : Boolean; override;
         function AllowDefaultProperty : Boolean; override;
         function CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol; override;
         function CreateAnonymousMethod(aFuncKind : TFuncKind; aVisibility : TdwsVisibility;
                                        isClassMethod : Boolean) : TMethodSymbol; override;

         procedure Initialize(const msgs : TdwsCompileMessageList); override;

         function HelpsType(typ : TTypeSymbol) : Boolean;

         property ForType : TTypeSymbol read FForType;
         property Priority : Integer read FPriority;
         property Strict : Boolean read FStrict write FStrict;
   end;

   THelperSymbols = class(TSimpleList<THelperSymbol>)
      public
         function AddHelper(helper : THelperSymbol) : Boolean;
   end;

   // nil "class"
   TNilSymbol = class sealed (TTypeSymbol)
      protected
         function GetCaption : String; override;

      public
         constructor Create;

         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;
         function IsCompatibleWithAnyFuncSymbol : Boolean; override;

         procedure InitData(const data : TData; offset : Integer); override;
   end;

   // Element of an enumeration type. E. g. "type DummyEnum = (Elem1, Elem2, Elem3);"
   TElementSymbol = class sealed (TConstSymbol)
      private
         FEnumeration : TEnumerationSymbol;
         FIsUserDef : Boolean;

      protected
         function GetDescription : String; override;
         function GetValue : Int64; inline;

      public
         constructor Create(const Name: String; Typ: TTypeSymbol;
                            const aValue : Int64; isUserDef: Boolean);

         function StandardName : String; inline;
         function QualifiedName : String; override;

         property Enumeration : TEnumerationSymbol read FEnumeration;
         property IsUserDef : Boolean read FIsUserDef;
         property Value : Int64 read GetValue;
   end;

   TEnumerationSymbolStyle = (enumClassic, enumScoped, enumFlags);

   // Enumeration type. E. g. "type myEnum = (One, Two, Three);"
   TEnumerationSymbol = class sealed (TTypeSymbol)
      private
         FElements : TSymbolTable;
         FLowBound, FHighBound : Int64;
         FStyle : TEnumerationSymbolStyle;
         FContinuous : Boolean;

      protected
         function GetCaption : String; override;
         function GetDescription : String; override;
         function DoIsOfType(typSym : TTypeSymbol) : Boolean; override;

      public
         constructor Create(const name : String; baseType : TTypeSymbol;
                            aStyle : TEnumerationSymbolStyle);
         destructor Destroy; override;

         function DefaultValue : Int64;
         procedure InitData(const data : TData; offset : Integer); override;
         function BaseType : TTypeSymbol; override;
         function IsCompatible(typSym : TTypeSymbol) : Boolean; override;

         procedure AddElement(element : TElementSymbol);
         function ElementByValue(const value : Int64) : TElementSymbol;

         property Elements : TSymbolTable read FElements;
         property Style : TEnumerationSymbolStyle read FStyle;
         property Continuous : Boolean read FContinuous write FContinuous;
         property LowBound : Int64 read FLowBound write FLowBound;
         property HighBound : Int64 read FHighBound write FHighBound;
         function ShortDescription : String;
   end;

   // variable with functions for read/write: var x: integer; extern 'type' in 'selector';
   TExternalVarSymbol = class sealed (TValueSymbol)
      private
         FReadFunc : TFuncSymbol;
         FWriteFunc : TFuncSymbol;

      protected
         function GetReadFunc : TFuncSymbol; virtual;
         function GetWriteFunc : TFuncSymbol; virtual;

      public
         destructor Destroy; override;

         property ReadFunc : TFuncSymbol read GetReadFunc write FReadFunc;
         property WriteFunc : TFuncSymbol read GetWriteFunc write FWriteFunc;
   end;

   TdwsBaseSymbolTypes = record
      TypBoolean : TBaseBooleanSymbol;
      TypFloat : TBaseFloatSymbol;
      TypInteger : TBaseIntegerSymbol;
      TypString : TBaseStringSymbol;
      TypVariant : TBaseVariantSymbol;

      TypNil : TNilSymbol;
      TypObject : TClassSymbol;
      TypTObject : TClassSymbol;
      TypClass : TClassOfSymbol;

      TypException : TClassSymbol;
      TypInterface : TInterfaceSymbol;
      TypCustomAttribute : TClassSymbol;
      TypAnyType : TAnyTypeSymbol;
      TypAnyFunc : TAnyFuncSymbol;
   end;

   TdwsBaseSymbolsContext = class
      private
         FBaseTypes : TdwsBaseSymbolTypes;

      protected
         procedure SetBaseTypes(const bt : TdwsBaseSymbolTypes);

      public
         function FindType(const typName : String) : TTypeSymbol; virtual; abstract;

         property TypBoolean: TBaseBooleanSymbol read FBaseTypes.TypBoolean;
         property TypFloat: TBaseFloatSymbol read FBaseTypes.TypFloat;
         property TypInteger: TBaseIntegerSymbol read FBaseTypes.TypInteger;
         property TypNil: TNilSymbol read FBaseTypes.TypNil;
         property TypObject: TClassSymbol read FBaseTypes.TypObject;
         property TypTObject: TClassSymbol read FBaseTypes.TypTObject;
         property TypString: TBaseStringSymbol read FBaseTypes.TypString;
         property TypVariant: TBaseVariantSymbol read FBaseTypes.TypVariant;
         property TypException: TClassSymbol read FBaseTypes.TypException;
         property TypInterface : TInterfaceSymbol read FBaseTypes.TypInterface;
         property TypAnyType: TAnyTypeSymbol read FBaseTypes.TypAnyType;
         property TypAnyFunc : TAnyFuncSymbol read FBaseTypes.TypAnyFunc;
   end;

   // TdwsExecution
   //
   TdwsExecution = class abstract (TInterfacedSelfObject, IdwsExecution)
      protected
         FStack : TStackMixIn;
         FStatus : TExecutionStatusResult;
         FCallStack : TTightStack; // expr + prog duples
         FSelfScriptObject : PIScriptObj;
         FSelfScriptClassSymbol : TClassSymbol;

         FDebugger : IDebugger;
         FIsDebugging : Boolean;
         FDebugSuspended : Integer;

         FSleepTime : Integer;
         FSleeping : Boolean;

         FInternalExecution : Integer;

         FEnvironment : IdwsEnvironment;

      protected
         FProgramState : TProgramState;  // here to reduce its offset

         function GetEnvironment : IdwsEnvironment;
         procedure SetEnvironment(const val : IdwsEnvironment);

      private
         FExternalObject : TObject;
         FUserObject : TObject;

         FExceptionObjectStack : TSimpleStack<IScriptObj>;
         FLastScriptError : TExprBase;
         FLastScriptCallStack : TdwsExprLocationArray;

         FRandSeed : UInt64;

         FFormatSettings : TdwsFormatSettings;

      protected
         function  GetDebugger : IDebugger;
         procedure SetDebugger(const aDebugger : IDebugger);
         procedure StartDebug;
         procedure StopDebug;

         function GetMsgs : TdwsRuntimeMessageList; virtual; abstract;

         function GetExecutionObject : TdwsExecution;

         function GetUserObject : TObject; virtual;
         procedure SetUserObject(const value : TObject); virtual;
         procedure SetRandSeed(const val : UInt64);

         function GetStack : TStack;

         function GetProgramState : TProgramState;

         function GetSleeping : Boolean;

         function GetFormatSettings : TdwsFormatSettings;

      public
         constructor Create(const stackParams : TStackParameters);
         destructor Destroy; override;

         procedure DoStep(expr : TExprBase);

         property Status : TExecutionStatusResult read FStatus write FStatus;
         property Stack : TStackMixIn read FStack;
         property SelfScriptObject : PIScriptObj read FSelfScriptObject write FSelfScriptObject;
         property SelfScriptClassSymbol : TClassSymbol read FSelfScriptClassSymbol write FSelfScriptClassSymbol;

         class function Status_Offset : Integer;
         class function StackMixin_Offset : Integer;

         function GetLastScriptErrorExpr : TExprBase;
         procedure SetScriptError(expr : TExprBase);
         procedure ClearScriptError;

         function GetCallStack : TdwsExprLocationArray; virtual; abstract;
         function CallStackLastExpr : TExprBase; virtual; abstract;
         function CallStackLastProg : TObject; virtual; abstract;
         function CallStackDepth : Integer; virtual; abstract;

         procedure SuspendDebug;
         procedure ResumeDebug;

         procedure DataContext_Create(const data : TData; addr : Integer; var Result : IDataContext); inline;
         procedure DataContext_CreateEmpty(size : Integer; var Result : IDataContext); inline;
         procedure DataContext_CreateValue(const value : Variant; var Result : IDataContext); inline;
         procedure DataContext_CreateBase(addr : Integer; var Result : IDataContext); inline;
         procedure DataContext_CreateLevel(level, addr : Integer; var Result : IDataContext); inline;
         procedure DataContext_CreateOffset(const data : IDataContext; offset : Integer; var Result : IDataContext); inline;
         function  DataContext_Nil : IDataContext; inline;

         function  GetStackPData : PData;

         procedure LocalizeSymbol(aResSymbol : TResourceStringSymbol; var Result : String); virtual;
         procedure LocalizeString(const aString : String; var Result : String); virtual;

         function ValidateFileName(const path : String) : String; virtual;

         function Random : Double;

         // interruptible sleep (in case program is stopped)
         procedure Sleep(msec, sleepCycle : Integer);
         property Sleeping : Boolean read FSleeping;

         property LastScriptError : TExprBase read FLastScriptError;
         property LastScriptCallStack : TdwsExprLocationArray read FLastScriptCallStack;
         property ExceptionObjectStack : TSimpleStack<IScriptObj> read FExceptionObjectStack;

         procedure EnterExceptionBlock(var exceptObj : IScriptObj); virtual;
         procedure LeaveExceptionBlock;

         property ProgramState : TProgramState read FProgramState;

         property Debugger : IDebugger read FDebugger write SetDebugger;
         property IsDebugging : Boolean read FIsDebugging;

         procedure DebuggerNotifyException(const exceptObj : IScriptObj); virtual; abstract;

         procedure BeginInternalExecution; inline;
         procedure EndInternalExecution; inline;
         function  InternalExecution : Boolean; inline;

         property Msgs : TdwsRuntimeMessageList read GetMsgs;

         // per-execution randseed
         property RandSeed : UInt64 read FRandSeed write SetRandSeed;

         property FormatSettings : TdwsFormatSettings read GetFormatSettings;

         // specifies an external object for IInfo constructors, temporary
         property ExternalObject : TObject read FExternalObject write FExternalObject;

         // user object, to attach to an execution
         property UserObject : TObject read GetUserObject write SetUserObject;

         // user environment
         property Environment : IdwsEnvironment read FEnvironment write FEnvironment;
   end;

   // IScriptObj
   //
   IScriptObj = interface (IDataContext)
      ['{8D534D1E-4C6B-11D5-8DCB-0000216D9E86}']
      function GetClassSym: TClassSymbol;
      function GetExternalObject: TObject;
      procedure SetExternalObject(value: TObject);
      function GetDestroyed : Boolean;
      procedure SetDestroyed(const val : Boolean);

      property ClassSym : TClassSymbol read GetClassSym;
      property ExternalObject : TObject read GetExternalObject write SetExternalObject;
      property Destroyed : Boolean read GetDestroyed write SetDestroyed;

      function FieldAsString(const fieldName : String) : String;
      function FieldAsInteger(const fieldName : String) : Int64;
      function FieldAsFloat(const fieldName : String) : Double;
      function FieldAsBoolean(const fieldName : String) : Boolean;
      function FieldAsScriptDynArray(const fieldName : String) : IScriptDynArray;
   end;

   // IScriptObjInterface
   //
   IScriptObjInterface = interface (IDataContext)
      ['{86B77C28-C396-4D53-812B-8FF1867A6128}']
      function GetScriptObj : IScriptObj;
   end;

   // IScriptDynArray
   //
   IScriptDynArray = interface (IGetSelf)
      ['{29767B6E-05C0-40E1-A41A-94DF54142312}']
      function GetElementSize : Integer;
      property ElementSize : Integer read GetElementSize;
      function GetElementType : TTypeSymbol;
      property ElementType : TTypeSymbol read GetElementType;

      function GetArrayLength : NativeInt;
      procedure SetArrayLength(n : NativeInt);
      property ArrayLength : NativeInt read GetArrayLength write SetArrayLength;

      function BoundsCheckPassed(index : NativeInt) : Boolean;

      function ToStringArray : TStringDynArray;
      function ToInt64Array : TInt64DynArray;
      function ToData : TData;

      procedure Insert(index : NativeInt);
      procedure Delete(index, count : NativeInt);
      procedure MoveItem(source, destination : NativeInt);
      procedure Swap(index1, index2 : NativeInt);

      function IndexOfValue(const item : Variant; fromIndex : NativeInt) : NativeInt;
      function IndexOfInteger(item : Int64; fromIndex : NativeInt) : NativeInt;
      function IndexOfFloat(item : Double; fromIndex : NativeInt) : NativeInt;
      function IndexOfString(const item : String; fromIndex : NativeInt) : NativeInt;
      function IndexOfInterface(const item : IUnknown; fromIndex : NativeInt) : NativeInt;
      function IndexOfFuncPtr(const item : Variant; fromIndex : NativeInt) : NativeInt;

      procedure WriteData(const src : TData; srcAddr, size : NativeInt);
      procedure ReplaceData(const v : TData);
      procedure Concat(const src : IScriptDynArray; index, size : NativeInt);

      procedure Reverse;
      procedure NaturalSort;

      procedure AddStrings(sl : TStrings);

      function GetAsFloat(index : NativeInt) : Double;
      procedure SetAsFloat(index : NativeInt; const v : Double);
      property AsFloat[index : NativeInt] : Double read GetAsFloat write SetAsFloat;

      function GetAsInteger(index : NativeInt) : Int64;
      procedure SetAsInteger(index : NativeInt; const v : Int64);
      property AsInteger[index : NativeInt] : Int64 read GetAsInteger write SetAsInteger;

      function GetAsBoolean(index : NativeInt) : Boolean;
      procedure SetAsBoolean(index : NativeInt; const v : Boolean);
      property AsBoolean[index : NativeInt] : Boolean read GetAsBoolean write SetAsBoolean;

      procedure SetAsVariant(index : NativeInt; const v : Variant);
      procedure EvalAsVariant(index : NativeInt; var result : Variant);
      property AsVariant[index : NativeInt] : Variant write SetAsVariant;

      procedure SetAsString(index : NativeInt; const v : String);
      procedure EvalAsString(index : NativeInt; var result : String);
      property AsString[index : NativeInt] : String write SetAsString;

      procedure SetAsInterface(index : NativeInt; const v : IUnknown);
      procedure EvalAsInterface(index : NativeInt; var result : IUnknown);
      property AsInterface[index : NativeInt] : IUnknown write SetAsInterface;

      function SetFromExpr(index : NativeInt; exec : TdwsExecution; valueExpr : TExprBase) : Boolean;

      function IsEmpty(addr : NativeInt) : Boolean;
      function VarType(addr : NativeInt) : TVarType;

      function HashCode(addr : NativeInt; size : NativeInt) : Cardinal;
   end;

   // IScriptAssociativeArray
   IScriptAssociativeArray = interface (IDataContext)
      ['{1162D4BD-6033-4505-8D8C-0715588C768C}']
      procedure Clear;
      function Count : NativeInt;
   end;

   TPerfectMatchEnumerator = class
      FuncSym, Match : TFuncSymbol;
      function Callback(sym : TSymbol) : Boolean;
   end;

   // The script has to be stopped because of an error
   EScriptError = class(Exception)
      private
         FScriptPos : TScriptPos;
         FScriptCallStack : TdwsExprLocationArray;
         FRawClassName : String;

         procedure SetScriptPos(const aPos : TScriptPos);

      public
         constructor CreatePosFmt(const aScriptPos: TScriptPos; const Msg: String; const Args: array of const);

         property ScriptPos : TScriptPos read FScriptPos write SetScriptPos;//FScriptPos;
         property ScriptCallStack : TdwsExprLocationArray read FScriptCallStack write FScriptCallStack;
         property RawClassName : String read FRawClassName write FRawClassName;
   end;

   EScriptStopped = class (EScriptError)
      public
         class procedure DoRaise(exec : TdwsExecution; stoppedOn : TExprBase); static;
   end;

const
   cFuncKindToString : array [Low(TFuncKind)..High(TFuncKind)] of String = (
      'function', 'procedure', 'constructor', 'destructor', 'method', 'lambda' );
   cParamSymbolSemanticsPrefix : array [Low(TParamSymbolSemantics)..High(TParamSymbolSemantics)] of String = (
      '', 'const', 'var', 'lazy'
   );
   cFirstFieldUnprepared = Pointer(-1);
   cDefaultRandSeed : UInt64 = 88172645463325252;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses dwsCompilerUtils, dwsStrings, dwsXPlatform;

// ------------------
// ------------------ TdwsExprLocation ------------------
// ------------------

// Line
//
function TdwsExprLocation.Line : Integer;
begin
   Result:=Expr.ScriptPos.Line;
end;

// SourceName
//
function TdwsExprLocation.SourceName : String;
begin
   Result:=Expr.ScriptPos.SourceName;
end;

// Location
//
function TdwsExprLocation.Location : String;
begin
   Result:=Expr.ScriptLocation(Prog);
end;

// ------------------
// ------------------ TExprBase ------------------
// ------------------

// CallStackToString
//
class function TExprBase.CallStackToString(const callStack : TdwsExprLocationArray) : String;
var
   i : Integer;
   buffer : TWriteOnlyBlockStream;
   expr : TExprBase;
begin
   buffer:=TWriteOnlyBlockStream.Create;
   try
      for i:=0 to High(callStack) do begin
         if i>0 then
            buffer.WriteString(#13#10);
         expr := callStack[i].Expr;
         if expr <> nil then
            buffer.WriteString(expr.ScriptLocation(callStack[i].Prog));
      end;
      Result:=buffer.ToString;
   finally
      buffer.Free;
   end;
end;

// RecursiveEnumerateSubExprs
//
function TExprBase.RecursiveEnumerateSubExprs(const callback : TExprBaseEnumeratorProc) : Boolean;
var
   i : Integer;
   abort : Boolean;
   base, expr : TExprBase;
   stack : TSimpleStack<TExprBase>;
begin
   if Self=nil then Exit(False);
   stack:=TSimpleStack<TExprBase>.Create;
   try
      abort:=False;
      stack.Push(Self);
      repeat
         base:=stack.Peek;
         stack.Pop;
         for i:=0 to base.SubExprCount-1 do begin
            expr:=base.SubExpr[i];
            if expr<>nil then begin
               stack.Push(expr);
               callback(base, expr, abort);
               if abort then Exit(True);
            end;
         end;
      until stack.Count=0;
   finally
      stack.Free;
   end;
   Result:=False;
end;

// ReferencesVariable
//
function TExprBase.ReferencesVariable(varSymbol : TDataSymbol) : Boolean;
var
   i : Integer;
   sub : TExprBase;
begin
   for i:=0 to SubExprCount-1 do begin
      sub:=SubExpr[i];
      if (sub<>nil) and sub.ReferencesVariable(varSymbol) then
         Exit(True)
   end;
   Result:=False;
end;

// IndexOfSubExpr
//
function TExprBase.IndexOfSubExpr(expr : TExprBase) : Integer;
var
   i : Integer;
begin
   for i:=0 to SubExprCount-1 do
      if SubExpr[i]=expr then
         Exit(i);
   Result:=-1;
end;

// GetSubExpr
//
function TExprBase.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=nil;
end;

// GetSubExprCount
//
function TExprBase.GetSubExprCount : Integer;
begin
   Result:=0;
end;

procedure TExprBase.EvalNoResult(exec : TdwsExecution);
var
   buf : Variant;
begin
   EvalAsVariant(exec, buf);
end;

// GetIsConstant
//
function TExprBase.GetIsConstant : Boolean;
begin
   Result:=False;
end;

// IsConstant
//
function TExprBase.IsConstant : Boolean;
begin
   Result:=(Self<>nil) and GetIsConstant;
end;

// Eval
//
function TExprBase.Eval(exec : TdwsExecution) : Variant;
begin
   EvalAsVariant(exec, Result);
end;

// RaiseScriptError
//
procedure TExprBase.RaiseScriptError(exec : TdwsExecution; e : EScriptError);
begin
   e.ScriptPos:=ScriptPos;
   e.ScriptCallStack:=exec.GetCallStack;
   raise e;
end;

// RaiseScriptError
//
procedure TExprBase.RaiseScriptError(exec : TdwsExecution);
var
   exc : Exception;
   e : EScriptError;
begin
   if (ExceptObject is EScriptError) or (ExceptObject is EScriptException) then
      raise Exception(AcquireExceptionObject);
   exc := ExceptObject as Exception;
   e := EScriptError.Create(exc.Message);
   e.RawClassName := exc.ClassName;
   RaiseScriptError(exec, e);
end;

// RaiseScriptError
//
procedure TExprBase.RaiseScriptError(exec : TdwsExecution; const msg : String);
begin
   RaiseScriptError(exec, EScriptError, msg);
end;

// RaiseScriptError
//
procedure TExprBase.RaiseScriptError(exec : TdwsExecution; exceptClass : EScriptErrorClass; const msg : String);
begin
   RaiseScriptError(exec, exceptClass.Create(msg));
end;

// RaiseScriptError
//
procedure TExprBase.RaiseScriptError(exec : TdwsExecution; exceptClass : EScriptErrorClass;
                                        const msg : String; const args : array of const);
begin
   RaiseScriptError(exec, exceptClass.CreateFmt(msg, args));
end;

// RaiseObjectNotInstantiated
//
procedure TExprBase.RaiseObjectNotInstantiated(exec : TdwsExecution);
begin
   RaiseScriptError(exec, EScriptError, RTE_ObjectNotInstantiated);
end;

// RaiseObjectAlreadyDestroyed
//
procedure TExprBase.RaiseObjectAlreadyDestroyed(exec : TdwsExecution);
begin
   RaiseScriptError(exec, EScriptError, RTE_ObjectAlreadyDestroyed);
end;

// Specialize
//
function TExprBase.Specialize(const context : ISpecializationContext) : TExprBase;
begin
   context.AddCompilerErrorFmt('Specialization of %s is not supported yet.', [Self.ClassName]);
   Result := nil;
end;

// FuncSymQualifiedName
//
function TExprBase.FuncSymQualifiedName : String;
begin
   Result:='';
end;

// EvalAsSafeScriptObj
//
procedure TExprBase.EvalAsSafeScriptObj(exec : TdwsExecution; var result : IScriptObj);
begin
   EvalAsScriptObj(exec, result);
   if result = nil then
      RaiseObjectNotInstantiated(exec)
   else if result.Destroyed then
      RaiseObjectAlreadyDestroyed(exec);
end;

// EvalAsSafeScriptObj
//
function TExprBase.EvalAsSafeScriptObj(exec : TdwsExecution) : IScriptObj;
begin
   EvalAsSafeScriptObj(exec, Result);
end;

// ------------------
// ------------------ TSymbol ------------------
// ------------------

// Create
//
constructor TSymbol.Create(const aName : String; aType : TTypeSymbol);
begin
   inherited Create;
   FName:=aName;
   FTyp:=aType;
   if Assigned(aType) then
      FSize:=aType.FSize
   else FSize:=0;
end;

// GetCaption
//
function TSymbol.GetCaption : String;
begin
   Result := FName;
end;

// GetDescription
//
function TSymbol.GetDescription : String;
begin
   Result:=Caption;
end;

// Initialize
//
procedure TSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
end;

// IsBaseType
//
class function TSymbol.IsBaseType : Boolean;
begin
   Result:=False;
end;

// IsType
//
function TSymbol.IsType : Boolean;
begin
   Result:=False;
end;

// IsPointerType
//
function TSymbol.IsPointerType : Boolean;
begin
   Result:=False;
end;

// GetAsFuncSymbol
//
function TSymbol.GetAsFuncSymbol : TFuncSymbol;
begin
   Result:=nil;
end;

// GetIsGeneric
//
function TSymbol.GetIsGeneric : Boolean;
begin
   if FTyp <> nil then
      Result := FTyp.IsGeneric
   else Result := False;
end;

// AsFuncSymbol
//
function TSymbol.AsFuncSymbol : TFuncSymbol;
begin
   if Self<>nil then
      Result:=GetAsFuncSymbol
   else Result:=nil;
end;

// IsGeneric
//
function TSymbol.IsGeneric : Boolean;
begin
   if Self <> nil then
      Result := GetIsGeneric
   else Result := False;
end;

// AsFuncSymbol
//
function TSymbol.AsFuncSymbol(var funcSym : TFuncSymbol) : Boolean;
begin
   if Self<>nil then
      funcSym:=GetAsFuncSymbol
   else funcSym:=nil;
   Result:=(funcSym<>nil);
end;

// QualifiedName
//
function TSymbol.QualifiedName : String;
begin
   Result := String(Name);
end;

// IsVisibleFor
//
function TSymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=True;
end;

// Specialize
//
function TSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   context.AddCompilerErrorFmt(CPE_SpecializationNotSupportedYet, [ClassName]);
   Result := nil;
end;

function TSymbol.BaseType: TTypeSymbol;
begin
  Result := nil;
end;

// SetName
//
procedure TSymbol.SetName(const newName : String; force : Boolean = False);
begin
   Assert(force or (FName=''));
   FName:=newName;
end;

// SafeGetCaption
//
function TSymbol.SafeGetCaption : String;
begin
   if Self=nil then
      Result:=SYS_VOID
   else Result:=GetCaption;
end;

// ------------------
// ------------------ TCompositeTypeSymbol ------------------
// ------------------

// Create
//
constructor TCompositeTypeSymbol.Create(const name : String; aUnit : TSymbol);
begin
   inherited Create(name, nil);
   FUnitSymbol := aUnit;
   FMembers := CreateMembersTable(nil);
   FFirstField := cFirstFieldUnprepared;
end;

// Destroy
//
destructor TCompositeTypeSymbol.Destroy;
begin
   FMembers.Free;
   inherited;
end;

// AddConst
//
procedure TCompositeTypeSymbol.AddConst(sym : TClassConstSymbol);
begin
   sym.OwnerSymbol:=Self;
   FMembers.AddSymbol(sym);
end;

// AddConst
//
procedure TCompositeTypeSymbol.AddConst(sym : TClassConstSymbol; visibility : TdwsVisibility);
begin
   sym.Visibility:=visibility;
   AddConst(sym);
end;

// AddClassVar
//
procedure TCompositeTypeSymbol.AddClassVar(sym : TClassVarSymbol);
begin
   sym.OwnerSymbol:=Self;
   FMembers.AddSymbol(sym);
end;

// AddProperty
//
procedure TCompositeTypeSymbol.AddProperty(propSym : TPropertySymbol);
begin
   FMembers.AddSymbol(propSym);
   propSym.FOwnerSymbol:=Self;
end;

// AddMethod
//
procedure TCompositeTypeSymbol.AddMethod(methSym : TMethodSymbol);
begin
   FMembers.AddSymbol(methSym);
   methSym.FStructSymbol:=Self;
end;

// AddField
//
procedure TCompositeTypeSymbol.AddField(fieldSym : TFieldSymbol);
begin
   Assert(FFirstField=cFirstFieldUnprepared);
   FMembers.AddSymbol(fieldSym);
   fieldSym.FStructSymbol:=Self;
end;

// FieldAtOffset
//
function TCompositeTypeSymbol.FieldAtOffset(offset : Integer) : TFieldSymbol;
var
   sym : TSymbol;
begin
   for sym in Members do begin
      if sym.ClassType=TFieldSymbol then begin
         Result:=TFieldSymbol(sym);
         if Result.Offset=offset then Exit;
      end;
   end;
   Result:=nil;
end;

// AllowVirtualMembers
//
function TCompositeTypeSymbol.AllowVirtualMembers : Boolean;
begin
   Result:=False;
end;

// AllowOverloads
//
function TCompositeTypeSymbol.AllowOverloads : Boolean;
begin
   Result:=True;
end;

// CreateMembersTable
//
function TCompositeTypeSymbol.CreateMembersTable(addrGenerator : TAddrGenerator) : TMembersSymbolTable;
begin
   Result := TMembersSymbolTable.Create(nil, addrGenerator);
   Result.Owner:=Self;
end;

// GetIsStatic
//
function TCompositeTypeSymbol.GetIsStatic : Boolean;
begin
   Result:=False;
end;

// GetIsExternal
//
function TCompositeTypeSymbol.GetIsExternal : Boolean;
begin
   Result:=False;
end;

// GetIsExternalRooted
//
function TCompositeTypeSymbol.GetIsExternalRooted : Boolean;
begin
   Result:=IsExternal;
end;

// GetExternalName
//
function TCompositeTypeSymbol.GetExternalName : String;
begin
   Result:=Name;
end;

// GetIsPartial
//
function TCompositeTypeSymbol.GetIsPartial : Boolean;
begin
   Result:=False;
end;

// GetIsImmutable
//
function TCompositeTypeSymbol.GetIsImmutable : Boolean;
begin
   Result:=False;
end;

// FindDefaultConstructor
//
function TCompositeTypeSymbol.FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol;
begin
   Result:=nil;
end;

// MembersVisibilities
//
function TCompositeTypeSymbol.MembersVisibilities : TdwsVisibilities;
begin
   Result:=Members.Visibilities;
   if Parent<>nil then
      Result:=Result+Parent.MembersVisibilities;
end;

// CheckMethodsImplemented
//
function CompareSourceMethSymbolByDeclarePos(a, b : Pointer) : Integer;
begin
   Result := TSourceMethodSymbol(a).DeclarationPosition.Compare(TSourceMethodSymbol(b).DeclarationPosition);
end;
procedure TCompositeTypeSymbol.CheckMethodsImplemented(const msgs : TdwsCompileMessageList);

   procedure CreateAutoFixAddImplementation(msg : TScriptMessage; methSym : TMethodSymbol);
   var
      afa : TdwsAFAAddImplementation;
      buf : String;
      k : Integer;
   begin
      afa := TdwsAFAAddImplementation.Create(msg, AFA_AddImplementation);
      buf := methSym.GetDescription;
      FastStringReplace(buf, '()', ' ');
      afa.Text :=  #10
                 + TrimRight(buf)
                 + ';'#10'begin'#10#9'|'#10'end;'#10;
      k := Pos(methSym.Name, afa.Text);
      afa.Text := Copy(afa.Text, 1, k-1) + methSym.StructSymbol.Name + '.'
                + Copy(afa.Text, k);
   end;

var
   i : Integer;
   methSym : TMethodSymbol;
   msg : TScriptMessage;
   errorList : TTightList;
begin
   errorList.Initialize;
   for i := 0 to FMembers.Count-1 do begin
      if FMembers[i] is TMethodSymbol then begin
         methSym := TMethodSymbol(FMembers[i]);
         if methSym.ClassType=TAliasMethodSymbol then continue;
         if methSym.IgnoreMissingImplementation then continue;
         if methSym.IsAbstract then continue;

         if Assigned(methSym.FExecutable) then
            methSym.FExecutable.InitSymbol(FMembers[i], msgs)
         else if not methSym.IsExternal then begin
            if methSym is TSourceMethodSymbol then begin
               errorList.Add(methSym)
            end else begin
               msgs.AddCompilerErrorFmt(cNullPos, CPE_MethodNotImplemented,
                                        [methSym.Name, methSym.StructSymbol.Caption]);
            end;
         end;
      end;
   end;
   if errorList.Count > 0 then begin
      errorList.Sort(CompareSourceMethSymbolByDeclarePos);
      for i := 0 to errorList.Count-1 do begin
         methSym := TMethodSymbol(errorList.List[i]);
         msg:=msgs.AddCompilerErrorFmt(methSym.DeclarationPosition, CPE_MethodNotImplemented,
                                       [methSym.Name, methSym.StructSymbol.Caption]);
         CreateAutoFixAddImplementation(msg, methSym);
      end;
      errorList.Clear;
   end;
end;

// ExternalRoot
//
function TCompositeTypeSymbol.ExternalRoot : TCompositeTypeSymbol;
begin
   Result:=Self;
   while (Result<>nil) and not Result.IsExternal do
      Result:=Result.Parent;
end;

// AllowFields
//
function TCompositeTypeSymbol.AllowFields : Boolean;
begin
   Result:=False;
end;

// AllowAnonymousMethods
//
function TCompositeTypeSymbol.AllowAnonymousMethods : Boolean;
begin
   Result:=True;
end;

// PrepareFirstField
//
function TCompositeTypeSymbol.PrepareFirstField : TFieldSymbol;
var
   member : TSymbol;
begin
   if Parent<>nil then
      Result:=Parent.FirstField
   else Result:=nil;
   for member in Members do begin
      if member is TFieldSymbol then begin
         TFieldSymbol(member).NextField:=Result;
         Result:=TFieldSymbol(member);
      end;
   end;
   FFirstField:=Result;
end;

// FirstField
//
function TCompositeTypeSymbol.FirstField : TFieldSymbol;
begin
   if FFirstField=cFirstFieldUnprepared then
      PrepareFirstField;
   Result:=FFirstField;
end;

// SpecializeMembers
//
procedure TCompositeTypeSymbol.SpecializeMembers(destination : TCompositeTypeSymbol;
                                                 const context : ISpecializationContext);
var
   i : Integer;
   member : TSymbol;
   specialized : TSymbol;
   field, specializedField : TFieldSymbol;
   fieldType : TTypeSymbol;
   specializedProp : TPropertySymbol;
   firstPropertyIndex : Integer;
begin
   firstPropertyIndex := Members.Count;
   // specialize fields in a first pass
   for i := 0 to Members.Count-1 do begin
      member := Members[i];
      if member is TFieldSymbol then begin
         field := TFieldSymbol(member);
         fieldType := context.SpecializeType(field.Typ);
         specializedField := TFieldSymbol.Create(field.Name, fieldType, field.Visibility);
         destination.AddField(specializedField);
         context.RegisterSpecialization(field, specializedField);
      end;
   end;
   // specialize methods
   for i := 0 to Members.Count-1 do begin
      member := Members[i];
      if member is TFieldSymbol then begin
         // already specialized
         continue;
      end else if member is TMethodSymbol then begin
         specialized := TMethodSymbol(member).SpecializeType(context);
         if specialized <> nil then begin
            destination.AddMethod(specialized as TMethodSymbol);
            context.RegisterSpecialization(member, specialized);
            specialized.IncRefCount;
         end;
      end else if member is TPropertySymbol then begin
         // specialize properties in a separate pass as they refer other members
         if i < firstPropertyIndex then
            firstPropertyIndex := i;
      end else begin
         context.AddCompilerErrorFmt(CPE_SpecializationNotSupportedYet, [member.ClassName]);
      end;
   end;
   // specialize properties
   for i := firstPropertyIndex to Members.Count-1 do begin
      member := Members[i];
      if member is TPropertySymbol then begin
         specializedProp := member.Specialize(context) as TPropertySymbol;
         destination.AddProperty(specializedProp);
      end;
   end;
end;

// GetIsGeneric
//
function TCompositeTypeSymbol.GetIsGeneric : Boolean;
begin
   Result := False; // TODO
end;

// ------------------
// ------------------ TStructuredTypeSymbol ------------------
// ------------------

// Destroy
//
destructor TStructuredTypeSymbol.Destroy;
begin
   if FForwardPosition<>nil then
      Dispose(FForwardPosition);
   FMetaSymbol.Free;
   inherited;
end;

// DoInheritFrom
//
procedure TStructuredTypeSymbol.DoInheritFrom(ancestor : TStructuredTypeSymbol);
begin
   Assert(FParent=nil);
   Assert(FMembers.Count=0);

   FMembers.AddParent(ancestor.Members);
   FParent:=ancestor;
end;

// NthParentOf
//
function TStructuredTypeSymbol.NthParentOf(structType : TCompositeTypeSymbol) : Integer;
begin
   Result:=0;
   while structType<>nil do begin
      if structType=Self then
         Exit
      else begin
         structType:=structType.Parent;
         Inc(Result);
      end;
   end;
   Result:=-1;
end;

// DistanceTo
//
function TStructuredTypeSymbol.DistanceTo(typeSym : TTypeSymbol) : Integer;
begin
   if typeSym=Self then
      Result:=0
   else if typeSym is TStructuredTypeSymbol then
      Result:=TStructuredTypeSymbol(typeSym).NthParentOf(Self)
   else Result:=MaxInt;
end;

// IsForwarded
//
function TStructuredTypeSymbol.IsForwarded : Boolean;
begin
   Result:=Assigned(FForwardPosition);
end;

// DuckTypedMatchingMethod
//
function TStructuredTypeSymbol.DuckTypedMatchingMethod(methSym : TMethodSymbol; visibility : TdwsVisibility) : TMethodSymbol;
var
   sym : TSymbol;
   meth : TMethodSymbol;
begin
   for sym in Members do begin
      if sym is TMethodSymbol then begin
         meth:=TMethodSymbol(sym);
         if     (meth.Visibility>=visibility)
            and UnicodeSameText(meth.Name, methSym.Name)
            and meth.IsCompatible(methSym) then
               Exit(meth);
      end;
   end;
   if Parent<>nil then
      Result:=(Parent as TStructuredTypeSymbol).DuckTypedMatchingMethod(methSym, cvPublic)
   else Result:=nil;
end;

// FindDefaultConstructor
//
function TStructuredTypeSymbol.FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol;
begin
   Result:=nil;
end;

// AllowDefaultProperty
//
function TStructuredTypeSymbol.AllowDefaultProperty : Boolean;
begin
   Result:=True;
end;

// SetForwardedPos
//
procedure TStructuredTypeSymbol.SetForwardedPos(const aScriptPos: TScriptPos);
begin
   if FForwardPosition=nil then
      New(FForwardPosition);
   FForwardPosition^:=aScriptPos;
end;

// ClearIsForwarded
//
procedure TStructuredTypeSymbol.ClearIsForwarded;
begin
   Dispose(FForwardPosition);
   FForwardPosition:=nil;
end;

// GetIsExternal
//
function TStructuredTypeSymbol.GetIsExternal : Boolean;
begin
   Result:=False;
end;

// GetExternalName
//
function TStructuredTypeSymbol.GetExternalName : String;
begin
   if FExternalName='' then
      Result:=Name
   else Result:=FExternalName;
end;

// GetMetaSymbol
//
function TStructuredTypeSymbol.GetMetaSymbol : TStructuredTypeMetaSymbol;
begin
   Result:=FMetaSymbol;
end;

// ------------------
// ------------------ TStructuredTypeMetaSymbol ------------------
// ------------------

// Create
//
constructor TStructuredTypeMetaSymbol.Create(const name : String; typ : TStructuredTypeSymbol);
begin
   inherited Create(name, typ);
   FSize:=1;
end;

// InitData
//
procedure TStructuredTypeMetaSymbol.InitData(const Data: TData; Offset: Integer);
begin
   Data[Offset] := Int64(0);
end;

// IsCompatible
//
function TStructuredTypeMetaSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(typSym is TStructuredTypeMetaSymbol) and (Typ.BaseType=typSym.Typ.BaseType);
end;

// StructSymbol
//
function TStructuredTypeMetaSymbol.StructSymbol : TStructuredTypeSymbol;
begin
   Result:=TStructuredTypeSymbol(Typ);
end;

// Parent
//
function TStructuredTypeMetaSymbol.Parent : TStructuredTypeMetaSymbol;
var
   p : TCompositeTypeSymbol;
begin
   p:=StructSymbol.Parent;
   if (p=nil) or not (p is TStructuredTypeSymbol) then
      Result:=nil
   else Result:=TStructuredTypeSymbol(p).MetaSymbol;
end;

// ------------------
// ------------------ TRecordSymbol ------------------
// ------------------

// Create
//
constructor TRecordSymbol.Create(const name : String; aUnit : TSymbol);
begin
   inherited Create(name, aUnit);
   FMetaSymbol:=TStructuredTypeMetaSymbol.Create('meta of '+name, Self);
end;

// AddField
//
procedure TRecordSymbol.AddField(fieldSym : TFieldSymbol);
begin
   inherited;
   fieldSym.FOffset := FSize;
   FSize := FSize + fieldSym.Typ.Size;
   if fieldSym.DefaultExpr <> nil then
      IsDynamic := True;
   if fieldSym.Typ.DynamicInitialization then
      Include(FFlags, rsfDynamicInitialization);
end;

// AddMethod
//
procedure TRecordSymbol.AddMethod(methSym : TMethodSymbol);
begin
   inherited;
   if methSym.IsClassMethod then
      methSym.SetIsStatic;
end;

// Initialize
//
procedure TRecordSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   CheckMethodsImplemented(msgs);
end;

// AllowFields
//
function TRecordSymbol.AllowFields : Boolean;
begin
   Result:=True;
end;

// CreateSelfParameter
//
function TRecordSymbol.CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol;
begin
   if methSym.IsClassMethod then
      Result:=nil
   else begin
      Result:=TVarParamSymbol.Create(SYS_SELF, Self);
      methSym.Params.AddSymbol(Result);
   end;
end;

// CreateAnonymousMethod
//
function TRecordSymbol.CreateAnonymousMethod(
      aFuncKind : TFuncKind; aVisibility : TdwsVisibility; isClassMethod : Boolean) : TMethodSymbol;
begin
   Result:=TSourceMethodSymbol.Create('', aFuncKind, Self, aVisibility, isClassMethod);
   if isClassMethod then
      TSourceMethodSymbol(Result).SetIsStatic;
end;

// InitData
//
procedure TRecordSymbol.InitData(const data : TData; offset : Integer);
var
   field : TFieldSymbol;
begin
   field:=FirstField;
   while field<>nil do begin
      field.InitData(data, offset);
      field:=field.NextField;
   end;
end;

// DynamicInitialization
//
function TRecordSymbol.DynamicInitialization : Boolean;
begin
   Result := rsfDynamicInitialization in FFlags;
end;

// IsCompatible
//
function TRecordSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   if typSym=nil then Exit(False);
   typSym:=typSym.UnAliasedType.BaseType;
   if not (typSym is TRecordSymbol) then
      Exit(False);
   if Self=typSym then
      Exit(True);

   Result:=False;
end;

// AssignsAsDataExpr
//
function TRecordSymbol.AssignsAsDataExpr : Boolean;
begin
   Result := True;
end;

// SpecializeType
//
function TRecordSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
var
   specializedRecord : TRecordSymbol;
begin
   Assert(rsfFullyDefined in FFlags);

   specializedRecord := TRecordSymbol.Create(context.Name, context.UnitSymbol);

   context.EnterComposite(specializedRecord);
   try
      SpecializeMembers(specializedRecord, context);
   finally
      context.LeaveComposite;
   end;

   specializedRecord.FFlags := FFlags;
   Result := specializedRecord;
end;

// SetIsExternal
//
procedure TRecordSymbol.SetIsExternal;
begin
   Include(FFlags, rsfExternal);
end;

// GetCaption
//
function TRecordSymbol.GetCaption : String;
begin
   if Name = '' then
      Result := 'anonymous record'
   else Result := 'record ' + Name;
end;

// GetDescription
//
function TRecordSymbol.GetDescription : String;
var
   member : TSymbol;
begin
   if Name='' then
      Result := 'anonymous record'#13#10
   else Result:=Name+' = record'#13#10;
   for member in FMembers do begin
      if member is TFieldSymbol then
         Result:=Result+'   '+member.Name+' : '+member.Typ.Name+';'#13#10;
   end;
   Result:=Result+'end;';
end;

// GetIsDynamic
//
function TRecordSymbol.GetIsDynamic : Boolean;
begin
   Result:=(rsfDynamic in FFlags);
end;

// SetIsDynamic
//
procedure TRecordSymbol.SetIsDynamic(const val : Boolean);
begin
   if val then
      Include(FFlags, rsfDynamic)
   else Exclude(FFlags, rsfDynamic);
end;

// GetIsImmutable
//
function TRecordSymbol.GetIsImmutable : Boolean;
begin
   Result:=(rsfImmutable in FFlags);
end;

// SetIsImmutable
//
procedure TRecordSymbol.SetIsImmutable(const val : Boolean);
begin
   if val then
      Include(FFlags, rsfImmutable)
   else Exclude(FFlags, rsfImmutable);
end;

// GetIsFullyDefined
//
function TRecordSymbol.GetIsFullyDefined : Boolean;
begin
   Result:=(rsfFullyDefined in FFlags);
end;

// SetIsFullyDefined
//
procedure TRecordSymbol.SetIsFullyDefined(const val : Boolean);
begin
   if val then
      Include(FFlags, rsfFullyDefined)
   else Exclude(FFlags, rsfFullyDefined);
end;

// GetIsExternal
//
function TRecordSymbol.GetIsExternal : Boolean;
begin
   Result := rsfExternal in FFlags;
end;

// ------------------
// ------------------ TInterfaceSymbol ------------------
// ------------------

// Create
//
constructor TInterfaceSymbol.Create(const name : String; aUnit : TSymbol);
begin
   inherited;
   FSize:=1;
end;

// GetCaption
//
function TInterfaceSymbol.GetCaption : String;
begin
   Result:=Name;
end;

// GetDescription
//
function TInterfaceSymbol.GetDescription : String;
begin
   Result:=Name+' = interface';
   if Parent<>nil then
      Result:=Result+'('+Parent.Name+')';
end;

// InheritFrom
//
procedure TInterfaceSymbol.InheritFrom(ancestor : TInterfaceSymbol);
begin
   DoInheritFrom(ancestor);
   FMethodCount:=ancestor.MethodCount;
end;

// AddMethod
//
procedure TInterfaceSymbol.AddMethod(methSym : TMethodSymbol);
begin
   inherited;
   if methSym.Name<>'' then begin
      methSym.FVMTIndex:=FMethodCount;
      Inc(FMethodCount);
   end;
end;

// InitData
//
procedure TInterfaceSymbol.InitData(const Data: TData; Offset: Integer);
const
   cNilIntf : IUnknown = nil;
begin
   Data[Offset]:=cNilIntf;
end;

// Initialize
//
procedure TInterfaceSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   // Check validity of the interface declaration
   if IsForwarded then
      msgs.AddCompilerErrorFmt(FForwardPosition^, CPE_InterfaceNotCompletelyDefined, [Name]);
end;

// IsCompatible
//
function TInterfaceSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   typSym:=typSym.UnAliasedType;
   if typSym is TNilSymbol then
      Result:=True
   else if typSym is TInterfaceSymbol then
      Result:=(NthParentOf(TInterfaceSymbol(typSym))>=0)
   else Result:=False;
end;

// IsPointerType
//
function TInterfaceSymbol.IsPointerType : Boolean;
begin
   Result:=True;
end;

// SpecializeType
//
function TInterfaceSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
var
   specializedInterface : TInterfaceSymbol;
begin
   specializedInterface := TInterfaceSymbol.Create(context.Name, context.UnitSymbol);

   context.EnterComposite(specializedInterface);
   try
      SpecializeMembers(specializedInterface, context);
   finally
      context.LeaveComposite;
   end;

   Result := specializedInterface;
end;

// CreateSelfParameter
//
function TInterfaceSymbol.CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol;
begin
   Assert(not methSym.IsClassMethod);
   Result:=TSelfSymbol.Create(SYS_SELF, Self);
   methSym.InternalParams.AddSymbol(Result);
end;

// CreateAnonymousMethod
//
function TInterfaceSymbol.CreateAnonymousMethod(
      aFuncKind : TFuncKind; aVisibility : TdwsVisibility; isClassMethod : Boolean) : TMethodSymbol;
begin
   Result:=TSourceMethodSymbol.Create('', aFuncKind, Self, aVisibility, isClassMethod);
end;

// DoIsOfType
//
function TInterfaceSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   typSym:=typSym.UnAliasedType;
   if typSym is TInterfaceSymbol then
      Result:=(NthParentOf(TInterfaceSymbol(typSym))>=0)
   else Result:=False;
end;

// Parent
//
function TInterfaceSymbol.Parent : TInterfaceSymbol;
begin
   Result:=TInterfaceSymbol(FParent);
end;

// ------------------
// ------------------ TFieldSymbol ------------------
// ------------------

// Create
//
constructor TFieldSymbol.Create(const Name: String; Typ: TTypeSymbol; aVisibility : TdwsVisibility);
begin
   inherited Create(Name, Typ);
   FVisibility:=aVisibility;
end;

// Destroy
//
destructor TFieldSymbol.Destroy;
begin
   FDefaultExpr.Free;
   inherited;
end;

// QualifiedName
//
function TFieldSymbol.QualifiedName : String;
begin
   Result := String(StructSymbol.QualifiedName+'.'+Name);
end;

// IsVisibleFor
//
function TFieldSymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=(FVisibility>=aVisibility);
end;

// HasExternalName
//
function TFieldSymbol.HasExternalName : Boolean;
begin
   Result:=(FExternalName<>'');
end;

// InitData
//
procedure TFieldSymbol.InitData(const data : TData; structOffset : Integer);
begin
   if DefaultValue<>nil then
      DWSCopyData(DefaultValue, 0, data, structOffset+Offset, Typ.Size)
   else Typ.InitData(data, structOffset+Offset);
end;

// GetExternalName
//
function TFieldSymbol.GetExternalName : String;
begin
   if FExternalName='' then
      Result:=Name
   else Result:=FExternalName;
end;

// ------------------
// ------------------ TClassConstSymbol ------------------
// ------------------

// QualifiedName
//
function TClassConstSymbol.QualifiedName : String;
begin
   Result := String(OwnerSymbol.QualifiedName+'.'+Name);
end;

// IsVisibleFor
//
function TClassConstSymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=(FVisibility>=aVisibility);
end;

// ------------------
// ------------------ TClassVarSymbol ------------------
// ------------------

// Create
//
constructor TClassVarSymbol.Create(const aName : String; aType : TTypeSymbol; aVisibility :  TdwsVisibility);
begin
   inherited Create(aName, aType);
   Visibility:=aVisibility;
end;

// QualifiedName
//
function TClassVarSymbol.QualifiedName : String;
begin
   Result := String(OwnerSymbol.QualifiedName+'.'+Name);
end;

// IsVisibleFor
//
function TClassVarSymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=(FVisibility>=aVisibility);
end;

// ------------------
// ------------------ TFuncSymbol ------------------
// ------------------

// Create
//
constructor TFuncSymbol.Create(const name : String; funcKind : TFuncKind;
                               funcLevel : SmallInt);
begin
   inherited Create(name, nil);
   FKind:=funcKind;
   FAddrGenerator:=TAddrGeneratorRec.CreateNegative(funcLevel);
   FInternalParams:=TUnSortedSymbolTable.Create(nil, @FAddrGenerator);
   FParams:= TParamsSymbolTable.Create(FInternalParams, @FAddrGenerator);
   FSize:=1;
end;

// Destroy
//
destructor TFuncSymbol.Destroy;
begin
   if FForwardPosition<>nil then
      Dispose(FForwardPosition);
   FParams.Free;
   FInternalParams.Free;
   FConditions.Free;
   inherited;
end;

// Generate
//
constructor TFuncSymbol.Generate(table : TSymbolTable; const funcName : String;
                                 const funcParams : TParamArray; const funcType : String);
var
   typSym : TTypeSymbol;
begin
   if funcType<>'' then begin
      Self.Create(funcName, fkFunction, 1);
      // Set function type
      typSym:=table.FindTypeSymbol(funcType, cvMagic);
      if (typSym=nil) or (typSym.BaseType=nil) then
         raise Exception.CreateFmt(CPE_TypeIsUnknown, [funcType]);
      Self.SetType(typSym);
   end else begin
      Self.Create(funcName, fkProcedure, 1);
   end;

   GenerateParams(table, funcParams);
end;

// AddParam
//
procedure TFuncSymbol.AddParam(param : TParamSymbol);
begin
   Params.AddSymbol(param);
end;

// AddParams
//
procedure TFuncSymbol.AddParams(params : TParamsSymbolTable);
var
   i : Integer;
begin
   for i:=0 to params.Count-1 do
      AddParam(params[i].Clone);
end;

// HasParam
//
function TFuncSymbol.HasParam(param : TParamSymbol) : Boolean;
begin
   Result:=(Params.FindLocal(param.Name)<>nil);
end;

// SetType
//
procedure TFuncSymbol.SetType(const value : TTypeSymbol);
begin
   FTyp:=Value;
   Assert(FResult=nil);
   if FTyp<>nil then begin
      FResult:=TResultSymbol.Create(SYS_RESULT, Value);
      FInternalParams.AddSymbol(FResult);
   end;
end;

// GenerateParams
//
procedure GenerateParams(table : TSymbolTable; const funcParams : TParamArray;
                         const addProc : TAddParamSymbolMethod);
var
   i : Integer;
   i64 : Int64;
   typSym : TTypeSymbol;
   baseTypClass : TClass;
   paramSym : TParamSymbol;
   paramSymWithDefault : TParamSymbolWithDefaultValue;
   paramRec : PParamRec;
begin
   typSym:=nil;

   for i:=0 to High(FuncParams) do begin

      paramRec:=@FuncParams[i];
      if (typSym=nil) or not UnicodeSameText(typSym.Name, paramRec.ParamType) then
         typSym:=Table.FindTypeSymbol(paramRec.ParamType, cvMagic);
      if (typSym = nil) and (paramRec.ParamType = 'array of Any Type') then begin
         typSym := TDynamicArraySymbol.Create('', table.FindTypeSymbol(SYS_ANY_TYPE, cvPublic), Table.FindTypeSymbol(SYS_INTEGER, cvPublic));
         table.AddSymbol(typSym);
      end;

      if not Assigned(typSym) then
         raise Exception.CreateFmt(CPE_TypeForParamNotFound,
                                   [paramRec.ParamType, paramRec.ParamName]);

      if paramRec.HasDefaultValue then begin

         if paramRec.IsVarParam then
            raise Exception.Create(CPE_VarParamCantHaveDefaultValue);
         if paramRec.IsConstParam then
            raise Exception.Create(CPE_ConstParamCantHaveDefaultValue);

         Assert(Length(paramRec.DefaultValue)=1);
         baseTypClass := typSym.BaseType.UnAliasedType.ClassType;
         if not baseTypClass.InheritsFrom(TBaseStringSymbol) then begin
            if baseTypClass.InheritsFrom(TBaseIntegerSymbol) then begin
               VariantToInt64(paramRec.DefaultValue[0], i64);
               paramRec.DefaultValue[0] := i64;
            end else if baseTypClass.InheritsFrom(TBaseFloatSymbol) then begin
               paramRec.DefaultValue[0] := VariantToFloat(paramRec.DefaultValue[0]);
            end else if baseTypClass.InheritsFrom(TBaseBooleanSymbol) then begin
               paramRec.DefaultValue[0] := SameText(paramRec.DefaultValue[0], 'True');
            end;
         end;

         paramSymWithDefault:=TParamSymbolWithDefaultValue.Create(paramRec.ParamName, typSym,
                                                                  paramRec.DefaultValue);
         paramSym:=paramSymWithDefault;

      end else begin

         if paramRec.IsVarParam then
            paramSym := TVarParamSymbol.Create(paramRec.ParamName, typSym)
         else if paramRec.IsConstParam then
            paramSym := CreateConstParamSymbol(paramRec.ParamName, typSym)
         else paramSym := TParamSymbol.Create(paramRec.ParamName, typSym, paramRec.Options);

      end;

      addProc(paramSym);

   end;
end;

// GenerateParams
//
procedure TFuncSymbol.GenerateParams(table : TSymbolTable; const funcParams : TParamArray);
begin
   dwsSymbols.GenerateParams(table, funcParams, addParam);
end;

// GetParamType
//
function TFuncSymbol.GetParamType(idx : Integer) : TTypeSymbol;
begin
   if Cardinal(idx)<Cardinal(Params.Count) then
      Result:=Params[idx].Typ
   else Result:=nil;
end;

// ParamTypeForbidsImplicitCasts
//
function TFuncSymbol.ParamTypeForbidsImplicitCasts(idx : Integer) : Boolean;
begin
   if Cardinal(idx) < Cardinal(Params.Count) then
      Result := Params[idx].ForbidImplicitCasts
   else Result := False;
end;

// GetCaption
//
function TFuncSymbol.GetCaption : String;
var
   i : Integer;
   nam : String;
   p : TParamSymbol;
   semantics : TParamSymbolSemantics;
begin
   nam:=cFuncKindToString[Kind]+' '+Name;

   if Params.Count>0 then begin
      Result := '(';
      for i := 0 to Params.Count-1 do begin
         if i > 0 then
            Result := Result + ', ';
         p := Params[i];
         semantics := p.Semantics;
         if cParamSymbolSemanticsPrefix[semantics] <> '' then
            Result := Result + cParamSymbolSemanticsPrefix[semantics] + ' ';
         Result := Result + Params[i].Typ.Caption;
      end;
      Result := Result + ')';
   end else Result:='';

   if Typ<>nil then
      if Typ.Name<>'' then
         Result:=nam+Result+': '+Typ.Name
      else Result:=nam+Result+': '+Typ.Caption
   else Result:=nam+Result;
end;

// GetIsForwarded
//
function TFuncSymbol.IsForwarded : Boolean;
begin
   Result:=Assigned(FForwardPosition);
end;

// GetDescription
//
function TFuncSymbol.GetDescription : String;
begin
   Result := cFuncKindToString[Kind] + ' ' + Name + ParamsDescription;
   if Typ <> nil then
      Result := Result + ': ' + Typ.Name;
end;

// Initialize
//
procedure TFuncSymbol.Initialize(const msgs : TdwsCompileMessageList);
var
   msg : TScriptMessage;
   afa : TdwsAFAAddImplementation;
begin
   inherited;
   if IsExternal then Exit;
   FInternalParams.Initialize(msgs);
   if Assigned(FExecutable) then
      FExecutable.InitSymbol(Self, msgs)
   else if Level>=0 then begin
      msg:=msgs.AddCompilerErrorFmt(FForwardPosition^, CPE_ForwardNotImplemented, [Name]);
      afa:=TdwsAFAAddImplementation.Create(msg, AFA_AddImplementation);
      afa.Text:= #13#10
                +TrimRight(StringReplace(GetDescription, '()', ' ', [rfIgnoreCase]))
                +';'#13#10'begin'#13#10#9'|'#13#10'end;'#13#10;
   end;
end;

// GetLevel
//
function TFuncSymbol.GetLevel: SmallInt;
begin
   Result:=FAddrGenerator.Level;
end;

// GetParamSize
//
function TFuncSymbol.GetParamSize : Integer;
begin
   Result:=FAddrGenerator.DataSize;
end;

// GetIsStateless
//
function TFuncSymbol.GetIsStateless : Boolean;
begin
   Result:=(fsfStateless in FFlags);
end;

// SetIsStateless
//
procedure TFuncSymbol.SetIsStateless(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfStateless)
   else Exclude(FFlags, fsfStateless);
end;

// GetIsExternal
//
function TFuncSymbol.GetIsExternal : Boolean;
begin
   Result:=(fsfExternal in FFlags);
end;

// SetIsExternal
//
procedure TFuncSymbol.SetIsExternal(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfExternal)
   else Exclude(FFlags, fsfExternal);
end;

// GetIsExport
//
function TFuncSymbol.GetIsExport : Boolean;
begin
   Result:=(fsfExport in FFlags);
end;

// SetIsExport
//
procedure TFuncSymbol.SetIsExport(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfExport)
   else Exclude(FFlags, fsfExport);
end;

// GetIsProperty
//
function TFuncSymbol.GetIsProperty : Boolean;
begin
   Result:=(fsfProperty in FFlags);
end;

// SetIsProperty
//
procedure TFuncSymbol.SetIsProperty(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfProperty)
   else Exclude(FFlags, fsfProperty);
end;

// GetIsOverloaded
//
function TFuncSymbol.GetIsOverloaded : Boolean;
begin
   Result:=(fsfOverloaded in FFlags);
end;

// SetIsOverloaded
//
procedure TFuncSymbol.SetIsOverloaded(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfOverloaded)
   else Exclude(FFlags, fsfOverloaded);
end;

// GetIsLambda
//
function TFuncSymbol.GetIsLambda : Boolean;
begin
   Result:=(fsfLambda in FFlags);
end;

// SetIsLambda
//
procedure TFuncSymbol.SetIsLambda(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfLambda)
   else Exclude(FFlags, fsfLambda);
end;

// GetIsOfObject
//
function TFuncSymbol.GetIsOfObject : Boolean;
begin
   Result := (fsfOfObject in FFlags);
end;

// SetIsOfObject
//
procedure TFuncSymbol.SetIsOfObject(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfOfObject)
   else Exclude(FFlags, fsfOfObject);
end;

// GetIsReferenceTo
//
function TFuncSymbol.GetIsReferenceTo : Boolean;
begin
   Result := (fsfReferenceTo in FFlags);
end;

// SetIsReferenceTo
//
procedure TFuncSymbol.SetIsReferenceTo(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfReferenceTo)
   else Exclude(FFlags, fsfReferenceTo);
end;

// GetIsAsync
//
function TFuncSymbol.GetIsAsync : Boolean;
begin
   Result := (fsfAsync in FFlags);
end;

// SetIsAsync
//
procedure TFuncSymbol.SetIsAsync(const val : Boolean);
begin
   if val then
      Include(FFlags, fsfAsync)
   else Exclude(FFlags, fsfAsync);
end;

// GetDeclarationPosition
//
function TFuncSymbol.GetDeclarationPosition : TScriptPos;
begin
   Result := cNullPos;
end;

// SetDeclarationPosition
//
procedure TFuncSymbol.SetDeclarationPosition(const val : TScriptPos);
begin
   Assert(False);
end;

// GetImplementationPosition
//
function TFuncSymbol.GetImplementationPosition : TScriptPos;
begin
   Result := cNullPos;
end;

// SetImplementationPosition
//
procedure TFuncSymbol.SetImplementationPosition(const val : TScriptPos);
begin
   Assert(False);
end;

// GetExternalName
//
function TFuncSymbol.GetExternalName : String;
begin
   if FExternalName='' then
      Result:=Name
   else Result:=FExternalName;
end;

// GetSourceSubExpr
//
function TFuncSymbol.GetSourceSubExpr(i : Integer) : TExprBase;
begin
   Result:=FExecutable.SubExpr(i);
end;

// GetSourceSubExprCount
//
function TFuncSymbol.GetSourceSubExprCount : Integer;
begin
   if FExecutable<>nil then
      Result:=FExecutable.SubExprCount
   else Result:=0;
end;

// IsCompatible
//
function TFuncSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
const
   cCompatibleKinds : array [TFuncKind, TFuncKind] of Boolean =
      //  fkFunction, fkProcedure, fkConstructor, fkDestructor, fkMethod, fkLambda
      ( (     True,      False,        False,         False,      True,     True),      // fkFunction
        (     False,     True,         False,         False,      True,     True),      // fkProcedure
        (     False,     False,        True,          False,      False,    False),     // fkConstructor
        (     False,     False,        False,         True,       False,    False),     // fkDestructor
        (     True,      True,         False,         False,      True,     True),      // fkMethod
        (     True,      True,         False,         False,      True,     True) );    // fkLambda
var
   funcSym : TFuncSymbol;
   i : Integer;
   param, otherParam : TSymbol;
begin
   if typSym = nil then Exit(False);
   typSym := typSym.BaseType;
   if typSym.IsCompatibleWithAnyFuncSymbol then
      Result := True
   else begin
      Result:=False;
      funcSym:=typSym.AsFuncSymbol;
      if funcSym=nil then
         Exit;
      if Params.Count<>funcSym.Params.Count then Exit;
      if not cCompatibleKinds[Kind, funcSym.Kind] then Exit;
      if    (Typ=funcSym.Typ)
         or (Typ.IsOfType(funcSym.Typ))
         or (funcSym.Typ is TAnyTypeSymbol) then begin
         for i:=0 to Params.Count-1 do begin
            param:=Params[i];
            otherParam:=funcSym.Params[i];
            if param.ClassType<>otherParam.ClassType then Exit;
            if param.Typ<>otherParam.Typ then begin
               if not param.Typ.IsCompatible(otherParam.Typ) then Exit;
               if not otherParam.Typ.IsCompatible(param.Typ) then Exit;
            end;
         end;
         Result:=True;
      end;
   end;
end;

// DoIsOfType
//
function TFuncSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
var
   i : Integer;
   funcSym : TFuncSymbol;
begin
   funcSym:=typSym.AsFuncSymbol;
   if funcSym=nil then
      Exit(False);

   Result:=    (Kind=funcSym.Kind)
           and (Params.Count=funcSym.Params.Count);
   if not Result then Exit;

   if Typ=nil then begin
      if funcSym.Typ<>nil then
         Exit(False)
   end else if not Typ.IsCompatible(funcSym.Typ) then
      Exit(False);

   for i:=0 to Params.Count-1 do begin
      if not Params[i].Typ.DoIsOfType(funcSym.Params[i].Typ) then
         Exit(False);
   end;
   Result:=True;
end;

// InternalSpecialize
//
procedure TFuncSymbol.InternalSpecialize(destination : TFuncSymbol; const context : ISpecializationContext);
var
   i, skip : Integer;
   specializedParam : TSymbol;
   param : TParamSymbol;
begin
   if FConditions <> nil then
      context.AddCompilerError('Functions with conditions cannot be specialized yet');

   destination.FFlags := FFlags;
   if fsfExternal in FFlags then
      if FExternalName <> '' then
         destination.FExternalName := FExternalName
      else destination.FExternalName := Name
   else destination.FExternalName := FExternalName;

   destination.FExternalConvention := FExternalConvention;

   // internal paramps are all pre-specialized
   // but Result is handled separately
   if Self.Result <> nil then
      skip := 1
   else skip := 0;
   Assert(destination.InternalParams.Count = InternalParams.Count-skip);
   for i := 0 to InternalParams.Count-1-skip do begin
      specializedParam := destination.InternalParams[i];
      context.RegisterSpecialization(InternalParams[i], specializedParam);
   end;

   // some params can be pre-specialized
   Assert(destination.Params.Count <= Params.Count);
   for i := 0 to destination.Params.Count-1 do begin
      specializedParam := destination.Params[i];
      context.RegisterSpecialization(Params[i], specializedParam);
   end;

   // specialize remaining parameters
   for i := destination.Params.Count to Params.Count-1 do begin
      param := Params[i];
      specializedParam := param.Specialize(context);
      destination.Params.AddSymbol(specializedParam);
      context.RegisterSpecialization(param, specializedParam);
   end;

   destination.Typ := context.SpecializeType(typ);
   context.RegisterSpecialization(Self.Result, destination.Result);

   destination.Executable := context.SpecializeExecutable(FExecutable);
end;

// IsType
//
function TFuncSymbol.IsType : Boolean;
begin
   Result:=(fsfType in FFlags);
end;

// SetIsType
//
procedure TFuncSymbol.SetIsType;
begin
   Include(FFlags, fsfType);
end;

// GetAsFuncSymbol
//
function TFuncSymbol.GetAsFuncSymbol : TFuncSymbol;
begin
   Result:=Self;
end;

// SetInline
//
procedure TFuncSymbol.SetInline;
begin
   Include(FFlags, fsfInline);
end;

procedure TFuncSymbol.InitData(const Data: TData; Offset: Integer);
const
  nilIntf: IUnknown = nil;
begin
  Data[Offset] := nilIntf;
end;

// AddCondition
//
procedure TFuncSymbol.AddCondition(cond : TConditionSymbol);
begin
   if FConditions=nil then
      FConditions:=TConditionsSymbolTable.Create(nil, @FAddrGenerator);
   FConditions.AddSymbol(cond);
end;

// IsValidOverloadOf
//
function TFuncSymbol.IsValidOverloadOf(other : TFuncSymbol) : Boolean;
var
   i : Integer;
   n : Integer;
   locParam, otherParam : TParamSymbol;
begin
   // overload is valid if parameter types differ,
   // and there is no ambiguity with default params

   n:=Min(Params.Count, other.Params.Count);

   // check special case of an overload of a parameter-less function
   if (Params.Count=0) and (other.Params.Count=0) then Exit(False);

   // check parameters positions defined in both
   for i:=0 to n-1 do begin
      locParam:=Params[i];
      otherParam:=other.Params[i];
      if     (locParam.ClassType=TParamSymbolWithDefaultValue)
         and (otherParam.ClassType=TParamSymbolWithDefaultValue) then Exit(False);
      if not locParam.Typ.IsOfType(otherParam.Typ) then Exit(True);
   end;

   // check that there is at least one remaining param that is not with a default
   if Params.Count>n then
      Result:=(Params[n].ClassType<>TParamSymbolWithDefaultValue)
   else if other.Params.Count>n then
      Result:=(other.Params[n].ClassType<>TParamSymbolWithDefaultValue)
   else Result:=False;
end;

// IsSameOverloadOf
//
function TFuncSymbol.IsSameOverloadOf(other : TFuncSymbol) : Boolean;
var
   i : Integer;
begin
   Result:=(Kind=other.Kind) and (Typ=other.Typ) and (Params.Count=other.Params.Count);
   if Result then begin
      for i:=0 to Params.Count-1 do begin
         if not Params[i].SameParam(other.Params[i]) then begin
            Result:=False;
            Break;
         end;
      end;
   end;
end;

// SameType
//
function TFuncSymbol.SameType(typSym : TTypeSymbol) : Boolean;
var
   otherFunc : TFuncSymbol;
   i : Integer;
begin
   Result := False;
   if (typSym = nil) or (ClassType <> typSym.ClassType) then Exit;
   if (Typ = nil) xor (typSym.Typ = nil) then Exit;
   if (Typ <> nil) and not Typ.SameType(typSym.Typ) then Exit;

   otherFunc := TFuncSymbol(typSym);
   if Params.Count <> otherFunc.Params.Count then Exit;
   for i := 0 to Params.Count-1 do
      if not Params[i].SameParam(otherFunc.Params[i]) then Exit;

   Result := True;
end;

// ParamsDescription
//
function TFuncSymbol.ParamsDescription : String;
begin
   Result := Params.Description(0);
end;

// SetForwardedPos
//
procedure TFuncSymbol.SetForwardedPos(const aScriptPos: TScriptPos);
begin
   if FForwardPosition=nil then
      New(FForwardPosition);
   FForwardPosition^:=aScriptPos;
end;

// ClearIsForwarded
//
procedure TFuncSymbol.ClearIsForwarded;
begin
   Dispose(FForwardPosition);
   FForwardPosition:=nil;
end;

// HasExternalName
//
function TFuncSymbol.HasExternalName : Boolean;
begin
   Result:=(FExternalName<>'');
end;

// ------------------
// ------------------ TSourceFuncSymbol ------------------
// ------------------

// GetDeclarationPosition
//
function TSourceFuncSymbol.GetDeclarationPosition : TScriptPos;
begin
   Result := FDeclarationPosition;
end;

// SetDeclarationPosition
//
procedure TSourceFuncSymbol.SetDeclarationPosition(const val : TScriptPos);
begin
   FDeclarationPosition := val;
end;

// GetImplementationPosition
//
function TSourceFuncSymbol.GetImplementationPosition : TScriptPos;
begin
   Result := FImplementationPosition;
end;

// SetImplementationPosition
//
procedure TSourceFuncSymbol.SetImplementationPosition(const val : TScriptPos);
begin
   FImplementationPosition := val;
end;

// SpecializeType
//
function TSourceFuncSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
var
   specializedFunc : TSourceFuncSymbol;
begin
   specializedFunc := TSourceFuncSymbol.Create(context.Name, Kind, Level);

   specializedFunc.DeclarationPosition := DeclarationPosition;
   specializedFunc.ImplementationPosition := ImplementationPosition;

   InternalSpecialize(specializedFunc, context);
   Result := specializedFunc;

   context.RegisterInternalType(Result);
end;

// ------------------
// ------------------ TMethodSymbol ------------------
// ------------------

// Create
//
constructor TMethodSymbol.Create(const Name: String; FuncKind: TFuncKind;
  aStructSymbol : TCompositeTypeSymbol; aVisibility : TdwsVisibility; isClassMethod : Boolean;
  funcLevel : Integer);
begin
   inherited Create(Name, FuncKind, funcLevel);
   FStructSymbol := aStructSymbol;
   if isClassMethod then
      Include(FAttributes, maClassMethod);
   FSelfSym := aStructSymbol.CreateSelfParameter(Self);
   FSize:=1; // wrapped in a interface
   FParams.AddParent(FStructSymbol.Members);
   FVisibility:=aVisibility;
   FVMTIndex:=-1;
   if aStructSymbol.IsExternal then
      IsExternal:=True;
end;

constructor TMethodSymbol.Generate(Table: TSymbolTable; MethKind: TMethodKind;
                              const Attributes: TMethodAttributes; const MethName: String;
                              const MethParams: TParamArray; const MethType: String;
                              Cls: TCompositeTypeSymbol; aVisibility : TdwsVisibility;
                              overloaded : Boolean);
var
   typSym : TTypeSymbol;
   meth : TSymbol;
   enumerator : TPerfectMatchEnumerator;
begin
   // Initialize MethodSymbol
   case MethKind of
      mkConstructor:
         Create(MethName, fkConstructor, Cls, aVisibility, False);
      mkDestructor:
         Create(MethName, fkDestructor, Cls, aVisibility, False);
      mkProcedure:
         Create(MethName, fkProcedure, Cls, aVisibility, False);
      mkFunction:
         Create(MethName, fkFunction, Cls, aVisibility, False);
      mkMethod :
         Create(MethName, fkMethod, Cls, aVisibility, False);
      mkClassProcedure:
         Create(MethName, fkProcedure, Cls, aVisibility, True);
      mkClassFunction:
         Create(MethName, fkFunction, Cls, aVisibility, True);
      mkClassMethod:
         Create(MethName, fkMethod, Cls, aVisibility, True);
   else
      Assert(False);
   end;

   // Set Result type
   if MethType <> '' then begin
      if not (Kind in [fkFunction, fkMethod]) then
         raise Exception.Create(CPE_NoResultTypeRequired);

      typSym := Table.FindTypeSymbol(MethType, cvMagic);
      if not Assigned(typSym) then
         raise Exception.CreateFmt(CPE_TypeIsUnknown, [MethType]);
      SetType(typSym);
   end;

   if (Kind = fkFunction) and (MethType = '') then
      raise Exception.Create(CPE_ResultTypeExpected);

   GenerateParams(Table, MethParams);

   // Check if name is already used
   if overloaded or (maOverride in Attributes) then begin
      enumerator:=TPerfectMatchEnumerator.Create;
      try
         enumerator.FuncSym:=Self;
         Cls.Members.EnumerateSymbolsOfNameInScope(MethName, enumerator.Callback);
         meth:=enumerator.Match;
      finally
         enumerator.Free;
      end;
   end else begin
      meth:=Cls.Members.FindSymbol(MethName, cvPrivate);
   end;
   if meth<>nil then begin
      if meth is TFieldSymbol then
         raise Exception.CreateFmt(CPE_FieldExists, [MethName])
      else if meth is TPropertySymbol then
         raise Exception.CreateFmt(CPE_PropertyExists, [MethName])
      else if meth is TMethodSymbol then begin
         if TMethodSymbol(meth).StructSymbol=Cls then begin
            if not overloaded then
               raise EScriptError.CreateFmt(CPE_MethodExists, [MethName])
            else if not TMethodSymbol(meth).IsOverloaded then
               raise EScriptError.CreateFmt(UNT_PreviousNotOverloaded, [MethName])
         end;
      end;
   end;

   if overloaded then
      IsOverloaded := True;
   if Assigned(meth) then
      SetOverlap(TMethodSymbol(meth));

   if Attributes = [maVirtual] then
      IsVirtual := True
   else if Attributes = [maVirtual, maAbstract] then begin
      IsVirtual := True;
      IsAbstract := True;
   end else if Attributes = [maVirtual, maOverride] then begin
      if (not IsOverlap) or (ParentMeth=nil) then
         raise EScriptError.CreateFmt(CPE_CanNotOverride, [Name])
      else if (not ParentMeth.IsVirtual)   then
         raise EScriptError.CreateFmt(CPE_CantOverrideNotVirtual, [Name])
      else if ParentMeth.IsFinal then
         raise EScriptError.CreateFmt(CPE_CantOverrideFinal, [Name])
      else SetOverride(TMethodSymbol(meth));
   end else if Attributes = [maReintroduce] then
      //
   else if IsClassMethod and ((Attributes = [maStatic]) or (Attributes = [maStatic, maClassMethod]))  then
      SetIsStatic
   else if Attributes = [] then
      //
   else raise EScriptError.Create(CPE_InvalidArgCombination);
end;

// GetIsClassMethod
//
function TMethodSymbol.GetIsClassMethod: Boolean;
begin
   Result:=(maClassMethod in FAttributes);
end;

// GetIsOverride
//
function TMethodSymbol.GetIsOverride : Boolean;
begin
   Result:=maOverride in FAttributes;
end;

// SetIsOverride
//
procedure TMethodSymbol.SetIsOverride(const val : Boolean);
begin
   if val then
      Include(FAttributes, maOverride)
   else Exclude(FAttributes, maOverride);
end;

// GetIsOverlap
//
function TMethodSymbol.GetIsOverlap : Boolean;
begin
   Result:=maOverlap in FAttributes;
end;

// SetIsOverlap
//
procedure TMethodSymbol.SetIsOverlap(const val : Boolean);
begin
   if val then
      Include(FAttributes, maOverlap)
   else Exclude(FAttributes, maOverlap);
end;

// GetIsVirtual
//
function TMethodSymbol.GetIsVirtual : Boolean;
begin
   Result:=maVirtual in FAttributes;
end;

// SetIsVirtual
//
procedure TMethodSymbol.SetIsVirtual(const val : Boolean);
begin
   if val then
      Include(FAttributes, maVirtual)
   else Exclude(FAttributes, maVirtual);
end;

// GetIsAbstract
//
function TMethodSymbol.GetIsAbstract : Boolean;
begin
   Result:=maAbstract in FAttributes;
end;

// SetIsAbstract
//
procedure TMethodSymbol.SetIsAbstract(const val : Boolean);
begin
   if val then
      Include(FAttributes, maAbstract)
   else Exclude(FAttributes, maAbstract);
end;

// GetIsFinal
//
function TMethodSymbol.GetIsFinal : Boolean;
begin
   Result:=maFinal in FAttributes;
end;

// GetIsInterfaced
//
function TMethodSymbol.GetIsInterfaced : Boolean;
begin
   Result:=maInterfaced in FAttributes;
end;

// SetIsInterfaced
//
procedure TMethodSymbol.SetIsInterfaced(const val : Boolean);
begin
   if val then
      Include(FAttributes, maInterfaced)
   else Exclude(FAttributes, maInterfaced);
end;

// GetIsDefault
//
function TMethodSymbol.GetIsDefault : Boolean;
begin
   Result:=maDefault in FAttributes;
end;

// SetIsDefault
//
procedure TMethodSymbol.SetIsDefault(const val : Boolean);
begin
   if val then
      Include(FAttributes, maDefault)
   else Exclude(FAttributes, maDefault);
end;

// GetIsStatic
//
function TMethodSymbol.GetIsStatic : Boolean;
begin
   Result:=maStatic in FAttributes;
end;

// GetIgnoreMissingImplementation
//
function TMethodSymbol.GetIgnoreMissingImplementation : Boolean;
begin
   Result := maIgnoreMissingImplementation in FAttributes;
end;

// SetIgnoreMissingImplementation
//
procedure TMethodSymbol.SetIgnoreMissingImplementation(const val : Boolean);
begin
   if val then
      Include(FAttributes, maIgnoreMissingImplementation)
   else Exclude(FAttributes, maIgnoreMissingImplementation);
end;

// SetIsStatic
//
procedure TMethodSymbol.SetIsStatic;
begin
   Include(FAttributes, maStatic);
   if FSelfSym<>nil then begin
      FInternalParams.Remove(FSelfSym);
      FParams.Remove(FSelfSym);
      FSelfSym.Free;
      FSelfSym:=nil;
   end;
end;

// SetIsFinal
//
procedure TMethodSymbol.SetIsFinal;
begin
   Include(FAttributes, maFinal);
end;

// GetCaption
//
function TMethodSymbol.GetCaption : String;
begin
   Result:=inherited GetCaption;
   if IsClassMethod then
      Result:='class '+Result;
end;

// GetDescription
//
function TMethodSymbol.GetDescription : String;
begin
   Result:=inherited GetDescription;
   if IsClassMethod then
      Result:='class '+Result;
end;

// GetRootParentMeth
//
function TMethodSymbol.GetRootParentMeth : TMethodSymbol;
begin
   Result:=Self;
   while Result.IsOverride do
      Result:=Result.ParentMeth;
end;

procedure TMethodSymbol.InitData(const Data: TData; Offset: Integer);
const
  nilIntf: IUnknown = nil;
begin
  inherited;
  if Size = 2 then
    Data[Offset + 1] := nilIntf;
end;

// QualifiedName
//
function TMethodSymbol.QualifiedName : String;
begin
   Result := String(StructSymbol.QualifiedName+'.'+Name);
end;

// ParamsDescription
//
function TMethodSymbol.ParamsDescription : String;
begin
   if IsStatic or not (StructSymbol is THelperSymbol) then
      Result := Params.Description(0)
   else Result := Params.Description(1);
end;

// HasConditions
//
function TMethodSymbol.HasConditions : Boolean;
begin
   Result:=(FConditions<>nil);
   if (not Result) and IsOverride and (ParentMeth<>nil) then
      Result:=ParentMeth.HasConditions;
end;

// IsVisibleFor
//
function TMethodSymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=(FVisibility>=aVisibility);
end;

// IsSameOverloadOf
//
function TMethodSymbol.IsSameOverloadOf(other : TFuncSymbol) : Boolean;
begin
   Result:=    inherited IsSameOverloadOf(other)
           and (other is TMethodSymbol)
           and (IsClassMethod=TMethodSymbol(other).IsClassMethod);
end;

// SpecializeType
//
function TMethodSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
var
   specializedMethod : TMethodSymbol;
begin
   specializedMethod := TMethodSymbolClass(ClassType).Create(
      Name, Kind, context.CompositeSymbol,
      Visibility, IsClassMethod, Level
   );

   if IsStatic then
      specializedMethod.SetIsStatic;
   if IsStateless then
      specializedMethod.SetIsStateless(True);
   InternalSpecialize(specializedMethod, context);
   Result := specializedMethod;

   context.RegisterInternalType(Result);
end;

// SetOverride
//
procedure TMethodSymbol.SetOverride(meth: TMethodSymbol);
begin
   FParentMeth:=meth;
   FVMTIndex:=meth.FVMTIndex;
   IsVirtual:=True;
   SetIsOverride(True);
   SetIsOverlap(False);
end;

// SetOverlap
//
procedure TMethodSymbol.SetOverlap(meth: TMethodSymbol);
begin
   FParentMeth := meth;
   SetIsOverride(False);
   SetIsOverlap(True);
end;

// ------------------
// ------------------ TSourceMethodSymbol ------------------
// ------------------

// GetDeclarationPosition
//
function TSourceMethodSymbol.GetDeclarationPosition : TScriptPos;
begin
   Result := FDeclarationPosition;
end;

// SetDeclarationPosition
//
procedure TSourceMethodSymbol.SetDeclarationPosition(const val : TScriptPos);
begin
   FDeclarationPosition := val;
end;

// GetImplementationPosition
//
function TSourceMethodSymbol.GetImplementationPosition : TScriptPos;
begin
   Result := FImplementationPosition;
end;

// SetImplementationPosition
//
procedure TSourceMethodSymbol.SetImplementationPosition(const val : TScriptPos);
begin
   FImplementationPosition := val;
end;

// ------------------
// ------------------ TPropertySymbol ------------------
// ------------------

// Create
//
constructor TPropertySymbol.Create(const Name: String; Typ: TTypeSymbol; aVisibility : TdwsVisibility;
                                   aArrayIndices : TParamsSymbolTable);
begin
   inherited Create(Name, Typ);
   FIndexValue:=nil;
   FVisibility:=aVisibility;
   FArrayIndices:=aArrayIndices;
end;

destructor TPropertySymbol.Destroy;
begin
  FArrayIndices.Free;
  FDefaultSym.Free;
  inherited;
end;

// GetArrayIndices
//
function TPropertySymbol.GetArrayIndices : TParamsSymbolTable;
begin
   if FArrayIndices=nil then
      FArrayIndices:=TParamsSymbolTable.Create;
   Result:=FArrayIndices;
end;

// AddParam
//
procedure TPropertySymbol.AddParam(Param: TParamSymbol);
begin
   ArrayIndices.AddSymbol(Param);
end;

// GetIsDeprecated
//
function TPropertySymbol.GetIsDeprecated : Boolean;
begin
   Result:=(FDeprecatedMessage<>'');
end;

// GetExternalName
//
function TPropertySymbol.GetExternalName : String;
begin
   if FExternalName <> '' then
      Result := FExternalName
   else Result := Name;
end;

procedure TPropertySymbol.GenerateParams(Table: TSymbolTable; const FuncParams: TParamArray);
begin
   dwsSymbols.GenerateParams(Table, FuncParams, AddParam);
end;

function TPropertySymbol.GetCaption : String;
begin
   Result := GetDescription;
end;

function TPropertySymbol.GetArrayIndicesDescription: String;
var
   i, j : Integer;
   sym, nextSym : TSymbol;
begin
   if (FArrayIndices=nil) or (ArrayIndices.Count=0) then
      Result:=''
   else begin
      Result:='[';
      i:=0;
      while i<ArrayIndices.Count do begin
         sym:=ArrayIndices[i];
         if i>0 then
            Result:=Result+', ';
         Result:=Result+sym.Name;
         for j:=i+1 to ArrayIndices.Count-1 do begin
            nextSym:=ArrayIndices[j];
            if nextSym.Typ<>sym.Typ then Break;
            Result:=Result+', '+nextSym.Name;
            i:=j;
         end;
         Result:=Result+': '+sym.Typ.Name;
         Inc(i);
      end;
      Result:=Result+']';
    end;
end;

// QualifiedName
//
function TPropertySymbol.QualifiedName : String;
begin
   Result := String(OwnerSymbol.QualifiedName+'.'+Name);
end;

// IsVisibleFor
//
function TPropertySymbol.IsVisibleFor(const aVisibility : TdwsVisibility) : Boolean;
begin
   Result:=(FVisibility>=aVisibility);
end;

// HasArrayIndices
//
function TPropertySymbol.HasArrayIndices : Boolean;
begin
   Result:=Assigned(FArrayIndices) and (FArrayIndices.Count>0);
end;

// Specialize
//
function TPropertySymbol.Specialize(const context : ISpecializationContext) : TSymbol;
var
   i : Integer;
   specializedArrayIndices : TParamsSymbolTable;
   specializedProperty : TPropertySymbol;
begin
   if HasArrayIndices then begin
      specializedArrayIndices := TParamsSymbolTable.Create;
      for i := 0 to ArrayIndices.Count-1 do
         specializedArrayIndices.AddSymbol(ArrayIndices[i].Specialize(context));
   end else specializedArrayIndices := nil;

   specializedProperty := TPropertySymbol.Create(Name, context.SpecializeType(Typ), Visibility,
                                                 specializedArrayIndices);

   specializedProperty.FReadSym := context.Specialize(FReadSym);
   specializedProperty.FWriteSym := context.Specialize(FWriteSym);
   specializedProperty.FIndexSym := context.SpecializeType(FIndexSym);
   specializedProperty.FIndexValue := FIndexValue;
   specializedProperty.FDefaultSym := FDefaultSym;
   if FDefaultSym <> nil then
      FDefaultSym.IncRefCount;
   specializedProperty.FDeprecatedMessage := FDeprecatedMessage;

   Result := specializedProperty;
end;

// GetDescription
//
function TPropertySymbol.GetDescription : String;
begin
   Result := Format('property %s%s: %s', [Name, GetArrayIndicesDescription, Typ.Name]);

   if Assigned(FIndexSym) then
      Result := Result + ' index ' + VariantToString(FIndexValue[0]);

   if Assigned(FReadSym) then
      Result := Result + ' read ' + FReadSym.Name;

   if Assigned(FWriteSym) then
      Result := Result + ' write ' + FWriteSym.Name;

   if IsDefault then
      Result := Result + '; default;';
end;

// GetIsDefault
//
function TPropertySymbol.GetIsDefault : Boolean;
begin
   Result:=(OwnerSymbol.DefaultProperty=Self);
end;

procedure TPropertySymbol.SetIndex(const data : TData; Sym: TTypeSymbol);
begin
   FIndexSym := Sym;
   SetLength(FIndexValue,FIndexSym.Size);
   DWSCopyData(data, 0, FIndexValue, 0, FIndexSym.Size);
end;

// ------------------
// ------------------ TClassOperatorSymbol ------------------
// ------------------

// Create
//
constructor TClassOperatorSymbol.Create(tokenType : TTokenType);
begin
   inherited Create(cTokenStrings[tokenType], nil);
   FTokenType:=tokenType;
end;

// QualifiedName
//
function TClassOperatorSymbol.QualifiedName : String;
begin
   Result := String(CompositeSymbol.QualifiedName+'.'+Name);
end;

// GetCaption
//
function TClassOperatorSymbol.GetCaption : String;
begin
   Result:='class operator '+cTokenStrings[TokenType]+' ';
   if (UsesSym<>nil) and (UsesSym.Params.Count>0) then
      Result:=Result+UsesSym.Params[0].Typ.Name
   else Result:=Result+'???';
   Result:=Result+' uses '+FUsesSym.Name;
end;

// GetDescription
//
function TClassOperatorSymbol.GetDescription : String;
begin
   Result:=GetCaption;
end;

// ------------------
// ------------------ TClassSymbol ------------------
// ------------------

// Create
//
constructor TClassSymbol.Create(const name : String; aUnit : TSymbol);
begin
   inherited;
   FSize:=1;
   FMetaSymbol:=TClassOfSymbol.Create('class of '+Name, Self);
end;

// Destroy
//
destructor TClassSymbol.Destroy;
begin
   FOperators.Free;
   FInterfaces.Free;
   inherited;
end;

// GetIsExplicitAbstract
//
function TClassSymbol.GetIsExplicitAbstract : Boolean;
begin
   Result:=(csfExplicitAbstract in FFlags);
end;

// SetIsExplicitAbstract
//
procedure TClassSymbol.SetIsExplicitAbstract(const val : Boolean);
begin
   if val then
      Include(FFlags, csfExplicitAbstract)
   else Exclude(FFlags, csfExplicitAbstract);
end;

// GetIsAbstract
//
function TClassSymbol.GetIsAbstract : Boolean;
begin
   Result:=(([csfAbstract, csfExplicitAbstract]*FFlags)<>[]);
end;

// GetIsSealed
//
function TClassSymbol.GetIsSealed : Boolean;
begin
   Result:=(csfSealed in FFlags);
end;

// SetIsSealed
//
procedure TClassSymbol.SetIsSealed(const val : Boolean);
begin
   if val then
      Include(FFlags, csfSealed)
   else Exclude(FFlags, csfSealed);
end;

// GetIsStatic
//
function TClassSymbol.GetIsStatic : Boolean;
begin
   Result:=(csfStatic in FFlags);
end;

// SetIsStatic
//
procedure TClassSymbol.SetIsStatic(const val : Boolean);
begin
   if val then
      Include(FFlags, csfStatic)
   else Exclude(FFlags, csfStatic);
end;

// GetIsExternal
//
function TClassSymbol.GetIsExternal : Boolean;
begin
   Result:=(csfExternal in FFlags);
end;

// SetIsExternal
//
procedure TClassSymbol.SetIsExternal(const val : Boolean);
begin
   if val then
      Include(FFlags, csfExternal)
   else Exclude(FFlags, csfExternal);
end;

// GetIsExternalRooted
//
function TClassSymbol.GetIsExternalRooted : Boolean;
begin
   Result:=IsExternal or (csfExternalRooted in FFlags);
end;

// GetIsPartial
//
function TClassSymbol.GetIsPartial : Boolean;
begin
   Result:=(csfPartial in FFlags);
end;

// GetIsAttribute
//
function TClassSymbol.GetIsAttribute : Boolean;
begin
   Result:=(csfAttribute in FFlags);
end;

// SetIsAttribute
//
procedure TClassSymbol.SetIsAttribute(const val : Boolean);
begin
   if val then
      Include(FFlags, csfAttribute)
   else Exclude(FFlags, csfAttribute);
end;

// GetIsInternal
//
function TClassSymbol.GetIsInternal : Boolean;
begin
   Result := (csfInternal in FFlags);
end;

// SetIsInternal
//
procedure TClassSymbol.SetIsInternal(const val : Boolean);
begin
   if val then
      Include(FFlags, csfInternal)
   else Exclude(FFlags, csfInternal);
end;

// SetIsPartial
//
procedure TClassSymbol.SetIsPartial;
begin
   Include(FFlags, csfPartial);
end;

// SetNoVirtualMembers
//
procedure TClassSymbol.SetNoVirtualMembers;
begin
   Include(FFlags, csfNoVirtualMembers);
end;

// SetNoOverloads
//
procedure TClassSymbol.SetNoOverloads;
begin
   Include(FFlags, csfNoOverloads);
end;

// AddField
//
procedure TClassSymbol.AddField(fieldSym : TFieldSymbol);
begin
   inherited;
   fieldSym.FOffset := FScriptInstanceSize;
   FScriptInstanceSize := FScriptInstanceSize + fieldSym.Typ.Size;
   Include(FFlags, csfHasOwnFields);
end;

// AddMethod
//
procedure TClassSymbol.AddMethod(methSym : TMethodSymbol);
begin
   inherited;
   if methSym.IsAbstract then
      Include(FFlags, csfAbstract);
   Include(FFlags, csfHasOwnMethods);
end;

// AddOperator
//
procedure TClassSymbol.AddOperator(sym: TClassOperatorSymbol);
begin
   sym.CompositeSymbol:=Self;
   FMembers.AddSymbol(sym);
   FOperators.Add(sym);
end;

// AddInterface
//
function TClassSymbol.AddInterface(intfSym : TInterfaceSymbol; visibility : TdwsVisibility;
                                   var missingMethod : TMethodSymbol) : Boolean;
var
   sym : TSymbol;
   iter : TInterfaceSymbol;
   resolved : TResolvedInterface;
   lookup, match : TMethodSymbol;
begin
   resolved.IntfSymbol:=intfSym;
   SetLength(resolved.VMT, intfSym.MethodCount);
   iter:=intfSym;
   while iter<>nil do begin
      for sym in iter.Members do begin
         if sym.Name='' then continue;
         if sym is TMethodSymbol then begin
            lookup:=TMethodSymbol(sym);
            match:=DuckTypedMatchingMethod(lookup, visibility);
            if match=nil then begin
               missingMethod:=lookup;
               Exit(False);
            end else begin
               resolved.VMT[lookup.VMTIndex]:=match;
               match.IsInterfaced:=True;
            end;
         end;
      end;
      iter:=iter.Parent;
   end;

   if FInterfaces=nil then
      FInterfaces:=TResolvedInterfaces.Create;
   FInterfaces.Add(resolved);
   missingMethod:=nil;
   Result:=True;
end;

// ProcessOverriddenInterface
//
function TClassSymbol.ProcessOverriddenInterface(const ancestorResolved : TResolvedInterface) : Boolean;
var
   i : Integer;
   newResolved : TResolvedInterface;
   meth : TMethodSymbol;
begin
   Result:=False;
   newResolved:=ancestorResolved;
   if (FInterfaces<>nil) and FInterfaces.Contains(newResolved) then Exit;
   SetLength(newResolved.VMT, Length(newResolved.VMT)); // make unique
   for i:=0 to High(newResolved.VMT) do begin
      meth:=newResolved.VMT[i];
      if meth.IsVirtual then begin
         if FVirtualMethodTable[meth.VMTIndex]<>meth then begin
            newResolved.VMT[i]:=FVirtualMethodTable[meth.VMTIndex];
            Result:=True;
         end;
      end;
   end;
   if Result then begin
      if FInterfaces=nil then
         FInterfaces:=TResolvedInterfaces.Create;
      FInterfaces.Add(newResolved);
   end;
end;

// ProcessOverriddenInterfaces
//
procedure TClassSymbol.ProcessOverriddenInterfaces;
var
   iter : TClassSymbol;
   loopProtection : TList;
   ri : TResolvedInterfaces;
begin
   iter:=Parent;
   loopProtection:=TList.Create;
   try
      while iter<>nil do begin
         if loopProtection.IndexOf(iter)>0 then Break;
         loopProtection.Add(iter);
         ri:=iter.Interfaces;
         if ri<>nil then begin
            ri.Enumerate(ProcessOverriddenInterfaceCallback);
         end;
         iter:=iter.Parent;
      end;
   finally
      loopProtection.Free;
   end;
end;

// ProcessOverriddenInterfaceCallback
//
function TClassSymbol.ProcessOverriddenInterfaceCallback(const item : TResolvedInterface) : TSimpleHashAction;
begin
   ProcessOverriddenInterface(item);
   Result:=shaNone;
end;

// ResolveInterface
//
function TClassSymbol.ResolveInterface(intfSym : TInterfaceSymbol; var resolved : TResolvedInterface) : Boolean;
begin
   if FInterfaces<>nil then begin;
      resolved.IntfSymbol:=intfSym;
      Result:=FInterfaces.Match(resolved);
      if Result then Exit;
   end;
   if Parent<>nil then
      Result:=Parent.ResolveInterface(intfSym, resolved)
   else Result:=False;
end;

// ImplementsInterface
//
function TClassSymbol.ImplementsInterface(intfSym : TInterfaceSymbol) : Boolean;
var
   resolved : TResolvedInterface;
begin
   Result:=ResolveInterface(intfSym, resolved);
end;

// FieldAtOffset
//
function TClassSymbol.FieldAtOffset(offset : Integer) : TFieldSymbol;
begin
   Result:=inherited FieldAtOffset(offset);
   if Result=nil then begin
      if Parent<>nil then
         Result:=Parent.FieldAtOffset(offset);
   end;
end;

procedure TClassSymbol.InitData(const Data: TData; Offset: Integer);
begin
   VarCopySafe(Data[Offset], IUnknown(nil));
end;

// Initialize
//
procedure TClassSymbol.Initialize(const msgs : TdwsCompileMessageList);
var
   i, a, v : Integer;
   differentVMT : Boolean;
   sym : TSymbol;
   field : TFieldSymbol;
   meth : TMethodSymbol;
begin
   if csfInitialized in Flags then Exit;
   Include(FFlags, csfInitialized);

   // Check validity of the class declaration
   if IsForwarded then begin
      msgs.AddCompilerErrorFmt(FForwardPosition^, CPE_ClassNotCompletelyDefined, [Name]);
      Exit;
   end;

   if Parent<>nil then begin
      Parent.Initialize(msgs);
      a:=Parent.ScriptInstanceSize;
      FVirtualMethodTable:=Parent.FVirtualMethodTable;
   end else begin
      a:=0;
      FVirtualMethodTable:=nil;
   end;
   v:=Length(FVirtualMethodTable);
   differentVMT:=False;

   // remap field offset & vmt index (cares for partial classes)
   for i:=0 to FMembers.Count-1 do begin
      sym:=FMembers[i];
      if sym.ClassType=TFieldSymbol then begin
         field:=TFieldSymbol(sym);
         field.FOffset:=a;
         Inc(a, field.Typ.Size);
      end else if sym is TMethodSymbol then begin
         meth:=TMethodSymbol(sym);
         if meth.IsVirtual then begin
            differentVMT:=True;
            if meth.IsOverride then
               meth.FVMTIndex:=meth.ParentMeth.VMTIndex
            else begin
               meth.FVMTIndex:=v;
               Inc(v);
            end;
         end;
      end;
   end;
   FScriptInstanceSize:=a;
   // prepare VMT
   if differentVMT then begin
      SetLength(FVirtualMethodTable, v); // make unique (and resize if necessary)
      for sym in FMembers do begin
         if sym is TMethodSymbol then begin
            meth:=TMethodSymbol(sym);
            if meth.IsVirtual then
               FVirtualMethodTable[meth.FVMTIndex]:=meth;
         end;
      end;
   end;
   // update abstract flag
   if csfAbstract in FFlags then begin
      if differentVMT then begin
         Exclude(FFlags, csfAbstract);
         for i:=0 to High(FVirtualMethodTable) do begin
            if FVirtualMethodTable[i].IsAbstract then begin
               Include(FFlags, csfAbstract);
               Break;
            end;
         end;
      end else if not (csfAbstract in Parent.FFlags) then
         Exclude(FFlags, csfAbstract);
   end;
   // process overridden interfaces
   ProcessOverriddenInterfaces;

   CheckMethodsImplemented(msgs);
end;

// InheritFrom
//
procedure TClassSymbol.InheritFrom(ancestorClassSym : TClassSymbol);
begin
   DoInheritFrom(ancestorClassSym);

   if csfAbstract in ancestorClassSym.FFlags then
      Include(FFlags, csfAbstract);
   FScriptInstanceSize:=ancestorClassSym.ScriptInstanceSize;

   IsStatic:=IsStatic or ancestorClassSym.IsStatic;

   if ancestorClassSym.IsAttribute then
      Include(FFlags, csfAttribute);

   if [csfExternalRooted, csfExternal]*ancestorClassSym.Flags<>[] then
      Include(FFlags, csfExternalRooted);

   if csfNoVirtualMembers in ancestorClassSym.FFlags then
      SetNoVirtualMembers;
   if    (csfNoOverloads in ancestorClassSym.FFlags)
      or (        (csfExternalRooted in FFlags)
          and not (csfExternal in FFlags)) then
      SetNoOverloads;
end;

// IsCompatible
//
function TClassSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   if typSym=nil then
      Result:=False
   else begin
      typSym:=typSym.UnAliasedType;
      if typSym is TNilSymbol then
         Result:=True
      else if typSym is TClassSymbol then
         Result:=(NthParentOf(TClassSymbol(typSym))>=0)
      else Result:=False;
   end;
end;

// IsPointerType
//
function TClassSymbol.IsPointerType : Boolean;
begin
   Result:=True;
end;

// HasMetaSymbol
//
function TClassSymbol.HasMetaSymbol : Boolean;
begin
   Result:=True;
end;

// CommonAncestor
//
function TClassSymbol.CommonAncestor(otherClass : TTypeSymbol) : TClassSymbol;
begin
   Result := Self;
   while (Result <> nil) and not otherClass.IsOfType(Result) do
      Result := Result.Parent;
end;

// DoIsOfType
//
function TClassSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(Self=typSym.UnAliasedType);
   if Result or (Self=nil) then Exit;
   if Parent<>nil then
      Result:=Parent.DoIsOfType(typSym.UnAliasedType)
   else Result:=False;
end;

// VMTMethod
//
function TClassSymbol.VMTMethod(index : Integer) : TMethodSymbol;
begin
   if Cardinal(index) < Cardinal(Length(FVirtualMethodTable)) then
      Result := FVirtualMethodTable[index]
   else Result := nil;
end;

// VMTCount
//
function TClassSymbol.VMTCount : Integer;
begin
   Result:=Length(FVirtualMethodTable);
end;

function TClassSymbol.GetDescription : String;
var
  i: Integer;
begin
  if FParent <> nil then
    Result := Name + ' = class (' + FParent.Name + ')'#13#10
  else
    Result := Name + ' = class'#13#10;

  for i := 0 to Members.Count - 1 do
    Result := Result + '   ' + Members.Symbols[i].Description + ';'#13#10;

  Result := Result + 'end';
end;

// FindClassOperatorStrict
//
function TClassSymbol.FindClassOperatorStrict(tokenType : TTokenType; paramType : TSymbol; recursive : Boolean) : TClassOperatorSymbol;
var
   i : Integer;
begin
   for i:=0 to FOperators.Count-1 do begin
      Result:=TClassOperatorSymbol(FOperators.List[i]);
      if     (Result.TokenType=tokenType)
         and (Result.Typ=paramType) then Exit;
   end;
   if recursive and (Parent<>nil) then
      Result:=Parent.FindClassOperatorStrict(tokenType, paramType, True)
   else Result:=nil;
end;

// FindClassOperator
//
function TClassSymbol.FindClassOperator(tokenType : TTokenType; paramType : TTypeSymbol) : TClassOperatorSymbol;
var
   i : Integer;
begin
   Result:=FindClassOperatorStrict(tokenType, paramType, False);
   if Result<>nil then Exit;

   if FOperators.Count>0 then begin
      for i:=0 to FOperators.Count-1 do begin
         Result:=TClassOperatorSymbol(FOperators.List[i]);
         if     (Result.TokenType=tokenType)
            and paramType.DoIsOfType(Result.Typ) then Exit;
      end;
      for i:=0 to FOperators.Count-1 do begin
         Result:=TClassOperatorSymbol(FOperators.List[i]);
         if     (Result.TokenType=tokenType)
            and Result.Typ.IsCompatible(paramType) then Exit;
      end;
   end;
   if Parent<>nil then
      Result:=Parent.FindClassOperator(tokenType, paramType)
   else Result:=nil;
end;

// FindDefaultConstructor
//
function TClassSymbol.FindDefaultConstructor(minVisibility : TdwsVisibility) : TMethodSymbol;
var
   i : Integer;
   member : TSymbol;
   createConstructor : TMethodSymbol;
begin
   createConstructor:=nil;
   for i:=0 to FMembers.Count-1 do begin
      member:=FMembers[i];
      if member is TMethodSymbol then begin
         Result:=TMethodSymbol(member);
         if (Result.Visibility>=minVisibility) and (Result.Kind=fkConstructor) then begin
            if Result.IsDefault then
               Exit;
            if UnicodeSameText(Result.Name, 'Create') then
               createConstructor:=Result;
         end;
      end;
   end;
   if createConstructor<>nil then
      Result:=createConstructor
   else if Parent<>nil then begin
      if minVisibility=cvPrivate then
         minVisibility:=cvProtected;
      Result:=Parent.FindDefaultConstructor(minVisibility);
   end else Result:=nil;
end;

// CollectPublishedSymbols
//
procedure TClassSymbol.CollectPublishedSymbols(symbolList : TSimpleSymbolList);
var
   i : Integer;
   member : TSymbol;
begin
   for i := 0 to Members.Count-1 do begin
      member := Members[i];
      if member.ClassType=TPropertySymbol then begin
         if TPropertySymbol(member).Visibility=cvPublished then
            symbolList.Add(member);
      end else if member.ClassType=TFieldSymbol then begin
         if TFieldSymbol(member).Visibility=cvPublished then
            symbolList.Add(member);
      end else if member.InheritsFrom(TMethodSymbol) then begin
         if TMethodSymbol(member).Visibility=cvPublished then
            symbolList.Add(member);
      end;
   end;
end;

// AllowVirtualMembers
//
function TClassSymbol.AllowVirtualMembers : Boolean;
begin
   Result:=not (csfNoVirtualMembers in FFlags);
end;

// AllowOverloads
//
function TClassSymbol.AllowOverloads : Boolean;
begin
   Result:=not (csfNoOverloads in FFlags);
end;

// AllowFields
//
function TClassSymbol.AllowFields : Boolean;
begin
   Result:=True;
end;

// AllowAnonymousMethods
//
function TClassSymbol.AllowAnonymousMethods : Boolean;
begin
   Result:=(not IsExternal);
end;

// CreateSelfParameter
//
function TClassSymbol.CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol;
begin
   if methSym.IsClassMethod then
      Result:=TSelfSymbol.Create(SYS_SELF, MetaSymbol)
   else Result:=TSelfSymbol.Create(SYS_SELF, Self);
   methSym.InternalParams.AddSymbol(Result);
end;

// CreateAnonymousMethod
//
function TClassSymbol.CreateAnonymousMethod(
      aFuncKind : TFuncKind; aVisibility : TdwsVisibility; isClassMethod : Boolean) : TMethodSymbol;
begin
   Result:=TSourceMethodSymbol.Create('', aFuncKind, Self, aVisibility, isClassMethod);
end;

// VisibilityToString
//
class function TClassSymbol.VisibilityToString(visibility : TdwsVisibility) : String;
const
   cVisibilityNames : array [TdwsVisibility] of String = (
      'magic', 'private', 'protected', 'public', 'published' );
begin
   Result:=cVisibilityNames[visibility];
end;

// SpecializeType
//
function TClassSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
var
   specializedClass : TClassSymbol;
begin
   if csfPartial in FFlags then
      context.AddCompilerError(CPE_PartialClassesCannotBeSpecialized);

   // temporary errors while generic support is in progress, so no standard error string
   if not (csfExternal in FFlags) then begin
      if Parent.IsGeneric then
         context.AddCompilerError('Subclasses of a generic class connt be specialized right now')
      else if FOperators.Count > 0 then
         context.AddCompilerError('Classes with operators cannot be specialized right now');
   end;
   if FOperators.Count <> 0 then
      context.AddCompilerError('Specialization of class operators not yet supported');
   if (FInterfaces <> nil) and (FInterfaces.Count <> 0) then
      context.AddCompilerError('Specialization of classes with interfaces not yet supported');
   if Assigned(FOnObjectDestroy) then
      context.AddCompilerError('Specialization of classes with custom destructor not yet supported');

   specializedClass := TClassSymbol.Create(context.Name, context.UnitSymbol);

   context.EnterComposite(specializedClass);
   try
      specializedClass.FFlags := FFlags - [csfInitialized];
      if csfExternal in FFlags then
         if FExternalName <> '' then
            specializedClass.FExternalName := FExternalName
         else specializedClass.FExternalName := Name
      else specializedClass.FExternalName := FExternalName;

      if Parent <> nil then
         specializedClass.InheritFrom( Parent );
//         specializedClass.InheritFrom( context.Specialize(Parent) as TClassSymbol );  TODO

      SpecializeMembers(specializedClass, context);
      specializedClass.Initialize(context.Msgs);
   finally
      context.LeaveComposite;
   end;
   Result := specializedClass;
end;

// Parent
//
function TClassSymbol.Parent : TClassSymbol;
begin
   Result:=TClassSymbol(FParent);
end;

// IsPureStatic
//
function TClassSymbol.IsPureStatic : Boolean;
var
   sym : TSymbol;
   symClass : TClass;
   meth : TMethodSymbol;
begin
   Result:=IsStatic and IsSealed;
   if not Result then Exit;

   for sym in FMembers do begin
      symClass:=sym.ClassType;
      if symClass=TFieldSymbol then exit;
      if symClass=TClassConstSymbol then continue;
      if symClass=TClassVarSymbol then continue;
      if symClass=TPropertySymbol then continue;
      if symClass.InheritsFrom(TMethodSymbol) then begin
         meth:=TMethodSymbol(symClass);
         if not meth.IsStatic then exit;
         if not meth.IsClassMethod then exit;
      end;
      exit;
   end;
   Result:=True;
end;

// ------------------
// ------------------ TNilSymbol ------------------
// ------------------

constructor TNilSymbol.Create;
begin
  inherited Create('<nil>', nil);
  FSize := 1;
end;

function TNilSymbol.GetCaption : String;
begin
  Result := 'nil';
end;

function TNilSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
  typSym := typSym.BaseType;
  Result := (TypSym is TClassSymbol) or (TypSym is TNilSymbol);
end;

// IsCompatibleWithAnyFuncSymbol
//
function TNilSymbol.IsCompatibleWithAnyFuncSymbol : Boolean;
begin
   Result := True;
end;

// InitData
//
procedure TNilSymbol.InitData(const data : TData; offset : Integer);
begin
   VarCopySafe(data[offset], IUnknown(nil));
end;

// ------------------
// ------------------ TClassOfSymbol ------------------
// ------------------

constructor TClassOfSymbol.Create(const Name: String; Typ: TClassSymbol);
begin
  inherited Create(Name, Typ);
end;

function TClassOfSymbol.GetCaption : String;
begin
   if Name <> '' then
      Result := Name
   else Result := GetDescription;
end;

// GetDescription
//
function TClassOfSymbol.GetDescription : String;
begin
   if Typ <> nil then
      Result := 'class of ' + Typ.Name
   else Result := 'class of ???';
end;

function TClassOfSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
  typSym := typSym.BaseType;
  Result :=    (typSym is TNilSymbol)
            or ((typSym is TClassOfSymbol) and Typ.IsCompatible(typSym.Typ));
end;

// SameType
//
function TClassOfSymbol.SameType(typSym : TTypeSymbol) : Boolean;
begin
   Result :=     (typSym<>nil)
             and (typSym.ClassType=TClassOfSymbol)
             and (Typ.SameType(typSym.Typ));
end;

// DoIsOfType
//
function TClassOfSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   if typSym is TClassOfSymbol then
      Result:=Typ.DoIsOfType(typSym.Typ.UnAliasedType)
   else Result:=False;
end;

// TypClassSymbol
//
function TClassOfSymbol.TypClassSymbol : TClassSymbol;
begin
   Result:=TClassSymbol(Typ);
end;

// ------------------
// ------------------ TBaseSymbol ------------------
// ------------------

// Create
//
constructor TBaseSymbol.Create(const name : String);
begin
   inherited Create(name, nil);
   FSize:=1;
end;

// IsCompatible
//
function TBaseSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=    (typSym<>nil)
           and (UnAliasedType=typSym.UnAliasedType);
end;

// IsBaseType
//
class function TBaseSymbol.IsBaseType : Boolean;
begin
   Result:=True;
end;

// SpecializeType
//
function TBaseSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
begin
   Result := Self;
end;

// ------------------
// ------------------ TBaseIntegerSymbol ------------------
// ------------------

// Create
//
constructor TBaseIntegerSymbol.Create;
begin
   inherited Create(SYS_INTEGER);
end;

// InitData
//
procedure TBaseIntegerSymbol.InitData(const data : TData; offset : Integer);
begin
   VarSetDefaultInt64(data[offset]);
end;

// InitVariant
//
procedure TBaseIntegerSymbol.InitVariant(var v : Variant);
begin
   VarSetDefaultInt64(v);
end;

// IsCompatible
//
function TBaseIntegerSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   if typSym<>nil then begin
      Result:=   (UnAliasedType=typSym.UnAliasedType)
              or (    (typSym.ClassType=TEnumerationSymbol)
                  and  IsCompatible(typSym.Typ));
   end else Result:=False;
end;

// ------------------
// ------------------ TBaseFloatSymbol ------------------
// ------------------

// Create
//
constructor TBaseFloatSymbol.Create;
begin
   inherited Create(SYS_FLOAT);
end;

// InitData
//
procedure TBaseFloatSymbol.InitData(const data : TData; offset : Integer);
begin
   VarSetDefaultDouble(data[offset]);
end;

// InitVariant
//
procedure TBaseFloatSymbol.InitVariant(var v : Variant);
begin
   VarSetDefaultDouble(v);
end;

// ------------------
// ------------------ TBaseStringSymbol ------------------
// ------------------

// Create
//
constructor TBaseStringSymbol.Create;
begin
   inherited Create(SYS_STRING);
end;

// Destroy
//
destructor TBaseStringSymbol.Destroy;
begin
   inherited;
   FLengthPseudoSymbol.Free;
   FHighPseudoSymbol.Free;
   FLowPseudoSymbol.Free;
end;

// InitData
//
procedure TBaseStringSymbol.InitData(const data : TData; offset : Integer);
begin
   VarSetDefaultString(data[offset]);
end;

// InitVariant
//
procedure TBaseStringSymbol.InitVariant(var v : Variant);
begin
   VarSetDefaultString(v);
end;

// InitPseudoSymbol
//
function TBaseStringSymbol.InitPseudoSymbol(var p : TPseudoMethodSymbol; sk : TSpecialKeywordKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;

   function DoInit(var p : TPseudoMethodSymbol; sk : TSpecialKeywordKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
   begin
      p := TPseudoMethodSymbol.Create(Self, cSpecialKeywords[sk], fkFunction, 0);
      p.Typ := baseSymbols.TypInteger;
      Result := p;
   end;

begin
   Result := p;
   if Result = nil then
      Result := DoInit(p, sk, baseSymbols);
end;

// LengthPseudoSymbol
//
function TBaseStringSymbol.LengthPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
begin
   Result := InitPseudoSymbol(FLengthPseudoSymbol, skLength, baseSymbols);
end;

// HighPseudoSymbol
//
function TBaseStringSymbol.HighPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
begin
   Result := InitPseudoSymbol(FHighPseudoSymbol, skHigh, baseSymbols);
end;

// LowPseudoSymbol
//
function TBaseStringSymbol.LowPseudoSymbol(baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
begin
   Result := InitPseudoSymbol(FLowPseudoSymbol, skLow, baseSymbols);
end;

// ------------------
// ------------------ TBaseBooleanSymbol ------------------
// ------------------

// Create
//
constructor TBaseBooleanSymbol.Create;
begin
   inherited Create(SYS_BOOLEAN);
end;

// InitData
//
procedure TBaseBooleanSymbol.InitData(const data : TData; offset : Integer);
begin
   data[offset]:=False;
end;

// InitVariant
//
procedure TBaseBooleanSymbol.InitVariant(var v : Variant);
begin
   v := False;
end;

// ------------------
// ------------------ TBaseVariantSymbol ------------------
// ------------------

// Create
//
constructor TBaseVariantSymbol.Create(const name : String = '');
begin
   if name='' then
      inherited Create(SYS_VARIANT)
   else inherited Create(name);
end;

// IsCompatible
//
function TBaseVariantSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
var
   ct : TClass;
begin
   if typSym<>nil then begin
      typSym:=typSym.UnAliasedType;
      if typSym.InheritsFrom(TBaseSymbol) then
         Result:=True
      else begin
         ct:=typSym.ClassType;
         Result:=   (ct=TEnumerationSymbol)
                 or (ct=TClassSymbol)
                 or (ct=TNilSymbol)
                 or (ct=TInterfaceSymbol);
      end;
   end else Result:=False;
end;

// InitData
//
procedure TBaseVariantSymbol.InitData(const data : TData; offset : Integer);
begin
   VarClearSafe(data[offset]);
end;

// InitVariant
//
procedure TBaseVariantSymbol.InitVariant(var v : Variant);
begin
   VarClearSafe(v);
end;

// SupportsEmptyParam
//
function TBaseVariantSymbol.SupportsEmptyParam : Boolean;
begin
   Result:=True;
end;

// ------------------
// ------------------ TParamsSymbolTable ------------------
// ------------------

// GetSymbol
//
function TParamsSymbolTable.GetSymbol(x : Integer) : TParamSymbol;
begin
   Result:=TParamSymbol(inherited Symbols[x]);
   Assert(Result is TParamSymbol);
end;

// Description
//
function TParamsSymbolTable.Description(skip : Integer) : String;
var
   i : Integer;
begin
   if Count > skip then begin
      Result := Symbols[skip].Description;
      for i := skip+1 to Count-1 do
         Result := Result + '; ' + Symbols[i].Description;
      Result := '(' + Result + ')';
   end else Result := '()';
end;

// ------------------
// ------------------ TValueSymbol ------------------
// ------------------

// Create
//
constructor TValueSymbol.Create(const aName : String; aType : TTypeSymbol);
begin
   inherited;
   FName := aName;
   FTyp:=aType;
   FSize:=aType.Size;
end;

function TValueSymbol.GetCaption : String;
begin
  Result := Name + ': ' + Typ.Caption;
end;

function TValueSymbol.GetDescription : String;
begin
  Result := Name + ': ' + Typ.Caption;
end;

// ------------------
// ------------------ TConstSymbol ------------------
// ------------------

// CreateValue
//
constructor TConstSymbol.CreateValue(const Name: String; Typ: TTypeSymbol; const Value: Variant);
begin
   inherited Create(Name, Typ);
   Assert(Typ.Size=1);
   SetLength(FData, 1);
   VarCopySafe(FData[0], Value);
end;

// CreateData
//
constructor TConstSymbol.CreateData(const Name: String; Typ: TTypeSymbol; const data : TData);
begin
   inherited Create(Name, Typ);
   SetLength(FData, Typ.Size);
   DWSCopyData(data, 0, FData, 0, Typ.Size);
end;

function TConstSymbol.GetCaption : String;
begin
  Result := 'const ' + inherited GetCaption;
end;

function TConstSymbol.GetDescription : String;
begin
   Result := 'const ' + inherited GetDescription + ' = ';
   if Length(FData) > 0 then
      Result := Result + VariantToString(FData[0])
   else Result := Result + '???';
end;

// GetIsDeprecated
//
function TConstSymbol.GetIsDeprecated : Boolean;
begin
   Result := (FDeprecatedMessage<>'');
end;

procedure TConstSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
end;

// ------------------
// ------------------ TDataSymbol ------------------
// ------------------

function TDataSymbol.GetDescription : String;
begin
   if Assigned(Typ) then
      if Typ.Name<>'' then
         Result:=Name+': '+Typ.Name
      else Result:=Name+': '+Typ.Description
  else Result:=Name+': ???';
end;

// GetExternalName
//
function TDataSymbol.GetExternalName : String;
begin
   if FExternalName = '' then
      Result := Name
   else Result := FExternalName;
end;

// AllocateStackAddr
//
procedure TDataSymbol.AllocateStackAddr(generator : TAddrGenerator);
begin
   FLevel := generator.Level;
   FStackAddr := generator.GetStackAddr(Size);
end;

// HasExternalName
//
function TDataSymbol.HasExternalName : Boolean;
begin
   Result := (FExternalName <> '');
end;

// IsWritable
//
function TDataSymbol.IsWritable : Boolean;
begin
   Result := True;
end;

// ------------------
// ------------------ TScriptDataSymbol ------------------
// ------------------

// Create
//
constructor TScriptDataSymbol.Create(const aName : String; aType : TTypeSymbol; aPurpose : TScriptDataSymbolPurpose = sdspGeneral);
begin
   inherited Create(aName, aType);
   Purpose := aPurpose;
end;

// Specialize
//
function TScriptDataSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TScriptDataSymbol.Create(Name, context.SpecializeType(Typ), Purpose);
end;

// ------------------
// ------------------ TVarDataSymbol ------------------
// ------------------

// Specialize
//
function TVarDataSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TScriptDataSymbol.Create(Name, context.SpecializeType(Typ));
end;

// ------------------
// ------------------ TParamSymbol ------------------
// ------------------

// Create
//
constructor TParamSymbol.Create(const aName : String; aType : TTypeSymbol; options : TParamSymbolOptions = []);
begin
   inherited Create(aName, aType);
   FOptions := options;
end;

// SameParam
//
function TParamSymbol.SameParam(other : TParamSymbol) : Boolean;
begin
   Result:=    (   (ClassType=other.ClassType)
                or (    (ClassType=TParamSymbol)
                    and (other.ClassType=TParamSymbolWithDefaultValue)))
           and Typ.SameType(other.Typ)
           and UnicodeSameText(Name, other.Name)
           and (FOptions = other.FOptions);
end;

// Semantics
//
function TParamSymbol.Semantics : TParamSymbolSemantics;
begin
   Result := pssCopy;
end;

// ForbidImplicitCasts
//
function TParamSymbol.ForbidImplicitCasts : Boolean;
begin
   Result := psoForbidImplicitCasts in FOptions;
end;

// Clone
//
function TParamSymbol.Clone : TParamSymbol;
begin
   Result:=TParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// GetDescription
//
function TParamSymbol.GetDescription : String;
var
   semantics : TParamSymbolSemantics;
begin
   semantics := Self.Semantics;
   if cParamSymbolSemanticsPrefix[semantics] = '' then
      Result := inherited GetDescription
   else Result := cParamSymbolSemanticsPrefix[semantics] + ' ' + inherited GetDescription;
   if psoForbidImplicitCasts in FOptions then
      FastStringReplace(Result, ': ', ': type ');
end;

// ------------------
// ------------------ TParamSymbolWithDefaultValue ------------------
// ------------------

// Create
//
constructor TParamSymbolWithDefaultValue.Create(const aName : String; aType : TTypeSymbol;
                                                const data : TData; options : TParamSymbolOptions = []);
begin
   inherited Create(aName, aType, options);
   SetLength(FDefaultValue, Typ.Size);
   if Length(data)>0 then
      DWSCopyData(data, 0, FDefaultValue, 0, Typ.Size);
end;

// Clone
//
function TParamSymbolWithDefaultValue.Clone : TParamSymbol;
begin
   Result:=TParamSymbolWithDefaultValue.Create(Name, Typ, FDefaultValue);
end;

// Specialize
//
function TParamSymbolWithDefaultValue.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TParamSymbolWithDefaultValue.Create(Name, context.SpecializeType(Typ), FDefaultValue);
end;

// SameParam
//
function TParamSymbolWithDefaultValue.SameParam(other : TParamSymbol) : Boolean;
begin
   Result:=    inherited SameParam(other)
           and DWSSameData(FDefaultValue, (other as TParamSymbolWithDefaultValue).FDefaultValue,
                           0, 0, Typ.Size);
end;

function TParamSymbolWithDefaultValue.GetDescription : String;
begin
   Result := inherited GetDescription;

   // Has a default parameter. Format display of param to show it.
   if Length(FDefaultValue) > 0 then begin
      if (Typ is TBaseStringSymbol) then
         Result := Result + ' = ''' + VariantToString(FDefaultValue[0]) + ''''  // put quotes around value
      else if (Typ is TArraySymbol) then
         Result := Result + ' = []'
      else Result := Result + ' = ' + VariantToString(FDefaultValue[0]);
   end;
end;

// ------------------
// ------------------ TByRefParamSymbol ------------------
// ------------------

constructor TByRefParamSymbol.Create(const Name: String; Typ: TTypeSymbol);
begin
  inherited Create(Name, Typ);
  FSize := 1;
end;

// Clone
//
function TByRefParamSymbol.Clone : TParamSymbol;
begin
   Result:=TByRefParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TByRefParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TByRefParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// ------------------
// ------------------ TLazyParamSymbol ------------------
// ------------------

// Clone
//
function TLazyParamSymbol.Clone : TParamSymbol;
begin
   Result:=TLazyParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TLazyParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TLazyParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// Semantics
//
function TLazyParamSymbol.Semantics : TParamSymbolSemantics;
begin
   Result := pssLazy;
end;

// ------------------
// ------------------ TConstByRefParamSymbol ------------------
// ------------------

// Clone
//
function TConstByRefParamSymbol.Clone : TParamSymbol;
begin
   Result := TConstByRefParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TConstByRefParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TConstByRefParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// IsWritable
//
function TConstByRefParamSymbol.IsWritable : Boolean;
begin
   Result := False;
end;

// Semantics
//
function TConstByRefParamSymbol.Semantics : TParamSymbolSemantics;
begin
   Result := pssConst;
end;

// ------------------
// ------------------ TConstByValueParamSymbol ------------------
// ------------------

// Clone
//
function TConstByValueParamSymbol.Clone : TParamSymbol;
begin
   Result := TConstByValueParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TConstByValueParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TConstByValueParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// IsWritable
//
function TConstByValueParamSymbol.IsWritable : Boolean;
begin
   Result := False;
end;

// Semantics
//
function TConstByValueParamSymbol.Semantics : TParamSymbolSemantics;
begin
   Result := pssConst;
end;

// ------------------
// ------------------ TVarParamSymbol ------------------
// ------------------

// Clone
//
function TVarParamSymbol.Clone : TParamSymbol;
begin
   Result:=TVarParamSymbol.Create(Name, Typ);
end;

// Specialize
//
function TVarParamSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := TVarParamSymbol.Create(Name, context.SpecializeType(Typ));
end;

// Semantics
//
function TVarParamSymbol.Semantics : TParamSymbolSemantics;
begin
   Result := pssVar;
end;

// ------------------
// ------------------ TSymbolTable ------------------
// ------------------

// Create
//
constructor TSymbolTable.Create(Parent: TSymbolTable; AddrGenerator: TAddrGenerator);
begin
   inherited Create;
   FAddrGenerator := AddrGenerator;
   if Assigned(Parent) then
      AddParent(Parent);
end;

// Destroy
//
destructor TSymbolTable.Destroy;
begin
   FSymbols.Clean;
   FParents.Clear;
   inherited;
end;

// GetCount
//
function TSymbolTable.GetCount : Integer;
begin
   Result:=FSymbols.Count
end;

// GetSymbol
//
function TSymbolTable.GetSymbol(index : Integer) : TSymbol;
begin
   Result:=TSymbol(FSymbols.List[Index]);
end;

procedure TSymbolTable.Initialize(const msgs : TdwsCompileMessageList);
var
   i : Integer;
   ptrList : PObjectTightList;
begin
   ptrList:=FSymbols.List;
   for i:=0 to FSymbols.Count-1 do
      TSymbol(ptrList[i]).Initialize(msgs);
end;

// FindLocal
//
function TSymbolTable.FindLocal(const aName : String; ofClass : TSymbolClass = nil) : TSymbol;
var
   lo, hi, mid, cmpResult : Integer;
   ptrList : PObjectTightList;
begin
   hi := FSymbols.Count-1;
   if hi < 0 then Exit(nil);

   if not (stfSorted in FFlags) then begin
      if hi > 0 then
         SortSymbols(0, hi);
      Include(FFlags, stfSorted);
   end;

   lo := 0;
   ptrList := FSymbols.List;
   while lo <= hi do begin
      mid := (lo + hi) shr 1;
      Result := TSymbol(ptrList[mid]);
      cmpResult := UnicodeCompareText(Result.Name, aName);
      if cmpResult < 0 then
         lo := mid+1
      else begin
         if cmpResult = 0 then begin
            if (ofClass <> nil) and not Result.InheritsFrom(ofClass) then
               Result := nil;
            Exit;
         end else hi := mid-1;
      end;
   end;
   Result := nil;
end;

// FindTypeLocal
//
function TSymbolTable.FindTypeLocal(const aName : String) : TTypeSymbol;
begin
   Result:=TTypeSymbol(FindLocal(aName, TTypeSymbol));
end;

// FindSymbolAtStackAddr
//
function TSymbolTable.FindSymbolAtStackAddr(const stackAddr, level : Integer) : TDataSymbol;
var
   i : Integer;
   sym : TSymbol;
begin
   for i:=0 to FSymbols.Count-1 do begin
      sym:=TSymbol(FSymbols.List[i]);
      if sym.InheritsFrom(TDataSymbol) then begin
         Result:=TDataSymbol(sym);
         if (Result.StackAddr=stackAddr) and (Result.Level=level) then
            Exit;
      end;
   end;

   for i:=0 to ParentCount-1 do begin
      Result:=Parents[i].FindSymbolAtStackAddr(stackAddr, level);
      if Assigned(Result) then Exit;
   end;

   Result:=nil;
end;

// SortSymbols
//
procedure TSymbolTable.SortSymbols(minIndex, maxIndex : Integer);
var
  i, j, p : Integer;
  pSym : TSymbol;
  ptrList : PObjectTightList;
begin
   if maxIndex <= minIndex then
      Exit;
   ptrList := FSymbols.List;
   repeat
      i := minIndex;
      j := maxIndex;
      p := ((i+j) shr 1);
      repeat
         pSym:=TSymbol(ptrList[p]);
         while UnicodeCompareText(TSymbol(ptrList[i]).Name, pSym.Name) < 0 do Inc(i);
         while UnicodeCompareText(TSymbol(ptrList[j]).Name, pSym.Name) > 0 do Dec(j);
         if i <= j then begin
            FSymbols.Exchange(i, j);
            if p = i then
               p := j
            else if p = j then
               p := i;
            Inc(i);
            Dec(j);
         end;
      until i > j;
      if minIndex < j then
         SortSymbols(minIndex, j);
      minIndex := i;
   until i >= maxIndex;
end;

// FindSymbol
//
function TSymbolTable.FindSymbol(const aName : String; minVisibility : TdwsVisibility;
                                 ofClass : TSymbolClass = nil) : TSymbol;
var
   i : Integer;
begin
   // Find Symbol in the local List
   Result := FindLocal(aName, ofClass);
   if Assigned(Result) then begin
      if Result.IsVisibleFor(minVisibility) then
         Exit
      else Result:=nil;
   end;

   // Find Symbol in all parent lists
   for i := 0 to ParentCount-1 do begin
      Result := Parents[i].FindSymbol(aName, minVisibility, ofClass);
      if Assigned(Result) then Break;
   end;
end;

// FindTypeSymbol
//
function TSymbolTable.FindTypeSymbol(
      const aName : String; minVisibility : TdwsVisibility) : TTypeSymbol;
begin
   Result:=TTypeSymbol(FindSymbol(aName, minVisibility, TTypeSymbol));
end;

// EnumerateLocalSymbolsOfName
//
function TSymbolTable.EnumerateLocalSymbolsOfName(
      const aName : String; const callback : TSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   sym : TSymbol;
begin
   // TODO: optimize to take advantage of sorting
   for i:=0 to Count-1 do begin
      sym:=Symbols[i];
      if UnicodeSameText(sym.Name, aName) then begin
         if callback(sym) then Exit(True);
      end;
   end;
   Result:=False;
end;

// EnumerateSymbolsOfNameInScope
//
function TSymbolTable.EnumerateSymbolsOfNameInScope(const aName : String;
                        const callback : TSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   visitedTables : TSimpleObjectHash<TSymbolTable>;
   tableStack : TSimpleStack<TSymbolTable>;
   current : TSymbolTable;
begin
   visitedTables:=TSimpleObjectHash<TSymbolTable>.Create;
   tableStack:=TSimpleStack<TSymbolTable>.Create;
   try
      tableStack.Push(Self);
      while tableStack.Count>0 do begin
         current:=tableStack.Peek;
         tableStack.Pop;
         if visitedTables.Add(current) then begin
            if current.EnumerateLocalSymbolsOfName(aName, callback) then Exit(True);
            for i:=0 to current.ParentCount-1 do
               tableStack.Push(current.Parents[i]);
         end;
      end;
      Result:=False;
   finally
      tableStack.Free;
      visitedTables.Free;
   end;
end;

// EnumerateLocalHelpers
//
function TSymbolTable.EnumerateLocalHelpers(helpedType : TTypeSymbol; const callback : THelperSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   sym : TSymbol;
   list : PObjectTightList;
begin
   if stfHasHelpers in FFlags then begin
      list := FSymbols.List;
      for i:=0 to FSymbols.Count-1 do begin
         sym:=TSymbol(list[i]);
         if sym.ClassType=THelperSymbol then
            if THelperSymbol(sym).HelpsType(helpedType) then begin
               if callback(THelperSymbol(sym)) then Exit(True);
         end;
      end;
   end;
   Result:=False;
end;

// EnumerateHelpers
//
function TSymbolTable.EnumerateHelpers(helpedType : TTypeSymbol; const callback : THelperSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   p : TSymbolTable;
begin
   if EnumerateLocalHelpers(helpedType, callback) then Exit(True);
   for i:=0 to ParentCount-1 do begin
      p:=Parents[i];
      if p.IsUnitTable then begin
         if p.EnumerateLocalHelpers(helpedType, callback) then
            Exit(True)
      end;
      if p.EnumerateHelpers(helpedType, callback) then Exit(True);
   end;
   Result:=False;
end;

// EnumerateLocalOperatorsFor
//
function TSymbolTable.EnumerateLocalOperatorsFor(aToken : TTokenType; aLeftType, aRightType : TTypeSymbol;
                                             const callback : TOperatorSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   sym : TSymbol;
   opSym : TOperatorSymbol;
   leftParam, rightParam : TTypeSymbol;
   list : PObjectTightList;
begin
   if stfHasLocalOperators in FFlags then begin
      list := FSymbols.List;
      for i:=0 to FSymbols.Count-1 do begin
         sym:=TSymbol(list[i]);
         if sym.ClassType=TOperatorSymbol then begin
            opSym:=TOperatorSymbol(sym);
            if opSym.Token<>aToken then continue;
            leftParam:=opSym.Params[0];
            if     (aLeftType<>leftParam)
               and not aLeftType.IsOfType(leftParam) then continue;
            rightParam:=opSym.Params[1];
            if     (aRightType<>rightParam)
               and not aRightType.IsOfType(rightParam) then continue;
            if callback(opSym) then Exit(True);
         end;
      end;
   end;
   Result:=False;
end;

// EnumerateOperatorsFor
//
function TSymbolTable.EnumerateOperatorsFor(aToken : TTokenType; aLeftType, aRightType : TTypeSymbol;
                                            const callback : TOperatorSymbolEnumerationCallback) : Boolean;
var
   i : Integer;
   p : TSymbolTable;
begin
   if stfHasLocalOperators in FFlags then
      if EnumerateLocalOperatorsFor(aToken, aLeftType, aRightType, callback) then Exit(True);
   if stfHasParentOperators in FFlags then begin
      for i:=0 to ParentCount-1 do begin
         p:=Parents[i];
         if p.EnumerateOperatorsFor(aToken, aLeftType, aRightType, callback) then Exit(True);
      end;
   end;
   Result:=False;
end;

// FindImplicitCastOperatorFor
//
function TSymbolTable.FindImplicitCastOperatorFor(fromType, toType : TTypeSymbol) : TOperatorSymbol;
var
   i : Integer;
   sym : TSymbol;
   list : PObjectTightList;
begin
   if stfHasLocalOperators in FFlags then begin
      list := FSymbols.List;
      for i := 0 to FSymbols.Count-1 do begin
         sym := TSymbol(list[i]);
         if sym.ClassType = TOperatorSymbol then begin
            Result := TOperatorSymbol(sym);
            if     (Result.Token = ttIMPLICIT)
               and (Result.Typ = toType)
               and (Result.Params[0] = fromType)
               and (Result.UsesSym <> nil) then Exit;
         end;
      end;
   end;
   if stfHasParentOperators in FFlags then begin
      for i:=0 to ParentCount-1 do begin
         Result := Parents[i].FindImplicitCastOperatorFor(fromType, toType);
         if Result <> nil then Exit;
      end;
   end;
   Result := nil;
end;

// HasSameLocalOperator
//
function TSymbolTable.HasSameLocalOperator(anOpSym : TOperatorSymbol) : Boolean;
var
   i : Integer;
   sym : TSymbol;
   opSym : TOperatorSymbol;
   leftType, rightType : TTypeSymbol;
begin
   Result:=False;
   if not (stfHasLocalOperators in FFlags) then Exit;
   if Length(anOpSym.Params)<>2 then Exit;
   leftType:=anOpSym.Params[0];
   rightType:=anOpSym.Params[1];
   if (leftType=nil) or (rightType=nil) then Exit;

   leftType:=leftType.UnAliasedType;
   rightType:=rightType.UnAliasedType;
   for i:=0 to Count-1 do begin
      sym:=Symbols[i];
      if sym=anOpSym then continue;
      if sym.ClassType=TOperatorSymbol then begin
         opSym:=TOperatorSymbol(sym);
         if     (opSym.Token=anOpSym.Token)
            and (leftType=opSym.Params[0].UnAliasedType)
            and (rightType=opSym.Params[1].UnAliasedType) then begin
            Exit(True);
         end;
      end;
   end;
end;

// HasOperators
//
function TSymbolTable.HasOperators : Boolean;
begin
   Result:=(stfHasOperators in FFlags);
end;

// CollectPublishedSymbols
//
procedure TSymbolTable.CollectPublishedSymbols(symbolList : TSimpleSymbolList);
var
   sym : TSymbol;
begin
   for sym in Self do begin
      if sym.ClassType = TClassSymbol then begin
         TClassSymbol(sym).CollectPublishedSymbols(symbolList);
      end;
   end;
end;

// HasChildTables
//
function TSymbolTable.HasChildTables : Boolean;
begin
   Result:=stfHasChildTables in FFlags;
end;

// HasClass
//
function TSymbolTable.HasClass(const aClass : TSymbolClass) : Boolean;
var
   i : Integer;
   ptrList : PObjectTightList;
begin
   ptrList:=FSymbols.List;
   for i:=FSymbols.Count-1 downto 0 do begin
      if TSymbol(ptrList[i]) is aClass then
         Exit(True);
   end;
   Result:=False;
end;

// HasSymbol
//
function TSymbolTable.HasSymbol(sym : TSymbol) : Boolean;
begin
   Result:=Assigned(Self) and (FSymbols.IndexOf(sym)>=0);
end;

// HasMethods
//
function TSymbolTable.HasMethods : Boolean;
var
   i : Integer;
   ptrList : PObjectTightList;
begin
   ptrList:=FSymbols.List;
   for i:=FSymbols.Count-1 downto 0 do begin
      if TSymbol(ptrList[i]).AsFuncSymbol<>nil then
         Exit(True);
   end;
   Result:=False;
end;

// IsUnitTable
//
class function TSymbolTable.IsUnitTable : Boolean;
begin
   Result:=False;
end;

// AddSymbol
//
function TSymbolTable.AddSymbol(sym : TSymbol) : Integer;
var
   ct : TClass;
begin
   Result:=AddSymbolDirect(sym);
   ct:=sym.ClassType;
   if ct=THelperSymbol then
      Include(FFlags, stfHasHelpers)
   else if ct=TOperatorSymbol then
      FFlags:=FFlags+[stfHasOperators, stfHasLocalOperators]
   else if (FAddrGenerator<>nil) and sym.InheritsFrom(TDataSymbol) then
      TDataSymbol(sym).AllocateStackAddr(FAddrGenerator);
end;

// AddSymbolDirect
//
function TSymbolTable.AddSymbolDirect(sym : TSymbol) : Integer;
var
   n : Integer;
   ptrList : PObjectTightList;
begin
   if stfSorted in FFlags then begin
      Result:=0;
      n:=FSymbols.Count;
      ptrList:=FSymbols.List;
      while Result<n do begin
         if UnicodeCompareText(TSymbol(ptrList[Result]).Name, Sym.Name)>=0 then
            Break;
         Inc(Result);
      end;
      FSymbols.Insert(Result, sym);
   end else Result:=FSymbols.Add(sym);
end;

// Remove
//
function TSymbolTable.Remove(Sym: TSymbol): Integer;
begin
   Result:=FSymbols.Remove(Sym);
end;

// Clear
//
procedure TSymbolTable.Clear;
begin
   FSymbols.Clear;
end;

// TransferSymbolsTo
//
procedure TSymbolTable.TransferSymbolsTo(destTable : TSymbolTable);
var
   i : Integer;
begin
   for i:=0 to Count-1 do
      destTable.AddSymbol(Symbols[i]);
   FSymbols.Clear;
end;

// AddParent
//
procedure TSymbolTable.AddParent(Parent: TSymbolTable);
begin
   InsertParent(ParentCount, Parent);
end;

// InsertParent
//
procedure TSymbolTable.InsertParent(Index: Integer; parent: TSymbolTable);
begin
   Include(Parent.FFlags, stfHasChildTables);
   FParents.Insert(Index, Parent);
   if stfHasOperators in Parent.FFlags then
      FFlags:=FFlags+[stfHasOperators, stfHasParentOperators];
end;

// RemoveParent
//
function TSymbolTable.RemoveParent(Parent: TSymbolTable): Integer;
begin
   Result:=FParents.Remove(Parent);
end;

// ClearParents
//
procedure TSymbolTable.ClearParents;
begin
   FParents.Clear;
end;

// GetParentCount
//
function TSymbolTable.GetParentCount: Integer;
begin
   Result := FParents.Count
end;

// GetParents
//
function TSymbolTable.GetParents(Index: Integer): TSymbolTable;
begin
   Result := TSymbolTable(FParents.List[Index]);
end;

// IndexOfParent
//
function TSymbolTable.IndexOfParent(Parent: TSymbolTable): Integer;
begin
   Result := FParents.IndexOf(Parent)
end;

// MoveParent
//
procedure TSymbolTable.MoveParent(CurIndex, NewIndex: Integer);
begin
   FParents.MoveItem(CurIndex,NewIndex);
end;

// MoveNext
//
function TSymbolTable.TSymbolTableEnumerator.MoveNext : Boolean;
begin
   Dec(Index);
   Result:=(Index>=0);
end;

// GetCurrent
//
function TSymbolTable.TSymbolTableEnumerator.GetCurrent : TSymbol;
begin
   Result:=Table[Index];
end;

// GetEnumerator
//
function TSymbolTable.GetEnumerator : TSymbolTableEnumerator;
begin
   if Self=nil then begin
      Result.Table:=nil;
      Result.Index:=0;
   end else begin
      Result.Table:=Self;
      Result.Index:=Count;
   end;
end;

// ------------------
// ------------------ TMembersSymbolTable ------------------
// ------------------

// AddParent
//
procedure TMembersSymbolTable.AddParent(parent : TMembersSymbolTable);
begin
   inherited AddParent(parent);
end;

// FindSymbol
//
function TMembersSymbolTable.FindSymbol(const aName : String; minVisibility : TdwsVisibility;
                                        ofClass : TSymbolClass = nil) : TSymbol;
var
   i : Integer;
begin
   // Find Symbol in the local List
   Result := FindLocal(aName, ofClass);
   if Assigned(Result) then begin
      if Result.IsVisibleFor(minVisibility) then Exit;
      // try harder in case of overload with different visibility
      for Result in Self do begin
         if     (UnicodeCompareText(Result.Name, aName)=0)
            and Result.IsVisibleFor(minVisibility) then Exit;
      end;
   end;
   Result:=nil;

   // Find Symbol in all parent lists
   if minVisibility = cvPrivate then
      minVisibility := cvProtected;

   for i := 0 to ParentCount-1 do begin
      Result := Parents[i].FindSymbol(aName, minVisibility, ofClass);
      if Assigned(Result) then Break;
   end;
end;

// VisibilityFromScope
//
function TMembersSymbolTable.VisibilityFromScope(scopeSym : TCompositeTypeSymbol) : TdwsVisibility;
begin
   if scopeSym=nil then
      Result:=cvPublic
   else if    (scopeSym=Owner)
           or (    (scopeSym.UnitSymbol<>nil)
               and (scopeSym.UnitSymbol=Owner.UnitSymbol)) then
      Result:=cvPrivate
   else if scopeSym.DoIsOfType(Owner) then
      Result:=cvProtected
   else Result:=cvPublic;
end;

// FindSymbolFromScope
//
function TMembersSymbolTable.FindSymbolFromScope(const aName : String; scopeSym : TCompositeTypeSymbol) : TSymbol;
begin
   Result:=FindSymbol(aName, VisibilityFromScope(scopeSym));
end;

// Visibilities
//
function TMembersSymbolTable.Visibilities : TdwsVisibilities;
var
   sym : TSymbol;
   symClass : TClass;
begin
   Result:=[];
   for sym in Self do begin
      symClass:=sym.ClassType;
      if symClass=TFieldSymbol then
         Include(Result, TFieldSymbol(sym).Visibility)
      else if symClass.InheritsFrom(TPropertySymbol) then
         Include(Result, TPropertySymbol(sym).Visibility)
      else if symClass.InheritsFrom(TMethodSymbol) then
         Include(Result, TMethodSymbol(sym).Visibility)
   end;
end;

// ------------------
// ------------------ TUnSortedSymbolTable ------------------
// ------------------

// FindLocal
//
function TUnSortedSymbolTable.FindLocal(const aName : String; ofClass : TSymbolClass = nil) : TSymbol;
var
   n : Integer;
   ptrList : PPointer;
begin
   n := FSymbols.Count;
   if n > 0 then begin
      ptrList := PPointer(FSymbols.List);
      repeat
         Result := TSymbol(ptrList^);
         if UnicodeCompareText(Result.Name, aName) = 0 then begin
            if (ofClass<>nil) and not Result.InheritsFrom(ofClass) then
               Result := nil;
            Exit;
         end;
         Inc(ptrList);
         Dec(n);
      until n <= 0;
   end;
   Result := nil;
end;

// IndexOf
//
function TUnSortedSymbolTable.IndexOf(sym : TSymbol) : Integer;
begin
   Result := FSymbols.IndexOf(sym);
end;

// ------------------
// ------------------ TExternalVarSymbol ------------------
// ------------------

destructor TExternalVarSymbol.Destroy;
begin
  FReadFunc.Free;
  FWriteFunc.Free;
  inherited;
end;

function TExternalVarSymbol.GetReadFunc: TFuncSymbol;
begin
  Result := FReadFunc;
end;

function TExternalVarSymbol.GetWriteFunc: TFuncSymbol;
begin
  Result := FWriteFunc;
end;

// ------------------
// ------------------ TAddrGeneratorRec ------------------
// ------------------

// CreatePositive
//
class function TAddrGeneratorRec.CreatePositive(aLevel : SmallInt; anInitialSize: Integer = 0) : TAddrGeneratorRec;
begin
   Result.DataSize:=anInitialSize;
   Result.FLevel:=aLevel;
   Result.FSign:=agsPositive;
end;

// CreateNegative
//
class function TAddrGeneratorRec.CreateNegative(aLevel : SmallInt) : TAddrGeneratorRec;
begin
   Result.DataSize:=0;
   Result.FLevel:=aLevel;
   Result.FSign:=agsNegative;
end;

// GetStackAddr
//
function TAddrGeneratorRec.GetStackAddr(size : Integer): Integer;
begin
   if FSign=agsPositive then begin
      Result:=DataSize;
      Inc(DataSize, Size);
   end else begin
      Inc(DataSize, Size);
      Result:=-DataSize;
   end;
end;

// ------------------
// ------------------ TSetOfSymbol ------------------
// ------------------

// Create
//
constructor TSetOfSymbol.Create(const name : String; indexType : TTypeSymbol;
                              aMin, aMax : Integer);
begin
   inherited Create(name, indexType);
   FMinValue:=aMin;
   FCountValue:=aMax-aMin+1;
   FSize:=1+(FCountValue shr 6);
end;

// IsCompatible
//
function TSetOfSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   typSym:=typSym.UnAliasedType;
   if typSym is TSetOfSymbol then begin
      Result:=     TSetOfSymbol(typSym).Typ.IsOfType(Typ)
              and  (TSetOfSymbol(typSym).MinValue=MinValue)
              and  (TSetOfSymbol(typSym).CountValue=CountValue);
   end else Result:=False;
end;

// InitData
//
procedure TSetOfSymbol.InitData(const data : TData; offset : Integer);
const
   cZero64 : Int64 = 0;
var
   i : Integer;
begin
   for i:=offset to offset+Size-1 do
      data[i]:=cZero64;
end;

// AssignsAsDataExpr
//
function TSetOfSymbol.AssignsAsDataExpr : Boolean;
begin
   Result := True;
end;

// ValueToOffsetMask
//
function TSetOfSymbol.ValueToOffsetMask(value : Integer; var mask : Int64) : Integer;
begin
   Result:=(value-MinValue) shr 6;
   mask:=Int64(1) shl (value and 63);
end;

// ValueToByteOffsetMask
//
function TSetOfSymbol.ValueToByteOffsetMask(value : Integer; var mask : Byte) : Integer;
begin
   Result := (value-MinValue) shr 3;
   mask := 1 shl (value and 7);
end;

// ElementByValue
//
function TSetOfSymbol.ElementByValue(value : Integer) : TElementSymbol;
begin
   Result := (Typ.UnAliasedType as TEnumerationSymbol).ElementByValue(value)
end;

// GetMaxValue
//
function TSetOfSymbol.GetMaxValue : Integer;
begin
   Result:=MinValue+CountValue-1;
end;

// InitializePseudoMethodSymbol
//
function TSetOfSymbol.InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
var
   methodName : String;
begin
   Result := nil;

   methodName := Copy(GetEnumName(TypeInfo(TArrayMethodKind), Ord(methodKind)), 4);
   case methodKind of
      amkInclude, amkExclude : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('element', Typ));
      end;
   end;
   if Result <> nil then
      FPseudoMethods[methodKind] := Result
end;

// ------------------
// ------------------ TPseudoMethodSymbol ------------------
// ------------------

// Create
//
constructor TPseudoMethodSymbol.Create(owner : TTypeSymbol; const name : String; funcKind : TFuncKind; funcLevel : SmallInt);
begin
   inherited Create(name, funcKind, funcLevel);
   FOwnerTyp := owner;
end;

// ------------------
// ------------------ TTypeWithPseudoMethodsSymbol ------------------
// ------------------

// InitializePseudoMethodSymbol
//
function TTypeWithPseudoMethodsSymbol.InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
begin
   Result := nil;
end;

// Destroy
//
destructor TTypeWithPseudoMethodsSymbol.Destroy;
var
   f : TPseudoMethodSymbol;
begin
   inherited;
   for f in FPseudoMethods do
      f.Free;
end;

// PseudoMethodSymbol
//
function TTypeWithPseudoMethodsSymbol.PseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
begin
   Result := FPseudoMethods[methodKind];
   if Result = nil then
      Result := InitializePseudoMethodSymbol(methodKind, baseSymbols);
end;

// ------------------
// ------------------ TArraySymbol ------------------
// ------------------

// Create
//
constructor TArraySymbol.Create(const name : String; elementType, indexType : TTypeSymbol);
begin
   inherited Create(name, elementType);
   FIndexType:=indexType;
end;

// Destroy
//
destructor TArraySymbol.Destroy;
begin
   FSortFunctionType.Free;
   FMapFunctionType.Free;
   FFilterFunctionType.Free;
   inherited;
end;

// DynamicInitialization
//
function TArraySymbol.DynamicInitialization : Boolean;
begin
   Result := True;
end;

// AssignsAsDataExpr
//
function TArraySymbol.AssignsAsDataExpr : Boolean;
begin
   Result := True;
end;

// InitializePseudoMethodSymbol
//
function TArraySymbol.InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
var
   methodName : String;
begin
   Result := nil;

   methodName := Copy(GetEnumName(TypeInfo(TArrayMethodKind), Ord(methodKind)), 4);
   case methodKind of
      amkLength, amkCount : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := baseSymbols.TypInteger;
      end;
      amkHigh, amkLow : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := IndexType;
      end;
   end;
   if Result <> nil then
      FPseudoMethods[methodKind] := Result
end;

// ElementSize
//
function TArraySymbol.ElementSize : Integer;
begin
   if Typ<>nil then
      Result:=Typ.Size
   else Result:=0;
end;

// SortFunctionType
//
function TArraySymbol.SortFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol;
begin
   if FSortFunctionType = nil then begin
      FSortFunctionType := TFuncSymbol.Create('', fkFunction, 0);
      FSortFunctionType.Typ := baseSymbols.TypInteger;
      FSortFunctionType.AddParam(TParamSymbol.Create('left', Typ));
      FSortFunctionType.AddParam(TParamSymbol.Create('right', Typ));
   end;
   Result := FSortFunctionType;
end;

// MapFunctionType
//
function TArraySymbol.MapFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol;
begin
   if FMapFunctionType = nil then begin
      FMapFunctionType := TFuncSymbol.Create('', fkFunction, 0);
      FMapFunctionType.Typ := baseSymbols.TypAnyType;
      FMapFunctionType.AddParam(TParamSymbol.Create('v', Typ));
   end;
   Result:=FMapFunctionType;
end;

// FilterFunctionType
//
function TArraySymbol.FilterFunctionType(baseSymbols : TdwsBaseSymbolsContext) : TFuncSymbol;
begin
   if FFilterFunctionType = nil then begin
      FFilterFunctionType := TFuncSymbol.Create('', fkFunction, 0);
      FFilterFunctionType.Typ := baseSymbols.TypBoolean;
      FFilterFunctionType.AddParam(TParamSymbol.Create('v', Typ));
   end;
   Result := FFilterFunctionType;
end;

// ------------------
// ------------------ TDynamicArraySymbol ------------------
// ------------------

var
   vInitDynamicArray : TInitDataProc;

// Create
//
constructor TDynamicArraySymbol.Create(const name : String; elementType, indexType : TTypeSymbol);
begin
  inherited;
  FSize:=1;
end;

// GetCaption
//
function TDynamicArraySymbol.GetCaption : String;
begin
   Result := 'array of '+Typ.Caption
end;

// InitData
//
procedure TDynamicArraySymbol.InitData(const Data: TData; Offset: Integer);
begin
   vInitDynamicArray(Self.Typ, Data[Offset]);
end;

// InitVariant
//
procedure TDynamicArraySymbol.InitVariant(var v : Variant);
begin
   vInitDynamicArray(Self.Typ, v);
end;

// DoIsOfType
//
function TDynamicArraySymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=   (typSym=Self)
           or ((typSym is TDynamicArraySymbol) and typSym.Typ.DoIsOfType(Typ));
end;

// InitializePseudoMethodSymbol
//
function TDynamicArraySymbol.InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
var
   methodName : String;
begin
   Result := nil;

   methodName := Copy(GetEnumName(TypeInfo(TArrayMethodKind), Ord(methodKind)), 4);
   case methodKind of
      amkAdd, amkPush : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('item', Typ));
         Result.Typ := Self;
      end;
      amkIndexOf, amkRemove : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('item', Typ));
         Result.Typ := IndexType;
      end;
      amkPop, amkPeek : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := Typ;
      end;
      amkMap : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('func', MapFunctionType(baseSymbols)));
         Result.Typ := Self;
      end;
      amkSort : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('func', SortFunctionType(baseSymbols)));
         Result.Typ := Self;
      end;
      amkFilter : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('func', FilterFunctionType(baseSymbols)));
         Result.Typ := Self;
      end;
      amkDelete : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkProcedure, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('index', IndexType));
         Result.Params.AddSymbol(TParamSymbolWithDefaultValue.Create('count', baseSymbols.TypInteger, [ Int64(0) ]));
      end;
      amkInsert : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkProcedure, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('index', baseSymbols.TypInteger));
         Result.Params.AddSymbol(TParamSymbol.Create('item', Typ));
      end;
      amkSetLength : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkProcedure, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('newLength', baseSymbols.TypInteger));
      end;
      amkClear : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkProcedure, 0);
      end;
      amkSwap : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('index1', IndexType));
         Result.Params.AddSymbol(TParamSymbol.Create('index2', IndexType));
         Result.Typ := Self;
      end;
      amkMove : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('fromIndex', IndexType));
         Result.Params.AddSymbol(TParamSymbol.Create('toIndex', IndexType));
         Result.Typ := Self;
      end;
      amkCopy : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('startIndex', IndexType));
         Result.Params.AddSymbol(TParamSymbolWithDefaultValue.Create('count', baseSymbols.TypInteger, [ Int64(0) ]));
         Result.Typ := Self;
      end;
      amkReverse : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := Self;
      end;
   end;
   if Result <> nil then
      FPseudoMethods[methodKind] := Result
   else Result := inherited InitializePseudoMethodSymbol(methodKind, baseSymbols);
end;

// IsCompatible
//
function TDynamicArraySymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
  Result :=    (    (typSym is TDynamicArraySymbol)
                and (Typ.IsCompatible(typSym.Typ) or (typSym.Typ is TNilSymbol))
            or (    (typSym is TStaticArraySymbol)
                and TStaticArraySymbol(typSym).IsEmptyArray));
end;

// IsPointerType
//
function TDynamicArraySymbol.IsPointerType : Boolean;
begin
   Result:=True;
end;

// SameType
//
function TDynamicArraySymbol.SameType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=    (typSym<>nil)
           and (typSym.ClassType=TDynamicArraySymbol)
           and Typ.SameType(typSym.Typ);
end;

// SpecializeType
//
function TDynamicArraySymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
begin
   Result := TDynamicArraySymbol.Create(Name, context.SpecializeType(Typ), context.SpecializeType(IndexType));
   context.RegisterInternalType(Result);
end;

// SetInitDynamicArrayProc
//
class procedure TDynamicArraySymbol.SetInitDynamicArrayProc(const aProc : TInitDataProc);
begin
   vInitDynamicArray:=aProc;
end;

// ------------------
// ------------------ TStaticArraySymbol ------------------
// ------------------

// Create
//
constructor TStaticArraySymbol.Create(const name : String; elementType, indexType : TTypeSymbol;
                                      lowBound, highBound : Integer);
begin
   inherited Create(name, elementType, indexType);
   FLowBound := lowBound;
   FHighBound := highBound;
   FElementCount := highBound - lowBound + 1;
   FSize := FElementCount * ElementSize;
end;

// InitData
//
procedure TStaticArraySymbol.InitData(const data : TData; offset : Integer);
var
   i, s : Integer;
begin
   s := Typ.BaseType.Size;
   for i := 1 to ElementCount do begin
      Typ.InitData(data, offset);
      Inc(offset, s);
   end;
end;

// IsCompatible
//
function TStaticArraySymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   typSym := typSym.UnAliasedType;
   Result :=     (typSym is TStaticArraySymbol)
             and (Size = TStaticArraySymbol(typSym).Size)
             and Typ.IsCompatible(typSym.Typ);
end;

// SameType
//
function TStaticArraySymbol.SameType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=    (typSym<>nil)
           and (typSym.ClassType=ClassType)
           and (Typ.SameType(typSym.Typ))
           and (LowBound=TStaticArraySymbol(typSym).LowBound)
           and (HighBound=TStaticArraySymbol(typSym).HighBound);
end;

// DoIsOfType
//
function TStaticArraySymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=inherited DoIsOfType(typSym);
   if not Result then begin
      if typSym.ClassType=TStaticArraySymbol then
         Result:=    (LowBound=TStaticArraySymbol(typSym).LowBound)
                 and (HighBound=TStaticArraySymbol(typSym).HighBound)
                 and Typ.IsCompatible(TypSym.Typ)
      else if typSym is TOpenArraySymbol then
         Result:=(ElementCount=0) or (Typ.IsCompatible(TypSym.Typ))
   end;
end;

// AddElement
//
procedure TStaticArraySymbol.AddElement;
begin
   Inc(FHighBound);
   Inc(FElementCount);
   FSize:=FElementCount*ElementSize;
end;

// IsEmptyArray
//
function TStaticArraySymbol.IsEmptyArray : Boolean;
begin
   Result:=(HighBound<LowBound);
end;

// GetCaption
//
function TStaticArraySymbol.GetCaption;
begin
   Result:= 'array ['+IntToStr(FLowBound)+'..'+IntToStr(FHighBound)
           +'] of '+Typ.Caption;
end;

// ------------------
// ------------------ TOpenArraySymbol ------------------
// ------------------

// Create
//
constructor TOpenArraySymbol.Create(const name : String; elementType, indexType : TTypeSymbol);
begin
   inherited Create(name, elementType, indexType, 0, -1);
   FSize:=1;
end;

// IsCompatible
//
function TOpenArraySymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   if typSym = nil then Exit(False);
   typSym := typSym.BaseType;
   Result :=     (typSym is TStaticArraySymbol)
             and Typ.IsCompatible(typSym.Typ);
end;

// GetCaption
//
function TOpenArraySymbol.GetCaption : String;
begin
   Result:='array of const';
end;

// ------------------
// ------------------ TAssociativeArraySymbol ------------------
// ------------------

var
   vInitAssociativeArray : TInitDataProc;

// Create
//
constructor TAssociativeArraySymbol.Create(const name : String; elementType, keyType : TTypeSymbol);
begin
   inherited Create(name, elementType);
   FKeyType := keyType;
   FSize := 1;
end;

// Destroy
//
destructor TAssociativeArraySymbol.Destroy;
begin
   inherited;
   FKeyArrayType.Free;
end;

// InitData
//
procedure TAssociativeArraySymbol.InitData(const Data: TData; Offset: Integer);
begin
   vInitAssociativeArray(Self, Data[Offset]);
end;

// InitVariant
//
procedure TAssociativeArraySymbol.InitVariant(var v : Variant);
begin
   vInitAssociativeArray(Self, v);
end;

// SetInitAssociativeArrayProc
//
class procedure TAssociativeArraySymbol.SetInitAssociativeArrayProc(const aProc : TInitDataProc);
begin
   vInitAssociativeArray:=aProc;
end;

// DynamicInitialization
//
function TAssociativeArraySymbol.DynamicInitialization : Boolean;
begin
   Result := True;
end;

// IsCompatible
//
function TAssociativeArraySymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
  Result :=     (typSym is TAssociativeArraySymbol)
            and Typ.IsCompatible(typSym.Typ)
            and KeyType.IsCompatible(TAssociativeArraySymbol(typSym).KeyType);
end;

// IsPointerType
//
function TAssociativeArraySymbol.IsPointerType : Boolean;
begin
   Result := True;
end;

// SameType
//
function TAssociativeArraySymbol.SameType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=    (typSym<>nil)
           and (typSym.ClassType=TAssociativeArraySymbol)
           and Typ.SameType(typSym.Typ)
           and KeyType.SameType(TAssociativeArraySymbol(typSym).KeyType);
end;

// KeysArrayType
//
function TAssociativeArraySymbol.KeysArrayType(baseSymbols : TdwsBaseSymbolsContext) : TDynamicArraySymbol;
begin
   if FKeyArrayType = nil then
      FKeyArrayType := TDynamicArraySymbol.Create('', KeyType, baseSymbols.TypInteger);
   Result := FKeyArrayType;
end;

// KeyAndElementSizeAreBaseTypesOfSizeOne
//
function TAssociativeArraySymbol.KeyAndElementSizeAreBaseTypesOfSizeOne : Boolean;
begin
   Result := (FKeyType.Size = 1) and (Typ.Size = 1) and FKeyType.IsBaseType and Typ.IsBaseType;
end;

// GetCaption
//
function TAssociativeArraySymbol.GetCaption : String;
begin
   Result := 'array [' + KeyType.Caption + '] of ' + Typ.Caption;
end;

// DoIsOfType
//
function TAssociativeArraySymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result := SameType(typSym.UnAliasedType);
end;

// InitializePseudoMethodSymbol
//
function TAssociativeArraySymbol.InitializePseudoMethodSymbol(methodKind : TArrayMethodKind; baseSymbols : TdwsBaseSymbolsContext) : TPseudoMethodSymbol;
var
   methodName : String;
begin
   Result := nil;

   methodName := Copy(GetEnumName(TypeInfo(TArrayMethodKind), Ord(methodKind)), 4);
   case methodKind of
     amkLength, amkCount : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := baseSymbols.TypInteger;
      end;
      amkClear : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkProcedure, 0);
      end;
      amkDelete : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Params.AddSymbol(TParamSymbol.Create('key', KeyType));
         Result.Typ := baseSymbols.TypBoolean;
      end;
      amkKeys : begin
         Result := TPseudoMethodSymbol.Create(Self, methodName, fkFunction, 0);
         Result.Typ := KeysArrayType(baseSymbols);
      end;
   end;
   if Result <> nil then
      FPseudoMethods[methodKind] := Result
   else Result := inherited InitializePseudoMethodSymbol(methodKind, baseSymbols);
end;

// ------------------
// ------------------ TElementSymbol ------------------
// ------------------

// Create
//
constructor TElementSymbol.Create(const Name: String; Typ: TTypeSymbol;
                                  const aValue : Int64; isUserDef: Boolean);
begin
   inherited CreateValue(Name, Typ, aValue);
   FIsUserDef := IsUserDef;
end;

// StandardName
//
function TElementSymbol.StandardName : String;
begin
   if Enumeration.Style=enumClassic then
      Result:=Name
   else Result:=QualifiedName;
end;

// QualifiedName
//
function TElementSymbol.QualifiedName : String;
begin
   Result := String(Enumeration.Name+'.'+Name);
end;

// GetDescription
//
function TElementSymbol.GetDescription : String;
begin
   if FIsUserDef then
      Result := Name+' = '+FastInt64ToStr(Value)
   else Result := Name;
end;

// GetValue
//
function TElementSymbol.GetValue : Int64;
begin
   Result:=PVarData(@Data[0]).VInt64;
end;

// ------------------
// ------------------ TEnumerationSymbol ------------------
// ------------------

// Create
//
constructor TEnumerationSymbol.Create(const Name: String; BaseType: TTypeSymbol;
                                      aStyle : TEnumerationSymbolStyle);
begin
   inherited Create(Name, BaseType);
   FElements:=TUnSortedSymbolTable.Create;
   FLowBound:=MaxInt;
   FHighBound:=-MaxInt;
   FStyle:=aStyle;
   FContinuous:=True;
end;

// Destroy
//
destructor TEnumerationSymbol.Destroy;
begin
   FElements.Free;
   inherited;
end;

// DefaultValue
//
function TEnumerationSymbol.DefaultValue : Int64;
begin
   if FElements.Count>0 then
      Result:=TElementSymbol(FElements[0]).Value
   else Result:=0;
end;

// InitData
//
procedure TEnumerationSymbol.InitData(const Data: TData; Offset: Integer);
begin
   Data[Offset]:=DefaultValue;
end;

// BaseType
//
function TEnumerationSymbol.BaseType : TTypeSymbol;
begin
   Result:=Typ;
end;

// IsCompatible
//
function TEnumerationSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(typSym.UnAliasedType=Self);
end;

// DoIsOfType
//
function TEnumerationSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=   inherited DoIsOfType(typSym)
           or BaseType.DoIsOfType(typSym);
end;

// AddElement
//
procedure TEnumerationSymbol.AddElement(element : TElementSymbol);
begin
   if FContinuous and (FElements.Count>0) then
      if element.Value<>FHighBound+1 then
         FContinuous:=False;
   if element.Value<FLowBound then
      FLowBound:=element.Value;
   if element.Value>FHighBound then
      FHighBound:=element.Value;
   FElements.AddSymbol(element);
   element.FEnumeration:=Self;
end;

// ElementByValue
//
function TEnumerationSymbol.ElementByValue(const value : Int64) : TElementSymbol;
var
   i : Integer;
begin
   if (value>=FLowBound) and (value<=FHighBound) then begin
      if Continuous then begin
         Result:=TElementSymbol(Elements[value-FLowBound]);
         Exit;
      end else begin
         for i:=0 to Elements.Count-1 do begin
            Result:=TElementSymbol(Elements[i]);
            if Result.Value=value then Exit;
         end;
      end;
   end;
   Result:=nil;
end;

// GetCaption
//
function TEnumerationSymbol.GetCaption : String;
begin
   Result:=Name;
end;

// GetDescription
//
function TEnumerationSymbol.GetDescription : String;
var
   i : Integer;
begin
   Result:='(';
   for i:=0 to FElements.Count-1 do begin
      if i<>0 then
         Result:=Result+', ';
      Result:=Result+FElements[i].GetDescription;
   end;
   Result:=Result+')';
end;

// ShortDescription
//
function TEnumerationSymbol.ShortDescription : String;
begin
   case FElements.Count of
      0 : Result:=' ';
      1 : Result:=FElements[0].GetDescription;
   else
      Result:=FElements[0].Name+',...';
   end;
   Result:='('+Result+')';
end;

// ------------------
// ------------------ TAliasSymbol ------------------
// ------------------

// BaseType
//
function TAliasSymbol.BaseType : TTypeSymbol;
begin
   Result:=Typ.BaseType;
end;

// UnAliasedType
//
function TAliasSymbol.UnAliasedType : TTypeSymbol;
begin
   Result:=Typ.UnAliasedType;
end;

// InitData
//
procedure TAliasSymbol.InitData(const data : TData; offset : Integer);
begin
   Typ.InitData(Data, Offset);
end;

// InitVariant
//
procedure TAliasSymbol.InitVariant(var v : Variant);
begin
   Typ.InitVariant(v);
end;

// IsCompatible
//
function TAliasSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=Typ.IsCompatible(typSym);
end;

// IsPointerType
//
function TAliasSymbol.IsPointerType : Boolean;
begin
   Result:=Typ.IsPointerType;
end;

// DoIsOfType
//
function TAliasSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=Typ.DoIsOfType(typSym);
end;

// GetAsFuncSymbol
//
function TAliasSymbol.GetAsFuncSymbol : TFuncSymbol;
begin
   Result:=Typ.GetAsFuncSymbol;
end;

// GetDescription
//
function TAliasSymbol.GetDescription : String;
begin
   Result := Name + ' = ' + Typ.Name;
end;

// ------------------
// ------------------ TTypeSymbol ------------------
// ------------------

// BaseType
//
function TTypeSymbol.BaseType: TTypeSymbol;
begin
   Result:=Self;
end;

// UnAliasedType
//
function TTypeSymbol.UnAliasedType : TTypeSymbol;
begin
   Result:=Self;
end;

// UnAliasedTypeIs
//
function TTypeSymbol.UnAliasedTypeIs(const typeSymbolClass : TTypeSymbolClass) : Boolean;
begin
   Result:=(Self<>nil) and UnAliasedType.InheritsFrom(typeSymbolClass);
end;

// IsOfType
//
function TTypeSymbol.IsOfType(typSym : TTypeSymbol) : Boolean;
begin
   if Self=nil then
      Result:=(typSym=nil)
   else Result:=(typSym<>nil) and DoIsOfType(typSym);
end;

// DoIsOfType
//
function TTypeSymbol.DoIsOfType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(Self=typSym.UnAliasedType);
end;

// GetIsDeprecated
//
function TTypeSymbol.GetIsDeprecated : Boolean;
begin
   Result:=(FDeprecatedMessage<>'');
end;

// IsCompatible
//
function TTypeSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=BaseType.IsCompatible(typSym.BaseType);
end;

// CanExpectAnyFuncSymbol
//
function TTypeSymbol.CanExpectAnyFuncSymbol : Boolean;
begin
   Result := False;
end;

// IsCompatibleWithAnyFuncSymbol
//
function TTypeSymbol.IsCompatibleWithAnyFuncSymbol : Boolean;
begin
   Result := False;
end;

// DistanceTo
//
function TTypeSymbol.DistanceTo(typeSym : TTypeSymbol) : Integer;
begin
   if Self=typeSym then
      Result:=0
   else if UnAliasedType=typeSym.UnAliasedType then
      Result:=1
   else if IsCompatible(typeSym) then
      Result:=2
   else Result:=3;
end;

// SameType
//
function TTypeSymbol.SameType(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(Self=typSym);
end;

// HasMetaSymbol
//
function TTypeSymbol.HasMetaSymbol : Boolean;
begin
   Result:=False;
end;

// IsForwarded
//
function TTypeSymbol.IsForwarded : Boolean;
begin
   Result := False;
end;

// AssignsAsDataExpr
//
function TTypeSymbol.AssignsAsDataExpr : Boolean;
begin
   Result := (Size <> 1);
end;

// Specialize
//
function TTypeSymbol.Specialize(const context : ISpecializationContext) : TSymbol;
begin
   Result := SpecializeType(context);
end;

// SpecializeType
//
function TTypeSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
begin
   context.AddCompilerErrorFmt(CPE_SpecializationNotSupportedYet, [ClassName]);
   Result := Self;
end;

// IsType
//
function TTypeSymbol.IsType : Boolean;
begin
   Result:=True;
end;

// InitData
//
procedure TTypeSymbol.InitData(const data : TData; offset : Integer);
begin
   Assert(False);
end;

// InitDataContext
//
procedure TTypeSymbol.InitDataContext(const data : IDataContext);
begin
   InitData(data.AsPData^, data.Addr);
end;

// InitVariant
//
procedure TTypeSymbol.InitVariant(var v : Variant);
var
   buf : TData;
begin
   Assert(Size = 1);
   SetLength(buf, 1);
   InitData(buf, 0);
   VarCopySafe(v, buf[0]);
end;

// DynamicInitialization
//
function TTypeSymbol.DynamicInitialization : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TAnyTypeSymbol ------------------
// ------------------

// IsCompatible
//
function TAnyTypeSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(typSym<>nil);
end;

// ------------------
// ------------------ EScriptError ------------------
// ------------------

// CreatePosFmt
//
constructor EScriptError.CreatePosFmt(const aScriptPos: TScriptPos; const Msg: String; const Args: array of const);
begin
   inherited CreateFmt(msg, args);
   FScriptPos:=aScriptPos;
end;

// SetScriptPos
//
procedure EScriptError.SetScriptPos(const aPos : TScriptPos);
begin
   FScriptPos:=aPos;
end;

// ------------------
// ------------------ EScriptStopped ------------------
// ------------------

// DoRaise
//
class procedure EScriptStopped.DoRaise(exec : TdwsExecution; stoppedOn : TExprBase);
var
   e : EScriptStopped;
begin
   e:=EScriptStopped.CreatePosFmt(stoppedOn.ScriptPos, RTE_ScriptStopped, []);
   e.ScriptCallStack:=exec.GetCallStack;
   raise e;
end;

// ------------------
// ------------------ EScriptException ------------------
// ------------------

// Create
//
constructor EScriptException.Create(const msgString : String;
      const anExceptionObj : IScriptObj; const aScriptPos: TScriptPos);
begin
   inherited Create(msgString);
   FExceptObj:=anExceptionObj;
   FScriptPos:=aScriptPos;
end;

// ------------------
// ------------------ TdwsBaseSymbolsContext ------------------
// ------------------

// SetBaseTypes
//
procedure TdwsBaseSymbolsContext.SetBaseTypes(const bt : TdwsBaseSymbolTypes);
begin
   FBaseTypes := bt;
end;

// ------------------
// ------------------ TdwsExecution ------------------
// ------------------

// Create
//
constructor TdwsExecution.Create(const stackParams : TStackParameters);
begin
   inherited Create;
   FStack.Initialize(stackParams);
   FStack.Reset;
   FExceptionObjectStack:=TSimpleStack<IScriptObj>.Create;
   FRandSeed:=cDefaultRandSeed xor (UInt64(System.Random($7FFFFFFF)) shl 15);
end;

// Destroy
//
destructor TdwsExecution.Destroy;
begin
   Assert(not Assigned(FSelfScriptObject));
   FExceptionObjectStack.Free;
   FStack.Finalize;
   FCallStack.Free;
   FFormatSettings.Free;
   inherited;
end;

// DoStep
//
procedure TdwsExecution.DoStep(expr : TExprBase);

   procedure DoDebug(exec : TdwsExecution; expr : TExprBase);
   begin
      exec.Debugger.DoDebug(exec, expr);
      if exec.ProgramState=psRunningStopped then
         EScriptStopped.DoRaise(exec, expr);
   end;

begin
   if ProgramState=psRunningStopped then
      EScriptStopped.DoRaise(Self, expr)
   else if IsDebugging then
      DoDebug(Self, expr);
end;

// Status_Offset
//
class function TdwsExecution.Status_Offset : Integer;
begin
   Assert(SizeOf(TdwsExecution(nil).FStatus) = 1);
   Result := IntPtr(@TdwsExecution(nil).FStatus);
end;

// StackMixin_Offset
//
class function TdwsExecution.StackMixin_Offset : Integer;
begin
   Result := IntPtr(@TdwsExecution(nil).FStack);
end;

// GetLastScriptErrorExpr
//
function TdwsExecution.GetLastScriptErrorExpr : TExprBase;
begin
   Result := FLastScriptError;
end;

// SetScriptError
//
procedure TdwsExecution.SetScriptError(expr : TExprBase);
begin
   if FLastScriptError=nil then begin
      FLastScriptError:=expr;
      FLastScriptCallStack:=GetCallStack;
   end;
end;

// ClearScriptError
//
procedure TdwsExecution.ClearScriptError;
begin
   if FLastScriptError<>nil then begin
      FLastScriptError:=nil;
      FLastScriptCallStack:=nil;
   end;
end;

// GetDebugger
//
function TdwsExecution.GetDebugger : IDebugger;
begin
   Result:=FDebugger;
end;

// SetDebugger
//
procedure TdwsExecution.SetDebugger(const aDebugger : IDebugger);
begin
   FDebugger:=aDebugger;
   FIsDebugging:=(aDebugger<>nil);
end;

// StartDebug
//
procedure TdwsExecution.StartDebug;
begin
   FIsDebugging:=Assigned(FDebugger);
   if FIsDebugging then
      FDebugger.StartDebug(Self);
end;

// StopDebug
//
procedure TdwsExecution.StopDebug;
begin
   if Assigned(FDebugger) then
      FDebugger.StopDebug(Self);
   FIsDebugging:=False;
end;

// GetUserObject
//
function TdwsExecution.GetUserObject : TObject;
begin
   Result:=FUserObject;
end;

// SetUserObject
//
procedure TdwsExecution.SetUserObject(const value : TObject);
begin
   FUserObject:=value;
end;

// GetStack
//
function TdwsExecution.GetStack : TStack;
begin
   Result:=@FStack;
end;

// GetProgramState
//
function TdwsExecution.GetProgramState : TProgramState;
begin
   Result:=FProgramState;
end;

// GetFormatSettings
//
function TdwsExecution.GetFormatSettings : TdwsFormatSettings;
begin
   if FFormatSettings=nil then
      FFormatSettings:=TdwsFormatSettings.Create;
   Result:=FFormatSettings;
end;

// GetExecutionObject
//
function TdwsExecution.GetExecutionObject : TdwsExecution;
begin
   Result:=Self;
end;

// Random
//
{$IFOPT R+}
  {$DEFINE RANGEON}
  {$R-}
{$ELSE}
  {$UNDEF RANGEON}
{$ENDIF}
function TdwsExecution.Random : Double;
// Marsaglia, George (July 2003). "Xorshift RNGs". Journal of Statistical Software Vol. 8 (Issue  14).
const
   cScale : Double = (2.0 / $10000 / $10000 / $10000 / $10000);  // 2^-63
var
   buf : Uint64;
begin
   if FRandSeed=0 then
      buf:=cDefaultRandSeed
   else begin
      buf:=FRandSeed xor (FRandSeed shl 13);
      buf:=buf xor (buf shr 17);
      buf:=buf xor (buf shl 5);
   end;
   FRandSeed:=buf;
   Result:=(buf shr 1)*cScale;
end;
{$IFDEF RANGEON}
  {$R+}
  {$UNDEF RANGEON}
{$ENDIF}

// Sleep
//
procedure TdwsExecution.Sleep(msec, sleepCycle : Integer);
var
   stopTicks, tStart, tNow : Int64;
begin
   // this is an abortable sleep with a granulosity
   if msec<0 then Exit;
   FSleeping:=True;
   tStart:=GetSystemMilliseconds;
   if msec=0 then begin
      // special case of relinquishing current time slice
      SystemSleep(0);
      tNow:=GetSystemMilliseconds;
   end else begin
      tNow:=tStart;
      stopTicks:=tStart+msec;
      repeat
         msec:=stopTicks-tNow;
         if msec<0 then break;
         if msec>sleepCycle then msec:=sleepCycle;
         SystemSleep(msec);
         tNow:=GetSystemMilliseconds;
      until ProgramState<>psRunning;
   end;
   FSleepTime:=FSleepTime+tNow-tStart;
   FSleeping:=False;
end;

// GetSleeping
//
function TdwsExecution.GetSleeping : Boolean;
begin
   Result:=FSleeping;
end;

// EnterExceptionBlock
//
procedure TdwsExecution.EnterExceptionBlock(var exceptObj : IScriptObj);
begin
   ExceptionObjectStack.Push(exceptObj);
end;

// LeaveExceptionBlock
//
procedure TdwsExecution.LeaveExceptionBlock;
begin
   ExceptionObjectStack.Peek:=nil;
   ExceptionObjectStack.Pop;
end;

// SetRandSeed
//
procedure TdwsExecution.SetRandSeed(const val : UInt64);
begin
   if val=0 then
      FRandSeed:=cDefaultRandSeed
   else FRandSeed:=val;
end;

// LocalizeSymbol
//
procedure TdwsExecution.LocalizeSymbol(aResSymbol : TResourceStringSymbol; var Result : String);
begin
   LocalizeString(aResSymbol.Value, Result);
end;

// LocalizeString
//
procedure TdwsExecution.LocalizeString(const aString : String; var Result : String);
begin
   Result:=aString;
end;

// ValidateFileName
//
function TdwsExecution.ValidateFileName(const path : String) : String;
begin
   raise EScriptException.CreateFmt(RTE_UnauthorizedFilePath, [path]);
end;

// DataContext_Create
//
procedure TdwsExecution.DataContext_Create(const data : TData; addr : Integer; var result : IDataContext);
begin
   Result:=FStack.CreateDataContext(data, addr);
end;

// DataContext_CreateEmpty
//
procedure TdwsExecution.DataContext_CreateEmpty(size : Integer; var Result : IDataContext);
var
   data : TData;
begin
   SetLength(data, size);
   Result:=FStack.CreateDataContext(data, 0);
end;

// DataContext_CreateValue
//
procedure TdwsExecution.DataContext_CreateValue(const value : Variant; var Result : IDataContext);
var
   data : TData;
begin
   SetLength(data, 1);
   data[0]:=value;
   Result:=FStack.CreateDataContext(data, 0);
end;

// DataContext_CreateBase
//
procedure TdwsExecution.DataContext_CreateBase(addr : Integer; var result : IDataContext);
begin
   FStack.InitDataPtr(Result, addr);
end;

// DataContext_CreateLevel
//
procedure TdwsExecution.DataContext_CreateLevel(level, addr : Integer; var Result : IDataContext);
begin
   FStack.InitDataPtrLevel(Result, level, addr);
end;

// DataContext_CreateOffset
//
procedure TdwsExecution.DataContext_CreateOffset(const data : IDataContext; offset : Integer; var Result : IDataContext);
begin
   Result := FStack.CreateDataContext(data.AsPData^, offset);
end;

// DataContext_Nil
//
function TdwsExecution.DataContext_Nil : IDataContext;
begin
   Result:=FStack.CreateDataContext(nil, 0);
end;

// GetStackPData
//
function TdwsExecution.GetStackPData : PData;
begin
   Result := FStack.GetPData;
end;

// SuspendDebug
//
procedure TdwsExecution.SuspendDebug;
begin
   if FDebugSuspended = 0 then begin
      if FIsDebugging then
         FDebugSuspended := 1
      else FDebugSuspended := -1;
      FIsDebugging := False;
   end else if FDebugSuspended > 0 then
      Inc(FDebugSuspended)
   else Dec(FDebugSuspended);
end;

// ResumeDebug
//
procedure TdwsExecution.ResumeDebug;
begin
   case FDebugSuspended of
      0 : Assert(False);
      1 : begin
         FDebugSuspended := 0;
         FIsDebugging := True;
      end;
      -1 : FDebugSuspended := 0;
   else
      if FDebugSuspended > 0 then
         Dec(FDebugSuspended)
      else Inc(FDebugSuspended);
   end;
end;

// GetEnvironment
//
function TdwsExecution.GetEnvironment : IdwsEnvironment;
begin
   Result := FEnvironment;
end;

// SetEnvironment
//
procedure TdwsExecution.SetEnvironment(const val : IdwsEnvironment);
begin
   FEnvironment := val;
end;

// BeginInternalExecution
//
procedure TdwsExecution.BeginInternalExecution;
begin
   Inc(FInternalExecution);
end;

// EndInternalExecution
//
procedure TdwsExecution.EndInternalExecution;
begin
   Dec(FInternalExecution);
end;

// InternalExecution
//
function TdwsExecution.InternalExecution : Boolean;
begin
   Result := (FInternalExecution > 0);
end;

// ------------------
// ------------------ TConditionSymbol ------------------
// ------------------

// Create
//
constructor TConditionSymbol.Create(const aScriptPos: TScriptPos; const cond : IBooleanEvalable; const msg : IStringEvalable);
begin
   inherited Create('', nil);
   FScriptPos:=aScriptPos;
   FCondition:=cond;
   FMessage:=msg;
end;

// ------------------
// ------------------ TRuntimeErrorMessage ------------------
// ------------------

// AsInfo
//
function TRuntimeErrorMessage.AsInfo: String;
begin
   Result:=Text;
   if ScriptPos.Defined then
      Result:=Result+ScriptPos.AsInfo
   else if Length(FCallStack)>0 then
      Result:=Result+' in '+FCallStack[High(FCallStack)].Expr.FuncSymQualifiedName;
   if Length(FCallStack)>0 then begin
      Result:=result+#13#10+TExprBase.CallStackToString(FCallStack);
   end;
   Result := Format(MSG_RuntimeError, [Result]);
end;

// ------------------
// ------------------ TdwsRuntimeMessageList ------------------
// ------------------

// AddRuntimeError
//
procedure TdwsRuntimeMessageList.AddRuntimeError(const Text: String);
begin
   AddRuntimeError(cNullPos, Text, nil);
end;

// AddRuntimeError
//
procedure TdwsRuntimeMessageList.AddRuntimeError(e : Exception);
begin
   AddRuntimeError(E.ClassName+': '+E.Message);
end;

// AddRuntimeError
//
procedure TdwsRuntimeMessageList.AddRuntimeError(const scriptPos : TScriptPos;
                     const Text: String; const callStack : TdwsExprLocationArray);
var
   msg : TRuntimeErrorMessage;
begin
   msg:=TRuntimeErrorMessage.Create(Self, Text, scriptPos);
   msg.FCallStack:=callStack;
end;

// ------------------
// ------------------ TOperatorSymbol ------------------
// ------------------

// Create
//
constructor TOperatorSymbol.Create(const aTokenType : TTokenType);
begin
   inherited Create('operator '+cTokenStrings[aTokenType], nil);
   FToken:=aTokenType;
end;

// AddParam
//
procedure TOperatorSymbol.AddParam(p : TTypeSymbol);
var
   n : Integer;
begin
   n:=Length(FParams);
   SetLength(FParams, n+1);
   FParams[n]:=p;
end;

// GetCaption
//
function TOperatorSymbol.GetCaption : String;
var
   i : Integer;
begin
   Result:='operator '+cTokenStrings[Token]+' (';
   for i:=0 to High(Params) do begin
      if i>0 then
         Result:=Result+', ';
      Result:=Result+Params[i].Typ.Caption;
   end;
   Result:=Result+') : '+Typ.Caption+' uses '+FUsesSym.Name;
end;

// ------------------
// ------------------ TResolvedInterfaces ------------------
// ------------------

// SameItem
//
function TResolvedInterfaces.SameItem(const item1, item2 : TResolvedInterface) : Boolean;
begin
   Result:=(item1.IntfSymbol=item2.IntfSymbol);
end;

// GetItemHashCode
//
function TResolvedInterfaces.GetItemHashCode(const item1 : TResolvedInterface) : Cardinal;
begin
   Result := SimplePointerHash(item1.IntfSymbol);
end;

// ------------------
// ------------------ TAnyFuncSymbol ------------------
// ------------------

// IsCompatible
//
function TAnyFuncSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result := (typSym.AsFuncSymbol<>nil);
end;

// IsCompatibleWithAnyFuncSymbol
//
function TAnyFuncSymbol.IsCompatibleWithAnyFuncSymbol : Boolean;
begin
   Result := True;
end;

// Initialize
//
procedure TAnyFuncSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   // nothing
end;

// ------------------
// ------------------ TResourceStringSymbol ------------------
// ------------------

// Create
//
constructor TResourceStringSymbol.Create(const aName, aValue : String);
begin
   inherited Create(aName, nil);
   FValue:=aValue;
   FIndex:=-1;
end;

// GetCaption
//
function TResourceStringSymbol.GetCaption : String;
begin
   Result:='resourcestring '+Name;
end;

// GetDescription
//
function TResourceStringSymbol.GetDescription : String;
begin
   Result:=Value;
   FastStringReplace(Result, '''', '''''');
   Result:='resourcestring '+Name+' = '''+Result+'''';
end;

// ------------------
// ------------------ TResourceStringSymbolList ------------------
// ------------------

// ComputeIndexes
//
procedure TResourceStringSymbolList.ComputeIndexes;
var
   i : Integer;
begin
   for i:=0 to Count-1 do
      Items[i].Index:=i;
end;

// ------------------
// ------------------ TFuncSymbolList ------------------
// ------------------

// ContainsChildMethodOf
//
function TFuncSymbolList.ContainsChildMethodOf(methSym : TMethodSymbol) : Boolean;
var
   i : Integer;
   funcSym : TFuncSymbol;
   meth : TMethodSymbol;
begin
   for i:=0 to Count-1 do begin
      funcSym:=Items[i];
      if funcSym is TMethodSymbol then begin
         meth:=TMethodSymbol(funcSym);
         repeat
            if meth=methSym then Exit(True);
            meth:=meth.ParentMeth;
         until meth=nil;
      end;
   end;
   Result:=False;
end;

// ------------------
// ------------------ THelperSymbol ------------------
// ------------------

// Create
//
constructor THelperSymbol.Create(const name : String; aUnit : TSymbol;
                                 aForType : TTypeSymbol; priority : Integer);
begin
   inherited Create(name, aUnit);
   FForType:=aForType;
   FUnAliasedForType:=aForType.UnAliasedType;
   if FUnAliasedForType is TStructuredTypeSymbol then
      FMetaForType:=TStructuredTypeSymbol(FUnAliasedForType).MetaSymbol;
end;

// IsCompatible
//
function THelperSymbol.IsCompatible(typSym : TTypeSymbol) : Boolean;
begin
   Result:=(typSym=Self);
end;

// IsType
//
function THelperSymbol.IsType : Boolean;
begin
   Result:=False;
end;

// AllowDefaultProperty
//
function THelperSymbol.AllowDefaultProperty : Boolean;
begin
   Result:=False;
end;

// CreateSelfParameter
//
function THelperSymbol.CreateSelfParameter(methSym : TMethodSymbol) : TDataSymbol;
var
   meta : TStructuredTypeMetaSymbol;
begin
   if methSym.IsClassMethod then begin
      if ForType is TStructuredTypeSymbol then begin
         meta:=TStructuredTypeSymbol(ForType).MetaSymbol;
         if meta<>nil then
            Result:=TParamSymbol.Create(SYS_SELF, meta)
         else Result:=nil;
      end else Result:=nil
   end else begin
      if    (ForType is TClassSymbol) or (ForType is TInterfaceSymbol)
         or (ForType is TDynamicArraySymbol) then
         Result:=TParamSymbol.Create(SYS_SELF, ForType)
      else Result := CreateConstParamSymbol(SYS_SELF, ForType);
   end;
   if Result<>nil then begin
      methSym.Params.AddSymbol(Result);
      if Result.Typ is TCompositeTypeSymbol then
         methSym.Params.AddParent(TCompositeTypeSymbol(Result.Typ).Members)
      else if Result.Typ is TStructuredTypeMetaSymbol then
         methSym.Params.AddParent(TStructuredTypeMetaSymbol(Result.Typ).StructSymbol.Members)
   end;
end;

// CreateAnonymousMethod
//
function THelperSymbol.CreateAnonymousMethod(aFuncKind : TFuncKind;
                                             aVisibility : TdwsVisibility;
                                             isClassMethod : Boolean) : TMethodSymbol;
begin
   Result:=TSourceMethodSymbol.Create('', aFuncKind, Self, aVisibility, isClassMethod);
   if isClassMethod and (not ForType.HasMetaSymbol) then
      TSourceMethodSymbol(Result).SetIsStatic;
end;

// Initialize
//
procedure THelperSymbol.Initialize(const msgs : TdwsCompileMessageList);
begin
   CheckMethodsImplemented(msgs);
end;

// HelpsType
//
function THelperSymbol.HelpsType(typ : TTypeSymbol) : Boolean;
begin
   if typ=ForType then
      Result:=True
   else if (typ=nil) or Strict then
      Result:=False
   else if typ.IsOfType(FUnAliasedForType) then
      Result:=True
   else if FMetaForType<>nil then
      Result:=typ.IsOfType(FMetaForType)
   else Result:=False;
end;

// GetMetaSymbol
//
function THelperSymbol.GetMetaSymbol : TStructuredTypeMetaSymbol;
begin
   Result:=FMetaForType;
end;

// ------------------
// ------------------ THelperSymbols ------------------
// ------------------

// AddHelper
//
function THelperSymbols.AddHelper(helper : THelperSymbol) : Boolean;
begin
   Add(helper);
   Result:=False;
end;

// ------------------
// ------------------ TAliasMethodSymbol ------------------
// ------------------

// GetDeclarationPosition
//
function TAliasMethodSymbol.GetDeclarationPosition : TScriptPos;
begin
   Result := Alias.GetDeclarationPosition;
end;

// GetImplementationPosition
//
function TAliasMethodSymbol.GetImplementationPosition : TScriptPos;
begin
   Result := Alias.GetImplementationPosition;
end;

// IsPointerType
//
function TAliasMethodSymbol.IsPointerType : Boolean;
begin
   Result:=Alias.IsPointerType;
end;

// ParamsDescription
//
function TAliasMethodSymbol.ParamsDescription : String;
begin
   Result := Params.Description(1);
end;

// SpecializeType
//
function TAliasMethodSymbol.SpecializeType(const context : ISpecializationContext) : TTypeSymbol;
begin
   context.AddCompilerErrorFmt(CPE_SpecializationNotSupportedYet, [ClassName]);
   Result := Self;
end;

// ------------------
// ------------------ TPerfectMatchEnumerator ------------------
// ------------------

// Callback
//
function TPerfectMatchEnumerator.Callback(sym : TSymbol) : Boolean;
var
   locSym : TFuncSymbol;
begin
   locSym:=sym.AsFuncSymbol;
   if locSym<>nil then begin
      if locSym.Level=FuncSym.Level then begin
         if FuncSym.IsSameOverloadOf(locSym) then begin
            Match:=locSym;
            Exit(True);
         end;
      end;
   end;
   Result:=False;
end;

end.
