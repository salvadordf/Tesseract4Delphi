unit uTesseractLoader;

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
  uTesseractLibFunctions, uTesseractTypes;

type
  /// <summary>
  /// Class used to simplify the Tesseract initialization and destruction.
  /// </summary>
  TTesseractLoader = class
    protected
      FLibHandle                         : {$IFDEF FPC}TLibHandle{$ELSE}THandle{$ENDIF};
      FLibLoaded                         : boolean;
      FReRaiseExceptions                 : boolean;
      FSetCurrentDir                     : boolean;
      FShowMessageDlg                    : boolean;
      FCheckRequiredLibs                 : boolean;
      FMustFreeLibrary                   : boolean;
      FStatus                            : TTesseractLoaderStatus;
      FLastErrorMessage                  : string;
      FMonitors                          : TList;
      FComponents                        : TList;

      function  GetInitialized : boolean;

      {$IFDEF MSWINDOWS}
      function  CheckRegistry(const aPath, aValue : string) : boolean;
      function  IsVisualCppInstalled : boolean;
      {$ENDIF}
      procedure FreeTesseractLibrary;
      function  LoadGeneralFreeFunctions : boolean;
      function  LoadRendererAPIFunctions : boolean;
      function  LoadBaseAPIFunctions1 : boolean;
      function  LoadBaseAPIFunctions2 : boolean;
      function  LoadBaseAPIFunctions3 : boolean;
      function  LoadBaseAPIFunctions4 : boolean;
      function  LoadPageIteratorFunctions : boolean;
      function  LoadResultIteratorFunctions : boolean;
      function  LoadChoiceIteratorFunctions : boolean;
      function  LoadProgressMonitorFunctions : boolean;

    public
      constructor Create;
      destructor  Destroy; override;
      procedure   AfterConstruction; override;
      function    Initialize(const aLibraryPath: string) : boolean;
      /// <summary>
      ///	<para>Internal function used to find the TTesseractOCR component to trigger the TTesseractOCR.OnProgress event.</para>
      /// <para>DON'T USE THIS FUNCTION.</para>
      /// </summary>
      function    InternalSearchMonitor(const aHandle: PETEXT_DESC; var aComponent : TComponent): boolean;
      /// <summary>
      ///	<para>Internal function that adds a monitor and the parent TTesseractOCR component to a list.</para>
      /// <para>This information is used to trigger the TTesseractOCR.OnProgress event.</para>
      /// <para>DON'T USE THIS FUNCTION.</para>
      /// </summary>
      function    InternalRegisterMonitor(const aHandle: PETEXT_DESC; const aComponent : TComponent): boolean;
      /// <summary>
      ///	<para>Internal function that removes a monitor and the parent TTesseractOCR component from a list.</para>
      /// <para>This information is used to trigger the TTesseractOCR.OnProgress event.</para>
      /// <para>DON'T USE THIS FUNCTION.</para>
      /// </summary>
      function    InternalUnregisterMonitor(const aHandle: PETEXT_DESC): boolean;

      /// <summary>
      ///	Used to set the current directory when the libraries are loaded. This is required if the application is launched from a different application.
      /// </summary>
      property SetCurrentDir                     : boolean                                  read FSetCurrentDir                     write FSetCurrentDir;
      /// <summary>
      /// Returns the TTesseractLoader initialization status.
      /// </summary>
      property Status                            : TTesseractLoaderStatus                   read FStatus;
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
  /// Global instance of TTesseractLoader used to simplify the Leptonica initialization and destruction.
  /// </summary>
  GlobalTesseractLoader : TTesseractLoader = nil;

procedure DestroyGlobalTesseractLoader;

implementation

uses
  {$IFDEF DELPHI16_UP}
  System.Math,
  {$ELSE}
  Math,
  {$ENDIF}
  uTesseractConstants, uTesseractMiscFunctions, uLeptonicaConstants;

procedure DestroyGlobalTesseractLoader;
begin
  if assigned(GlobalTesseractLoader) then
    FreeAndNil(GlobalTesseractLoader);
