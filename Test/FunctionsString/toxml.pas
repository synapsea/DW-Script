var s := '<script>alert("xss")</script>';

PrintLn(s.ToXML);