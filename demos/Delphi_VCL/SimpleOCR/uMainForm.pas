unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  uTesseractBaseAPI, Vcl.ComCtrls, uTesseractOCR;

type
  TMainForm = class(TForm)
    OpenDialog1: TOpenDialog;
    OpenBtn: TButton;
    ButtonPnl: TPanel;
    MainPnl: TPanel;
    Splitter1: TSplitter;
    Image1: TImage;
    RecognizeBtn: TButton;
    TesseractOCR1: TTesseractOCR;
    OpenSampleBtn: TButton;
    ModeCb: TComboBox;
    StatusBar1: TStatusBar;
    Label1: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure RecognizeBtnClick(Sender: TObject);
    procedure TesseractOCR1Progress(Sender: TObject; progress, left, right, top,
      bottom: Integer);
    procedure OpenSampleBtnClick(Sender: TObject);
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

{$R *.dfm}

uses
  uLeptonicaLoader, uTesseractLoader, uLeptonicaPix, uTesseractTypes,
  uTesseractResultIterator, uTesseractMiscFunctions;

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

procedure TMainForm.TesseractOCR1Progress(Sender: TObject; progress, left,
  right, top, bottom: Integer);
begin
  StatusBar1.Panels[0].Text := inttostr(progress) + ' %';
end;

end.
