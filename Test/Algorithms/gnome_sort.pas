procedure GnomeSort(a : array of Integer);
var
   i, j : Integer;
begin
   i := 1;
   j := 2;
   while i < a.Length do begin
      if a[i-1] <= a[i] then begin
         i := j;
         j := j + 1;
      end else begin
         a.Swap(i-1, i);
         i := i - 1;
         if i = 0 then begin
            i := j;
            j := j + 1;
         end;
      end;
   end;
end;

var i : Integer;
var a := new Integer[16];

Print('{');
for i := 0 to a.High do begin
   a[i] := i xor 5;
   Print(Format('%3d ', [a[i]]));
end;
PrintLn('}');

GnomeSort(a);

Print('{');
for i := 0 to a.High do
   Print(Format('%3d ', [a[i]]));
PrintLn('}');


