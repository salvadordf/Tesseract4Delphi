object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Simple OCR'
  ClientHeight = 571
  ClientWidth = 981
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object ButtonPnl: TPanel
    Left = 0
    Top = 0
    Width = 981
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Panel1: TPanel
      Left = 508
      Top = 0
      Width = 473
      Height = 41
      Align = alClient
      BevelOuter = bvNone
      Padding.Left = 10
      Padding.Top = 10
      Padding.Right = 10
      Padding.Bottom = 10
      TabOrder = 0
      ExplicitLeft = 382
      ExplicitWidth = 599
      object Label1: TLabel
        Left = 10
        Top = 10
        Width = 39
        Height = 21
        Align = alLeft
        AutoSize = False
        Caption = 'Mode'
        Layout = tlCenter
      end
      object ModeCb: TComboBox
        Left = 49
        Top = 10
        Width = 414
        Height = 23
        Align = alClient
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'Orientation and script detection only'
        Items.Strings = (
          'Orientation and script detection only'
          
            'Automatic page segmentation with orientation and script detectio' +
            'n'
          'Automatic page segmentation, but no OSD, or OCR'
          'Fully automatic page segmentation, but no OSD'
          'Assume a single column of text of variable sizes'
          'Assume a single uniform block of vertically aligned text'
          'Assume a single uniform block of text'
          'Treat the image as a single text line'
          'Treat the image as a single word'
          'Treat the image as a single word in a circle'
          'Treat the image as a single character'
          'Find as much text as possible in no particular order'
          'Sparse text with orientation and script det.'
          'Treat the image as a single text line, Tesseract-specific')
        ExplicitWidth = 540
      end
    end
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 508
      Height = 41
      Align = alLeft
      BevelOuter = bvNone
      Padding.Left = 5
      Padding.Top = 5
      Padding.Right = 5
      Padding.Bottom = 5
      TabOrder = 1
      object OpenBtn: TButton
        Left = 131
        Top = 5
        Width = 120
        Height = 31
        Caption = 'Open image...'
        TabOrder = 0
        OnClick = OpenBtnClick
      end
      object OpenSampleBtn: TButton
        Left = 5
        Top = 5
        Width = 120
        Height = 31
        Align = alLeft
        Caption = 'Open sample'
        TabOrder = 1
        OnClick = OpenSampleBtnClick
        ExplicitTop = 4
      end
      object RecognizeBtn: TButton
        Left = 383
        Top = 5
        Width = 120
        Height = 31
        Align = alRight
        Caption = 'Recognize'
        TabOrder = 2
        OnClick = RecognizeBtnClick
        ExplicitLeft = 387
        ExplicitTop = 4
      end
      object ScanBtn: TButton
        Left = 257
        Top = 5
        Width = 120
        Height = 31
        Caption = 'Scan image...'
        TabOrder = 3
        OnClick = ScanBtnClick
      end
    end
  end
  object MainPnl: TPanel
    Left = 0
    Top = 41
    Width = 981
    Height = 530
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 0
      Top = 315
      Width = 981
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 0
      ExplicitWidth = 318
    end
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 981
      Height = 315
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
      ExplicitTop = 1
    end
    object StatusBar1: TStatusBar
      Left = 0
      Top = 511
      Width = 981
      Height = 19
      Panels = <
        item
          Width = 150
        end
        item
          Width = 500
        end>
    end
    object PageControl1: TPageControl
      Left = 0
      Top = 318
      Width = 981
      Height = 193
      ActivePage = TabSheet2
      Align = alBottom
      TabOrder = 1
      object TabSheet1: TTabSheet
        Caption = 'Text result'
        object Memo1: TMemo
          Left = 0
          Top = 0
          Width = 973
          Height = 163
          Align = alClient
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Analysis'
        ImageIndex = 1
        object Memo2: TMemo
          Left = 0
          Top = 0
          Width = 973
          Height = 163
          Align = alClient
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Bitmap files (*.bmp)|*.BMP'
    InitialDir = '..\assets\samples'
    Left = 144
    Top = 56
  end
  object TesseractOCR1: TTesseractOCR
    OnProgress = TesseractOCR1Progress
    Left = 320
    Top = 57
  end
end
