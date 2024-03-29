type TFnType = function(x : Float) : Float;
 
function First(f : TFnType) : Float;
begin
   Result := f(1) + 2;
end;
 
function Second(f : Float) : Float;
begin
   Result := f/2;
end;
 
PrintLn(First(Second));