end;

constructor TTesseractLoader.Create;
begin
  inherited Create;

  FLibHandle         := 0;
  FLibLoaded         := False;
  FReRaiseExceptions := False;
  FSetCurrentDir     := False;
  FShowMessageDlg    := True;
  FStatus            := tlsLoading;
  FLastErrorMessage  := '';
  FMonitors          := nil;
  FComponents        := nil;
  FCheckRequiredLibs := True;
  FMustFreeLibrary   := {$IFDEF LINUXFPC}False{$ELSE}True{$ENDIF};

  IsMultiThread := True;

  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
end;

destructor TTesseractLoader.Destroy;
begin
  try
    if assigned(FMonitors) then
      FreeAndNil(FMonitors);

    if assigned(FComponents) then
      FreeAndNil(FComponents);

    FreeTesseractLibrary;
  finally
    inherited Destroy;
  end;
end;

procedure TTesseractLoader.AfterConstruction;
begin
  inherited AfterConstruction;

  FMonitors   := TList.Create;
  FComponents := TList.Create;
end;

function TTesseractLoader.GetInitialized : boolean;
begin
  Result := (FStatus = tlsInitialized);
end;

procedure TTesseractLoader.FreeTesseractLibrary;
begin
  try
    try
      if FMustFreeLibrary and (FLibHandle <> 0) then
         FreeLibrary(FLibHandle);
    except
      on e : exception do
        if CustomExceptionHandler('TTesseractLoader.FreeTesseractLibrary', e) then raise;
    end;
  finally
    FLibHandle := 0;
    FLibLoaded := False;
    FStatus    := tlsUnloaded;
  end;
end;

