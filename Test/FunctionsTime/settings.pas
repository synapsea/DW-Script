﻿
FormatSettings.ShortDateFormat := '= mm-dd';
FormatSettings.ShortTimeFormat := '= hh-nn';
FormatSettings.LongDateFormat := '= yy-mm-dd';
FormatSettings.LongTimeFormat := '= hh-nn-ss';
FormatSettings.TimeAMString := 'Xx';
FormatSettings.TimePMString := 'Yy';

var t := ParseDateTime('dd/mm/yyyy hh:nn:ss', '27/12/2014 10:04:48');

PrintLn(DateToStr(t));
PrintLn(TimeToStr(t));
PrintLn(DateTimeToStr(t));

PrintLn(FormatDateTime('dd/mm dd-mm dd.mm', t));

PrintLn(FormatDateTime('hh:nn am/pm', t));
PrintLn(FormatDateTime('hh:nn a/p', t));
PrintLn(FormatDateTime('hh:nn ampm', t));

t := ParseDateTime('dd/mm/yyyy hh:nn:ss', '27/12/2014 20:09:10');

PrintLn(FormatDateTime('hh:nn am/pm', t));
PrintLn(FormatDateTime('hh:nn a/p', t));
PrintLn(FormatDateTime('hh:nn ampm', t));

PrintLn(FormatSettings.ShortDateFormat);
PrintLn(FormatSettings.ShortTimeFormat);
PrintLn(FormatSettings.LongDateFormat);
PrintLn(FormatSettings.LongTimeFormat);
PrintLn(FormatSettings.TimeAMString);
PrintLn(FormatSettings.TimePMString);
PrintLn(FormatSettings.Zone);
