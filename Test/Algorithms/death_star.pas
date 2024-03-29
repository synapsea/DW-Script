const cShades = '.:!*oe&#%@';

type TVector3 = array [0..2] of Float;

var light : TVector3 = [-50.0, 30, 50];
 
procedure Normalize(var v : TVector3);
begin
   var len := Sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
   v[0] /= len; v[1] /= len; v[2] /= len;
end;
 
function Dot(x, y : TVector3) : Float;
begin
   var d := x[0]*y[0] + x[1]*y[1] + x[2]*y[2];
   if d<0 then 
      Result:=-d 
   else Result:=0;
end;
 
type 
   TSphere = record
      cx, cy, cz, r : Float;
   end;
   
const big : TSphere = (cx: 20; cy: 20; cz: 0; r: 20);
const small : TSphere = (cx: 7; cy: 7; cz: -10; r: 15);
 
function HitSphere(sph : TSphere; x, y : Float; var z1, z2 : Float) : Boolean;
begin
   x -= sph.cx;
   y -= sph.cy;
   var zsq = sph.r * sph.r - (x * x + y * y);
   if (zsq < 0) then Exit False;
   zsq := Sqrt(zsq);
   z1 := sph.cz - zsq;
   z2 := sph.cz + zsq;
   Result:=True;
end;
 
procedure DrawSphere(k, ambient : Float);
var
   i, j, intensity : Integer;
   b : Float;
   x, y, zb1, zb2, zs1, zs2 : Float;
   vec : TVector3;
begin
   for i:=Trunc(big.cy-big.r) to Trunc(big.cy+big.r)+1 do begin
      y := i + 0.5;
      for j := Trunc(big.cx-2*big.r) to Trunc(big.cx+2*big.r) do begin
         x := (j-big.cx)/2 + 0.5 + big.cx;
 
         if not HitSphere(big, x, y, zb1, zb2) then begin
            Print(' ');
            continue;
         end;
         if not HitSphere(small, x, y, zs1, zs2) then begin
            vec[0] := x - big.cx;
            vec[1] := y - big.cy;
            vec[2] := zb1 - big.cz;
         end else begin
            if zs1 < zb1 then begin
               if zs2 > zb2 then begin
                  Print(' ');
                  continue;
               end;
               if zs2 > zb1 then begin
                  vec[0] := small.cx - x;
                  vec[1] := small.cy - y;
                  vec[2] := small.cz - zs2;
               end else begin
                  vec[0] := x - big.cx;
                  vec[1] := y - big.cy;
                  vec[2] := zb1 - big.cz;
               end;
            end else begin
               vec[0] := x - big.cx;
               vec[1] := y - big.cy;
               vec[2] := zb1 - big.cz;
            end;
         end;
 
         Normalize(vec);
         b := Power(Dot(light, vec), k) + ambient;
         intensity := Round((1 - b) * Length(cShades));
         Print(cShades[ClampInt(intensity+1, 1, Length(cShades))]);
      end;
      PrintLn('');
   end;
end;
 
Normalize(light);
 
DrawSphere(2, 0.3);
