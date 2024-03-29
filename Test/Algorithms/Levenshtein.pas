function LevenshteinDistance(s, t : String) : Integer;
var
   i, j : Integer;
begin
   var d:=new Integer[Length(s)+1,Length(t)+1];
   for i:=0 to Length(s) do
      d[i,0]:=i;
   for j:=0 to Length(t) do
      d[0,j]:=j;
   
   for j:=1 to Length(t) do
      for i:=1 to Length(s) do
         if s[i]=t[j] then
            d[i,j]:=d[i-1,j-1] //no operation
         else d[i,j]:=MinInt(MinInt(
               d[i-1,j]+1,    //a deletion
               d[i,j-1]+1),   //an insertion
               d[i-1,j-1]+1   //a substitution
               );
   Result:=d[Length(s), Length(t)];
end;

procedure PrintDistance(s, t : String);
begin
   PrintLn(Format('%s -> %s = %d', [s, t, LevenshteinDistance(s, t)]));
end;

PrintDistance('kitten', 'sitting');
PrintDistance('rosettacode', 'raisethysword');