function TTesseractLoader.LoadGeneralFreeFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessVersion{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessVersion');
  {$IFDEF FPC}Pointer({$ENDIF}TessDeleteText{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'TessDeleteText');
  {$IFDEF FPC}Pointer({$ENDIF}TessDeleteTextArray{$IFDEF FPC}){$ENDIF} := GetProcAddress(FLibHandle, 'TessDeleteTextArray');
  {$IFDEF FPC}Pointer({$ENDIF}TessDeleteIntArray{$IFDEF FPC}){$ENDIF}  := GetProcAddress(FLibHandle, 'TessDeleteIntArray');

  Result := assigned(TessVersion) and
            assigned(TessDeleteText) and
            assigned(TessDeleteTextArray) and
            assigned(TessDeleteIntArray);
end;

function TTesseractLoader.LoadRendererAPIFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessTextRendererCreate{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessTextRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessHOcrRendererCreate{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessHOcrRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessHOcrRendererCreate2{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessHOcrRendererCreate2');
  {$IFDEF FPC}Pointer({$ENDIF}TessAltoRendererCreate{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessAltoRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessPAGERendererCreate{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessPAGERendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessTsvRendererCreate{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessTsvRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessPDFRendererCreate{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessPDFRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessUnlvRendererCreate{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessUnlvRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessBoxTextRendererCreate{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'TessBoxTextRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessLSTMBoxRendererCreate{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'TessLSTMBoxRendererCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessWordStrBoxRendererCreate{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'TessWordStrBoxRendererCreate');

  {$IFDEF FPC}Pointer({$ENDIF}TessDeleteResultRenderer{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessDeleteResultRenderer');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererInsert{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessResultRendererInsert');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererNext{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessResultRendererNext');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererBeginDocument{$IFDEF FPC}){$ENDIF}  := GetProcAddress(FLibHandle, 'TessResultRendererBeginDocument');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererAddImage{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessResultRendererAddImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererEndDocument{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'TessResultRendererEndDocument');

  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererExtention{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'TessResultRendererExtention');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererTitle{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessResultRendererTitle');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultRendererImageNum{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessResultRendererImageNum');

  Result := assigned(TessTextRendererCreate) and
            assigned(TessHOcrRendererCreate) and
            assigned(TessHOcrRendererCreate2) and
            assigned(TessAltoRendererCreate) and
            {$IFNDEF LINUXFPC}assigned(TessPAGERendererCreate) and{$ENDIF}
            assigned(TessTsvRendererCreate) and
            assigned(TessPDFRendererCreate) and
            assigned(TessUnlvRendererCreate) and
            assigned(TessBoxTextRendererCreate) and
            assigned(TessLSTMBoxRendererCreate) and
            assigned(TessWordStrBoxRendererCreate) and
            assigned(TessDeleteResultRenderer) and
            assigned(TessResultRendererInsert) and
            assigned(TessResultRendererNext) and
            assigned(TessResultRendererBeginDocument) and
            assigned(TessResultRendererAddImage) and
            assigned(TessResultRendererEndDocument) and
            assigned(TessResultRendererExtention) and
            assigned(TessResultRendererTitle) and
            assigned(TessResultRendererImageNum);
end;

function TTesseractLoader.LoadBaseAPIFunctions1 : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPICreate{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessBaseAPICreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIDelete{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessBaseAPIDelete');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetInputName{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPISetInputName');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetInputName{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPIGetInputName');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetInputImage{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessBaseAPISetInputImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetInputImage{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessBaseAPIGetInputImage');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetSourceYResolution{$IFDEF FPC}){$ENDIF}   := GetProcAddress(FLibHandle, 'TessBaseAPIGetSourceYResolution');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetDatapath{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessBaseAPIGetDatapath');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetOutputName{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessBaseAPISetOutputName');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetVariable{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessBaseAPISetVariable');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetDebugVariable{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessBaseAPISetDebugVariable');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetIntVariable{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessBaseAPIGetIntVariable');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetBoolVariable{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'TessBaseAPIGetBoolVariable');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetDoubleVariable{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'TessBaseAPIGetDoubleVariable');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetStringVariable{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'TessBaseAPIGetStringVariable');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIPrintVariables{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessBaseAPIPrintVariables');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIPrintVariablesToFile{$IFDEF FPC}){$ENDIF}   := GetProcAddress(FLibHandle, 'TessBaseAPIPrintVariablesToFile');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInit1{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIInit1');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInit2{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIInit2');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInit3{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIInit3');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInit4{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIInit4');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInit5{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIInit5');

  Result := assigned(TessBaseAPICreate) and
            assigned(TessBaseAPIDelete) and
            assigned(TessBaseAPISetInputName) and
            assigned(TessBaseAPIGetInputName) and
            assigned(TessBaseAPISetInputImage) and
            assigned(TessBaseAPIGetInputImage) and
            assigned(TessBaseAPIGetSourceYResolution) and
            assigned(TessBaseAPIGetDatapath) and
            assigned(TessBaseAPISetOutputName) and
            assigned(TessBaseAPISetVariable) and
            assigned(TessBaseAPISetDebugVariable) and
            assigned(TessBaseAPIGetIntVariable) and
            assigned(TessBaseAPIGetBoolVariable) and
            assigned(TessBaseAPIGetDoubleVariable) and
            assigned(TessBaseAPIGetStringVariable) and
            assigned(TessBaseAPIPrintVariables) and
            assigned(TessBaseAPIPrintVariablesToFile) and
            assigned(TessBaseAPIInit1) and
            assigned(TessBaseAPIInit2) and
            assigned(TessBaseAPIInit3) and
            assigned(TessBaseAPIInit4) and
            assigned(TessBaseAPIInit5);
end;

function TTesseractLoader.LoadBaseAPIFunctions2 : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetInitLanguagesAsString{$IFDEF FPC}){$ENDIF}      := GetProcAddress(FLibHandle, 'TessBaseAPIGetInitLanguagesAsString');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetLoadedLanguagesAsVector{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'TessBaseAPIGetLoadedLanguagesAsVector');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetAvailableLanguagesAsVector{$IFDEF FPC}){$ENDIF} := GetProcAddress(FLibHandle, 'TessBaseAPIGetAvailableLanguagesAsVector');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIInitForAnalysePage{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessBaseAPIInitForAnalysePage');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIReadConfigFile{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessBaseAPIReadConfigFile');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIReadDebugConfigFile{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPIReadDebugConfigFile');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetPageSegMode{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessBaseAPISetPageSegMode');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetPageSegMode{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessBaseAPIGetPageSegMode');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIRect{$IFDEF FPC}){$ENDIF}                          := GetProcAddress(FLibHandle, 'TessBaseAPIRect');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIClearAdaptiveClassifier{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessBaseAPIClearAdaptiveClassifier');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetImage{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPISetImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetImage2{$IFDEF FPC}){$ENDIF}                     := GetProcAddress(FLibHandle, 'TessBaseAPISetImage2');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetSourceResolution{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPISetSourceResolution');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetRectangle{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPISetRectangle');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetThresholdedImage{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPIGetThresholdedImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetGradient{$IFDEF FPC}){$ENDIF}                   := GetProcAddress(FLibHandle, 'TessBaseAPIGetGradient');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetRegions{$IFDEF FPC}){$ENDIF}                    := GetProcAddress(FLibHandle, 'TessBaseAPIGetRegions');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetTextlines{$IFDEF FPC}){$ENDIF}                  := GetProcAddress(FLibHandle, 'TessBaseAPIGetTextlines');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetTextlines1{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessBaseAPIGetTextlines1');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetStrips{$IFDEF FPC}){$ENDIF}                     := GetProcAddress(FLibHandle, 'TessBaseAPIGetStrips');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetWords{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetWords');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetConnectedComponents{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'TessBaseAPIGetConnectedComponents');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetComponentImages{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessBaseAPIGetComponentImages');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetComponentImages1{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPIGetComponentImages1');

  Result := assigned(TessBaseAPIGetInitLanguagesAsString) and
            assigned(TessBaseAPIGetLoadedLanguagesAsVector) and
            assigned(TessBaseAPIGetAvailableLanguagesAsVector) and
            assigned(TessBaseAPIInitForAnalysePage) and
            assigned(TessBaseAPIReadConfigFile) and
            assigned(TessBaseAPIReadDebugConfigFile) and
            assigned(TessBaseAPISetPageSegMode) and
            assigned(TessBaseAPIGetPageSegMode) and
            assigned(TessBaseAPIRect) and
            assigned(TessBaseAPIClearAdaptiveClassifier) and
            assigned(TessBaseAPISetImage) and
            assigned(TessBaseAPISetImage2) and
            assigned(TessBaseAPISetSourceResolution) and
            assigned(TessBaseAPISetRectangle) and
            assigned(TessBaseAPIGetThresholdedImage) and
            {$IFNDEF LINUXFPC}assigned(TessBaseAPIGetGradient) and{$ENDIF}
            assigned(TessBaseAPIGetRegions) and
            assigned(TessBaseAPIGetTextlines) and
            assigned(TessBaseAPIGetTextlines1) and
            assigned(TessBaseAPIGetStrips) and
            assigned(TessBaseAPIGetWords) and
            assigned(TessBaseAPIGetConnectedComponents) and
            assigned(TessBaseAPIGetComponentImages) and
            assigned(TessBaseAPIGetComponentImages1);
end;

function TTesseractLoader.LoadBaseAPIFunctions3 : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetThresholdedImageScaleFactor{$IFDEF FPC}){$ENDIF}   := GetProcAddress(FLibHandle, 'TessBaseAPIGetThresholdedImageScaleFactor');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIAnalyseLayout{$IFDEF FPC}){$ENDIF}                    := GetProcAddress(FLibHandle, 'TessBaseAPIAnalyseLayout');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIRecognize{$IFDEF FPC}){$ENDIF}                        := GetProcAddress(FLibHandle, 'TessBaseAPIRecognize');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIProcessPages{$IFDEF FPC}){$ENDIF}                     := GetProcAddress(FLibHandle, 'TessBaseAPIProcessPages');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIProcessPage{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIProcessPage');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetIterator{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetIterator');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetMutableIterator{$IFDEF FPC}){$ENDIF}               := GetProcAddress(FLibHandle, 'TessBaseAPIGetMutableIterator');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetUTF8Text{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetUTF8Text');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetHOCRText{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetHOCRText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetAltoText{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetAltoText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetPAGEText{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIGetPAGEText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetTsvText{$IFDEF FPC}){$ENDIF}                       := GetProcAddress(FLibHandle, 'TessBaseAPIGetTsvText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetBoxText{$IFDEF FPC}){$ENDIF}                       := GetProcAddress(FLibHandle, 'TessBaseAPIGetBoxText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetLSTMBoxText{$IFDEF FPC}){$ENDIF}                   := GetProcAddress(FLibHandle, 'TessBaseAPIGetLSTMBoxText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetWordStrBoxText{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessBaseAPIGetWordStrBoxText');

  Result := assigned(TessBaseAPIGetThresholdedImageScaleFactor) and
            assigned(TessBaseAPIAnalyseLayout) and
            assigned(TessBaseAPIRecognize) and
            assigned(TessBaseAPIProcessPages) and
            assigned(TessBaseAPIProcessPage) and
            assigned(TessBaseAPIGetIterator) and
            assigned(TessBaseAPIGetMutableIterator) and
            assigned(TessBaseAPIGetUTF8Text) and
            assigned(TessBaseAPIGetHOCRText) and
            assigned(TessBaseAPIGetAltoText) and
            {$IFNDEF LINUXFPC}assigned(TessBaseAPIGetPAGEText) and{$ENDIF}
            assigned(TessBaseAPIGetTsvText) and
            assigned(TessBaseAPIGetBoxText) and
            assigned(TessBaseAPIGetLSTMBoxText) and
            assigned(TessBaseAPIGetWordStrBoxText);
end;

function TTesseractLoader.LoadBaseAPIFunctions4 : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetUNLVText{$IFDEF FPC}){$ENDIF}              := GetProcAddress(FLibHandle, 'TessBaseAPIGetUNLVText');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIMeanTextConf{$IFDEF FPC}){$ENDIF}             := GetProcAddress(FLibHandle, 'TessBaseAPIMeanTextConf');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIAllWordConfidences{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessBaseAPIAllWordConfidences');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIAdaptToWordStr{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessBaseAPIAdaptToWordStr');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIClear{$IFDEF FPC}){$ENDIF}                    := GetProcAddress(FLibHandle, 'TessBaseAPIClear');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIEnd{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIEnd');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIIsValidWord{$IFDEF FPC}){$ENDIF}              := GetProcAddress(FLibHandle, 'TessBaseAPIIsValidWord');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetTextDirection{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessBaseAPIGetTextDirection');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIGetUnichar{$IFDEF FPC}){$ENDIF}               := GetProcAddress(FLibHandle, 'TessBaseAPIGetUnichar');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIClearPersistentCache{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'TessBaseAPIClearPersistentCache');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIDetectOrientationScript{$IFDEF FPC}){$ENDIF}  := GetProcAddress(FLibHandle, 'TessBaseAPIDetectOrientationScript');

  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPISetMinOrientationMargin{$IFDEF FPC}){$ENDIF}  := GetProcAddress(FLibHandle, 'TessBaseAPISetMinOrientationMargin');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPINumDawgs{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessBaseAPINumDawgs');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseAPIOem{$IFDEF FPC}){$ENDIF}                      := GetProcAddress(FLibHandle, 'TessBaseAPIOem');
  {$IFDEF FPC}Pointer({$ENDIF}TessBaseGetBlockTextOrientations{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'TessBaseGetBlockTextOrientations');

  Result := assigned(TessBaseAPIGetUNLVText) and
            assigned(TessBaseAPIMeanTextConf) and
            assigned(TessBaseAPIAllWordConfidences) and
            assigned(TessBaseAPIAdaptToWordStr) and
            assigned(TessBaseAPIClear) and
            assigned(TessBaseAPIEnd) and
            assigned(TessBaseAPIIsValidWord) and
            assigned(TessBaseAPIGetTextDirection) and
            assigned(TessBaseAPIGetUnichar) and
            assigned(TessBaseAPIClearPersistentCache) and
            assigned(TessBaseAPIDetectOrientationScript) and
            assigned(TessBaseAPISetMinOrientationMargin) and
            assigned(TessBaseAPINumDawgs) and
            assigned(TessBaseAPIOem) and
            assigned(TessBaseGetBlockTextOrientations);
end;

function TTesseractLoader.LoadPageIteratorFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorDelete{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessPageIteratorDelete');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorCopy{$IFDEF FPC}){$ENDIF}              := GetProcAddress(FLibHandle, 'TessPageIteratorCopy');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorBegin{$IFDEF FPC}){$ENDIF}             := GetProcAddress(FLibHandle, 'TessPageIteratorBegin');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorNext{$IFDEF FPC}){$ENDIF}              := GetProcAddress(FLibHandle, 'TessPageIteratorNext');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorIsAtBeginningOf{$IFDEF FPC}){$ENDIF}   := GetProcAddress(FLibHandle, 'TessPageIteratorIsAtBeginningOf');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorIsAtFinalElement{$IFDEF FPC}){$ENDIF}  := GetProcAddress(FLibHandle, 'TessPageIteratorIsAtFinalElement');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorBoundingBox{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessPageIteratorBoundingBox');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorBlockType{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessPageIteratorBlockType');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorGetBinaryImage{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'TessPageIteratorGetBinaryImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorGetImage{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessPageIteratorGetImage');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorBaseline{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessPageIteratorBaseline');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorOrientation{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessPageIteratorOrientation');
  {$IFDEF FPC}Pointer({$ENDIF}TessPageIteratorParagraphInfo{$IFDEF FPC}){$ENDIF}     := GetProcAddress(FLibHandle, 'TessPageIteratorParagraphInfo');

  Result := assigned(TessPageIteratorDelete) and
            assigned(TessPageIteratorCopy) and
            assigned(TessPageIteratorBegin) and
            assigned(TessPageIteratorNext) and
            assigned(TessPageIteratorIsAtBeginningOf) and
            assigned(TessPageIteratorIsAtFinalElement) and
            assigned(TessPageIteratorBoundingBox) and
            assigned(TessPageIteratorBlockType) and
            assigned(TessPageIteratorGetBinaryImage) and
            assigned(TessPageIteratorGetImage) and
            assigned(TessPageIteratorBaseline) and
            assigned(TessPageIteratorOrientation) and
            assigned(TessPageIteratorParagraphInfo);
end;

function TTesseractLoader.LoadResultIteratorFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorDelete{$IFDEF FPC}){$ENDIF}                     := GetProcAddress(FLibHandle, 'TessResultIteratorDelete');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorCopy{$IFDEF FPC}){$ENDIF}                       := GetProcAddress(FLibHandle, 'TessResultIteratorCopy');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorGetPageIterator{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessResultIteratorGetPageIterator');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorGetPageIteratorConst{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessResultIteratorGetPageIteratorConst');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorGetChoiceIterator{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessResultIteratorGetChoiceIterator');

  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorNext{$IFDEF FPC}){$ENDIF}                       := GetProcAddress(FLibHandle, 'TessResultIteratorNext');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorGetUTF8Text{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessResultIteratorGetUTF8Text');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorConfidence{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessResultIteratorConfidence');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorWordRecognitionLanguage{$IFDEF FPC}){$ENDIF}    := GetProcAddress(FLibHandle, 'TessResultIteratorWordRecognitionLanguage');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorWordFontAttributes{$IFDEF FPC}){$ENDIF}         := GetProcAddress(FLibHandle, 'TessResultIteratorWordFontAttributes');

  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorWordIsFromDictionary{$IFDEF FPC}){$ENDIF}       := GetProcAddress(FLibHandle, 'TessResultIteratorWordIsFromDictionary');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorWordIsNumeric{$IFDEF FPC}){$ENDIF}              := GetProcAddress(FLibHandle, 'TessResultIteratorWordIsNumeric');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorSymbolIsSuperscript{$IFDEF FPC}){$ENDIF}        := GetProcAddress(FLibHandle, 'TessResultIteratorSymbolIsSuperscript');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorSymbolIsSubscript{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessResultIteratorSymbolIsSubscript');
  {$IFDEF FPC}Pointer({$ENDIF}TessResultIteratorSymbolIsDropcap{$IFDEF FPC}){$ENDIF}            := GetProcAddress(FLibHandle, 'TessResultIteratorSymbolIsDropcap');

  Result := assigned(TessResultIteratorDelete) and
            assigned(TessResultIteratorCopy) and
            assigned(TessResultIteratorGetPageIterator) and
            assigned(TessResultIteratorGetPageIteratorConst) and
            assigned(TessResultIteratorGetChoiceIterator) and
            assigned(TessResultIteratorNext) and
            assigned(TessResultIteratorGetUTF8Text) and
            assigned(TessResultIteratorConfidence) and
            assigned(TessResultIteratorWordRecognitionLanguage) and
            assigned(TessResultIteratorWordFontAttributes) and
            assigned(TessResultIteratorWordIsFromDictionary) and
            assigned(TessResultIteratorWordIsNumeric) and
            assigned(TessResultIteratorSymbolIsSuperscript) and
            assigned(TessResultIteratorSymbolIsSubscript) and
            assigned(TessResultIteratorSymbolIsDropcap);
end;

function TTesseractLoader.LoadChoiceIteratorFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessChoiceIteratorDelete{$IFDEF FPC}){$ENDIF}                     := GetProcAddress(FLibHandle, 'TessChoiceIteratorDelete');
  {$IFDEF FPC}Pointer({$ENDIF}TessChoiceIteratorNext{$IFDEF FPC}){$ENDIF}                       := GetProcAddress(FLibHandle, 'TessChoiceIteratorNext');
  {$IFDEF FPC}Pointer({$ENDIF}TessChoiceIteratorGetUTF8Text{$IFDEF FPC}){$ENDIF}                := GetProcAddress(FLibHandle, 'TessChoiceIteratorGetUTF8Text');
  {$IFDEF FPC}Pointer({$ENDIF}TessChoiceIteratorConfidence{$IFDEF FPC}){$ENDIF}                 := GetProcAddress(FLibHandle, 'TessChoiceIteratorConfidence');

  Result := assigned(TessChoiceIteratorDelete) and
            assigned(TessChoiceIteratorNext) and
            assigned(TessChoiceIteratorGetUTF8Text) and
            assigned(TessChoiceIteratorConfidence);
