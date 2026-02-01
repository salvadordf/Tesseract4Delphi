unit uTesseractConstants;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  System.Classes;
  {$ELSE}
  Classes;
  {$ENDIF}

const
  {$I uTesseractVersion.inc}

  {$IFDEF DELPHI16_UP}
  {$IF NOT DECLARED(pidWin32)}
  pidWin32 = $00000001;
  {$IFEND}
  {$IF NOT DECLARED(pidWin64)}
  pidWin64 = $00000002;
  {$IFEND}
  {$IF NOT DECLARED(pfidWindows)}
  pfidWindows = pidWin32 or pidWin64;
  {$IFEND}
  {$ENDIF}

implementation

end.
