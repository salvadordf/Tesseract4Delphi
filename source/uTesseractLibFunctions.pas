unit uTesseractLibFunctions;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF TARGET_64BITS}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 4}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows,{$ENDIF} System.Classes,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes, {$IFDEF FPC}{$IFDEF LINUX}lcltype,{$ENDIF}{$ENDIF}
  {$ENDIF}
  uTesseractTypes, uLeptonicaTypes;

var
  {* General free functions *}
  TessVersion                               : function(): PUTF8Char; cdecl;
  TessDeleteText                            : procedure(const text: PUTF8Char); cdecl;
  TessDeleteTextArray                       : procedure(arr: PPUTF8Char); cdecl;
  TessDeleteIntArray                        : procedure(const arr: PInteger); cdecl;

  {* Renderer API *}
  TessTextRendererCreate                    : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessHOcrRendererCreate                    : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessHOcrRendererCreate2                   : function(const outputbase: PUTF8Char; font_info: BOOL): TessResultRenderer; cdecl;
  TessAltoRendererCreate                    : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessPAGERendererCreate                    : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessTsvRendererCreate                     : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessPDFRendererCreate                     : function(const outputbase: PUTF8Char; const datadir: PUTF8Char; textonly: BOOL): TessResultRenderer; cdecl;
  TessUnlvRendererCreate                    : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessBoxTextRendererCreate                 : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessLSTMBoxRendererCreate                 : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TessWordStrBoxRendererCreate              : function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;

  TessDeleteResultRenderer                  : procedure(renderer: TessResultRenderer); cdecl;
  TessResultRendererInsert                  : procedure(renderer: TessResultRenderer; next: TessResultRenderer); cdecl;
  TessResultRendererNext                    : function(renderer: TessResultRenderer): TessResultRenderer; cdecl;
  TessResultRendererBeginDocument           : function(renderer: TessResultRenderer; const title: PUTF8Char): BOOL; cdecl;
  TessResultRendererAddImage                : function(renderer: TessResultRenderer; api: TessBaseAPI): BOOL; cdecl;
  TessResultRendererEndDocument             : function(renderer: TessResultRenderer): BOOL; cdecl;

  TessResultRendererExtention               : function(renderer: TessResultRenderer): PUTF8Char; cdecl;
  TessResultRendererTitle                   : function(renderer: TessResultRenderer): PUTF8Char; cdecl;
  TessResultRendererImageNum                : function(renderer: TessResultRenderer): Integer; cdecl;

  {* Base API *}
  TessBaseAPICreate                         : function(): TessBaseAPI; cdecl;
  TessBaseAPIDelete                         : procedure(handle: TessBaseAPI); cdecl;

  TessBaseAPISetInputName                   : procedure(handle: TessBaseAPI; const name: PUTF8Char); cdecl;
  TessBaseAPIGetInputName                   : function(handle: TessBaseAPI): PUTF8Char; cdecl;

  TessBaseAPISetInputImage                  : procedure(handle: TessBaseAPI; const pix: PPix); cdecl;
  TessBaseAPIGetInputImage                  : function(handle: TessBaseAPI): PPix; cdecl;

  TessBaseAPIGetSourceYResolution           : function(handle: TessBaseAPI): Integer; cdecl;
  TessBaseAPIGetDatapath                    : function(handle: TessBaseAPI): PUTF8Char; cdecl;

  TessBaseAPISetOutputName                  : procedure(handle: TessBaseAPI; const name: PUTF8Char); cdecl;

  TessBaseAPISetVariable                    : function(handle: TessBaseAPI; const name: PUTF8Char; const value: PUTF8Char): BOOL; cdecl;
  TessBaseAPISetDebugVariable               : function(handle: TessBaseAPI; const name: PUTF8Char; const value: PUTF8Char): BOOL; cdecl;

  TessBaseAPIGetIntVariable                 : function(const handle: TessBaseAPI; const name: PUTF8Char; out value: Integer): BOOL; cdecl;
  TessBaseAPIGetBoolVariable                : function(const handle: TessBaseAPI; const name: PUTF8Char; out value: BOOL): BOOL; cdecl;
  TessBaseAPIGetDoubleVariable              : function(const handle: TessBaseAPI; const name: PUTF8Char; out value: double): BOOL; cdecl;
  TessBaseAPIGetStringVariable              : function(const handle: TessBaseAPI; const name: PUTF8Char): PUTF8Char; cdecl;

  TessBaseAPIPrintVariables                 : procedure(const handle: TessBaseAPI; fp: PFileDescriptor); cdecl;
  TessBaseAPIPrintVariablesToFile           : function(const handle: TessBaseAPI; const filename: PUTF8Char): BOOL; cdecl;

  TessBaseAPIInit1                          : function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode; configs: PPUTF8Char; configs_size: Integer): Integer; cdecl;
  TessBaseAPIInit2                          : function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode): Integer; cdecl;
  TessBaseAPIInit3                          : function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char): Integer; cdecl;
  TessBaseAPIInit4                          : function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode; configs: PPUTF8Char; configs_size: Integer; vars_vec, vars_values: PPUTF8Char; vars_vec_size: NativeUInt; set_only_non_debug_params: BOOL): Integer; cdecl;
  TessBaseAPIInit5                          : function(handle: TessBaseAPI; const data: Pointer; data_size: Integer; const language: PUTF8Char; mode: TessOcrEngineMode; configs: PPUTF8Char; configs_size: Integer; vars_vec, vars_values: PPUTF8Char; vars_vec_size: NativeUInt; set_only_non_debug_params: BOOL): Integer; cdecl;

  TessBaseAPIGetInitLanguagesAsString       : function(const handle: TessBaseAPI): PUTF8Char; cdecl;
  TessBaseAPIGetLoadedLanguagesAsVector     : function(const handle: TessBaseAPI): PPUTF8Char; cdecl;
  TessBaseAPIGetAvailableLanguagesAsVector  : function(const handle: TessBaseAPI): PPUTF8Char; cdecl;

  TessBaseAPIInitForAnalysePage             : procedure(handle: TessBaseAPI); cdecl;

  TessBaseAPIReadConfigFile                 : procedure(handle: TessBaseAPI; const filename: PUTF8Char); cdecl;
  TessBaseAPIReadDebugConfigFile            : procedure(handle: TessBaseAPI; const filename: PUTF8Char); cdecl;

  TessBaseAPISetPageSegMode                 : procedure(handle: TessBaseAPI; mode: TessPageSegMode); cdecl;
  TessBaseAPIGetPageSegMode                 : function(handle: TessBaseAPI): TessPageSegMode; cdecl;

  TessBaseAPIRect                           : function(handle: TessBaseAPI; const imagedata: PByte; bytes_per_pixel: Integer; bytes_per_line: Integer; left: Integer; top: Integer; width: Integer; height: Integer): PUTF8Char; cdecl;

  TessBaseAPIClearAdaptiveClassifier        : procedure(handle: TessBaseAPI); cdecl;

  TessBaseAPISetImage                       : procedure(handle: TessBaseAPI; const imagedata: PByte; width: Integer; height: Integer; bytes_per_pixel: Integer; bytes_per_line: Integer); cdecl;
  TessBaseAPISetImage2                      : procedure(handle: TessBaseAPI; pix: PPix); cdecl;

  TessBaseAPISetSourceResolution            : procedure(handle: TessBaseAPI; ppi: Integer); cdecl;

  TessBaseAPISetRectangle                   : procedure(handle: TessBaseAPI; left: Integer; top: Integer; width: Integer; height: Integer); cdecl;

  TessBaseAPIGetThresholdedImage            : function(handle: TessBaseAPI): PPix; cdecl;
  TessBaseAPIGetGradient                    : function(handle: TessBaseAPI): Single; cdecl;
  TessBaseAPIGetRegions                     : function(handle: TessBaseAPI; out pixa: PPixa): PBoxa; cdecl;
  TessBaseAPIGetTextlines                   : function(handle: TessBaseAPI; out pixa: PPixa; blockids: PPInteger): PBoxa; cdecl;
  TessBaseAPIGetTextlines1                  : function(handle: TessBaseAPI; const raw_image: BOOL; const raw_padding: Integer; out pixa: PPixa; blockids, paraids: PPInteger): PBoxa; cdecl;
  TessBaseAPIGetStrips                      : function(handle: TessBaseAPI; out pixa: PPixa; blockids: PPInteger): PBoxa; cdecl;
  TessBaseAPIGetWords                       : function(handle: TessBaseAPI; out pixa: PPixa): PBoxa; cdecl;
  TessBaseAPIGetConnectedComponents         : function(handle: TessBaseAPI; out cc: PPixa): PBoxa; cdecl;
  TessBaseAPIGetComponentImages             : function(handle: TessBaseAPI; level: TessPageIteratorLevel; text_only: BOOL; out pixa: PPixa; blockids: PPInteger): PBoxa; cdecl;
  TessBaseAPIGetComponentImages1            : function(handle: TessBaseAPI; level: TessPageIteratorLevel; text_only: BOOL; raw_image: BOOL; raw_padding: Integer; out pixa: PPixa; blockids, paraids: PPInteger): PBoxa; cdecl;

  TessBaseAPIGetThresholdedImageScaleFactor : function(const handle: TessBaseAPI): Integer; cdecl;

  TessBaseAPIAnalyseLayout                  : function(handle: TessBaseAPI): TessPageIterator; cdecl;

  TessBaseAPIRecognize                      : function(handle: TessBaseAPI; monitor: PETEXT_DESC): Integer; cdecl;

  TessBaseAPIProcessPages                   : function(handle: TessBaseAPI; const filename: PUTF8Char; const retry_config: PUTF8Char; timeout_millisec: Integer; renderer: TessResultRenderer): BOOL; cdecl;
  TessBaseAPIProcessPage                    : function(handle: TessBaseAPI; pix: PPix; page_index: Integer; const filename: PUTF8Char; const retry_config: PUTF8Char; timeout_millisec: Integer; renderer: TessResultRenderer): BOOL; cdecl;

  TessBaseAPIGetIterator                    : function(handle: TessBaseAPI): TessResultIterator; cdecl;
  TessBaseAPIGetMutableIterator             : function(handle: TessBaseAPI): TessMutableIterator; cdecl;    // ******************

  TessBaseAPIGetUTF8Text                    : function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TessBaseAPIGetHOCRText                    : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetAltoText                    : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetPAGEText                    : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetTsvText                     : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetBoxText                     : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetLSTMBoxText                 : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;
  TessBaseAPIGetWordStrBoxText              : function(handle: TessBaseAPI; page_number: Integer): PUTF8Char; cdecl;

  TessBaseAPIGetUNLVText                    : function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TessBaseAPIMeanTextConf                   : function(handle: TessBaseAPI): Integer; cdecl;

  TessBaseAPIAllWordConfidences             : function(handle: TessBaseAPI): PInteger; cdecl;

  TessBaseAPIAdaptToWordStr                 : function(handle: TessBaseAPI; mode: TessPageSegMode; const wordstr: PUTF8Char): BOOL; cdecl;

  TessBaseAPIClear                          : procedure(handle: TessBaseAPI); cdecl;
  TessBaseAPIEnd                            : procedure(handle: TessBaseAPI); cdecl;

  TessBaseAPIIsValidWord                    : function(handle: TessBaseAPI; const word: PUTF8Char): Integer; cdecl;
  TessBaseAPIGetTextDirection               : function(handle: TessBaseAPI; out out_offset: Integer; out out_slope: single): BOOL; cdecl;

  TessBaseAPIGetUnichar                     : function(handle: TessBaseAPI; unichar_id: Integer): PUTF8Char; cdecl;
  TessBaseAPIClearPersistentCache           : procedure(handle: TessBaseAPI); cdecl;
  TessBaseAPIDetectOrientationScript        : function(handle: TessBaseAPI; out orient_deg: Integer; out orient_conf: Single; out script_name: PUTF8Char; out script_conf: Single): BOOL; cdecl;

  TessBaseAPISetMinOrientationMargin        : procedure(handle: TessBaseAPI; margin: double); cdecl;
  TessBaseAPINumDawgs                       : function(handle: TessBaseAPI): Integer; cdecl;
  TessBaseAPIOem                            : function(handle: TessBaseAPI): TessOcrEngineMode; cdecl;
  TessBaseGetBlockTextOrientations          : procedure(handle: TessBaseAPI; out block_orientation: Pinteger; out vertical_writing: PBOOL); cdecl;

  {* Page iterator *}
  TessPageIteratorDelete                    : procedure(handle: TessPageIterator); cdecl;
  TessPageIteratorCopy                      : function(const handle: TessPageIterator): TessPageIterator; cdecl;
  TessPageIteratorBegin                     : procedure(handle: TessPageIterator); cdecl;
  TessPageIteratorNext                      : function(handle: TessPageIterator; level: TessPageIteratorLevel): BOOL; cdecl;
  TessPageIteratorIsAtBeginningOf           : function(const handle: TessPageIterator; level: TessPageIteratorLevel): BOOL; cdecl;
  TessPageIteratorIsAtFinalElement          : function(const handle: TessPageIterator; level: TessPageIteratorLevel; element: TessPageIteratorLevel): BOOL; cdecl;
  TessPageIteratorBoundingBox               : function(const handle: TessPageIterator; level: TessPageIteratorLevel; out left: Integer; out top: Integer; out right: Integer; out bottom: Integer): BOOL; cdecl;
  TessPageIteratorBlockType                 : function(const handle: TessPageIterator): TessPolyBlockType; cdecl;
  TessPageIteratorGetBinaryImage            : function(const handle: TessPageIterator; level: TessPageIteratorLevel): PPix; cdecl;
  TessPageIteratorGetImage                  : function(const handle: TessPageIterator; level: TessPageIteratorLevel; padding: Integer; original_image: PPix; out left: Integer; out top: Integer): PPix; cdecl;
  TessPageIteratorBaseline                  : function(const handle: TessPageIterator; level: TessPageIteratorLevel; out x1: Integer; out y1: Integer; out x2: Integer; out y2: Integer): BOOL; cdecl;
  TessPageIteratorOrientation               : procedure(handle: TessPageIterator; out orientation: TessOrientation; out writing_direction: TessWritingDirection; out textline_order: TessTextlineOrder; out deskew_angle: single); cdecl;
  TessPageIteratorParagraphInfo             : procedure(handle: TessPageIterator; out justification: TessParagraphJustification; out is_list_item: BOOL; out is_crown: BOOL; out first_line_indent: Integer); cdecl;

  {* Result iterator *}
  TessResultIteratorDelete                  : procedure(handle: TessResultIterator); cdecl;
  TessResultIteratorCopy                    : function(const handle: TessResultIterator): TessResultIterator; cdecl;
  TessResultIteratorGetPageIterator         : function(const handle: TessResultIterator): TessPageIterator; cdecl;
  TessResultIteratorGetPageIteratorConst    : function(const handle: TessResultIterator): TessPageIterator; cdecl;
  TessResultIteratorGetChoiceIterator       : function(const handle: TessResultIterator): TessChoiceIterator; cdecl;

  TessResultIteratorNext                    : function(handle: TessResultIterator; level: TessPageIteratorLevel): BOOL; cdecl;
  TessResultIteratorGetUTF8Text             : function(const handle: TessResultIterator; level: TessPageIteratorLevel): PUTF8Char; cdecl;
  TessResultIteratorConfidence              : function(const handle: TessResultIterator; level: TessPageIteratorLevel): single; cdecl;
  TessResultIteratorWordRecognitionLanguage : function(const handle: TessResultIterator): PUTF8Char; cdecl;
  TessResultIteratorWordFontAttributes      : function(const handle: TessResultIterator; out is_bold: BOOL; out is_italic: BOOL; out is_underlined: BOOL; out is_monospace: BOOL; out is_serif: BOOL; out is_smallcaps: BOOL; out pointsize: Integer; out font_id: Integer): PUTF8Char; cdecl;

  TessResultIteratorWordIsFromDictionary    : function(const handle: TessResultIterator): BOOL; cdecl;
  TessResultIteratorWordIsNumeric           : function(const handle: TessResultIterator): BOOL; cdecl;
  TessResultIteratorSymbolIsSuperscript     : function(const handle: TessResultIterator): BOOL; cdecl;
  TessResultIteratorSymbolIsSubscript       : function(const handle: TessResultIterator): BOOL; cdecl;
  TessResultIteratorSymbolIsDropcap         : function(const handle: TessResultIterator): BOOL; cdecl;

  {* Choice iterator *}
  TessChoiceIteratorDelete                  : procedure(handle: TessChoiceIterator); cdecl;
  TessChoiceIteratorNext                    : function(handle: TessChoiceIterator): BOOL; cdecl;
  TessChoiceIteratorGetUTF8Text             : function(const handle: TessChoiceIterator): PUTF8Char; cdecl;
  TessChoiceIteratorConfidence              : function(const handle: TessChoiceIterator): single; cdecl;

  {* Progress monitor *}
  TessMonitorCreate                         : function(): PETEXT_DESC; cdecl;
  TessMonitorDelete                         : procedure(monitor: PETEXT_DESC); cdecl;
  TessMonitorSetCancelFunc                  : procedure(monitor: PETEXT_DESC; cancelFunc: TessCancelFunc); cdecl;
  TessMonitorSetCancelThis                  : procedure(monitor: PETEXT_DESC; cancelThis: Pointer); cdecl;
  TessMonitorGetCancelThis                  : function(monitor: PETEXT_DESC): Pointer; cdecl;
  TessMonitorSetProgressFunc                : procedure(monitor: PETEXT_DESC; progressFunc: TessProgressFunc); cdecl;
  TessMonitorGetProgress                    : function(monitor: PETEXT_DESC): Integer; cdecl;
  TessMonitorSetDeadlineMSecs               : procedure(monitor: PETEXT_DESC; deadline: Integer); cdecl;

implementation

end.
