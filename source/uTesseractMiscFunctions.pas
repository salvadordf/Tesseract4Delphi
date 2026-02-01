unit uTesseractMiscFunctions;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows, {$ENDIF}
    {$IFDEF FMX}FMX.Types, FMX.Platform,{$ENDIF} System.SysUtils,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows, {$ENDIF} SysUtils,
  {$ENDIF}
  uLeptonicaTypes;

/// <summary>
/// Retrieves the fully qualified path for the current module.
/// </summary>
/// <remarks>
/// <para><see href="https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulefilenamew">See the GetModuleFileNameW article.</see></para>
/// </remarks>
function  GetModulePath : string;
procedure OutputDebugMessage(const aMessage : string);
function  CustomExceptionHandler(const aFunctionName : string; const aException : exception) : boolean;
procedure ShowErrorMessageDlg(const aError : string);

function  TessUTF8ToString(aString: PUTF8Char; aDeleteText: Boolean = True): string;
function  StringToTessUTF8(const aString: string): AnsiString;

implementation

uses
  uTesseractLoader, uTesseractLibFunctions;

function GetModulePath : string;
{$IFDEF MACOSX}
const
  MAC_APP_POSTFIX = '.app/';
  MAC_APP_SUBPATH = 'Contents/MacOS/';
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(GetModuleName(HINSTANCE{$IFDEF FPC}(){$ENDIF})));
  {$ENDIF}

  {$IFDEF LINUX}
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
  {$ENDIF}

  {$IFDEF MACOSX}
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

  {$IFDEF FPC}
  if copy(Result, Length(Result) + 1 - Length(MAC_APP_POSTFIX) - Length(MAC_APP_SUBPATH)) = MAC_APP_POSTFIX + MAC_APP_SUBPATH then
    SetLength(Result, Length(Result) - Length(MAC_APP_SUBPATH));

  Result := CreateAbsolutePath(Result, GetCurrentDirUTF8);
  {$ELSE}
  if Result.Contains(MAC_APP_POSTFIX + MAC_APP_SUBPATH) then
    Result := Result.Remove(Result.IndexOf(MAC_APP_SUBPATH));
  {$ENDIF}
  {$ENDIF}
end;

procedure OutputDebugMessage(const aMessage : string);
begin
  {$IFDEF DEBUG}
    {$IFDEF MSWINDOWS}
      {$IFDEF FMX}
        FMX.Types.Log.d(aMessage);
      {$ELSE}
        OutputDebugString({$IFDEF DELPHI12_UP}PWideChar{$ELSE}PAnsiChar{$ENDIF}(aMessage + chr(0)));
      {$ENDIF}
    {$ENDIF}

    {$IFDEF LINUX}
      {$IFDEF FPC}
        // TO-DO: Find a way to write in the error console using Lazarus in Linux
      {$ELSE}
        FMX.Types.Log.d(aMessage);
      {$ENDIF}
    {$ENDIF}
    {$IFDEF MACOSX}
      {$IFDEF FPC}
        // TO-DO: Find a way to write in the error console using Lazarus in MacOS
      {$ELSE}
        FMX.Types.Log.d(aMessage);
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
end;

function CustomExceptionHandler(const aFunctionName : string; const aException : exception) : boolean;
begin
  OutputDebugMessage(aFunctionName + ' error : ' + aException.message);

  Result := (GlobalTesseractLoader <> nil) and GlobalTesseractLoader.ReRaiseExceptions;
end;

procedure ShowErrorMessageDlg(const aError : string);
begin
  OutputDebugMessage(aError);

  if (GlobalTesseractLoader <> nil) and GlobalTesseractLoader.ShowMessageDlg then
    begin
      {$IFDEF MSWINDOWS}
      MessageBox(0, PChar(aError + #0), PChar('Error' + #0), MB_ICONERROR or MB_OK or MB_TOPMOST);
      {$ENDIF}

      {$IFDEF LINUX}
        {$IFDEF FPC}
        if (WidgetSet <> nil) then
          Application.MessageBox(PChar(aError + #0), PChar('Error' + #0), MB_ICONERROR or MB_OK)
         else
          if (DisplayServer = ldsX11) then
            ShowX11Message(aError);
        {$ELSE}
        // TO-DO: Find a way to show message boxes in FMXLinux
        {$ENDIF}
      {$ENDIF}

      {$IFDEF MACOSX}
        {$IFDEF FPC}
        // TO-DO: Find a way to show message boxes in Lazarus/FPC for MacOS
        {$ELSE}
        ShowMessageCF('Error', aError, 10);
        {$ENDIF}
      {$ENDIF}
    end;
end;

function TessUTF8ToString(aString: PUTF8Char; aDeleteText: Boolean): string;
begin
  if assigned(aString) then
    begin
      {$IFDEF FPC}
      Result := aString;
      {$ELSE}
        {$IFDEF DELPHI12_UP}
        Result := UTF8ToString(RawByteString(aString));
        {$ELSE}
        Result := UTF8Decode(UTF8String(aString));
        {$ENDIF}
      {$ENDIF}

      if aDeleteText then
        TessDeleteText(aString);
    end
   else
    Result := '';
end;

function StringToTessUTF8(const aString: string): AnsiString;
begin
  {$IFDEF FPC}
  Result := aString;
  {$ELSE}
  Result := UTF8Encode(aString);
  {$ENDIF}
end;

end.
