function DotProduct(a, b : array of Float) : Float;
require
   a.Length = b.Length;
var
   i : Integer;
begin
   Result := 0;
   for i := 0 to a.High do
      Result += a[i]*b[i];
end;

PrintLn(DotProduct([1,3,-5], [4,-2,-1]));