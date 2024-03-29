procedure ExtractRanges(const values : array of Integer);
begin
   var i:=0;
   while i<values.Length do begin
      if i>0 then
         Print(',');
      Print(values[i]);
      var j:=i+1;
      while (j<values.Length) and (values[j]=values[j-1]+1) do
         Inc(j);
      Dec(j);
      if j>i then begin
         if j=i+1 then
            Print(',')
         else Print('-');
         Print(values[j]);
      end;
      i:=j+1;
   end;
end;

ExtractRanges([ 0,  1,  2,  4,  6,  7,  8, 11, 12, 14,
               15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
               25, 27, 28, 29, 30, 31, 32, 33, 35, 36,
               37, 38, 39]);
PrintLn('');