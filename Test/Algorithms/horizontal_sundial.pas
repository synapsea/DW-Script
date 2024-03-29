procedure PrintSundial(lat, lng, lme : Float);
begin
   PrintLn(Format('latitude:        %7.2f', [lat]));
   PrintLn(Format('longitude:       %7.2f', [lng]));
   PrintLn(Format('legal meridian:  %7.2f', [lme]));

   var slat := Sin(DegToRad(lat));

   PrintLn(Format('sine of latitude: %.3f', [slat]));
   PrintLn(Format('diff longitude:   %.3f', [lng-lme]));
   PrintLn('');
   PrintLn('Hour, sun hour angle, dial hour line angle from 6am to 6pm');

   var h : Integer;
   for h:=-6 to 6 do begin
      var hra := 15 * h - (lng - lme);
      var hraRad := DegToRad(hra);
      var hla :=RadToDeg(ArcTan2(Sin(hraRad)*slat, Cos(hraRad)));
      PrintLn(Format('HR=%3d; HRA=%7.3f; HLA=%7.3f', [h, hra, hla]));
   end
end;

PrintSundial(-4.95, -150.5, -150);

