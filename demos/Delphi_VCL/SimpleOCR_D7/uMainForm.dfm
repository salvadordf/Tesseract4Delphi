object MainForm: TMainForm
  Left = 374
  Top = 189
  Width = 1093
  Height = 643
  Caption = 'Simple OCR'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object ButtonPnl: TPanel
    Left = 0
    Top = 0
    Width = 1077
    Height = 23
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 379
      Height = 23
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object RecognizeBtn: TButton
        Left = 252
        Top = 0
        Width = 120
        Height = 23
        Caption = 'Recognize'
        TabOrder = 2
        OnClick = RecognizeBtnClick
      end
      object OpenBtn: TButton
        Left = 126
        Top = 0
        Width = 120
        Height = 23
        Caption = 'Open image...'
        TabOrder = 1
        OnClick = OpenBtnClick
      end
      object OpenSampleBtn: TButton
        Left = 1
        Top = 0
        Width = 120
        Height = 23
        Caption = 'Open sample'
        TabOrder = 0
        OnClick = OpenSampleBtnClick
      end
    end
    object Panel2: TPanel
      Left = 379
      Top = 0
      Width = 698
      Height = 23
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        698
        23)
      object Label1: TLabel
        Left = 0
        Top = 0
        Width = 49
        Height = 23
        Align = alLeft
        Alignment = taCenter
        AutoSize = False
        Caption = 'Mode'
        Layout = tlCenter
      end
      object ModeCb: TComboBox
        Left = 56
        Top = 0
        Width = 636
        Height = 23
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight, akBottom]
        ItemHeight = 15
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
      end
    end
  end
  object MainPnl: TPanel
    Left = 0
    Top = 23
    Width = 1077
    Height = 562
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 0
      Top = 366
      Width = 1077
      Height = 3
      Cursor = crVSplit
      Align = alBottom
    end
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 1077
      Height = 366
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
    end
    object PageControl1: TPageControl
      Left = 0
      Top = 369
      Width = 1077
      Height = 193
      ActivePage = TabSheet1
      Align = alBottom
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Text result'
        object Memo1: TMemo
          Left = 0
          Top = 0
          Width = 1069
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
          Width = 1069
          Height = 163
          Align = alClient
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 585
    Width = 1077
    Height = 19
    Panels = <
      item
        Width = 500
      end>
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
