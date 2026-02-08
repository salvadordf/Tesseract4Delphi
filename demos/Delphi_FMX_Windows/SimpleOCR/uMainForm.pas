unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation, uTesseractBaseAPI, uTesseractOCR, FMX.TabControl,
  FMX.ListBox, FMX.Media;

type
  TMainForm = class(TForm)
    ToolBar1: TToolBar;
    OpenSampleBtn: TButton;
    OpenBtn: TButton;
    RecognizeBtn: TButton;
    Layout1: TLayout;
    Image1: TImage;
    Memo1: TMemo;
    Splitter1: TSplitter;
    OpenDialog1: TOpenDialog;
    Layout3: TLayout;
    Label1: TLabel;
    ModeCb: TComboBox;
    TabControl1: TTabControl;
    TextTabItem: TTabItem;
    AnalysisTabItem: TTabItem;
    Memo2: TMemo;
    StatusBar1: TStatusBar;
    StatusLbl: TLabel;
    TesseractOCR1: TTesseractOCR;
    CopyVideoFrameBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure OpenSampleBtnClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure RecognizeBtnClick(Sender: TObject);
    procedure TesseractOCR1Progress(Sender: TObject; progress, left, right, top, bottom: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure CopyVideoFrameBtnClick(Sender: TObject);

  protected
    FVideoCap : TVideoCaptureDevice;
    FBitmap : TBitmap;
    procedure OpenImage(const aFileName: string);
    procedure AnalyzeLayout;
    procedure SampleBufferSync;
    procedure VideoCap_OnSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  FMX.Surfaces, uLeptonicaLoader, uTesseractLoader, uLeptonicaPix, uTesseractTypes,
  uTesseractResultIterator, uTesseractMiscFunctions;

procedure TMainForm.CopyVideoFrameBtnClick(Sender: TObject);
var
  TempStream : TMemoryStream;
begin
  if assigned(FVideoCap) and not(FBitmap.IsEmpty) then
    begin
      Image1.Bitmap.Assign(FBitmap);

      TempStream := TMemoryStream.Create;
      FBitmap.SaveToStream(TempStream);
      TesseractOCR1.BaseAPI.SetImage(TempStream);
      TempStream.Free;
    end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if assigned(FVideoCap) then
    FVideoCap.StopCapture;

  FBitmap.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ModeCb.ItemIndex := Ord(PSM_AUTO_OSD);

  FBitmap := TBitmap.Create;

  if assigned(TCaptureDeviceManager.Current) and (TCaptureDeviceManager.Current.Count > 0) then
    begin
      FVideoCap := TCaptureDeviceManager.Current.DefaultVideoCaptureDevice;

      if assigned(FVideoCap) and (FVideoCap.Name <> 'OBS Virtual Camera') then
        begin
          FVideoCap.OnSampleBufferReady := VideoCap_OnSampleBufferReady;
          FVideoCap.Quality             := TVideoCaptureQuality.PhotoQuality;
        end
       else
        FVideoCap := nil;
    end
   else
    FVideoCap := nil;

  if not(TesseractOCR1.Initialize('org.sw.demo.danbloomberg.leptonica-1.86.0.dll',
                                  'google.tesseract.libtesseract-main.dll',
                                  '..\assets\tessdata\',
                                  'eng')) then
    begin
      Memo1.Lines.Add('There was an issue initializing Tesseract.');
      ToolBar1.Enabled := False;
    end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if assigned(FVideoCap) then
    begin
      CopyVideoFrameBtn.Enabled := True;
      FVideoCap.StartCapture;
    end;
end;

procedure TMainForm.VideoCap_OnSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
begin
  TThread.Synchronize(TThread.CurrentThread, SampleBufferSync);
end;

procedure TMainForm.SampleBufferSync;
begin
  FVideoCap.SampleBufferToBitmap(FBitmap, true);
end;

procedure TMainForm.OpenImage(const aFileName: string);
var
  TempImage : TBitmap;
begin
  if FileExists(aFileName) then
    begin
      TempImage := TBitmap.Create;
      TempImage.LoadFromFile(aFileName);
      Image1.Bitmap.Assign(TempImage);
      TempImage.Free;

      TesseractOCR1.BaseAPI.SetImage(aFileName);
    end;
end;

procedure TMainForm.TesseractOCR1Progress(Sender: TObject; progress, left, right, top, bottom: Integer);
begin
  StatusLbl.Text := inttostr(progress) + ' %';
end;

procedure TMainForm.OpenSampleBtnClick(Sender: TObject);
begin
  OpenImage('..\assets\samples\eng-text.bmp');
end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    OpenImage(OpenDialog1.FileName);
end;

procedure TMainForm.RecognizeBtnClick(Sender: TObject);
begin
  if not(TesseractOCR1.Initialized) then exit;

  StatusLbl.Text := 'Recognizing text...';
  StatusLbl.Repaint;

  TesseractOCR1.BaseAPI.PageSegMode := TessPageSegMode(ModeCb.ItemIndex);

  if TesseractOCR1.Recognize then
    begin
      Memo1.Lines.SetText(PChar(TesseractOCR1.BaseAPI.GetText));
      AnalyzeLayout;
    end
   else
    begin
      Memo2.Lines.Clear;
      Memo1.Lines.Clear;
      Memo1.Lines.Add('There was an issue recognizing the text.');
    end;

  StatusLbl.Text := 'OCR completed';

  TabControl1.ActiveTab := TextTabItem;
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

end.

