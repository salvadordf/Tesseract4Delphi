program SimpleOCR;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  WIA_TLB in 'WIA_TLB.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
