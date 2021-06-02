type
  IIntfA = interface 
    procedure A;
  end;
type
  IIntfB = interface 
    procedure B;
  end;
  
type
  TImpAB = class(TObject, IIntfA, IIntfB)
    procedure A; begin PrintLn('A'); end;
    procedure B; begin PrintLn('B'); end;
  end;

var Imp: TImpAB;
var IntfA: IIntfA;
var IntfB: IIntfB;

Imp := TImpAB.Create;
Imp.A;
Imp.B;

IntfA := Imp;
IntfA.A;

IntfB := Imp;
IntfB.B;