end;

function TTesseractLoader.LoadProgressMonitorFunctions : boolean;
begin
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorCreate{$IFDEF FPC}){$ENDIF}                    := GetProcAddress(FLibHandle, 'TessMonitorCreate');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorDelete{$IFDEF FPC}){$ENDIF}                    := GetProcAddress(FLibHandle, 'TessMonitorDelete');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorSetCancelFunc{$IFDEF FPC}){$ENDIF}             := GetProcAddress(FLibHandle, 'TessMonitorSetCancelFunc');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorSetCancelThis{$IFDEF FPC}){$ENDIF}             := GetProcAddress(FLibHandle, 'TessMonitorSetCancelThis');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorGetCancelThis{$IFDEF FPC}){$ENDIF}             := GetProcAddress(FLibHandle, 'TessMonitorGetCancelThis');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorSetProgressFunc{$IFDEF FPC}){$ENDIF}           := GetProcAddress(FLibHandle, 'TessMonitorSetProgressFunc');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorGetProgress{$IFDEF FPC}){$ENDIF}               := GetProcAddress(FLibHandle, 'TessMonitorGetProgress');
  {$IFDEF FPC}Pointer({$ENDIF}TessMonitorSetDeadlineMSecs{$IFDEF FPC}){$ENDIF}          := GetProcAddress(FLibHandle, 'TessMonitorSetDeadlineMSecs');

  Result := assigned(TessMonitorCreate) and
            assigned(TessMonitorDelete) and
            assigned(TessMonitorSetCancelFunc) and
            assigned(TessMonitorSetCancelThis) and
            assigned(TessMonitorGetCancelThis) and
            assigned(TessMonitorSetProgressFunc) and
            assigned(TessMonitorGetProgress) and
            assigned(TessMonitorSetDeadlineMSecs);
