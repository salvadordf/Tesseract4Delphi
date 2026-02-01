unit uLeptonicaLoader;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows, System.Win.Registry,{$ENDIF}
    System.Classes, System.SysUtils,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows, Registry,{$ENDIF} Classes, SysUtils,
    {$IFDEF FPC}dynlibs,{$ENDIF}
  {$ENDIF}
  uLeptonicaLibFunctions, uLeptonicaTypes;

type
  /// <summary>
  /// Class used to simplify the Leptonica initialization and destruction.
  /// </summary>
  TLeptonicaLoader = class
    protected
      FLibHandle                         : {$IFDEF FPC}TLibHandle{$ELSE}THandle{$ENDIF};
      FLibLoaded                         : boolean;
      FReRaiseExceptions                 : boolean;
      FSetCurrentDir                     : boolean;
      FShowMessageDlg                    : boolean;
      FCheckRequiredLibs                 : boolean;  
      FMustFreeLibrary                   : boolean;
      FStatus                            : TLeptonicaLoaderStatus;
      FLastErrorMessage                  : string;

      function  GetInitialized : boolean;

      {$IFDEF MSWINDOWS}
      function  CheckRegistry(const aPath, aValue : string) : boolean;
      function  IsVisualCppInstalled : boolean;
      {$ENDIF}
      procedure FreeLeptonicaLibrary;

    public
      constructor Create;
      destructor  Destroy; override;
      function    Initialize(const aLibraryPath: string) : boolean;

      /// <summary>
      ///	Used to set the current directory when the libraries are loaded. This is required if the application is launched from a different application.
      /// </summary>
      property SetCurrentDir                     : boolean                                  read FSetCurrentDir                     write FSetCurrentDir;
      /// <summary>
      /// Returns the TLeptonicaLoader initialization status.
      /// </summary>
      property Status                            : TLeptonicaLoaderStatus                   read FStatus;
      /// <summary>
      /// Returns true if the loader has an initialized status.
      /// </summary>
      property Initialized                       : boolean                                  read GetInitialized;
      /// <summary>
      /// Set to true to raise all exceptions.
      /// </summary>
      property ReRaiseExceptions                 : boolean                                  read FReRaiseExceptions                 write FReRaiseExceptions;
      /// <summary>
      /// Last error message that is usually shown when there's an initialization problem.
      /// </summary>
      property LastErrorMessage                  : string                                   read FLastErrorMessage;
      /// <summary>
      /// Set to true when you need to use a showmessage dialog to show the error messages.
      /// </summary>
      property ShowMessageDlg                    : boolean                                  read FShowMessageDlg                    write FShowMessageDlg;
      /// <summary>
      /// Check if other required libraries are installed before initialization.
      /// </summary>
      property CheckRequiredLibs                 : boolean                                  read FCheckRequiredLibs                 write FCheckRequiredLibs;
      /// <summary>
      /// Set to true to free the library handle when the loader is destroyed.
      /// </summary>
      property MustFreeLibrary                   : boolean                                  read FMustFreeLibrary                   write FMustFreeLibrary;
  end;

var
  /// <summary>
  /// Global instance of TLeptonicaLoader used to simplify the Leptonica initialization and destruction.
  /// </summary>
  GlobalLeptonicaLoader : TLeptonicaLoader = nil;

procedure DestroyGlobalLeptonicaLoader;

implementation

uses
  uLeptonicaConstants, uLeptonicaMiscFunctions;

procedure DestroyGlobalLeptonicaLoader;
begin
  if assigned(GlobalLeptonicaLoader) then
    FreeAndNil(GlobalLeptonicaLoader);
end;

constructor TLeptonicaLoader.Create;
begin
  inherited Create;

  FLibHandle         := 0;
  FLibLoaded         := False;
  FReRaiseExceptions := False;
  FSetCurrentDir     := False;
  FShowMessageDlg    := True;
  FCheckRequiredLibs := True;      
  FMustFreeLibrary   := True;
  FStatus            := llsLoading;
  FLastErrorMessage  := '';
end;

destructor TLeptonicaLoader.Destroy;
begin
  FreeLeptonicaLibrary;
  inherited Destroy;
end;

function TLeptonicaLoader.GetInitialized : boolean;
begin
  Result := (FStatus = llsInitialized);
end;

{$IFDEF MSWINDOWS}
function TLeptonicaLoader.CheckRegistry(const aPath, aValue : string) : boolean;
var
  TempReg : TRegistry;
begin
  Result   := false;
  TempReg  := nil;

  try
    try
      TempReg         := TRegistry.Create;
      TempReg.RootKey := HKEY_LOCAL_MACHINE;

      if TempReg.KeyExists(aPath)       and
         TempReg.OpenKeyReadOnly(aPath) and
         TempReg.ValueExists(aValue)    then
        begin
          Result := (TempReg.ReadInteger(aValue) > 0);
          TempReg.CloseKey;
        end;
    except
      on e : exception do
        if CustomExceptionHandler('TLeptonicaLoader.CheckRegistry', e) then raise;
    end;
  finally
    if (TempReg <> nil) then FreeAndNil(TempReg);
  end;
end;

function TLeptonicaLoader.IsVisualCppInstalled : boolean;
begin
  {$IFDEF TARGET_32BITS}
  Result := CheckRegistry(VCPPREG_PATH1_32BITS, 'Installed') or
            CheckRegistry(VCPPREG_PATH2_32BITS, 'Installed');
  {$ELSE}
  Result := CheckRegistry(VCPPREG_PATH1_64BITS, 'Installed') or
            CheckRegistry(VCPPREG_PATH2_64BITS, 'Installed');
  {$ENDIF}

  if not(Result) then
    FLastErrorMessage := 'Microsoft Visual C++ 2017 Redistributable is not installed.';
