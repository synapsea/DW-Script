type
   TChainItem = class (TExposedClass)
      Next : TChainItem;
      Prev : TChainItem;
   end;

var i1, i2, i3 : TChainItem;

i1:=TChainItem.Create;
i2:=TChainItem.Create;
i3:=TChainItem.Create;

i1.Next:=i2;
i1.Prev:=i3;
i2.Next:=i3;
i2.Prev:=i1;
i3.Next:=i1;
i3.Prev:=i2;

