unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation, FMX.TabControl, FMX.ListBox, FMX.Media,
  uOCRWorkerThread;

type
  TMainForm = class(TForm, IMessageReceiverForm)
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
    StatusBar1: TStatusBar;
    StatusLbl: TLabel;
    CopyVideoFrameBtn: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);

    procedure OpenSampleBtnClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure RecognizeBtnClick(Sender: TObject);
    procedure CopyVideoFrameBtnClick(Sender: TObject);

  protected
    FVideoCap : TVideoCaptureDevice;
    FBitmap   : TBitmap;
    FThread   : TOCRWorkerThread;
    FMsgID    : integer;

    function  GetNextMsgID : integer;
    procedure OpenImage(const aFileName: string);
    procedure SampleBufferSync;

    procedure EnqueueThreadMessage(aMsg, aPageSegMode : integer); overload;
    procedure EnqueueThreadMessage(aMsg : integer; const aStream : TMemoryStream); overload;
    procedure EnqueueThreadMessage(aMsg : integer); overload;
    procedure EnqueueThreadMessage(aMsg : integer; const aLeptonicaLib, aTesseractLib, aDatapath, aLanguage : string); overload;

    procedure VideoCap_OnSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
    procedure HandleSetImageResult(aMessageID: integer; aResult : boolean);
    procedure HandleRecognizeResult(aMessageID: integer; const aText: string; aResult : boolean);
    procedure HandleInitializationResult(aResult : boolean);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  uLeptonicaLoader, uTesseractLoader, uLeptonicaPix, uTesseractTypes,
  uTesseractResultIterator, uTesseractMiscFunctions;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if assigned(FVideoCap) then
    FVideoCap.StopCapture;

  FBitmap.Free;

  FThread.Terminate;
  EnqueueThreadMessage(OCRTHREADMSG_QUIT);
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ModeCb.ItemIndex := Ord(PSM_AUTO_OSD);

  FThread     := TOCRWorkerThread.Create(self);
  FThread.Start;

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
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if assigned(FVideoCap) then
    begin
      CopyVideoFrameBtn.Enabled := True;
      FVideoCap.StartCapture;
    end;

  EnqueueThreadMessage(OCRTHREADMSG_INITIALIZE,
                       'org.sw.demo.danbloomberg.leptonica-1.86.0.dll',
                       'google.tesseract.libtesseract-main.dll',
                       '..\assets\tessdata\',
                       'eng');
end;

procedure TMainForm.EnqueueThreadMessage(aMsg, aPageSegMode : integer);
var
  TempMessage : TCustomMessage;
  TempInfo : TMsgInfo;
begin
  TempInfo.Msg          := aMsg;
  TempInfo.ID           := GetNextMsgID;
  TempInfo.PageSegMode  := aPageSegMode;
  TempInfo.Data         := nil;
  TempInfo.LeptonicaLib := '';
  TempInfo.TesseractLib := '';
  TempInfo.Datapath     := '';
  TempInfo.Language     := '';

  TempMessage := TCustomMessage.Create(TempInfo);

  FThread.EnqueueMessage(TempMessage);
end;

procedure TMainForm.EnqueueThreadMessage(aMsg : integer; const aStream : TMemoryStream);
var
  TempMessage : TCustomMessage;
  TempInfo : TMsgInfo;
begin
  TempInfo.Msg          := aMsg;
  TempInfo.ID           := GetNextMsgID;
  TempInfo.PageSegMode  := 0;
  TempInfo.LeptonicaLib := '';
  TempInfo.TesseractLib := '';
  TempInfo.Datapath     := '';
  TempInfo.Language     := '';

  SetLength(TempInfo.Data, aStream.Size);
  aStream.Position := 0;
  aStream.ReadBuffer(TempInfo.Data, Length(TempInfo.Data));

  TempMessage := TCustomMessage.Create(TempInfo);

  FThread.EnqueueMessage(TempMessage);
end;

procedure TMainForm.EnqueueThreadMessage(aMsg : integer);
var
  TempMessage : TCustomMessage;
  TempInfo : TMsgInfo;
