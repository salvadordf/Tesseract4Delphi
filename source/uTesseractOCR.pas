unit uTesseractOCR;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Classes, System.SysUtils, System.Types,
  {$ELSE}
    Classes, SysUtils, Types, {$IFDEF FPC}dynlibs, LResources,{$ENDIF}
  {$ENDIF}
  uTesseractTypes, uLeptonicaLoader, uTesseractLoader, uTesseractBaseAPI,
  uTesseractMonitor, uTesseractConstants;

type
  TOnCancelEvent   = procedure(Sender: TObject; words: integer; var aResult: boolean) of object;
  TOnProgressEvent = procedure(Sender: TObject; progress, left_, right_, top_, bottom_: Integer) of object;

  /// <summary>
  /// This is the main component you use in a form to handle all Tesseract
  /// methods and events.
  /// </summary>
  {$IFDEF DELPHI16_UP}[ComponentPlatformsAttribute(pfidWindows)]{$ENDIF}
  TTesseractOCR = class(TComponent)
    protected
      FBaseAPI    : TTesseractBaseAPI;
      FMonitor    : TTesseractMonitor;
      FOnCancel   : TOnCancelEvent;
      FOnProgress : TOnProgressEvent;

      function  GetInitialized : boolean;
      function  GetVersion : string;
      function  GetComponentVersion : string;

      procedure doOnCancelEvent(aWords: integer; var aResult: boolean); virtual;
      procedure doOnProgressEvent(aLeft, aRight, aTop, aBottom: integer); virtual;

      procedure InitializeLeptonica(const aLeptonicaLib : string); virtual;
      procedure InitializeTesseract(const aTesseractLib : string); virtual;
      procedure InitializeMonitor; virtual;

    public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure   BeforeDestruction; override;
      /// <summary>
      /// Initalizes all the libraries, the TTesseractBaseAPI and TTesseractMonitor instances.
      /// </summary>
      /// <param name="aLeptonicaLib">Path to the Leptonica library.</param>
      /// <param name="aTesseractLib">Path to the Tesseract library.</param>
      /// <param name="aDatapath">Path to the tessdata directory.</param>
      /// <param name="aLanguage">The language is (usually) an ISO 639-3 string or empty will default to eng.</param>
      /// <param name="aOcrEngineMode">The engine mode used for OCR.</param>
      /// <param name="aConfigs">A set of optional param, value pairs.</param>
      /// <remarks>
      /// <para>Read the documentation about TTesseractBaseAPI.Init for more information.</para>
      /// </remarks>
      function    Initialize(const aLeptonicaLib, aTesseractLib, aDatapath, aLanguage : string; aOcrEngineMode : TessOcrEngineMode = OEM_DEFAULT; const aConfigs: TStringList = nil) : boolean;
      /// <summary>
      /// Initalizes the TTesseractBaseAPI instance manually.
      /// </summary>
      /// <param name="aDatapath">Path to the tessdata directory.</param>
      /// <param name="aLanguage">The language is (usually) an ISO 639-3 string or empty will default to eng.</param>
      /// <param name="aOcrEngineMode">The engine mode used for OCR.</param>
      /// <param name="aConfigs">A set of optional param, value pairs.</param>
      /// <remarks>
      /// <para>Read the documentation about TTesseractBaseAPI.Init for more information.</para>
      /// </remarks>
      procedure   InitializeBaseAPI(const aDatapath, aLanguage : string; aOcrEngineMode : TessOcrEngineMode = OEM_DEFAULT; const aConfigs: TStringList = nil); virtual;
      /// <summary>
      /// Destroy the TTesseractBaseAPI instance manually.
      /// </summary>
      procedure   DestroyBaseAPI;
      /// <summary>
      /// Recognize the image from SetAndThresholdImage, generating Tesseract
      /// internal structures.
      /// Optional. The Get*Text functions below will call Recognize if needed.
      /// After Recognize, the output is kept internally until the next SetImage.
      /// </summary>
      function    Recognize : boolean;
      /// <summary>
      /// Returns the TTesseractBaseAPI instance.
      /// </summary>
      property    BaseAPI          : TTesseractBaseAPI    read FBaseAPI;
      /// <summary>
      /// Returns the TTesseractMonitor instance.
      /// </summary>
      property    Monitor          : TTesseractMonitor    read FMonitor;
      /// <summary>
      /// Returns true if all the loaders, the base api and the monitor are initialized.
      /// </summary>
      property    Initialized      : boolean              read GetInitialized;
      /// <summary>
      /// Returns the Tesseract4Delphi version.
      /// </summary>
      property    ComponentVersion : string               read GetComponentVersion;
      /// <summary>
      /// Returns the Tesseract version.
      /// </summary>
      property    Version          : string               read GetVersion;

    published
      /// <summary>
      /// <para>Event triggered during the call to TTesseractBaseAPI.Recognize
      /// with the number of user words found.</para>
      /// <para>Set aResult to True to cancel the operation.</para>
      /// </summary>
      property    OnCancel        : TOnCancelEvent       read FOnCancel         write FOnCancel;
      /// <summary>
      /// <para>Event triggered during the call to TTesseractBaseAPI.Recognize
      /// with information about the progress and the bounding box of the word
      /// that is currently being processed.</para>
      /// <para>Progress starts at 0 and increases to 100 during OCR.</para>
      /// </summary>
      property    OnProgress      : TOnProgressEvent     read FOnProgress       write FOnProgress;
  end;

{$IFDEF FPC}
procedure Register;
{$ENDIF}

implementation

uses
  uTesseractResultIterator, uTesseractPageIterator, uTesseractMiscFunctions;

function CancelCallback(cancel_this: Pointer; words: Integer): Boolean; cdecl;
begin
  Result := False;

  if assigned(cancel_this) then
    TTesseractOCR(cancel_this).doOnCancelEvent(words, Result);