end;
{$ENDIF}

procedure TLeptonicaLoader.FreeLeptonicaLibrary;
begin
  try
    try
      if FMustFreeLibrary and (FLibHandle <> 0) then
        FreeLibrary(FLibHandle);
    except
      on e : exception do
        if CustomExceptionHandler('TLeptonicaLoader.FreeLeptonicaLibrary', e) then raise;
    end;
  finally
    FLibHandle := 0;
    FLibLoaded := False;
    FStatus    := llsUnloaded;
  end;
end;

function TLeptonicaLoader.Initialize(const aLibraryPath: string) : boolean;
var
  TempOldDir : string;
  TempError  : {$IFDEF MSWINDOWS}DWORD;{$ELSE}Integer;{$ENDIF}
begin
  Result := False;

  if (FStatus <> llsLoading) or FLibLoaded or (FLibHandle <> 0) then
    begin
      Result := True;
      exit;
    end;

  {$IFDEF MSWINDOWS}
  if FCheckRequiredLibs and not(IsVisualCppInstalled()) then
    begin
      ShowErrorMessageDlg({$IFDEF FPC}UTF8Encode({$ENDIF}FLastErrorMessage{$IFDEF FPC}){$ENDIF});
      exit;
    end;
  {$ENDIF}

  if FSetCurrentDir then
    begin
      TempOldDir := GetCurrentDir;
      chdir(GetModulePath);
    end;

  {$IFDEF MSWINDOWS}
    {$IFDEF DELPHI12_UP}
    FLibHandle := LoadLibraryExW(PWideChar(aLibraryPath), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
    {$ELSE}
      {$IFDEF FPC}
      FLibHandle := LoadLibraryExW(PWideChar(UTF8Decode(aLibraryPath)), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
      {$ELSE}
      FLibHandle := LoadLibraryExA(PChar(aLibraryPath), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
      {$ENDIF}
    {$ENDIF}
  {$ELSE}
    {$IFDEF FPC}
    FLibHandle := LoadLibrary(aLibraryPath);
    {$ELSE}
    FLibHandle := LoadLibrary(PChar(aLibraryPath));
    {$ENDIF}
  {$ENDIF}

  if (FLibHandle = 0) then
    begin
      FStatus := llsErrorLoadingLibrary;

      {$IFDEF MSWINDOWS}
      TempError         := GetLastError;
      FLastErrorMessage := 'Error loading ' + aLibraryPath + CRLF + CRLF +
                           'Error code : 0x' + inttohex(TempError, 8) + CRLF +
                           SysErrorMessage(TempError);
      {$ELSE}
        {$IFDEF FPC}
        TempError         := GetLastOSError;
        FLastErrorMessage := 'Error loading ' + aLibraryPath + CRLF + CRLF +
                             'Error code : 0x' + inttohex(TempError, 8) + CRLF +
                             GetLoadErrorStr;
        {$ELSE}
        FLastErrorMessage := 'Error loading ' + aLibraryPath;
        {$ENDIF}
      {$ENDIF}

      ShowErrorMessageDlg({$IFDEF FPC}UTF8Encode({$ENDIF}FLastErrorMessage{$IFDEF FPC}){$ENDIF});
      exit;
    end;

  {$IFDEF FPC}Pointer({$ENDIF}pixRead{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'pixRead');
  {$IFDEF FPC}Pointer({$ENDIF}pixDestroy{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'pixDestroy');
  {$IFDEF FPC}Pointer({$ENDIF}pixReadMem{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'pixReadMem');
  {$IFDEF FPC}Pointer({$ENDIF}pixWriteMem{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'pixWriteMem');
  {$IFDEF FPC}Pointer({$ENDIF}pixDeskew{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'pixDeskew');
  {$IFDEF FPC}Pointer({$ENDIF}lept_free{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'lept_free');
  {$IFDEF FPC}Pointer({$ENDIF}boxCreate{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'boxCreate');
  {$IFDEF FPC}Pointer({$ENDIF}boxDestroy{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'boxDestroy');
  {$IFDEF FPC}Pointer({$ENDIF}boxCopy{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'boxCopy');
  {$IFDEF FPC}Pointer({$ENDIF}boxClone{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'boxClone');
  {$IFDEF FPC}Pointer({$ENDIF}boxaCreate{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'boxaCreate');
  {$IFDEF FPC}Pointer({$ENDIF}boxaDestroy{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'boxaDestroy');
  {$IFDEF FPC}Pointer({$ENDIF}pixaCreate{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'pixaCreate');
  {$IFDEF FPC}Pointer({$ENDIF}pixaDestroy{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'pixaDestroy');

  if assigned(pixRead) and
     assigned(pixDestroy) and
     assigned(pixReadMem) and
     assigned(pixWriteMem) and
     assigned(pixDeskew) and
     assigned(lept_free) and
     assigned(boxCreate) and
     assigned(boxDestroy) and
     assigned(boxCopy) and
     assigned(boxClone) and
     assigned(boxaCreate) and
     assigned(boxaDestroy) and
     assigned(pixaCreate) and
     assigned(pixaDestroy) then
    begin
      FStatus    := llsInitialized;
      FLibLoaded := True;
      Result     := True;
    end
   else
    begin
      FStatus           := llsErrorDLLVersion;
      FLastErrorMessage := 'Unsupported Leptonica version!';

      ShowErrorMessageDlg({$IFDEF FPC}UTF8Encode({$ENDIF}FLastErrorMessage{$IFDEF FPC}){$ENDIF});
    end;

  if FSetCurrentDir then chdir(TempOldDir);
end;

initialization

finalization
  DestroyGlobalLeptonicaLoader;

end.
