
function Cholesky(a : array of Float) : array of Float;
var
   i, j, k, n : Integer;
   s : Float;
begin
   n:=Round(Sqrt(a.Length));
   Result:=new Float[n*n];
   for i:=0 to n-1 do begin
      for j:=0 to i do begin
         s:=0 ;
         for k:=0 to j-1 do
            s+=Result[i*n+k] * Result[j*n+k];
         if i=j then
            Result[i*n+j]:=Sqrt(a[i*n+i]-s)
         else Result[i*n+j]:=1/Result[j*n+j]*(a[i*n+j]-s);
      end;
   end;
end;

procedure ShowMatrix(a : array of Float);
var
   i, j, n : Integer;
begin
   n:=Round(Sqrt(a.Length));
   for i:=0 to n-1 do begin
      for j:=0 to n-1 do
         Print(Format('%2.5f ', [a[i*n+j]]));
      PrintLn('');
   end;
end;

var m1 := new Float[9];
m1 := [ 25.0, 15.0, -5.0, 
        15.0, 18.0,  0.0, 
        -5.0,  0.0, 11.0 ];
var c1 := Cholesky(m1);
ShowMatrix(c1);

PrintLn('');

var m2 : array of Float := [ 18.0, 22.0,  54.0,  42.0,
                             22.0, 70.0,  86.0,  62.0,
                             54.0, 86.0, 174.0, 134.0,
                             42.0, 62.0, 134.0, 106.0 ];
var c2 := Cholesky(m2);
ShowMatrix(c2);