end;

{$IFDEF MSWINDOWS}
function TTesseractLoader.CheckRegistry(const aPath, aValue : string) : boolean;
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
        if CustomExceptionHandler('TTesseractLoader.CheckRegistry', e) then raise;
    end;
  finally
    if (TempReg <> nil) then FreeAndNil(TempReg);
  end;
end;

function TTesseractLoader.IsVisualCppInstalled : boolean;
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

function TTesseractLoader.Initialize(const aLibraryPath: string) : boolean;
var
  TempOldDir : string;
  TempError  : {$IFDEF MSWINDOWS}DWORD;{$ELSE}Integer;{$ENDIF}
begin
  Result := False;

  if (FStatus <> tlsLoading) or FLibLoaded or (FLibHandle <> 0) then
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
      FStatus := tlsErrorLoadingLibrary;

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

  if LoadGeneralFreeFunctions and
     LoadRendererAPIFunctions and
     LoadBaseAPIFunctions1 and
     LoadBaseAPIFunctions2 and
     LoadBaseAPIFunctions3 and
     LoadBaseAPIFunctions4 and
     LoadPageIteratorFunctions and
     LoadResultIteratorFunctions and
     LoadChoiceIteratorFunctions and
     LoadProgressMonitorFunctions then
    begin
      FStatus    := tlsInitialized;
      FLibLoaded := True;
      Result     := True;
    end
   else
    begin
      FStatus           := tlsErrorDLLVersion;
      FLastErrorMessage := 'Unsupported Tesseract version!';

      ShowErrorMessageDlg({$IFDEF FPC}UTF8Encode({$ENDIF}FLastErrorMessage{$IFDEF FPC}){$ENDIF});
    end;

  if FSetCurrentDir then chdir(TempOldDir);
