function InCarpet(x, y : Integer) : Boolean;
begin
   while (x<>0) and (y<>0) do begin
      if ((x mod 3)=1) and ((y mod 3)=1) then
         Exit(False);
      x := x div 3;
      y := y div 3;
   end;
   Result := True;
end;

procedure Carpet(n : Integer);
var
   i, j, p : Integer;
begin
   p := Round(IntPower(3, n));

   for i:=0 to p-1 do begin
      for j:=0 to p-1 do begin
         if InCarpet(i, j) then
            Print('#')
         else Print(' ');
      end;
      PrintLn('');
   end;
end;

Carpet(3);