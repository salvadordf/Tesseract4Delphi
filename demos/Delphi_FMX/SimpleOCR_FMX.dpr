program SimpleOCR_FMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit3 in 'Unit3.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
