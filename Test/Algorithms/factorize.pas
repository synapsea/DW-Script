function Factorize(n : Integer) : String;
begin
   if n <= 1 then
      Exit('1');
   var k := 2;
   while n >= k do begin
      while (n mod k) = 0 do begin
         Result += ' * '+IntToStr(k);
         n := n div k;
      end;
      Inc(k);
   end;
   Result:=SubStr(Result, 4);
end;

var i : Integer;
for i := 1 to 22 do
   PrintLn(IntToStr(i) + ': ' + Factorize(i));