unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation, uTesseractBaseAPI, uTesseractOCR;

type
  TForm2 = class(TForm)
    ToolBar1: TToolBar;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Layout1: TLayout;
    Image1: TImage;
    Layout2: TLayout;
    Memo1: TMemo;
    Splitter1: TSplitter;
    OpenDialog1: TOpenDialog;
    ProgressBar1: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    TesseractOCR1: TTesseractOCR;
    procedure OpenImage(const aFileName: string);
    procedure TesseractOCR1Progress(Sender: TObject; progress, left, right, top, bottom: Integer);
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

uses
  FMX.Surfaces, uLeptonicaLoader, uTesseractLoader, uLeptonicaPix, uTesseractTypes;

procedure TForm2.OpenImage(const aFileName: string);
var
  TempImage: TBitmap;
  Stream: TMemoryStream;
  Surf: TBitmapSurface;
begin
  if FileExists(aFileName) then
  begin
    TempImage := TBitmap.Create;
    TempImage.LoadFromFile(aFileName);
    TMonitor.Enter(Self);
    try
      Surf := TBitmapSurface.Create;
      Stream := TMemoryStream.Create;
      try
        Surf.Assign(TempImage);
        if not TBitmapCodecManager.SaveToStream(Stream, Surf, '.bmp') then
          raise EBitmapSavingFailed.Create('Wrong image');
        Image1.Bitmap := TempImage;
        Stream.Position := 0;
        TesseractOCR1.BaseAPI.SetImage(Stream);
      finally
        Surf.Free;
        Stream.Free;
      end;
    finally
      TMonitor.Exit(Self);
    end;
    TempImage.Free;

  end;
end;

procedure TForm2.TesseractOCR1Progress(Sender: TObject; progress, left, right, top, bottom: Integer);
begin
  if (progress in [0..99]) then
  begin
    ProgressBar1.Visible := True;
    ProgressBar1.Value := progress;
  end
  else
    ProgressBar1.Visible := False;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  OpenImage('..\assets\samples\eng-text.bmp');
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    OpenImage(OpenDialog1.FileName);
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
  if TesseractOCR1.Recognize then
    Memo1.Lines.SetText(PChar(TesseractOCR1.BaseAPI.GetText))
  else
    Memo1.Lines.Clear;

  ProgressBar1.Visible := False;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  TesseractOCR1 := TTesseractOCR.Create(Self);
  TesseractOCR1.OnProgress := TesseractOCR1Progress;
  if not (TesseractOCR1.Initialize('org.sw.demo.danbloomberg.leptonica-1.86.0.dll',
    'google.tesseract.libtesseract-main.dll',
    '..\assets\tessdata\',
    'eng+rus')) then
  begin
    Memo1.Lines.Add('There was an issue initializing Tesseract.');
    ToolBar1.Enabled := False;
    Exit;
  end;
  var Langs := TesseractOCR1.BaseAPI.GetLoadedLanguagesAsVector;
  Memo1.Lines.AddStrings(Langs);
  Langs.Free;
end;

end.

