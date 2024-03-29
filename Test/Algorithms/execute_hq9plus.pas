procedure RunCode(code : String);
var
   i : Integer;
   accum, bottles : Integer;
begin
   for i:=1 to Length(code) do begin
      case code[i] of
         'Q', 'q' : PrintLn(code);
         'H', 'h' : PrintLn('Hello, world!');
         '9' : begin
            bottles:=3; // for brevity
            while bottles>1 do begin
               Print(bottles); PrintLn(' bottles of beer on the wall,');
               Print(bottles); PrintLn(' bottles of beer.');
               PrintLn('Take one down, pass it around,');
               Dec(bottles);
               if bottles>1 then begin
                  Print(bottles); PrintLn(' bottles of beer on the wall.'#13#10);
               end;
            end;
            PrintLn('1 bottle of beer on the wall.');
         end;
         '+' : Inc(accum);
      else
         PrintLn('Syntax Error');
      end;
   end;
end;

RunCode('HQ9+!');