end;

function ProgressCallback(ths: PETEXT_DESC; left, right, top, bottom: Integer): Boolean; cdecl;
var
  TempComponent : TComponent;
begin
  // TesseractOcr doesn't use the return value of this callback but it's set
  // to True in default_progress_func
  Result        := True;
  TempComponent := nil;

  if assigned(GlobalTesseractLoader) and
     GlobalTesseractLoader.InternalSearchMonitor(ths, TempComponent) then
    TTesseractOCR(TempComponent).doOnProgressEvent(left, right, top, bottom);
end;

constructor TTesseractOCR.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FBaseAPI    := nil;
  FMonitor    := nil;
  FOnCancel   := nil;
  FOnProgress := nil;
end;

destructor TTesseractOCR.Destroy;
begin
  DestroyBaseAPI;

  if assigned(FMonitor) then
    FreeAndNil(FMonitor);

  inherited Destroy;
end;

procedure TTesseractOCR.DestroyBaseAPI;
begin
  if assigned(FBaseAPI) then
    begin
      FBaseAPI.End_;
      FreeAndNil(FBaseAPI);
    end;
end;

procedure TTesseractOCR.BeforeDestruction;
begin
  if assigned(GlobalTesseractLoader) and
     assigned(FMonitor) and
     FMonitor.Initialized then
    GlobalTesseractLoader.InternalUnregisterMonitor(FMonitor.Handle);

  inherited BeforeDestruction;
end;

function TTesseractOCR.GetInitialized : boolean;
begin
  Result := assigned(GlobalLeptonicaLoader) and GlobalLeptonicaLoader.Initialized and
            assigned(GlobalTesseractLoader) and GlobalTesseractLoader.Initialized and
            assigned(FBaseAPI) and FBaseAPI.Initialized and
            assigned(FMonitor) and FMonitor.Initialized;
end;

function TTesseractOCR.GetVersion : string;
begin
  if assigned(FBaseAPI) then
    Result := FBaseAPI.Version
   else
    Result := inttostr(TESSERACT_MAJOR_VERSION) + '.' +
              inttostr(TESSERACT_MINOR_VERSION) + '.' +
              inttostr(TESSERACT_MICRO_VERSION);
end;

function TTesseractOCR.GetComponentVersion : string;
begin
  Result := inttostr(TESSERACT4DELPHI_MAJOR_VERSION)   + '.' +
            inttostr(TESSERACT4DELPHI_MINOR_VERSION)   + '.' +
            inttostr(TESSERACT4DELPHI_RELEASE_VERSION) + '.' +
            inttostr(TESSERACT4DELPHI_BUILD_VERSION);
end;

procedure TTesseractOCR.doOnCancelEvent(aWords: integer; var aResult: boolean);
begin
  if assigned(FOnCancel) then
    FOnCancel(self, aWords, aResult);
end;

procedure TTesseractOCR.doOnProgressEvent(aLeft, aRight, aTop, aBottom: integer);
begin
  if assigned(FOnProgress) then
    FOnProgress(self, FMonitor.Progress, aLeft, aRight, aTop, aBottom);
end;

procedure TTesseractOCR.InitializeLeptonica(const aLeptonicaLib : string);
begin
  if not(assigned(GlobalLeptonicaLoader)) then
    begin
      GlobalLeptonicaLoader               := TLeptonicaLoader.Create;
      GlobalLeptonicaLoader.SetCurrentDir := True;
      GlobalLeptonicaLoader.Initialize(aLeptonicaLib);
    end;
end;

procedure TTesseractOCR.InitializeTesseract(const aTesseractLib : string);
begin
  if not(assigned(GlobalTesseractLoader)) then
    begin
      GlobalTesseractLoader               := TTesseractLoader.Create;
      GlobalTesseractLoader.SetCurrentDir := True;
      GlobalTesseractLoader.Initialize(aTesseractLib);
    end;
end;

procedure TTesseractOCR.InitializeBaseAPI(const aDatapath, aLanguage : string; aOcrEngineMode: TessOcrEngineMode; const aConfigs: TStringList);
begin
  if not(assigned(FBaseAPI)) then
    begin
      FBaseAPI := TTesseractBaseAPI.Create;
      FBaseAPI.Init(aDatapath, aLanguage, aOcrEngineMode, aConfigs);
    end;
end;

procedure TTesseractOCR.InitializeMonitor;
begin
  if not(assigned(FMonitor)) then
    begin
      FMonitor            := TTesseractMonitor.Create;
      FMonitor.CancelThis := self;
      FMonitor.SetCancelFunc({$IFDEF FPC}@{$ENDIF}CancelCallback);
      FMonitor.SetProgressFunc({$IFDEF FPC}@{$ENDIF}ProgressCallback);

      GlobalTesseractLoader.InternalRegisterMonitor(FMonitor.Handle, self);
    end;
end;

function TTesseractOCR.Initialize(const aLeptonicaLib, aTesseractLib, aDatapath, aLanguage : string; aOcrEngineMode: TessOcrEngineMode; const aConfigs: TStringList) : boolean;
begin
  InitializeLeptonica(aLeptonicaLib);
  InitializeTesseract(aTesseractLib);
  InitializeBaseAPI(aDatapath, aLanguage, aOcrEngineMode, aConfigs);
  InitializeMonitor;

  Result := Initialized;
end;

function TTesseractOCR.Recognize : boolean;
begin
  Result := Initialized and
            FBaseAPI.Recognize(FMonitor);
end;

{$IFDEF FPC}
procedure Register;
begin
  {$I ttesseractocr.lrs}
  RegisterComponents('Tesseract4Delphi', [TTesseractOCR]);
end;
{$ENDIF}

end.
