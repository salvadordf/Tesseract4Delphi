unit uTesseractMiscFunctions;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows,{$ENDIF}
    {$IFDEF FMX}FMX.Types, FMX.Platform,{$ENDIF} System.SysUtils,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} SysUtils,
    {$IFDEF LINUXFPC}Types,{$ENDIF}
  {$ENDIF}
  uLeptonicaTypes, uTesseractTypes;

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

function  TessParagraphJustificationToStr(aTessParagraphJustification : TessParagraphJustification) : string;
function  TessPolyBlockTypeToStr(aTessPolyBlockType : TessPolyBlockType) : string;
function  TessOrientationToStr(aTessOrientation : TessOrientation) : string;
function  TessWritingDirectionToStr(aTessWritingDirection : TessWritingDirection) : string;
function  TessTextlineOrderToStr(aTessTextlineOrder : TessTextlineOrder) : string;
function  RectToStr(const aRect : TRect) : string;

implementation

uses
  {$IFDEF LINUXFPC}lcltype, Forms,{$ENDIF}
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
        Application.MessageBox(PChar(aError + #0), PChar('Error' + #0), MB_ICONERROR or MB_OK)
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

function TessParagraphJustificationToStr(aTessParagraphJustification : TessParagraphJustification) : string;
begin
  case aTessParagraphJustification of
    JUSTIFICATION_LEFT    : Result := 'left';
    JUSTIFICATION_CENTER  : Result := 'center';
    JUSTIFICATION_RIGHT   : Result := 'right';
    else                    Result := 'unknown';
  end;
end;

function TessPolyBlockTypeToStr(aTessPolyBlockType : TessPolyBlockType) : string;
begin
  case aTessPolyBlockType of
    PT_FLOWING_TEXT    : Result := 'Text that lives inside a column';
    PT_HEADING_TEXT    : Result := 'Text that spans more than one column';
    PT_PULLOUT_TEXT    : Result := 'Text that is in a cross-column pull-out region';
    PT_EQUATION        : Result := 'Partition belonging to an equation region';
    PT_INLINE_EQUATION : Result := 'Partition has inline equation';
    PT_TABLE           : Result := 'Partition belonging to a table region';
    PT_VERTICAL_TEXT   : Result := 'Text-line runs vertically';
    PT_CAPTION_TEXT    : Result := 'Text that belongs to an image';
    PT_FLOWING_IMAGE   : Result := 'Image that lives inside a column';
    PT_HEADING_IMAGE   : Result := 'Image that spans more than one column';
    PT_PULLOUT_IMAGE   : Result := 'Image that is in a cross-column pull-out region';
    PT_HORZ_LINE       : Result := 'Horizontal Line';
    PT_VERT_LINE       : Result := 'Vertical Line';
    PT_NOISE           : Result := 'Lies outside of any column';
    else                 Result := 'unknown';
  end;
end;

function  TessOrientationToStr(aTessOrientation : TessOrientation) : string;
begin
  case aTessOrientation of
    ORIENTATION_PAGE_UP    : Result := 'up';
    ORIENTATION_PAGE_RIGHT : Result := 'right';
    ORIENTATION_PAGE_DOWN  : Result := 'down';
    else                     Result := 'left';
  end;
end;

function TessWritingDirectionToStr(aTessWritingDirection : TessWritingDirection) : string;
begin
  case aTessWritingDirection of
    WRITING_DIRECTION_LEFT_TO_RIGHT : Result := 'left to right';
    WRITING_DIRECTION_RIGHT_TO_LEFT : Result := 'right to left';
    else                              Result := 'top to bottom';
  end;
end;

function TessTextlineOrderToStr(aTessTextlineOrder : TessTextlineOrder) : string;
begin
  case aTessTextlineOrder of
    TEXTLINE_ORDER_LEFT_TO_RIGHT : Result := 'left to right';
    TEXTLINE_ORDER_RIGHT_TO_LEFT : Result := 'right to left';
    else                           Result := 'top to bottom';
  end;
end;

function RectToStr(const aRect : TRect) : string;
begin
  Result := '(' + inttostr(aRect.Left) + ',' + inttostr(aRect.Top) + ',' + inttostr(aRect.Right) + ',' + inttostr(aRect.Bottom) + ')';
end;

end.
