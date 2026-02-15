unit uMainForm;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, ExtCtrls, StdCtrls, ComCtrls, ActiveX,
  uTesseractBaseAPI, uTesseractOCR;

type

  { TMainForm }

  TMainForm = class(TForm)
    ScanBtn: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    ModeCb: TComboBox;
    Label1: TLabel;
    OpenBtn: TButton;
    OpenDialog1: TOpenDialog;
    ButtonPnl: TPanel;
    MainPnl: TPanel;
    OpenSampleBtn: TButton;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    RecognizeBtn: TButton;
    Splitter1: TSplitter;
    Image1: TImage;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TesseractOCR1: TTesseractOCR;
    procedure FormCreate(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure OpenSampleBtnClick(Sender: TObject);
    procedure RecognizeBtnClick(Sender: TObject);
    procedure ScanBtnClick(Sender: TObject);
    procedure TesseractOCR1Progress(Sender: TObject; progress, left_, right_, top_, bottom_: Integer);
  private
    { Private declarations }
    procedure OpenImage(const aFileName : string);
    procedure AnalyzeLayout;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  uLeptonicaLoader, uTesseractLoader, uLeptonicaPix, uTesseractTypes,
  uTesseractResultIterator, uTesseractMiscFunctions, WIA_TLB;

procedure TMainForm.FormCreate(Sender: TObject);
begin                                
  ModeCb.ItemIndex := Ord(PSM_AUTO_OSD);  
  PageControl1.ActivePageIndex := 0;

  if not(TesseractOCR1.Initialize('org.sw.demo.danbloomberg.leptonica-1.86.0.dll',
                                  'google.tesseract.libtesseract-main.dll',
                                  '..\assets\tessdata\',
                                  'eng')) then
    begin
      Memo1.Lines.Add('There was an issue initializing Tesseract.');
      ButtonPnl.Enabled := False;
    end;
end;

procedure TMainForm.OpenImage(const aFileName : string);
var
  TempImage : TBitmap;
begin
  if FileExists(aFileName) then
    begin
      TempImage := TBitmap.Create;
      TempImage.LoadFromFile(aFileName);
      Image1.Picture.Assign(TempImage);
      TempImage.Free;

      if not(TesseractOCR1.BaseAPI.SetImage(aFileName)) then
        begin
          Memo1.Lines.Clear;
          Memo1.Lines.Add('There was an issue loading the image.');
        end;
    end;
end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    OpenImage(OpenDialog1.FileName);
end;

procedure TMainForm.OpenSampleBtnClick(Sender: TObject);
begin
  OpenImage('..\assets\samples\eng-text.bmp');
end;

procedure TMainForm.RecognizeBtnClick(Sender: TObject);      
var
  TempTicks : cardinal;
begin
  if not(TesseractOCR1.Initialized) then exit;

  ButtonPnl.Enabled := False;
  StatusBar1.Panels[0].Text := 'Recognizing text...';
  Refresh;

  TesseractOCR1.BaseAPI.PageSegMode := TessPageSegMode(ModeCb.ItemIndex);      

  TempTicks := GetTickCount;

  if TesseractOCR1.Recognize then
    begin                  
      StatusBar1.Panels[1].Text := FloatToStrF((GetTickCount - TempTicks) / 1000, ffFixed, 18, 2) + ' seconds';
      Memo1.Lines.SetText(PChar(TesseractOCR1.BaseAPI.GetText));
      AnalyzeLayout;
    end
   else
    begin
      Memo2.Lines.Clear;
      Memo1.Lines.Clear;
      Memo1.Lines.Add('There was an issue recognizing the text.');
    end;

  StatusBar1.Panels[0].Text := 'OCR completed';
  PageControl1.ActivePageIndex := 0;
  ButtonPnl.Enabled := True;
end;

procedure TMainForm.ScanBtnClick(Sender: TObject);
const
  // Read this for other formats:
  // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/wiaaut/-wiaaut-consts-formatid
  wiaFormatBMP = '{B96B3CAB-0728-11D3-9D7B-0000F81EF32E}';
var
  TempDialog : ICommonDialog;
  TempImage  : IImageFile;
  TempVector : IVector;
  TempStream : TMemoryStream;
  TempBuffer : TBytes;
  TempBitmap : TBitmap;
begin
  // This code shows a very simple way to scan an image using WIA.
  // For a more advanced way to scan images check these repositories:
  // https://github.com/maxm74/WIAPascal
  // https://github.com/maxm74/DelphiTwain

  // Read this for more information about the CommonDialog.ShowAcquireImage method:
  // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/wiaaut/-wiaaut-icommondialog-showacquireimage
  TempDialog := nil;
  TempVector := nil;
  TempImage  := nil;
  TempStream := nil;
  TempBuffer := nil;
  TempBitmap := nil;

  try
    CoInitialize(nil);

    TempDialog := CoCommonDialog.Create;

    if (TempDialog <> nil) then
      begin
        TempImage := TempDialog.ShowAcquireImage(UnspecifiedDeviceType,
                                                 UnspecifiedIntent,
                                                 MaximizeQuality,
                                                 wiaFormatBMP,
                                                 True, True, False);

        if assigned(TempImage) and assigned(TempImage.FileData) then
          begin
            TempVector := TempImage.FileData;

            TempBuffer := TBytes(TempVector.Get_BinaryData);
            TempStream := TMemoryStream.Create;
            TempStream.Write(TempBuffer[0], TempVector.Count);

            TempBitmap := TBitmap.Create;
            TempStream.Seek(0, soBeginning);
            TempBitmap.LoadFromStream(TempStream);

            Image1.Picture.Assign(TempBitmap);

            if not(TesseractOCR1.BaseAPI.SetImage(TempStream)) then
              begin
                Memo1.Lines.Clear;
                Memo1.Lines.Add('There was an issue loading the image.');
              end;
          end;
      end;
  finally
    TempDialog := nil;
    TempImage  := nil;
    TempVector := nil;

    if (TempStream <> nil) then FreeAndNil(TempStream);
    if (TempBitmap <> nil) then FreeAndNil(TempBitmap);

    CoUninitialize;
  end;
end;

procedure TMainForm.AnalyzeLayout;
var
  TempResultIterator : TTesseractResultIterator;
  TempBoundingBox : TRect;
  TempText : string;
  TempConf : single;
begin
  TempResultIterator := TesseractOCR1.BaseAPI.Iterator;

  if assigned(TempResultIterator) then
    try
      Memo2.Lines.Clear;
      TempResultIterator.Begin_;

      repeat
        TempText := TempResultIterator.GetText(RIL_WORD);
        TempConf := TempResultIterator.Confidence(RIL_WORD);
        TempResultIterator.BoundingBox(RIL_WORD, TempBoundingBox);

        Memo2.Lines.Add('Word:' + quotedstr(TempText) + ', ' +
                        'Confidence:' + FloatToStrF(TempConf, ffFixed, 18, 2) + '%, ' +
                        'Box:' + RectToStr(TempBoundingBox));

      until not(TempResultIterator.Next(RIL_WORD));

    finally
      FreeAndNil(TempResultIterator);
    end;
end;

procedure TMainForm.TesseractOCR1Progress(Sender: TObject; progress, left_, right_, top_, bottom_: Integer);
begin
  StatusBar1.Panels[0].Text := inttostr(progress) + ' %';
end;

end.
