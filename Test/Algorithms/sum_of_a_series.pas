var s : Float;
for var i := 1 to 1000 do
   s += 1 / Sqr(i);

PrintLn(Format('%.3f', [s]));