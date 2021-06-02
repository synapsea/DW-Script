object FrmBasic: TFrmBasic
  Left = 0
  Top = 0
  Caption = 'Live Scripting IDE'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object SplitterVertical: TSplitter
    Left = 0
    Top = 461
    Width = 1000
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  object SynEdit: TSynEdit
    Left = 0
    Top = 0
    Width = 1000
    Height = 461
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentBackground = False
    TabOrder = 0
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Highlighter = SynDWSSyn
    Lines.Strings = (
      '// simple '#39'Hello World'#39' example '
      'PrintLn('#39'Hello World'#39');'
      ''
      '// change width of entire IDE'
      'Self.Width := 800;'
      ''
      '// change background color if SynEdit'
      'Self.SynEdit.Color := $EFFFFF;')
    Options = [eoAutoIndent, eoDragDropEditing, eoEnhanceEndKey, eoGroupUndo, eoShowScrollHint, eoSmartTabDelete, eoSmartTabs, eoTabsToSpaces]
    SearchEngine = SynEditSearch
    OnChange = SynEditChange
    OnGutterPaint = SynEditGutterPaint
    FontSmoothing = fsmNone
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 581
    Width = 1000
    Height = 19
    Panels = <>
  end
  object PageControl: TPageControl
    Left = 0
    Top = 464
    Width = 1000
    Height = 117
    ActivePage = TabSheetCompiler
    Align = alBottom
    TabOrder = 2
    object TabSheetCompiler: TTabSheet
      Caption = '&Compiler'
      object ListBoxCompiler: TListBox
        Left = 0
        Top = 0
        Width = 992
        Height = 89
        Align = alClient
        ItemHeight = 13
        PopupMenu = PopupMenuMessages
        TabOrder = 0
      end
    end
    object TabSheetOutput: TTabSheet
      Caption = '&Output'
      ImageIndex = 1
      object ListBoxOutput: TListBox
        Left = 0
        Top = 0
        Width = 992
        Height = 89
        Align = alClient
        ItemHeight = 13
        PopupMenu = PopupMenuMessages
        TabOrder = 0
      end
    end
  end
  object ProposalImages: TImageList
    ColorDepth = cd32Bit
    DrawingStyle = dsTransparent
    Left = 448
    Top = 129
    Bitmap = {
      494C010107000900040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000002000000001002000000000000020
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000F4E8
      DFFD0000000000000000000000000000000000000000000000005D41596B8D4D
      63BCAC5A43EDB25F37F7B25F37F7B25F37F7B25E37F7B25E37F7B15E36F7B15E
      36F7B15D36F7AB5A3FEF8D4D62BD583E5563339DD2FF339DD2FF339DD2FF339D
      D2FF000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000F0E2DBFB9830
      02FDF4E8DFFD0000000000000000000000000000000000000000A25651DEE0CF
      D4F2F3E6DBFDF6EBDEFFF6EADEFFF6EADCFFF6EADCFFFAF3EBFFFAF3EBFFFAF2
      EAFFFCF7F3FFF8F2F0FDE1D4E1F0994F54D54092C2FFC4EBF7FFC6F4FBFFBBEF
      FAFF339DD2FF339DD2FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000F0E2DBFBB05D34FBD498
      57FD983002FDF4E8DFFD00000000000000000000000000000000B56841F5F3E8
      DDFEFDBF65FFFCBD64FFFBBE62FFFCBE61FFFCBE61FFFCBD5FFFFBBD60FFFBBC
      5EFFFCBE5DFFFCBC5FFFF9F5F4FDAE5C39F33B8EC1FF7CE1F6FF4BDBF6FF4BDB
      F6FFF0FCFEFF339DD2FF00000000000000000000000000000000000000000404
      0405000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000967A6BFD967A6BFDD49857FDFBC798FDE5AE
      78FDD49857FD983002FDF4E8DFFD000000000000000000000000B96E41F7F7ED
      E3FFFDC26BFFFFD8A0FFFFD79EFFFFD69BFFFFD798FFFFD696FFFFD695FFFFD5
      94FFFFD493FFFBBE62FFFBF7F4FFB36038F73889C1FF9FE6F7FF2FC9EFFF4BDB
      F6FFB0EEFAFF339DD2FF339DD2FF339DD2FF0000000000000000000000000000
      0000000000000000000000000000000000010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000967A6BFD00000000F0E2DBFBD09559FBFBC7
      98FDE5AE78FDD49857FD983002FD000000000000000000000000BD7043F7E092
      5DFFE08C49FFF7B453FFE2964CFFE2893EFFF6AD4DFFF7B34FFFF7B34FFFF7B2
      4EFFF7B24CFFF7B24CFFFCF9F5FFB7683CF7000000003888C0FF82E1F5FF2FC9
      EFFF4BDBF6FFB0EEFAFFF1FCFEFF339DD2FF0000000000000000000000010000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000967A6BFD0000000000000000F0E2DBFBD498
      57FDFBC798FDC56D42FDF4E8DFFD000000000000000011101112D37B3FFDE5A3
      62FFE19155FFFDE5D3FFE59D59FFE7A865FFE3975CFFF9DAC4FFFCE2CEFFFCE2
      CCFFFBE0C9FFFBE1C8FFFDFAF7FFB96D40F700000000000000003687BFFF85E2
      F7FF2FC9EFFF4BDBF6FFB0EEFAFF339DD2FF339DD2FF339DD2FF0486C8FF2D6E
      AFE7624E7B99201C202100000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000D4E8
      F2FD000000000000000000000000967A6BFD000000000000000000000000F3D8
      DEFDD49857FDF4E8DFFD0000000000000000503B4E58D99357F7E8AA67FFE39B
      5AFFF9D8C3FFFDE7D6FFF9DBC3FFE5A05AFFE8AA67FFE39B53FFEEB694FFFCE2
      CDFFFBE1CBFFFBE1C9FFFBF7F2FFBD7144F70000000000000000000000003889
      C1FF89E2F7FF2FC9EFFF4BDBF6FF4BDBF6FF42D5F4FF3AD0F2FF34CCF0FF33CA
      EEFF29B9E5FF1C7BBCF33F324045000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000D4E8F2FD0D72
      9DFDD4E8F2FD0000000000000000967A6BFD0000000000000000F5E0F5FB8C2A
      8BFDF3D8DEFD000000000000000000000000D1925DF1ECB876FFE5A455FFF2D8
      C4FFFEE8D6FFFEE8D7FFFDE7D6FFF6D1B3FFE6A657FFE9B272FFE49D55FFFAE0
      C8FFFADFC7FFFADFC6FFFAF2EAFFBE7547F70000000000000000000000000000
      00003889C1FF89E2F7FF2FC9EFFF40D4F3FF3BD1F2FF39D0F2FF38CFF1FF36CE
      F1FF34CCF0FF33C9EEFF1F7EBCF3201C20210000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D4E8F2FD0D729DFD1BB0
      EAFD0D729DFDD4E8F2FD00000000967A6BFD00000000F5E0F5FBAE36ADFBD86A
      D7FD8C2A8BFDF9E6F9FD0000000000000000503B4E58DB9F5CF7EAB56EFFE8A6
      60FFFADBC5FFFEE8D8FFFBDDC5FFE9AB5EFFEAB56EFFE8A759FFEFBA93FFFAE0
      C7FFF9DDC3FFF8DCC2FFFAF4EDFFBE774AF70000000000000000000000000000
      0000000000001C92CDFF79DEF6FF41D5F4FF3FD4F3FF3ED2F3FF3CD1F2FF3AD0
      F2FF38CFF1FF37CEF1FF31BDE6FF624D79960000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000D8EEF6FF0B759EFF4CCBF1FF31C0
      EFFF2CBEEFFF095F81FF97806CFF967A6BFD967A6BFDD566D4FDF6A8F6FDF795
      F6FDD86AD7FD8C2A8BFDF9E6F9FD000000000000000011101112DA9548FDEBB6
      6FFFE8A75EFFFDE7D6FFECB262FFECBB73FFEAAC64FFF9DAC1FFFADFC7FFF8DC
      C2FFF6DABDFFF6D8BBFFFAF4EFFFBE784BF70000000000000000000000000000
      0000000000002870B3EA7ADFF6FF45D7F5FF43D6F4FF42D5F4FF40D4F3FF3ED3
      F3FF3CD2F2FF3BD0F2FF38CCEFFF306BADE40000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000011AAE1FF85E1F5FF68D7F4FF4DCB
      F1FF31C0F0FF1AB5EEFF095F81FFD4E8F2FD00000000F9E6F9FDCF5FCEFDF6A8
      F6FDF795F6FDD86AD7FD8C2A8BFD000000000000000000000000C0814EF7E9B1
      6BFFE8AE5CFFFCE6D4FFECB662FFECB266FFF9DEC4FFFAE0C8FFF8DCC2FFF5D6
      BBFFF3D4B5FFF1D2B3FFF8F4F0FFBC774BF70000000000000000000000000000
      0000000000000486C8FF84E1F7FF48D9F5FF47D8F5FF46D8F5FF22ACDDFF0486
      C8FF21ABDCFF3FD3F3FF46D3F3FF1080C0F90000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000D8EEF6FF11AAE1FF86E1F5FF69D6
      F3FF4DCBF2FF32C0F0FF19B5EDFF0B5C7DFDD4E8F2FD00000000F9E6F9FDCF5F
      CEFDF6A8F6FDCF5FCEFDF9E6F9FD000000000000000000000000BE8150F7F8EF
      E6FFFCE3CFFFFBE4D0FFFCE4CFFFFCE3CDFFFAE1CAFFF9DDC4FFF6D9BCFFF4E9
      DFFFF7F2ECFFFBF7F3FFF5EFE9FFBE7746FB0000000000000000000000000000
      0000050505062D6EAFE78DDFF4FF4BDBF6FF4ADAF6FF49DAF5FF078ACAFFB0EE
      FAFF078ACAFF43D6F4FF6DD8F2FF306BADE40000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D4E8F2FD13A7DDFD84DA
      F1FD69D6F3FF4DCBF2FF31C0EFFF1CAFE9FD0B5C7DFDD4E8F2FD00000000F9E6
      F9FDCF5FCEFDF9E6F9FD00000000000000000000000000000000BC7E50F6F9F5
      F1FFFCE3CDFFFBE3CEFFFBE3CDFFFBE2CBFFF9E0C8FFF8DCC2FFF5D6BAFFFDFB
      F8FFFCE6CDFFFAE5C9FFE2B684FF814F6AA60000000000000000000000000000
      00000000000061507F9F6ABBE1FF73E3F8FF4BDBF6FF4BDBF6FF26AFDEFF0486
      C8FF25AEDEFF67DFF7FF67BEE2FF624D79960000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000D4E8F2FD13A7
      DDFD86E1F4FF68D6F4FF4DCBF1FF1695C4FDD4E8F2FD00000000000000000000
      0000F9E6F9FD0000000000000000000000000000000000000000B07258EAF4ED
      ECFCFAE0C7FFFBE1C9FFFBE2C9FFFBE0C8FFF9DFC5FFF8DBC1FFF4D6B8FFFFFB
      F8FFF6D8B4FFE1B07AFFCD8765F6060606070000000000000000000000000000
      000000000000171517182672B6EDACDCF0FFA3ECFAFF6CE2F8FF4DDBF6FF6AE1
      F8FFA1EBFAFFAADCF1FF2A71B3EA141314150000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000D4E8
      F2FD11AAE1FF85E1F5FF1498C8FFD4E8F2FD0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000945969C3D6C2
      CDECF2EBE8FCF8F4EDFFF8F3EDFFF8F3EDFFF8F3EDFFF8F2ECFFF7F2ECFFF2E6
      D7FFE2B27AFFCB8766F506060607000000000000000000000000000000000000
      00000000000000000000423443482176B8F069BAE0FFB8E1F3FFE5F9FDFFBBE3
      F3FF69BAE0FF2A71B3EA3D313E42000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000D8EEF6FF11AAE1FFD8EEF6FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000563E53609059
      6BBBB67959EEBE8153F6C08453F7C08453F7C08553F7C08453F7BF8353F79F63
      63D4754A68910505050600000000000000000000000000000000000000000000
      00000000000000000000000000001A181A1B61507F9F2572B5ED0486C8FF2572
      B5ED624E7D9C1413141500000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000786F6FFD4D484AFD534C4CFD534C
      4CFD534C4CFD544E4CFD524D4BFD514C4AFD514C4BFD514C4AFD504B4AFD534B
      45FD000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000E8CCE8FD6E21
      6DFDE2C6E2FD0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CCE4E8FD2364
      6FFDC6DEE2FD000000000000000000000000D5C9C4FDFBF9FBFDF7F7FBFDF7F7
      FBFDFBF9F2FDFBF9F2FDFBF9F2FDFBF3E8FDFBEADDFDFBE4D1FDFBE4CEFD534B
      45FD000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E9D2E9FDA84DA7FD7C2D
      7BFD712471FDE7CBE7FD00000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D3E5E9FD4F9FA8FD2F72
      7DFD266972FDCBE3E7FD0000000000000000CEC2BDFDFBF9FBFDC0A9A1FDC0A9
      A1FDFBF5F5FDC0A9A1FDC0A9A1FDC0A9A1FDC0A9A1FDC0A9A1FDF9D8C7FD534B
      45FD00000000000000000000000000000000A4C7DAFB5C829AFB567796FB5070
      8FFB4A6889FB436382FB3D5C79FB385673FBAEB7C6FB00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000E4CBE4FDA84DA8FDC861C7FD7A2B
      7AFD953594FD772876FDECCFECFD000000000000000000000000000000000000
      000000000000000000000000000000000000CCE0E4FD4F9FA8FD62BBC8FD2D72
      7BFD378B97FD2A6D78FDD0E8ECFD00000000CEC2BDFDFBF9FBFDF7F7FBFDF7F7
      FBFDFBF8F8FDF9F4F4FDF7EEEBFDF7E8E2FDF6E3DAFDF4DCCEFDFBDCCCFD534B
      45FD0000000000000000000000000000000047AFD7FB80CFE7FB74C8E4FB6AC6
      E2FB62BFDFFB57BADDFB4DB4DAFB42AED8FB375472FB00000000000000000000
      00000000000000000000000000000000000000000000A8EAF3FDA8DCE1FDA8C8
      C8FDA9B5B1FDAAA49BFD00000000E0C4E0FDA84DA7FDCF65CEFDD068CFFD7B2D
      7AFD9E399EFD8D328CFD792A78FDF5F1F5FD00000000A8E8F3FDA8DAE1FDA8C6
      C8FDA9B3B1FDAAA49DFD00000000C4DCE0FD4F9FA8FD65C2CFFD68C3D0FD2F71
      7BFD3B96A1FD348490FD2C6F7AFDF1F3F5FDCFC3BEFDFBF9FBFDC0A9A1FDC0A9
      A1FDFBF9FAFDC0A9A1FDC0A9A1FDC0A9A1FDC0A9A1FDC0A9A1FDFBDFD2FD534B
      45FD000000000000000000000000000000004CB3DAFB8CD4E9FB83CFE7FBA186
      75FB977869FB937164FB58BADDFB4EB5DBFB3A5875FB00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000A84FA8FDCE64CDFDD169D1FDB96AB8FDDA95
      D9FD8E438DFD9C399BFD7A2B7AFDF6F4F6FD0000000000000000000000000000
      000000000000000000000000000051A0A8FD64C0CEFD69C6D1FD6BAFB9FD98D1
      DAFD458791FD3B929FFD2D727BFDF4F4F6FDCDC1BCFDFBF9FBFDF7F7FBFDF7F7
      FBFDFBF9FBFDFAF8F9FDFAF5F4FDF9F0EEFDF8EAE4FDF8EAE4FDFBE3D8FD534B
      45FD000000000000000000000000000000004EB5DBFB96DAECFB8DD5EAFB83D0
      E7FB77CAE5FB6DC7E2FB64C1E1FB5ABCDDFB3E5C78FB00000000000000000000
      000000000000000000000000000000000000A8EAF3FDA8DFE5FDA8CFD1FDA8BE
      BDFDA9AFA8FDAAA197FD00000000A74CA6FDCE67CDFDB869B7FDEBA2EAFDF79C
      F6FDEB9AEAFD964F95FD782B78FDF6F4F6FDA8E8F3FDA8DDE5FDA8CDD1FDA8BC
      BDFDA9ADA8FDAAA199FD000000004F9EA8FD68C1CEFD6AAEB8FDA5E1EBFD9FEB
      F7FD9DE0EBFD518F99FD2D7079FDF4F4F6FDCDC2BDFDFBF9FBFDF7F7FBFDF7F7
      FBFDFBF9FBFDFBF9FBFDFAF8F8FDACA8A8FD40566EFDDFD3CFFDFBE7DFFD534B
      45FD000000000000000000000000000000004EB5DBFB9ADFEEFB96DAECFBA285
      75FB98786AFB937164FB6EC7E3FB65C2E1FB41607CFB50708FFB4A6889FB4363
      82FB3D5C79FB385673FBAEB7C6FB000000000000000000000000000000000000
      0000000000000000000000000000A64DA5FDB869B7FDEBA2EAFDF798F6FDF795
      F6FDF796F6FDE395E2FD904B8FFDF8F6F8FD0000000000000000000000000000
      0000000000000000000000000000509DA8FD6AAEB8FDA5E1EBFD9BEBF7FD97EA
      F7FD99EAF7FD97D8E3FD4D8993FDF6F6F8FDCDC2BDFDFBF9FBFDDEE3E5FD5A6F
      83FDDBDEE1FDFBF9FBFDBEC4CAFD495B6CFD2DA6D2FD0A0D1AFD59565CFDA39A
      95FD0000000000000000A3B8A6FD1B6028FD4EB5DBFBA1E1EFFB9BDFEDFB96DB
      ECFB8FD7EAFB87D2E9FB7ACCE6FB70C8E3FB456484FB6AC6E2FB62BFDFFB57BA
      DDFB4DB4DAFB42AED8FB375472FB000000000000000000000000A8EAF3FDA8CF
      D1FDAAAEA8FDAA9689FD00000000CB85CBFDDEA9DEFDF7A8F6FDF795F6FDF392
      F2FBE28AE1FBC882C8FBECDAECFB000000000000000000000000A8E8F3FDA8CD
      D1FDAAACA8FDAA968BFD0000000087C3CBFDAAD8DEFDA8ECF7FD97EAF7FD96E4
      F3FB8ED4E2FB86C2C8FBDAE6ECFB00000000DF9D7AFFF1CAB7FF8FA4ACFF86D3
      E5FF485E6DFFA79289FF475E6DFF5EC1DEFF544A56FF1CD0FFFF122430FF0D04
      07FF001E2BFF4C5362FF567558FF158C2FFFC8E1EFFB4EB5DBFB4EB5DBFB4DB4
      DAFB47AFD6FB3FA7D0FB36A0CAFB3299C7FB65B6D1FBA18675FB977869FB9371
      64FB58BADDFB4EB5DBFB3A5875FB000000000000000000000000000000000000
      0000000000000000000000000000ECCEECFDCB85CBFDEAB8EAFDF7A8F6FDE48B
      E3FBC882C8FBEBD4EAFB00000000000000000000000000000000000000000000
      0000000000000000000000000000CEE7ECFD87C3CBFDB8E4EAFDA9ECF7FD90D6
      E4FB86C2C8FBD5E4EBFB0000000000000000DF9D7AFFFFC5A4FFE5C9B9FF8FA4
      ACFF83E1F6FF485E6DFF77CDE2FF4F5D64FF65EDFFFF3E3A4DFF2FB2DFFF1A99
      C8FF1293C4FF115F8EFF3D634EFF26973CFF0000000000000000000000000000
      000000000000000000004EB5DBFB96DAECFB8DD5EAFB83D0E7FB77CAE5FB6DC7
      E2FB64C1E1FB5ABCDDFB3E5C78FB000000000000000000000000000000000000
      000000000000000000000000000000000000EED5EEFDCB85CBFDDFA8DFFDC882
      C8FBEBD7EBFB0000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000D6EAEEFD87C3CBFDA8D8DFFD86C2
      C8FBD7E5EBFB000000000000000000000000DF9D7AFFDF9D7AFFDF9D7AFFDABA
      AAFF8FA4ACFF7CE3F9FF508495FF65EDFFFF2D374CFF66DBF6FF55D2F3FF3DC3
      EDFF2EBBEAFF0EA8ECFF4D908CFF2F9E3EFF0000000000000000000000000000
      000000000000000000004EB5DBFB9ADFEEFB96DAECFBA28575FB98786AFB9371
      64FB6EC7E3FB65C2E1FB41607CFB000000000000000000000000000000000000
      00000000000000000000000000000000000000000000EED5EEFDCB85CBFDE8D7
      E8FB000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D6EAEEFD87C3CBFDD8E3
      E8FB000000000000000000000000000000000000000000000000000000000000
      0000E7EBEDFF546880FF65EDFFFF5598AEFF6BEBFFFF6FE1F9FF67DDF7FF53CF
      F2FF48C7EDFF1FBAFAFF5CA2A6FF3EAC50FF0000000000000000000000000000
      000000000000000000004EB5DBFBA1E1EFFB9BDFEDFB96DBECFB8FD7EAFB87D2
      E9FB7ACCE6FB70C8E3FB456484FB000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000FAF5FAFD0000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000F6F8FAFD0000
      0000000000000000000000000000000000000000000000000000000000000000
      0000C2C8D0FFB0EBFAFF586A7CFF6BEBFFFF6BEBFFFF6BEBFFFF6FE2FAFF64D7
      F4FF51BDDCFF4E6F8BFF669C89FF85CC85FF0000000000000000000000000000
      00000000000000000000C8E1EFFB4EB5DBFB4EB5DBFB4DB4DAFB47AFD6FB3FA7
      D0FB36A0CAFB3299C7FBA4C7DAFB000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000A3ACB8FF95B8C4FFD4D9DDFF81A6B5FF8097A3FF8096A0FF778F99FF7085
      93FF596E80FFBFC8CDFF99B89CFFAEC1A6FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000200000000100010000000000000100000000000000000000
      000000000000000000000000FFFFFF00FFEFC00000000000FFC7C00000000000
      FF83C00000000000FE01C00000000000FE81C00000000000FEC1800000000000
      EEE3000000000000C6C700000000000082830000000000000001800000000000
      0081C000000000000041C000000000008023C00000000000C077C00000000000
      E0FFC00100000000F1FFC00300000000FFFFFFFFFFFFFFFFFFFFFFFF000FFFFF
      FFC7FFC7000FFFFFFF83FF83000F007FFF01FF01000F007F82008200000F007F
      FE00FE00000F007F02000200000F0001FE00FE00000C0001C201C20100000001
      FE03FE030000FC01FF07FF070000FC01FF8FFF8FF000FC01FFDFFFDFF000FC01
      FFFFFFFFF000FFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000
      000000000000}
  end
  object DelphiWebScript: TDelphiWebScript
    Config.CompilerOptions = [coOptimize, coSymbolDictionary, coContextMap, coAssertions]
    Left = 72
    Top = 16
  end
  object dwsRTTIConnector: TdwsRTTIConnector
    Script = DelphiWebScript
    StaticSymbols = False
    Left = 72
    Top = 72
  end
  object SynDWSSyn: TSynDWSSyn
    DefaultFilter = 'DWScript Files (*.dws;*.pas;*.inc)|*.dws;*.pas;*.inc'
    Options.AutoDetectEnabled = False
    Options.AutoDetectLineLimit = 0
    Options.Visible = False
    StringAttri.Foreground = clPurple
    Left = 264
    Top = 16
  end
  object SynMacroRecorder: TSynMacroRecorder
    Editor = SynEdit
    RecordShortCut = 24658
    PlaybackShortCut = 24656
    Left = 352
    Top = 16
  end
  object SynEditOptionsDialog: TSynEditOptionsDialog
    UseExtendedStrings = False
    Left = 264
    Top = 72
  end
  object SynEditSearch: TSynEditSearch
    Left = 352
    Top = 72
  end
  object SynCompletionProposal: TSynCompletionProposal
    Options = [scoLimitToMatchedText, scoTitleIsCentered, scoUseInsertList, scoEndCharCompletion, scoCompleteWithEnter]
    EndOfTokenChr = '()[]. '
    TriggerChars = '.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clBtnText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = [fsBold]
    Columns = <>
    ItemHeight = 19
    Images = ProposalImages
    Margin = 4
    OnExecute = SynCompletionProposalExecute
    OnPaintItem = SynCompletionProposalPaintItem
    OnShow = SynCompletionProposalShow
    ShortCut = 16416
    Editor = SynEdit
    Left = 448
    Top = 72
  end
  object MainMenu: TMainMenu
    Left = 176
    Top = 16
    object MnuFile: TMenuItem
      Caption = '&File'
      object MnuFileNew: TMenuItem
        Action = AcnFileNew
      end
      object MnuScriptOpen: TMenuItem
        Action = AcnFileOpen
      end
      object MnuEditSaveAs: TMenuItem
        Action = AcnFileSaveScriptAs
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object MnuScriptExit: TMenuItem
        Action = AcnFileExit
      end
    end
    object MnuEdit: TMenuItem
      Caption = '&Edit'
      object MnuEditCut: TMenuItem
        Action = AcnEditCut
      end
      object MnuEditCopy: TMenuItem
        Action = AcnEditCopy
      end
      object MnuEditPaste: TMenuItem
        Action = AcnEditPaste
      end
      object MnuEditDelete: TMenuItem
        Action = AcnEditDelete
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object MnuEditUndo: TMenuItem
        Action = AcnEditUndo
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object MnuSelectAll: TMenuItem
        Action = AcnEditSelectAll
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object MnuOptions: TMenuItem
        Action = AcnOptions
      end
    end
    object MnuSearch: TMenuItem
      Caption = '&Search'
      object MnuEditSearch: TMenuItem
        Action = AcnSearchFind
      end
    end
    object MnuScript: TMenuItem
      Caption = 'Script'
      object MnuScriptCompile: TMenuItem
        Action = AcnScriptCompile
      end
      object MnuScriptAutomaticallyCompile: TMenuItem
        Action = AcnAutoCompile
        AutoCheck = True
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object MnuScriptUseRTTI: TMenuItem
        Action = AcnUseRTTI
        AutoCheck = True
      end
    end
    object MnuCodeGen: TMenuItem
      Caption = '&CodeGen'
      object MnuCodeGenLLVM: TMenuItem
        Action = AcnCodeGenLLVM
      end
      object MnuCodeGenJS: TMenuItem
        Action = AcnCodeGenJS
      end
    end
  end
  object ActionList: TActionList
    Left = 176
    Top = 72
    object AcnEditCut: TEditCut
      Category = 'Edit'
      Caption = '&Cut'
      Hint = 'Cut|Cut selection to clipboard'
      ImageIndex = 0
      ShortCut = 16472
    end
    object AcnEditCopy: TEditCopy
      Category = 'Edit'
      Caption = '&Copy'
      Hint = 'Copy|Copy selection to clipboard'
      ImageIndex = 1
      ShortCut = 16451
    end
    object AcnEditPaste: TEditPaste
      Category = 'Edit'
      Caption = '&Paste'
      Hint = 'Paste|Paste content of clipboard'
      ImageIndex = 2
      ShortCut = 16470
    end
    object AcnEditSelectAll: TEditSelectAll
      Category = 'Edit'
      Caption = 'Select &all'
      Hint = 'Select all|Select entire document'
      ShortCut = 16449
    end
    object AcnEditDelete: TEditDelete
      Category = 'Edit'
      Caption = '&Delete'
      Hint = 'Delete|Delete selection'
      ImageIndex = 5
      ShortCut = 46
    end
    object AcnEditUndo: TEditUndo
      Category = 'Edit'
      Caption = '&Undo'
      Hint = 'Undo|Undo recent changes'
      ImageIndex = 3
      ShortCut = 16474
    end
    object AcnSearchFind: TSearchFind
      Category = 'Search'
      Caption = '&Search...'
      Hint = 'Search|Search for text'
      ImageIndex = 34
      ShortCut = 16454
    end
    object AcnFileNew: TAction
      Category = 'File'
      Caption = '&New'
      OnExecute = AcnFileNewExecute
    end
    object AcnFileOpen: TFileOpen
      Category = 'File'
      Caption = '&Open...'
      Dialog.DefaultExt = '.dws'
      Dialog.Filter = 'Delphi Web Script (*.dws)|*.dws'
      Dialog.Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
      Hint = 'Open|Open script'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = AcnFileOpenAccept
    end
    object AcnFileScriptSave: TAction
      Category = 'File'
      Caption = 'AcnFileScriptSave'
      ShortCut = 16467
      OnExecute = AcnFileScriptSaveExecute
    end
    object AcnFileSaveScriptAs: TFileSaveAs
      Category = 'File'
      Caption = 'Save &as...'
      Dialog.DefaultExt = '.dws'
      Dialog.Filter = 'Delphi Web Script (*.dws)|*.dws'
      Hint = 'Save as|Save active script'
      ImageIndex = 30
      OnAccept = AcnFileSaveScriptAsAccept
    end
    object AcnFileExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Close Application'
      ImageIndex = 43
    end
    object AcnOptions: TAction
      Category = 'Edit'
      Caption = '&Options'
      ShortCut = 121
      OnExecute = AcnOptionsExecute
    end
    object AcnAutoCompile: TAction
      Category = 'Script'
      AutoCheck = True
      Caption = 'A&utomatically Compile'
      Checked = True
      OnExecute = AcnAutoCompileExecute
    end
    object AcnScriptCompile: TAction
      Category = 'Script'
      Caption = '&Compile'
      ShortCut = 120
      OnExecute = AcnScriptCompileExecute
    end
    object AcnUseRTTI: TAction
      Category = 'Script'
      AutoCheck = True
      Caption = 'Use RTTI'
      Checked = True
      OnExecute = AcnUseRTTIExecute
    end
    object AcnCodeGenLLVM: TAction
      Category = 'CodeGen'
      Caption = '&LLVM'
      ShortCut = 116
      OnExecute = AcnCodeGenLLVMExecute
    end
    object AcnCodeGenJS: TAction
      Category = 'CodeGen'
      Caption = '&JS'
      OnExecute = AcnCodeGenJSExecute
    end
  end
  object PopupMenuOutput: TPopupMenu
    Left = 176
    Top = 128
    object MnuSaveOutputAs: TMenuItem
      Caption = 'Save &as...'
      Hint = 'Save as|Save current output'
      ImageIndex = 30
    end
  end
  object PopupMenuMessages: TPopupMenu
    Left = 72
    Top = 508
    object MnuSaveMessagesAs: TMenuItem
      Caption = 'Save &as...'
      Hint = 'Save as|Save current messages'
      ImageIndex = 30
      OnClick = MnuSaveMessagesAsClick
    end
  end
  object SynParameters: TSynCompletionProposal
    DefaultType = ctParams
    Options = [scoLimitToMatchedText, scoUsePrettyText, scoUseBuiltInTimer]
    ClBackground = clInfoBk
    Width = 262
    EndOfTokenChr = '()[]. '
    TriggerChars = '('
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clBtnText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = [fsBold]
    Columns = <>
    ItemHeight = 19
    Margin = 4
    OnExecute = SynParametersExecute
    ShortCut = 24608
    Editor = SynEdit
    Left = 448
    Top = 16
  end
  object dwsUnitExternal: TdwsUnit
    Script = DelphiWebScript
    Functions = <
      item
        Name = 'ExternalFunction'
      end
      item
        Name = 'SetPixel'
        Parameters = <
          item
            Name = 'x'
            DataType = 'Integer'
          end
          item
            Name = 'y'
            DataType = 'Integer'
          end
          item
            Name = 'Color'
            DataType = 'Integer'
          end>
      end>
    UnitName = 'ExternalUnit'
    StaticSymbols = False
    Left = 72
    Top = 128
  end
end
