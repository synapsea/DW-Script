//
// Ray-traced sphere
//

type
   TFloat3  = array[0..2] of Float;

var
   light : TFloat3 = [ 30, 30, -50 ];

procedure normalize(var v : TFloat3);
var
   len: Float;
begin
    len := sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
    v[0] /= len;
    v[1] /= len;
    v[2] /= len;
end;

function dot(x, y : TFloat3) : Float;
begin
    Result := x[0]*y[0] + x[1]*y[1] + x[2]*y[2];
    if Result<0 then
       Result:=-Result
    else Result:=0;
end;

procedure drawSphere(R, k, ambient : Float);
var
   vec : TFloat3;
   x, y, b : Float;
   i, j, size, intensity : Integer;
begin
   size:=Trunc(Ceil(R)-Floor(-R)+1);
   PrintLn('P2');
   PrintLn(IntToStr(size)+' '+IntToStr(size));
   PrintLn('255');
   for i := Floor(-R) to Ceil(R) do begin
      x := i + 0.5;
      for j := Floor(-R) to Ceil(R) do begin
         y := j + 0.5;
         if (x * x + y * y <= R * R) then begin
            vec[0] := x;
            vec[1] := y;
            vec[2] := sqrt(R * R - x * x - y * y);
            normalize(vec);
            b := Power(dot(light, vec), k) + ambient;
            intensity := ClampInt( Round(b*255), 0, 255);
            Print(intensity);
            Print(' ')
         end else Print('0 ');
      end;
      PrintLn('');
   end;
end;

normalize(light);
drawSphere(19, 4, 0.1);