end;

function TTesseractLoader.InternalSearchMonitor(const aHandle: PETEXT_DESC; var aComponent : TComponent): boolean;
var
  i : integer;
begin
  Result := False;

  if assigned(FMonitors) and assigned(FComponents) then
    begin
      i := FMonitors.IndexOf(aHandle);
      if (i >= 0) then
        begin
          aComponent := TComponent(FComponents[i]);
          Result     := True;
        end;
    end;
end;

function TTesseractLoader.InternalRegisterMonitor(const aHandle: PETEXT_DESC; const aComponent : TComponent): boolean;
var
  i : integer;
begin
  Result := False;

  if assigned(FMonitors) and assigned(FComponents) then
    begin
      i := FMonitors.IndexOf(aHandle);
      if (i < 0) then
        begin
          FMonitors.Add(aHandle);
          FComponents.Add(aComponent);
          Result := True;
        end;
    end;
end;

function TTesseractLoader.InternalUnregisterMonitor(const aHandle: PETEXT_DESC): boolean;
var
  i : integer;
begin
  Result := False;

  if assigned(FMonitors) and assigned(FComponents) then
    begin
      i := FMonitors.IndexOf(aHandle);
      if (i >= 0) then
        begin
          FMonitors.Delete(i);
          FComponents.Delete(i);
          Result := True;
        end;
    end;
end;

initialization

finalization
  DestroyGlobalTesseractLoader;

end.

