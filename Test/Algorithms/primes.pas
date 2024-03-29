// Sieve of Eratosthenes implemented via dynamic arrays

function Primes(limit : Integer) : array of Integer;
var
   n, k : Integer;
   sieve := new Boolean[limit+1];
begin
   for n := 2 to Round(Sqrt(limit)) do begin
      if not sieve[n] then begin
         for k := n*n to limit step n do
            sieve[k] := True;
      end;
   end;
   
   for k:=2 to limit do
      if not sieve[k] then
         Result.Add(k);
end;

var r := Primes(50);
var i : Integer;
for i:=0 to r.High do
   PrintLn(r[i]);
   
