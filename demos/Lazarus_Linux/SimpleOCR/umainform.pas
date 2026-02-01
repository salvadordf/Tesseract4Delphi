unit umainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, uTesseractOCR;

type

  { TMainForm }

  TMainForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Image1: TImage;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    ButtonPnl: TPanel;
    ProgressBar1: TProgressBar;
    Splitter1: TSplitter;
    TesseractOCR1: TTesseractOCR;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private      
    procedure OpenImage(const aFileName : string);
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}       

uses
  uLeptonicaLoader, uTesseractLoader;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not(TesseractOCR1.Initialize('libleptonica.so',
                                  'libtesseract.so',
                                  '../assets/tessdata/',
                                  'eng')) then
    begin
      Memo1.Lines.Add('There was an issue initializing Tesseract.');
      ButtonPnl.Enabled := False;
    end;
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    OpenImage(OpenDialog1.FileName);
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
  if TesseractOCR1.Recognize then
    Memo1.Lines.SetText(PChar(TesseractOCR1.BaseAPI.GetText))
   else
    Memo1.Lines.Clear;

  ProgressBar1.Visible := False;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  OpenImage('../assets/samples/eng-text.bmp');
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

      TesseractOCR1.BaseAPI.SetImage(aFileName);
    end;
end;

end.