begin
  TempInfo.Msg          := aMsg;
  TempInfo.ID           := GetNextMsgID;
  TempInfo.PageSegMode  := 0;
  TempInfo.Data         := nil;
  TempInfo.LeptonicaLib := '';
  TempInfo.TesseractLib := '';
  TempInfo.Datapath     := '';
  TempInfo.Language     := '';

  TempMessage := TCustomMessage.Create(TempInfo);

  FThread.EnqueueMessage(TempMessage);
end;

procedure TMainForm.EnqueueThreadMessage(aMsg : integer; const aLeptonicaLib, aTesseractLib, aDatapath, aLanguage : string);
var
  TempMessage : TCustomMessage;
  TempInfo : TMsgInfo;
begin
  TempInfo.Msg          := aMsg;
  TempInfo.ID           := GetNextMsgID;
  TempInfo.PageSegMode  := 0;
  TempInfo.Data         := nil;
  TempInfo.LeptonicaLib := aLeptonicaLib;
  TempInfo.TesseractLib := aTesseractLib;
  TempInfo.Datapath     := aDatapath;
  TempInfo.Language     := aLanguage;

  TempMessage := TCustomMessage.Create(TempInfo);

  FThread.EnqueueMessage(TempMessage);
end;

procedure TMainForm.VideoCap_OnSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
begin
  TThread.Synchronize(TThread.CurrentThread, SampleBufferSync);
end;

procedure TMainForm.SampleBufferSync;
begin
  FVideoCap.SampleBufferToBitmap(FBitmap, true);
end;

function TMainForm.GetNextMsgID : integer;
begin
  if (FMsgID < pred(high(integer))) then
    inc(FMsgID)
   else
    FMsgID := 1;

  Result := FMsgID;
end;

procedure TMainForm.OpenImage(const aFileName: string);
var
  TempImage : TBitmap;
  TempStream : TMemoryStream;
begin
  TempImage := nil;

  if FileExists(aFileName) then
    try
      TempImage := TBitmap.Create;
      TempImage.LoadFromFile(aFileName);

      if not(TempImage.IsEmpty) then
        begin
          TempStream := TMemoryStream.Create;

          Image1.Bitmap.Assign(TempImage);
          TempImage.SaveToStream(TempStream);

          EnqueueThreadMessage(OCRTHREADMSG_SETIMAGE, TempStream);
        end;
    finally
      if assigned(TempImage) then
        TempImage.Free;
    end;
end;

procedure TMainForm.CopyVideoFrameBtnClick(Sender: TObject);
var
  TempStream : TMemoryStream;
begin
  if assigned(FVideoCap) and not(FBitmap.IsEmpty) then
    begin
      Image1.Bitmap.Assign(FBitmap);

      TempStream := TMemoryStream.Create;
      FBitmap.SaveToStream(TempStream);

      EnqueueThreadMessage(OCRTHREADMSG_SETIMAGE, TempStream);
    end;
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
  StatusLbl.Text   := 'Recognizing text...';
  ToolBar1.Enabled := False;

  EnqueueThreadMessage(OCRTHREADMSG_RECOGNIZE, ModeCb.ItemIndex);
end;

procedure TMainForm.HandleSetImageResult(aMessageID: integer; aResult : boolean);
begin
  if aResult then
    StatusLbl.Text := 'Image set'
   else
    StatusLbl.Text := 'There was an issue setting the image.';

  ToolBar1.Enabled := True;
end;

procedure TMainForm.HandleRecognizeResult(aMessageID: integer; const aText: string; aResult : boolean);
begin
  if aResult then
    begin
      Memo1.Lines.SetText(PChar(aText));
      StatusLbl.Text := 'OCR completed';
    end
   else
    begin
      Memo1.Lines.Clear;
      StatusLbl.Text := 'There was an issue recognizing the text.';
    end;

  ToolBar1.Enabled := True;
end;

procedure TMainForm.HandleInitializationResult(aResult : boolean);
begin
  if aResult then
    ToolBar1.Enabled := True
   else
    begin
      StatusLbl.Text := 'There was an issue initializing Tesseract.';
      ToolBar1.Enabled := False;
    end;
end;

end.

