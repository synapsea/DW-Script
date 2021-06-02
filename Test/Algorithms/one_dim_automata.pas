const ngenerations = 10;
const table = [0, 0, 0, 1, 0, 1, 1, 0];
 
var a := [0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0];
var b := a;
 
var i, j : Integer;
for i := 1 to ngenerations do begin
   for j := a.low+1 to a.high-1 do begin
      if a[j] = 0 then
         Print('_')
      else Print('#');
      var val := (a[j-1] shl 2) or (a[j] shl 1) or a[j+1];
      b[j] := table[val];
   end;
   var tmp := a;
   a := b;
   b := tmp;
   PrintLn('');
end;