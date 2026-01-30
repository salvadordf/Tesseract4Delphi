unit uTesseractBaseAPI;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF FPC}{$IFNDEF DELPHI12_UP}
  // Workaround for "Internal error" in old Delphi versions
  {$R-}
{$ENDIF}{$ENDIF}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows,{$ENDIF} System.Classes, System.SysUtils,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes, SysUtils,
  {$ENDIF}
  uTesseractTypes, uLeptonicaTypes, uTesseractLibFunctions, uLeptonicaPix,
  uLeptonicaBoxArray, uLeptonicaPixArray, uTesseractIntegerArray,
  uTesseractPageIterator, uTesseractResultIterator, uTesseractMonitor;

type
  TTesseractResultRenderer = class;

  /// <summary>
  /// <para>Base class for all tesseract APIs.</para>
  /// <para>Specific classes can add ability to work on different inputs or produce
  /// different outputs.</para>
  /// <para>This class is mostly an interface layer on top of the Tesseract instance
  /// class to hide the data types so that users of this class don't have to
  /// include any other Tesseract headers.</para>
  /// </summary>
  TTesseractBaseAPI = class
    private
      FHandle       : TessBaseAPI;
      FInit         : boolean;
      FErrorMessage : string;

      procedure SetInputName(const name_ : string);
      procedure SetInputImage(const pix : TLeptonicaPix);
      procedure SetOutputName(const name_ : string);
      procedure SetPageSegMode(mode: TessPageSegMode);

      function  GetInitialized : boolean;
      function  GetVersion : string;
      function  GetInputName : string;
      function  GetInputImage : TLeptonicaPix;
      function  GetSourceYResolution : integer;
      function  GetDatapath : string;
      function  GetInitLanguagesAsString : string;
      function  GetPageSegMode : TessPageSegMode;
      function  GetThresholdedImage : TLeptonicaPix;
      function  GetGradient : single;
      function  GetThresholdedImageScaleFactor : integer;
      function  GetIterator : TTesseractResultIterator;

    public
      constructor Create; overload;
      constructor Create(aHandle: TessBaseAPI); overload;
      destructor  Destroy; override;
      /// <summary>
      /// <para>Set the value of an internal "parameter."</para>
      /// <para>Supply the name of the parameter and the value as a string, just as
      /// you would in a config file.</para>
      /// <para>Returns false if the name lookup failed.</para>
      /// <para>Eg SetVariable("tessedit_char_blacklist", "xyz"); to ignore x, y and z.
      /// Or SetVariable("classify_bln_numeric_mode", "1"); to set numeric-only mode.
      /// SetVariable may be used before Init, but settings will revert to
      /// defaults on End().</para>
      /// <para>Note: Must be called after Init(). Only works for non-init variables
      /// (init variables should be passed to Init()).</para>
      /// </summary>
      function    SetVariable(const name_, value_ : string) : boolean;
      function    SetDebugVariable(const name_, value_ : string) : boolean;
      /// <summary>
      /// Returns true if the parameter was found among Tesseract parameters. Fills in value_ with the value of the parameter.
      /// </summary>
      function    GetIntVariable(const name_ : string; out value_ : Integer) : boolean;
      /// <summary>
      /// Returns true if the parameter was found among Tesseract parameters. Fills in value_ with the value of the parameter.
      /// </summary>
      function    GetBoolVariable(const name_ : string; out value_ : boolean) : boolean;
      /// <summary>
      /// Returns true if the parameter was found among Tesseract parameters. Fills in value_ with the value of the parameter.
      /// </summary>
      function    GetDoubleVariable(const name_ : string; out value_ : double) : boolean;
      /// <summary>
      /// Returns the string that represents the value of the parameter if it was found among Tesseract parameters.
      /// </summary>
      function    GetStringVariable(const name_ : string) : string;
      /// <summary>
      /// Print Tesseract parameters to the given file.
      /// </summary>
      function    PrintVariables(fp: PFileDescriptor) : boolean;
      /// <summary>
      /// Print Tesseract parameters to the given file.
      /// </summary>
      function    PrintVariablesToFile(const filename : string) : boolean;
      /// <summary>
      /// <para>Start tesseract. Returns true on success and false on failure.</para>
      ///
      /// <para>Instances are now mostly thread-safe and totally independent,
      /// but some global parameters remain. Basically it is safe to use multiple
      /// TessBaseAPIs in different threads in parallel, UNLESS:
      /// you use SetVariable on some of the Params in classify and textord.
      /// If you do, then the effect will be to change it for all your instances.</para>
      ///
      /// <para>The datapath must be the name of the tessdata directory.</para>
      ///
      /// <para>The language is (usually) an ISO 639-3 string or empty will default to
      /// eng. It is entirely safe (and eventually will be efficient too) to call
      /// Init multiple times on the same instance to change language, or just
      /// to reset the classifier.</para>
      ///
      /// <para>The language may be a string of the form [~]<lang>[+[~]<lang>]* indicating
      /// that multiple languages are to be loaded. Eg hin+eng will load Hindi and
      /// English. Languages may specify internally that they want to be loaded
      /// with one or more other languages, so the ~ sign is available to override
      /// that. Eg if hin were set to load eng by default, then hin+~eng would force
      /// loading only hin. The number of loaded languages is limited only by
      /// memory, with the caveat that loading additional languages will impact
      /// both speed and accuracy, as there is more work to do to decide on the
      /// applicable language, and there is more chance of hallucinating incorrect
      /// words.</para>
      ///
      /// <para>WARNING: On changing languages, all Tesseract parameters are reset
      /// back to their default values. (Which may vary between languages.)
      /// If you have a rare need to set a Variable that controls
      /// initialization for a second call to Init you should explicitly
      /// call End() and then use SetVariable before Init. This is only a very
      /// rare use case, since there are very few uses that require any parameters
      /// to be set before Init.</para>
      ///
      /// <para>If set_only_non_debug_params is true, only params that do not contain
      /// "debug" in the name will be set.</para>
      /// </summary>
      function    Init(const datapath, language: string; mode: TessOcrEngineMode; const configs, vars_vec, vars_values: TStringList; set_only_non_debug_params: boolean) : boolean; overload;
      /// <summary>
      /// In-memory version reads the trained data file directly from the given data stream, and/or reads data via a FileReader.
      /// </summary>
      function    Init(const data: TStream; const language: string; mode: TessOcrEngineMode; const configs, vars_vec, vars_values: TStringList; set_only_non_debug_params: boolean) : boolean; overload;
      function    Init(const datapath, language: string; oem: TessOcrEngineMode; const configs: TStringList = nil) : boolean; overload;
      function    Init(const datapath, language: string) : boolean; overload;
      /// <summary>
      /// Init only for page layout analysis. Use only for calls to SetImage and
      /// AnalysePage. Calls that attempt recognition will generate an error.
      /// </summary>
      function    InitForAnalysePage : boolean;
      /// <summary>
      /// Returns the loaded languages in the TStringList.
      /// Includes all languages loaded by the last Init, including those loaded
      /// as dependencies of other loaded languages.
      /// </summary>
      function    GetLoadedLanguagesAsVector : TStringList;
      /// <summary>
      /// Returns the available languages in the sorted TStringList.
      /// </summary>
      function    GetAvailableLanguagesAsVector : TStringList;
      /// <summary>
      /// Returns true if a language is loaded.
      /// </summary>
      function    IsLanguageLoaded(const aLanguage: string): Boolean;
      /// <summary>
      /// <para>Read a "config" file containing a set of param, value pairs.
      /// Searches the standard places: tessdata/configs, tessdata/tessconfigs
      /// and also accepts a relative or absolute path name.</para>
      /// <para>Note: only non-init params will be set (init params are set by Init()).</para>
      /// </summary>
      function    ReadConfigFile(const filename : string) : boolean;
      /// <summary>
      /// Same as above, but only set debug params from the given config file.
      /// </summary>
      function    ReadDebugConfigFile(const filename : string) : boolean;
      /// <summary>
      /// <para>Recognize a rectangle from an image and return the result as a string.
      /// May be called many times for a single Init.</para>
      /// <para>Currently has no error checking.</para>
      /// <para>Greyscale of 8 and color of 24 or 32 bits per pixel may be given.
      /// Palette color images will not work properly and must be converted to
      /// 24 bit.</para>
      /// <para>Binary images of 1 bit per pixel may also be given but they must be
      /// byte packed with the MSB of the first byte being the first pixel, and a
      /// 1 represents WHITE. For binary images set bytes_per_pixel=0.
      /// The recognized text is returned as a char* which is coded
      /// as a string.</para>
      ///
      /// <para>Note that TesseractRect is the simplified convenience interface.
      /// For advanced uses, use SetImage, (optionally) SetRectangle, Recognize,
      /// and one or more of the Get*Text functions below.</para>
      /// </summary>
      function    TesseractRect(const imagedata: TStream; bytes_per_pixel, bytes_per_line, left, top, width, height: Integer) : string;
      /// <summary>
      /// Call between pages or documents etc to free up memory and forget adaptive data.
      /// </summary>
      function    ClearAdaptiveClassifier : boolean;
      /// <summary>
      /// <para>Provide an image for Tesseract to recognize. Format is as
      /// TesseractRect above. Copies the image buffer and converts to Pix.</para>
      /// <para>SetImage clears all recognition results, and sets the rectangle to the
      /// full image, so it may be followed immediately by a GetUTF8Text, and it
      /// will automatically perform recognition.</para>
      /// </summary>
      function    SetImage(const imagedata: TStream; width, height, bytes_per_pixel, bytes_per_line: Integer) : boolean; overload;
      function    SetImage(const imagedata: TStream) : boolean; overload;
      /// <summary>
      /// <para>Provide an image for Tesseract to recognize. As with SetImage above,
      /// Tesseract takes its own copy of the image, so it need not persist until
      /// after Recognize.</para>
      /// <para>Pix vs raw, which to use?
      /// Use Pix where possible. Tesseract uses Pix as its internal representation
      /// and it is therefore more efficient to provide a Pix directly.</para>
      /// </summary>
      function    SetImage(const pix: TLeptonicaPix) : boolean; overload;
      /// <summary>
      /// Provide an image for Tesseract to recognize.
      /// </summary>
      function    SetImage(const aFilename : string) : boolean; overload;
      /// <summary>
      /// Set the resolution of the source image in pixels per inch so font size
      /// information can be calculated in results.  Call this after SetImage().
      /// </summary>
      function    SetSourceResolution(ppi: Integer) : boolean;
      /// <summary>
      /// Restrict recognition to a sub-rectangle of the image. Call after SetImage.
      /// Each SetRectangle clears the recogntion results so multiple rectangles
      /// can be recognized with the same image.
      /// </summary>
      function    SetRectangle(left, top, width, height: Integer) : boolean;
      /// <summary>
      /// Get the result of page layout analysis as a leptonica-style
      /// Boxa, Pixa pair, in reading order. Can be called before or after Recognize.
      /// </summary>
      function    GetRegions(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
      /// <summary>
      /// <para>Get the textlines as a leptonica-style Boxa, Pixa pair, in reading order.</para>
      /// <para>Can be called before or after Recognize.</para>
      ///
      /// <para>If raw_image is true, then extract from the original image instead of the
      /// thresholded image and pad by raw_padding pixels.</para>
      ///
      /// <para>If blockids is not nullptr, the block-id of each line is also returned as
      /// an array of one element per line.</para>
      ///
      /// <para>If paraids is not nullptr, the paragraph-id of each line within its block is also returned as
      /// an array of one element per line.</para>
      /// </summary>
      function    GetTextlines(raw_image: boolean; raw_padding: integer; var pixs : TLeptonicaPixClassArray; var blockids, paraids : TIntegerArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// Helper method to extract from the thresholded image.
      /// </summary>
      function    GetTextlines(var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// Helper method to extract from the thresholded image.
      /// </summary>
      function    GetTextlines(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// <para>Get textlines and strips of image regions as a leptonica-style Boxa, Pixa
      /// pair, in reading order. Enables downstream handling of non-rectangular
      /// regions.</para>
      /// <para>Can be called before or after Recognize.</para>
      /// <para>If blockids is not nullptr, the block-id of each line is also returned as
      /// an array of one element per line.</para>
      /// </summary>
      function    GetStrips(var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// Helper method to get textlines and strips of image regions.
      /// </summary>
      function    GetStrips(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// Get the words as a leptonica-style Boxa, Pixa pair, in reading order.
      /// Can be called before or after Recognize.
      /// </summary>
      function    GetWords(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
      /// <summary>
      /// Gets the individual connected (text) components (created
      /// after pages segmentation step, but before recognition)
      /// as a leptonica-style Boxa, Pixa pair, in reading order.
      /// Can be called before or after Recognize.
      /// </summary>
      function    GetConnectedComponents(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
      /// <summary>
      /// <para>Get the given level kind of components (block, textline, word etc.) as a
      /// leptonica-style Boxa, Pixa pair, in reading order.</para>
      ///
      /// <para>Can be called before or after Recognize.</para>
      ///
      /// <para>If blockids is not nullptr, the block-id of each component is also returned
      /// as an array of one element per component.</para>
      ///
      /// <para>If blockids is not nullptr, the paragraph-id of each component with its
      /// block is also returned as an array of one element per component.</para>
      ///
      /// <para>If raw_image is true, then portions of the original image are
      /// extracted instead of the thresholded image and padded with raw_padding.</para>
      ///
      /// <para>If text_only is true, then only text components are returned.</para>
      /// </summary>
      function    GetComponentImages(level: TessPageIteratorLevel; text_only, raw_image: boolean; raw_padding: Integer; var pixs : TLeptonicaPixClassArray; var blockids, paraids : TIntegerArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// Helper function to get binary images with no padding (most common usage).
      /// </summary>
      function    GetComponentImages(level: TessPageIteratorLevel; text_only: boolean; var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean; overload;
      /// <summary>
      /// <para>Runs page layout analysis in the mode set by PageSegMode.
      /// May optionally be called prior to Recognize to get access to just
      /// the page layout results. Returns an iterator to the results.</para>
      /// <para>If merge_similar_words is true, words are combined where suitable for use
      /// with a line recognizer. Use if you want to use AnalyseLayout to find the
      /// textlines, and then want to process textline fragments with an external
      /// line recognizer.</para>
      /// <para>Returns nullptr on error or an empty page.</para>
      /// <para>The returned iterator must be deleted after use.</para>
      /// <para>WARNING! This class points to data held within the TessBaseAPI class, and
      /// therefore can only be used while the TessBaseAPI class still exists and
      /// has not been subjected to a call of Init, SetImage, Recognize, Clear, End
      /// DetectOS, or anything else that changes the internal PAGE_RES.</para>
      /// </summary>
      function    AnalyseLayout : TTesseractPageIterator;
      /// <summary>
      /// Recognize the image from SetAndThresholdImage, generating Tesseract
      /// internal structures.
      /// Optional. The Get*Text functions below will call Recognize if needed.
      /// After Recognize, the output is kept internally until the next SetImage.
      /// </summary>
      function    Recognize(const monitor : TTesseractMonitor = nil) : boolean;
      /// <summary>
      /// <para>Turns images into symbolic text.</para>
      ///
      /// <para>filename can point to a single image, a multi-page TIFF,
      /// or a plain text list of image filenames.</para>
      ///
      /// <para>retry_config is useful for debugging. If not nullptr, you can fall
      /// back to an alternate configuration if a page fails for some
      /// reason.</para>
      ///
      /// <para>timeout_millisec terminates processing if any single page
      /// takes too long. Set to 0 for unlimited time.</para>
      ///
      /// <para>renderer is responsible for creating the output. For example,
      /// use the TessTextRenderer if you want plaintext output, or
      /// the TessPDFRender to produce searchable PDF.</para>
      ///
      /// <para>If tessedit_page_number is non-negative, will only process that
      /// single page. Works for multi-page tiff file, or filelist.</para>
      ///
      /// <para>Returns true if successful, false on error.</para>
      /// </summary>
      function    ProcessPages(const filename, retry_config: string; timeout_millisec: Integer; const renderer: TTesseractResultRenderer) : boolean;
      /// <summary>
      /// <para>Turn a single image into symbolic text.</para>
      ///
      /// <para>The pix is the image processed. filename and page_index are
      /// metadata used by side-effect processes, such as reading a box
      /// file or formatting as hOCR.</para>
      ///
      /// <para>See ProcessPages for descriptions of other parameters.</para>
      /// </summary>
      function    ProcessPage(var pix: TLeptonicaPix; page_index: Integer; const filename, retry_config: string; timeout_millisec: Integer; const renderer: TTesseractResultRenderer) : boolean;
      /// <summary>
      /// The recognized text is returned as a text string.
      /// </summary>
      function    GetText : string;
      /// <summary>
      /// The recognized text is returned as a UTF8 string.
      /// </summary>
      function    GetUTF8Text : UTF8String;
      /// <summary>
      /// Make a HTML-formatted string with hOCR markup from the internal
      /// data structures.
      /// page_number is 0-based but will appear in the output as 1-based.
      /// </summary>
      function    GetHOCRText(page_number: Integer) : string;
      /// <summary>
      /// Make an XML-formatted string with Alto markup from the internal data structures.
      /// </summary>
      function    GetAltoText(page_number: Integer) : string;
      /// <summary>
      /// Make an XML-formatted string with PAGE markup from the internal data structures.
      /// </summary>
      function    GetPAGEText(page_number: Integer) : string;
      /// <summary>
      /// Make a TSV-formatted string from the internal data structures.
      /// page_number is 0-based but will appear in the output as 1-based.
      /// </summary>
      function    GetTsvText(page_number: Integer) : string;
      /// <summary>
      /// The recognized text is returned as a char* which is coded in the same
      /// format as a box file used in training.
      /// Constructs coordinates in the original image - not just the rectangle.
      /// page_number is a 0-based page index that will appear in the box file.
      /// </summary>
      function    GetBoxText(page_number: Integer) : string;
      /// <summary>
      /// Make a box file for LSTM training from the internal data structures.
      /// Constructs coordinates in the original image - not just the rectangle.
      /// page_number is a 0-based page index that will appear in the box file.
      /// </summary>
      function    GetLSTMBoxText(page_number: Integer) : string;
      /// <summary>
      /// The recognized text is returned as a char* which is coded in the same
      /// format as a WordStr box file used in training.
      /// page_number is a 0-based page index that will appear in the box file.
      /// </summary>
      function    GetWordStrBoxText(page_number: Integer) : string;
      /// <summary>
      /// The recognized text is returned as a char* which is coded
      /// as UNLV format Latin-1 with specific reject and suspect codes.
      /// </summary>
      function    GetUNLVText : string;
      /// <summary>
      /// Returns the (average) confidence value between 0 and 100.
      /// </summary>
      function    MeanTextConf : integer;
      /// <summary>
      /// Returns all word confidences (between 0 and 100) in an array.
      /// The number of confidences should correspond to the number of space-
      /// delimited words in GetUTF8Text.
      /// </summary>
      function    AllWordConfidences(var confidences : TIntegerArray) : boolean;
      /// <summary>
      /// <para>Applies the given word to the adaptive classifier if possible.
      /// The word must be SPACE-DELIMITED UTF-8 - l i k e t h i s , so it can
      /// tell the boundaries of the graphemes.</para>
      /// <para>Assumes that SetImage/SetRectangle have been used to set the image
      /// to the given word. The mode arg should be PSM_SINGLE_WORD or
      /// PSM_CIRCLE_WORD, as that will be used to control layout analysis.</para>
      /// <para>The currently set PageSegMode is preserved.</para>
      /// <para>Returns false if adaption was not possible for some reason.</para>
      /// </summary>
      function    AdaptToWordStr(mode: TessPageSegMode; const wordstr: string) : boolean;
      /// <summary>
      /// Free up recognition results and any stored image data, without actually
      /// freeing any recognition data that would be time-consuming to reload.
      /// Afterwards, you must call SetImage or TesseractRect before doing
      /// any Recognize or Get* operation.
      /// </summary>
      procedure   Clear;
      /// <summary>
      /// <para>Close down tesseract and free up all memory. End() is equivalent to
      /// destructing and reconstructing your TessBaseAPI.</para>
      /// <para>Once End() has been used, none of the other API functions may be used
      /// other than Init and anything declared above it in the class definition.</para>
      /// </summary>
      procedure   End_;
      /// <summary>
      /// <para>Check whether a word is valid according to Tesseract's language model.</para>
      /// <para>Returns 0 if the word is invalid, non-zero if valid.</para>
      /// <para>Warning temporary! This function will be removed from here and placed
      /// in a separate API at some future time.</para>
      /// </summary>
      function    IsValidWord(const word : string) : boolean;
      /// <summary>
      /// Calculate offset and slope in Tesseract coordinates.
      /// </summary>
      function    GetTextDirection(out out_offset: Integer; out out_slope: single) : boolean;
      /// <summary>
      /// This method returns the string form of the specified unichar.
      /// </summary>
      function    GetUnichar(unichar_id: Integer): string;
      /// <summary>
      /// Clear any library-level memory caches.
      /// There are a variety of expensive-to-load constant data structures (mostly
      /// language dictionaries) that are cached globally -- surviving the Init()
      /// and End() of individual TessBaseAPI's.  This function allows the clearing
      /// of these caches.
      /// </summary>
      procedure   ClearPersistentCache;
      /// <summary>
      /// Detect the orientation of the input image and apparent script (alphabet).
      /// orient_deg is the detected clockwise rotation of the input image in degrees
      /// (0, 90, 180, 270)
      /// orient_conf is the confidence (15.0 is reasonably confident)
      /// script_name is an ASCII string, the name of the script, e.g. "Latin"
      /// script_conf is confidence level in the script
      /// Returns true on success and writes values to each parameter as an output
      /// </summary>
      function    DetectOrientationScript(out orient_deg: Integer; out orient_conf: Single; out script_name: string; out script_conf: Single) : boolean;
      /// <summary>
      /// Min acceptable orientation margin (difference in scores between top and 2nd
      /// choice in OSResults::orientations) to believe the page orientation.
      /// </summary>
      procedure   SetMinOrientationMargin(margin: double);
      /// <summary>
      /// Return the number of dawgs loaded into tesseract_ object.
      /// </summary>
      function    NumDawgs : integer;
      /// <summary>
      /// Last ocr language mode requested.
      /// </summary>
      function    Oem : TessOcrEngineMode;
      /// <summary>
      /// <para>Return text orientation of each block as determined in an earlier page layout
      /// analysis operation. Orientation is returned as the number of ccw 90-degree
      /// rotations (in [0..3]) required to make the text in the block upright
      /// (readable). Note that this may not necessary be the block orientation
      /// preferred for recognition (such as the case of vertical CJK text).</para>
      ///
      /// <para>Also returns whether the text in the block is believed to have vertical
      /// writing direction (when in an upright page orientation).</para>
      ///
      /// <para>The returned array is of length equal to the number of text blocks, which may
      /// be less than the total number of blocks. The ordering is intended to be
      /// consistent with GetTextLines().</para>
      /// </summary>
      function    GetBlockTextOrientations(var block_orientation: TIntegerArray; var vertical_writing: TBooleanArray) : boolean;

      property Handle                      : TessBaseAPI               read FHandle;
      /// <summary>
      /// Returns true when this instance is fully initialized.
      /// </summary>
      property Initialized                 : boolean                   read GetInitialized;
      /// <summary>
      /// Returns the version identifier as a static string.
      /// </summary>
      property Version                     : string                    read GetVersion;
      /// <summary>
      /// Set the name of the input file. Needed for training and
      /// reading a UNLV zone file, and for searchable PDF output.
      /// </summary>
      property InputName                   : string                    read GetInputName                               write SetInputName;
      /// <summary>
      /// Input pix.
      /// </summary>
      property InputImage                  : TLeptonicaPix             read GetInputImage                              write SetInputImage;
      property SourceYResolution           : integer                   read GetSourceYResolution;
      /// <summary>
      /// Path to the tessdata directory.
      /// </summary>
      property Datapath                    : string                    read GetDatapath;
      /// <summary>
      /// Set the name of the bonus output files. Needed only for debugging.
      /// </summary>
      property OutputName                  : string                    write SetOutputName;
      /// <summary>
      /// Returns the languages string used in the last valid initialization.
      /// If the last initialization specified "deu+hin" then that will be
      /// returned. If hin loaded eng automatically as well, then that will
      /// not be included in this list. To find the languages actually
      /// loaded use GetLoadedLanguagesAsVector.
      /// </summary>
      property InitLanguagesAsString       : string                    read GetInitLanguagesAsString;
      /// <summary>
      /// Set the current page segmentation mode. Defaults to PSM_SINGLE_BLOCK.
      /// The mode is stored as an IntParam so it can also be modified by
      /// ReadConfigFile or SetVariable("tessedit_pageseg_mode", mode as string).
      /// </summary>
      property PageSegMode                 : TessPageSegMode           read GetPageSegMode                             write SetPageSegMode;
      /// <summary>
      /// Get a copy of the internal thresholded image from Tesseract.
      /// Caller takes ownership of the Pix and must pixDestroy it.
      /// May be called any time after SetImage, or after TesseractRect.
      /// </summary>
      property ThresholdedImage            : TLeptonicaPix             read GetThresholdedImage;
      /// <summary>
      /// Return average gradient of lines on page.
      /// </summary>
      property Gradient                    : single                    read GetGradient;
      /// <summary>
      /// Returns the scale factor of the thresholded image that would be returned by
      /// GetThresholdedImage() and the various GetX() methods that call
      /// GetComponentImages().
      /// Returns 0 if no thresholder has been set.
      /// </summary>
      property ThresholdedImageScaleFactor : integer                   read GetThresholdedImageScaleFactor; 
      /// <summary>
      /// Get a reading-order iterator to the results of LayoutAnalysis and/or
      /// Recognize. The returned iterator must be deleted after use.
      /// WARNING! This class points to data held within the TessBaseAPI class, and
      /// therefore can only be used while the TessBaseAPI class still exists and
      /// has not been subjected to a call of Init, SetImage, Recognize, Clear, End
      /// DetectOS, or anything else that changes the internal PAGE_RES.
      /// </summary>
      property Iterator                    : TTesseractResultIterator  read GetIterator;
      /// <summary>
      /// Error message if there's an issue initializing this class.
      /// </summary>
      property ErrorMessage                : string                    read FErrorMessage;
  end;

  /// <summary>
  /// <para>Interface for rendering tesseract results into a document, such as text,
  /// HOCR or pdf. This class is abstract. Specific classes handle individual
  /// formats. This interface is then used to inject the renderer class into
  /// tesseract when processing images.</para>
  ///
  /// <para>For simplicity implementing this with tesseract version 3.01,
  /// the renderer contains document state that is cleared from document
  /// to document just as the TessBaseAPI is. This way the base API can just
  /// delegate its rendering functionality to injected renderers, and the
  /// renderers can manage the associated state needed for the specific formats
  /// in addition to the heuristics for producing it.</para>
  /// </summary>
  TTesseractResultRenderer = class
    private
      FHandle : TessResultRenderer;

      function GetInitialized : boolean;

    public
      constructor Create(aHandle : TessResultRenderer);
      destructor  Destroy; override;
      /// <summary>
      /// Takes ownership of pointer so must be new'd instance.
      /// Renderers aren't ordered, but appends the sequences of next parameter
      /// and existing next(). The renderers should be unique across both lists.
      /// </summary>
      function    Insert(const next: TTesseractResultRenderer) : boolean;
      /// <summary>
      /// Returns the next renderer or nullptr.
      /// </summary>
      function    Next : TTesseractResultRenderer;
      /// <summary>
      /// Starts a new document with the given title.
      /// This clears the contents of the output data.
      /// </summary>
      function    BeginDocument(const title : string) : boolean;
      /// <summary>
      /// <para>Adds the recognized text from the source image to the current document.
      /// Invalid if BeginDocument not yet called.</para>
      /// <para>Note that this API is a bit weird but is designed to fit into the
      /// current TessBaseAPI implementation where the api has lots of state
      /// information that we might want to add in.</para>
      /// </summary>
      function    AddImage(const api : TTesseractBaseAPI) : boolean;
      /// <summary>
      /// Finishes the document and finalizes the output data
      /// Invalid if BeginDocument not yet called.
      /// </summary>
      function    EndDocument : boolean;
      /// <summary>
      /// file extension to be used for output files. For example "pdf" will
      /// produce a .pdf file, and "hocr" will produce .hocr files.
      /// </summary>
      function    FileExtension : string;
      function    Title : string;
      /// <summary>
      /// <para>Returns the index of the last image given to AddImage
      /// (i.e. images are incremented whether the image succeeded or not)</para>
      /// <para>This is always defined. It means either the number of the
      /// current image, the last image ended, or in the completed document
      /// depending on when in the document lifecycle you are looking at it.</para>
      /// <para>Will return -1 if a document was never started.</para>
      /// </summary>
      function    ImageNum : integer;

      property Handle       : TessResultRenderer  read FHandle;
      /// <summary>
      /// Returns true when this instance is fully initialized.
      /// </summary>
      property Initialized  : boolean             read GetInitialized;
  end;

  /// <summary>
  /// Renders tesseract output into a plain text string.
  /// </summary>
  TTesseractTextRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders tesseract output into an hocr text string.
  /// </summary>
  TTesseractHOcrRenderer = class(TTesseractResultRenderer)
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
    public
      constructor Create(const outputbase : string); overload;
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      /// <param name="font_info">Whether to print font information.</param>
      constructor Create(const outputbase : string; font_info : boolean); overload;
  end;

  /// <summary>
  /// Renders tesseract output into an alto text string.
  /// </summary>
  TTesseractAltoRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders Tesseract output into a PAGE XML text string.
  /// </summary>
  TTesseractPAGERenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders Tesseract output into a TSV string.
  /// </summary>
  TTesseractTsvRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders tesseract output into searchable PDF.
  /// </summary>
  TTesseractPDFRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      /// <param name="datadir">datadir is the location of the TESSDATA. We need it because we load a custom PDF font from this location. Where to find the custom font.</param>
      /// <param name="textonly">skip images if set</param>
      constructor Create(const outputbase, datadir : string; textonly : boolean);
  end;

  /// <summary>
  /// Renders tesseract output into a plain text string.
  /// </summary>
  TTesseractUnlvRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders tesseract output into a plain text string.
  /// </summary>
  TTesseractBoxTextRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders tesseract output into a plain text string for LSTMBox.
  /// </summary>
  TTesseractLSTMBoxRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

  /// <summary>
  /// Renders tesseract output into a plain text string in WordStr format.
  /// </summary>
  TTesseractWordStrBoxRenderer = class(TTesseractResultRenderer)
    public
      /// <summary>
      /// Creates a renderer instance.
      /// </summary>
      /// <param name="outputbase">outputbase is the name of the output file excluding extension. For example, "/path/to/chocolate-chip-cookie-recipe"</param>
      constructor Create(const outputbase : string);
  end;

implementation

uses
  uTesseractMiscFunctions, uTesseractLoader;

constructor TTesseractBaseAPI.Create(aHandle: TessChoiceIterator);
begin
  inherited Create;

  FInit   := False;
  FHandle := aHandle;

  if (FHandle = nil) then
    FErrorMessage := 'The Tesseract BaseAPI handle is not initialized.';
end;

constructor TTesseractBaseAPI.Create;
begin
  if assigned(GlobalTesseractLoader) and GlobalTesseractLoader.Initialized then
    Create(TessBaseAPICreate())
   else
    Create(nil);
end;

destructor TTesseractBaseAPI.Destroy;
begin
  if Initialized then
    begin
      TessBaseAPIDelete(FHandle);
      FHandle := nil;
    end;

  inherited Destroy;
end;

procedure TTesseractBaseAPI.SetInputName(const name_ : string);
begin
  if Initialized then
    TessBaseAPISetInputName(FHandle, PUTF8Char(StringToTessUTF8(name_)));
end;

procedure TTesseractBaseAPI.SetInputImage(const pix : TLeptonicaPix);
begin
  if Initialized and assigned(pix) and pix.Initialized then
    TessBaseAPISetInputImage(FHandle, pix.Pix);
end;

procedure TTesseractBaseAPI.SetOutputName(const name_ : string);
begin
  if Initialized then
    TessBaseAPISetOutputName(FHandle, PUTF8Char(StringToTessUTF8(name_)));
end;

procedure TTesseractBaseAPI.SetPageSegMode(mode: TessPageSegMode);
begin
  if Initialized then
    TessBaseAPISetPageSegMode(FHandle, mode);
end;

function TTesseractBaseAPI.SetVariable(const name_, value_ : string) : boolean;
begin
  Result := Initialized and
            TessBaseAPISetVariable(FHandle, PUTF8Char(StringToTessUTF8(name_)), PUTF8Char(StringToTessUTF8(value_)));
end;

function TTesseractBaseAPI.SetDebugVariable(const name_, value_ : string) : boolean;
begin
  Result := Initialized and
            TessBaseAPISetDebugVariable(FHandle, PUTF8Char(StringToTessUTF8(name_)), PUTF8Char(StringToTessUTF8(value_)));
end;

function TTesseractBaseAPI.GetInitialized : boolean;
begin
  Result := FInit and (FHandle <> nil);
end;

function TTesseractBaseAPI.GetVersion : string;
begin
  Result := TessUTF8ToString(TessVersion());
end;

function TTesseractBaseAPI.GetInputName : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetInputName(FHandle))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetInputImage : TLeptonicaPix;
var
  TempPix : PPix;
begin
  Result := nil;

  if Initialized then
    begin
      TempPix := TessBaseAPIGetInputImage(FHandle);

      if assigned(TempPix) then
        Result := TLeptonicaPix.Create(TempPix);
    end;
end;

function TTesseractBaseAPI.GetSourceYResolution : integer;
begin
  if Initialized then
    Result := TessBaseAPIGetSourceYResolution(FHandle)
   else
    Result := 0;
end;

function TTesseractBaseAPI.GetDatapath : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetDatapath(FHandle))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetInitLanguagesAsString : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetInitLanguagesAsString(FHandle))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetPageSegMode : TessPageSegMode;
begin
  if Initialized then
    Result := TessBaseAPIGetPageSegMode(FHandle)
   else
    Result := PSM_SINGLE_BLOCK;
end;

function TTesseractBaseAPI.GetLoadedLanguagesAsVector : TStringList;
var
  Languages: PPUTF8Char;
  LangPtr: PUTF8Char;
begin
  Result := nil;

  if Initialized then
  begin
    Languages := TessBaseAPIGetLoadedLanguagesAsVector(FHandle);
    if Assigned(Languages) then
    begin
      Result := TStringList.Create;
      LangPtr := Languages^;

      while Assigned(LangPtr) do
      begin
        Result.Add(TessUTF8ToString(LangPtr, False));
        Inc(Languages);
        LangPtr := Languages^;
      end;

      Dec(Languages, Result.Count);
      TessDeleteTextArray(Languages);
    end;
  end;
end;

function TTesseractBaseAPI.GetAvailableLanguagesAsVector : TStringList;
var
  Languages: PPUTF8Char;
  LangPtr: PUTF8Char;
begin
  Result := nil;

  if Initialized then
  begin
    Languages := TessBaseAPIGetAvailableLanguagesAsVector(FHandle);
    if Assigned(Languages) then
    begin
      Result := TStringList.Create;
      LangPtr := Languages^;

      while Assigned(LangPtr) do
      begin
        Result.Add(TessUTF8ToString(LangPtr, False));
        Inc(Languages);
        LangPtr := Languages^;
      end;

      Dec(Languages, Result.Count);
      TessDeleteTextArray(Languages);
    end;
  end;
end;

function TTesseractBaseAPI.IsLanguageLoaded(const aLanguage: string): Boolean;
var
  TempLanguages : TStringList;
begin
  TempLanguages := GetAvailableLanguagesAsVector();

  if assigned(TempLanguages) then
    begin
      Result := (TempLanguages.IndexOf(aLanguage) >= 0);
      TempLanguages.Free;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.InitForAnalysePage : boolean;
begin
  if Initialized then
    begin
      TessBaseAPIInitForAnalysePage(FHandle);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.ReadConfigFile(const filename : string) : boolean;
begin
  if Initialized then
    begin
      TessBaseAPIReadConfigFile(FHandle, PUTF8Char(StringToTessUTF8(filename)));
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.ReadDebugConfigFile(const filename : string) : boolean;
begin
  if Initialized then
    begin
      TessBaseAPIReadDebugConfigFile(FHandle, PUTF8Char(StringToTessUTF8(filename)));
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.TesseractRect(const imagedata: TStream; bytes_per_pixel, bytes_per_line, left, top, width, height: Integer) : string;
var
  TempBuffer : pointer;
begin
  if Initialized and assigned(imagedata) and (imagedata.Size > 0) then
    begin
      TempBuffer := AllocMem(imagedata.Size);
      imagedata.Seek(0, soBeginning);
      imagedata.ReadBuffer(TempBuffer^, imagedata.Size);
      Result := TessUTF8ToString(TessBaseAPIRect(FHandle, TempBuffer, bytes_per_pixel, bytes_per_line, left, top, width, height));
      FreeMem(TempBuffer);
    end
   else
    Result := '';
end;

function TTesseractBaseAPI.SetImage(const imagedata: TStream; width, height, bytes_per_pixel, bytes_per_line: Integer) : boolean;
var
  TempBuffer : pointer;
begin
  if Initialized and assigned(imagedata) and (imagedata.Size > 0) then
    begin
      TempBuffer := AllocMem(imagedata.Size);
      imagedata.Seek(0, soBeginning);
      imagedata.ReadBuffer(TempBuffer^, imagedata.Size);
      TessBaseAPISetImage(FHandle, TempBuffer, width, height, bytes_per_pixel, bytes_per_line);
      Result := True;
      FreeMem(TempBuffer);
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.SetImage(const pix: TLeptonicaPix) : boolean;
begin
  if Initialized and assigned(pix) and pix.Initialized then
    begin
      TessBaseAPISetImage2(FHandle, pix.Pix);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.SetImage(const aFilename : string) : boolean;
var
  TempImg : TLeptonicaPix;
begin
  TempImg := TLeptonicaPix.Create(aFilename);
  Result  := SetImage(TempImg);
  TempImg.Free;
end;

function TTesseractBaseAPI.SetImage(const imagedata: TStream): boolean;
var
  TempImg : TLeptonicaPix;
begin
  TempImg := TLeptonicaPix.Create(imagedata);
  Result  := SetImage(TempImg);
  TempImg.Free;
end;

function TTesseractBaseAPI.SetSourceResolution(ppi: Integer) : boolean;
begin
  if Initialized then
    begin
      TessBaseAPISetSourceResolution(FHandle, ppi);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.SetRectangle(left, top, width, height: Integer) : boolean;
begin
  if Initialized then
    begin
      TessBaseAPISetRectangle(FHandle, left, top, width, height);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.GetRegions(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
var
  TempPixa : PPixa;
  TempBoxa : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetRegions(FHandle, TempPixa);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetTextlines(var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean;
var
  TempPixa : PPixa;
  TempBoxa : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
  TempIntArray : PInteger;
  i : integer;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetTextlines(FHandle, TempPixa, @TempIntArray);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          if (length(pixs) > 0) and assigned(TempIntArray) then
            begin
              SetLength(blockids, length(pixs));

              for i := 0 to pred(length(pixs)) do
                begin
                  blockids[i] := TempIntArray^;
                  inc(TempIntArray);
                end;

              TessDeleteIntArray(TempIntArray);
            end;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetTextlines(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
var
  TempPixa : PPixa;
  TempBoxa : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetTextlines(FHandle, TempPixa, nil);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetTextlines(raw_image: boolean; raw_padding: integer; var pixs : TLeptonicaPixClassArray; var blockids, paraids : TIntegerArray; var boxes : TRectArray) : boolean;
var
  TempPixa         : PPixa;
  TempBoxa         : PBoxa;
  TempBlockids     : PInteger;
  TempParaids      : PInteger;
  TempPixArray     : TLeptonicaPixArray;
  TempBoxArray     : TLeptonicaBoxArray;
  TempIntegerArray : TTesseractIntegerArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetTextlines1(FHandle, raw_image, raw_padding, TempPixa, @TempBlockids, @TempParaids);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          if (length(pixs) > 0) then
            begin
              if assigned(TempBlockids) then
                begin
                  TempIntegerArray := TTesseractIntegerArray.Create(TempBlockids, length(pixs));
                  TempIntegerArray.CopyToArray(blockids);
                  TempIntegerArray.Free;
                end;

              if assigned(TempParaids) then
                begin
                  TempIntegerArray := TTesseractIntegerArray.Create(TempParaids, length(pixs));
                  TempIntegerArray.CopyToArray(paraids);
                  TempIntegerArray.Free;
                end;
            end;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetStrips(var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean;
var
  TempPixa         : PPixa;
  TempBoxa         : PBoxa;
  TempBlockids     : PInteger;
  TempPixArray     : TLeptonicaPixArray;
  TempBoxArray     : TLeptonicaBoxArray;
  TempIntegerArray : TTesseractIntegerArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetStrips(FHandle, TempPixa, @TempBlockids);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          if (length(pixs) > 0) and assigned(TempBlockids) then
            begin
              TempIntegerArray := TTesseractIntegerArray.Create(TempBlockids, length(pixs));
              TempIntegerArray.CopyToArray(blockids);
              TempIntegerArray.Free;
            end;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetStrips(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
var
  TempPixa     : PPixa;
  TempBoxa     : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetStrips(FHandle, TempPixa, nil);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetWords(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
var
  TempPixa     : PPixa;
  TempBoxa     : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetWords(FHandle, TempPixa);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetConnectedComponents(var pixs : TLeptonicaPixClassArray; var boxes : TRectArray) : boolean;
var
  TempPixa     : PPixa;
  TempBoxa     : PBoxa;
  TempPixArray : TLeptonicaPixArray;
  TempBoxArray : TLeptonicaBoxArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetConnectedComponents(FHandle, TempPixa);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetComponentImages(level: TessPageIteratorLevel;
                                              text_only, raw_image: boolean;
                                              raw_padding: Integer;
                                              var pixs : TLeptonicaPixClassArray;
                                              var blockids, paraids : TIntegerArray;
                                              var boxes : TRectArray) : boolean;
var
  TempPixa         : PPixa;
  TempBoxa         : PBoxa;
  TempBlockids     : PInteger;
  TempParaids      : PInteger;
  TempPixArray     : TLeptonicaPixArray;
  TempBoxArray     : TLeptonicaBoxArray;
  TempIntegerArray : TTesseractIntegerArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetComponentImages1(FHandle, level, text_only, raw_image, raw_padding, TempPixa, @TempBlockids, @TempParaids);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          if (length(pixs) > 0) then
            begin
              if assigned(TempBlockids) then
                begin
                  TempIntegerArray := TTesseractIntegerArray.Create(TempBlockids, length(pixs));
                  TempIntegerArray.CopyToArray(blockids);
                  TempIntegerArray.Free;
                end;

              if assigned(TempParaids) then
                begin
                  TempIntegerArray := TTesseractIntegerArray.Create(TempParaids, length(pixs));
                  TempIntegerArray.CopyToArray(paraids);
                  TempIntegerArray.Free;
                end;
            end;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.GetComponentImages(level: TessPageIteratorLevel; text_only: boolean; var pixs : TLeptonicaPixClassArray; var blockids : TIntegerArray; var boxes : TRectArray) : boolean;
var
  TempPixa         : PPixa;
  TempBoxa         : PBoxa;
  TempBlockids     : PInteger;
  TempPixArray     : TLeptonicaPixArray;
  TempBoxArray     : TLeptonicaBoxArray;
  TempIntegerArray : TTesseractIntegerArray;
begin
  Result := False;

  if Initialized then
    begin
      TempBoxa := TessBaseAPIGetComponentImages(FHandle, level, text_only, TempPixa, @TempBlockids);

      if assigned(TempBoxa) and assigned(TempPixa) then
        begin
          TempPixArray := TLeptonicaPixArray.Create(TempPixa);
          TempPixArray.CopyToArray(pixs);
          TempPixArray.Free;

          TempBoxArray := TLeptonicaBoxArray.Create(TempBoxa);
          TempBoxArray.CopyToArray(boxes);
          TempBoxArray.Free;

          if (length(pixs) > 0) and assigned(TempBlockids) then
            begin
              TempIntegerArray := TTesseractIntegerArray.Create(TempBlockids, length(pixs));
              TempIntegerArray.CopyToArray(blockids);
              TempIntegerArray.Free;
            end;

          Result := True;
        end;
    end;
end;

function TTesseractBaseAPI.AnalyseLayout : TTesseractPageIterator;
var
  TempHandle : TessPageIterator;
begin
  Result := nil;

  if Initialized then
    begin
      TempHandle := TessBaseAPIAnalyseLayout(FHandle);

      if assigned(TempHandle) then
        Result := TTesseractPageIterator.Create(TempHandle);
    end;
end;

function TTesseractBaseAPI.Recognize(const monitor : TTesseractMonitor) : boolean;
var
  TempHandle : PETEXT_DESC;
begin
  if assigned(monitor) then
    TempHandle := monitor.Handle
   else
    TempHandle := nil;

  Result := Initialized and
            (TessBaseAPIRecognize(FHandle, TempHandle) = 0);
end;

function TTesseractBaseAPI.ProcessPages(const filename, retry_config: string; timeout_millisec: Integer; const renderer: TTesseractResultRenderer): boolean;
begin
  Result := Initialized and
            assigned(renderer) and
            renderer.Initialized and
            TessBaseAPIProcessPages(FHandle,
                                    PUTF8Char(StringToTessUTF8(filename)),
                                    PUTF8Char(StringToTessUTF8(retry_config)),
                                    timeout_millisec,
                                    renderer.Handle);
end;

function TTesseractBaseAPI.ProcessPage(var pix: TLeptonicaPix; page_index: Integer; const filename, retry_config: string; timeout_millisec: Integer; const renderer: TTesseractResultRenderer) : boolean;
begin
  Result := Initialized and
            assigned(renderer) and
            renderer.Initialized and
            assigned(pix) and
            pix.Initialized and
            TessBaseAPIProcessPage(FHandle,
                                   pix.Pix,
                                   page_index,
                                   PUTF8Char(StringToTessUTF8(filename)),
                                   PUTF8Char(StringToTessUTF8(retry_config)),
                                   timeout_millisec,
                                   renderer.Handle);
end;

function TTesseractBaseAPI.GetText : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetUTF8Text(FHandle))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetUTF8Text : UTF8String;
var
  TempUTF8Str : PUTF8Char;
begin
  Result := '';

  if Initialized then
    begin
      TempUTF8Str := TessBaseAPIGetUTF8Text(FHandle);
      Result := UTF8String(TempUTF8Str);
      TessDeleteText(TempUTF8Str);
    end;
end;

function TTesseractBaseAPI.GetHOCRText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetHOCRText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetAltoText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetAltoText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetPAGEText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetPAGEText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetTsvText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetTsvText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetBoxText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetBoxText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetLSTMBoxText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetLSTMBoxText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetWordStrBoxText(page_number: Integer) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetWordStrBoxText(FHandle, page_number))
   else
    Result := '';
end;

function TTesseractBaseAPI.GetUNLVText : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetUNLVText(FHandle))
   else
    Result := '';
end;

function TTesseractBaseAPI.MeanTextConf : integer;
begin
  if Initialized then
    Result := TessBaseAPIMeanTextConf(FHandle)
   else
    Result := 0;
end;

function TTesseractBaseAPI.AllWordConfidences(var confidences : TIntegerArray) : boolean;
var
  TempFirst, TempConf : PInteger;
  TempLen, i : integer;
begin
  Result := False;

  if Initialized then
    begin
      TempFirst := TessBaseAPIAllWordConfidences(FHandle);
      TempConf  := TempFirst;
      TempLen   := 0;

      while assigned(TempConf) and (TempConf^ <> -1) do
        begin
          inc(TempLen);
          inc(TempConf);
        end;

      if (TempLen > 0) then
        begin
          SetLength(confidences, TempLen);
          TempConf := TempFirst;
          for i := 0 to pred(TempLen) do
            begin
              confidences[i] := TempConf^;
              inc(TempConf);
            end;
        end;

      TessDeleteIntArray(TempFirst);
    end;
end;

function TTesseractBaseAPI.AdaptToWordStr(mode: TessPageSegMode; const wordstr: string) : boolean;
begin
  Result := Initialized and
            TessBaseAPIAdaptToWordStr(FHandle, mode, PUTF8Char(StringToTessUTF8(wordstr)));
end;

procedure TTesseractBaseAPI.Clear;
begin
  if Initialized then
    TessBaseAPIClear(FHandle);
end;

procedure TTesseractBaseAPI.End_;
begin
  if Initialized then
    TessBaseAPIEnd(FHandle);
end;

function TTesseractBaseAPI.IsValidWord(const word : string) : boolean;
begin
  Result := Initialized and
            (TessBaseAPIIsValidWord(FHandle, PUTF8Char(StringToTessUTF8(word))) <> 0);
end;

function TTesseractBaseAPI.GetTextDirection(out out_offset: Integer; out out_slope: single) : boolean;
begin
  Result := Initialized and
            TessBaseAPIGetTextDirection(FHandle, out_offset, out_slope);
end;

function TTesseractBaseAPI.GetUnichar(unichar_id: Integer): string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetUnichar(FHandle, unichar_id))
   else
    Result := '';
end;

procedure TTesseractBaseAPI.ClearPersistentCache;
begin
  if Initialized then
    TessBaseAPIClearPersistentCache(FHandle);
end;

function TTesseractBaseAPI.DetectOrientationScript(out orient_deg: Integer; out orient_conf: Single; out script_name: string; out script_conf: Single) : boolean;
var
  TempScriptName : PUTF8Char;
begin
  Result := False;
  if Initialized and TessBaseAPIDetectOrientationScript(FHandle, orient_deg, orient_conf, TempScriptName, script_conf) then
    begin
      script_name := TessUTF8ToString(TempScriptName);
      Result := True;
    end;
end;

procedure TTesseractBaseAPI.SetMinOrientationMargin(margin: double);
begin
  if Initialized then
    TessBaseAPISetMinOrientationMargin(FHandle, margin);
end;

function TTesseractBaseAPI.NumDawgs : integer;
begin
  if Initialized then
    Result := TessBaseAPINumDawgs(FHandle)
   else
    Result := 0;
end;

function TTesseractBaseAPI.Oem : TessOcrEngineMode;
begin
  if Initialized then
    Result := TessBaseAPIOem(FHandle)
   else
    Result := OEM_DEFAULT;
end;

function TTesseractBaseAPI.GetBlockTextOrientations(var block_orientation: TIntegerArray; var vertical_writing: TBooleanArray) : boolean;
var
  TempBlockOrientation, TempInta : PInteger;
  TempVertical, TempBoola : PBOOL;
  TempLen, i : integer;
begin
  Result := False;

  if Initialized then
    begin
      TessBaseGetBlockTextOrientations(FHandle, TempBlockOrientation, TempVertical);

      TempLen  := 0;
      TempInta := TempBlockOrientation;
      while assigned(TempInta) do
        begin
          inc(TempLen);
          inc(TempInta);
        end;

      if (TempLen > 0) then
        begin
          SetLength(block_orientation, TempLen);
          TempInta := TempBlockOrientation;
          for i := 0 to pred(TempLen) do
            begin
              block_orientation[i] := TempInta^;
              inc(TempInta);
            end;

          SetLength(vertical_writing, TempLen);
          TempBoola := TempVertical;
          for i := 0 to pred(TempLen) do
            begin
              vertical_writing[i] := TempBoola^;
              inc(TempBoola);
            end;
        end;

      TessDeleteIntArray(TempBlockOrientation);
      TessDeleteIntArray(PInteger(TempVertical));
    end;
end;

function TTesseractBaseAPI.GetThresholdedImage : TLeptonicaPix;
var
  TempPix : PPix;
begin
  Result := nil;

  if Initialized then
    begin
      TempPix := TessBaseAPIGetThresholdedImage(FHandle);

      if assigned(TempPix) then
        Result := TLeptonicaPix.Create(TempPix);
    end;
end;

function TTesseractBaseAPI.GetGradient : single;
begin
  if Initialized then
    Result := TessBaseAPIGetGradient(FHandle)
   else
    Result := 0;
end;

function TTesseractBaseAPI.GetThresholdedImageScaleFactor : integer;
begin
  if Initialized then
    Result := TessBaseAPIGetThresholdedImageScaleFactor(FHandle)
   else
    Result := 0;
end;

function TTesseractBaseAPI.GetIterator : TTesseractResultIterator;
var
  TempHandle : TessResultIterator;
begin
  Result := nil;

  if Initialized then
    begin
      TempHandle := TessBaseAPIGetIterator(FHandle);

      if assigned(TempHandle) then
        Result := TTesseractResultIterator.Create(TempHandle);
    end;
end;

function TTesseractBaseAPI.ClearAdaptiveClassifier : boolean;
begin
  if Initialized then
    begin
      TessBaseAPIClearAdaptiveClassifier(FHandle);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.GetIntVariable(const name_ : string; out value_ : Integer) : boolean;
begin
  Result := Initialized and
            TessBaseAPIGetIntVariable(FHandle, PUTF8Char(StringToTessUTF8(name_)), value_);
end;

function TTesseractBaseAPI.GetBoolVariable(const name_ : string; out value_ : boolean) : boolean;
var
  TempValue : BOOL;
begin
  Result := False;

  if Initialized and TessBaseAPIGetBoolVariable(FHandle, PUTF8Char(StringToTessUTF8(name_)), TempValue) then
    begin
      value_ := TempValue;
      Result := True;
    end;
end;

function TTesseractBaseAPI.GetDoubleVariable(const name_ : string; out value_ : double) : boolean;
begin
  Result := Initialized and
            TessBaseAPIGetDoubleVariable(FHandle, PUTF8Char(StringToTessUTF8(name_)), value_);
end;

function TTesseractBaseAPI.GetStringVariable(const name_ : string) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessBaseAPIGetStringVariable(FHandle, PUTF8Char(StringToTessUTF8(name_))))
   else
    Result := '';
end;

function TTesseractBaseAPI.PrintVariables(fp: PFileDescriptor) : boolean;
begin
  if Initialized then
    begin
      TessBaseAPIPrintVariables(FHandle, fp);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractBaseAPI.PrintVariablesToFile(const filename : string) : boolean;
begin
  Result := Initialized and
            TessBaseAPIPrintVariablesToFile(FHandle, PUTF8Char(StringToTessUTF8(filename)));
end;

function TTesseractBaseAPI.Init(const datapath, language: string; oem: TessOcrEngineMode; const configs: TStringList) : boolean;
var
  TempArray : array of AnsiString;
  TempSize, i : integer;
begin
  Result := False;
  if (FHandle = nil) or FInit then exit;

  if assigned(configs) then
    TempSize := configs.Count
   else
    TempSize := 0;

  if (TempSize > 0) then
    begin
      SetLength(TempArray, TempSize);

      for i := 0 to pred(TempSize) do
        TempArray[i] := StringToTessUTF8(configs[i]) + #0;

      Result := (TessBaseAPIInit1(FHandle, PUTF8Char(StringToTessUTF8(datapath)), PUTF8Char(StringToTessUTF8(language)), oem, PPUTF8Char(TempArray), TempSize) = 0);
    end
   else
    Result := (TessBaseAPIInit2(FHandle, PUTF8Char(StringToTessUTF8(datapath)), PUTF8Char(StringToTessUTF8(language)), oem) = 0);

  FInit := Result;

  if not(FInit) then
    FErrorMessage := 'There was an issue initializing the Tesseract BaseAPI class.';
end;

function TTesseractBaseAPI.Init(const datapath, language: string) : boolean;
begin
  Result := False;
  if (FHandle = nil) or FInit then exit;

  Result := (TessBaseAPIInit3(FHandle, PUTF8Char(StringToTessUTF8(datapath)), PUTF8Char(StringToTessUTF8(language))) = 0);
  FInit  := Result;           

  if not(FInit) then
    FErrorMessage := 'There was an issue initializing the Tesseract BaseAPI class.';
end;

function TTesseractBaseAPI.Init(const datapath, language: string; mode: TessOcrEngineMode; const configs, vars_vec, vars_values: TStringList; set_only_non_debug_params: boolean) : boolean;
var
  TempConfigsArray, TempVarsVecArray, TempVarsValuesArray : array of AnsiString;
  TempConfigsSize, TempVarsVecSize, TempVarsValuesSize, i : integer;
begin
  Result := False;
  if (FHandle = nil) or FInit then exit;

  if assigned(configs) then
    TempConfigsSize := configs.Count
   else
    TempConfigsSize := 0;

  if assigned(vars_vec) then
    TempVarsVecSize := vars_vec.Count
   else
    TempVarsVecSize := 0;

  if assigned(vars_values) then
    TempVarsValuesSize := vars_values.Count
   else
    TempVarsValuesSize := 0;

  if (TempVarsVecSize <> TempVarsValuesSize) then exit;

  if (TempVarsVecSize = 0) then
    begin
      Result := Init(datapath, language, mode, configs);
      exit;
    end;

  if (TempConfigsSize > 0) then
    begin
      SetLength(TempConfigsArray, TempConfigsSize);

      for i := 0 to pred(TempConfigsSize) do
        TempConfigsArray[i] := StringToTessUTF8(configs[i]) + #0;
    end
   else
    TempConfigsArray := nil;

  SetLength(TempVarsVecArray, TempVarsVecSize);

  for i := 0 to pred(TempVarsVecSize) do
    TempVarsVecArray[i] := StringToTessUTF8(vars_vec[i]) + #0;

  SetLength(TempVarsValuesArray, TempVarsValuesSize);

  for i := 0 to pred(TempVarsValuesSize) do
    TempVarsValuesArray[i] := StringToTessUTF8(vars_values[i]) + #0;

  Result := (TessBaseAPIInit4(FHandle,
                              PUTF8Char(StringToTessUTF8(datapath)),
                              PUTF8Char(StringToTessUTF8(language)),
                              mode,
                              PPUTF8Char(TempConfigsArray),
                              TempConfigsSize,
                              PPUTF8Char(TempVarsVecArray),
                              PPUTF8Char(TempVarsValuesArray),
                              TempVarsVecSize,
                              set_only_non_debug_params) = 0);

  FInit := Result;         

  if not(FInit) then
    FErrorMessage := 'There was an issue initializing the Tesseract BaseAPI class.';
end;

function TTesseractBaseAPI.Init(const data: TStream; const language: string; mode: TessOcrEngineMode; const configs, vars_vec, vars_values: TStringList; set_only_non_debug_params: boolean) : boolean;
var
  TempConfigsArray, TempVarsVecArray, TempVarsValuesArray : array of AnsiString;
  TempConfigsSize, TempVarsVecSize, TempVarsValuesSize, i, TempBufferSize : integer;
  TempBuffer : pointer;
begin
  Result := False;
  if (FHandle = nil) or FInit then exit;

  if assigned(configs) then
    TempConfigsSize := configs.Count
   else
    TempConfigsSize := 0;

  if assigned(vars_vec) then
    TempVarsVecSize := vars_vec.Count
   else
    TempVarsVecSize := 0;

  if assigned(vars_values) then
    TempVarsValuesSize := vars_values.Count
   else
    TempVarsValuesSize := 0;

  if (TempVarsVecSize <> TempVarsValuesSize) then exit;

  if (TempConfigsSize > 0) then
    begin
      SetLength(TempConfigsArray, TempConfigsSize);

      for i := 0 to pred(TempConfigsSize) do
        TempConfigsArray[i] := StringToTessUTF8(configs[i]) + #0;
    end
   else
    TempConfigsArray := nil;

  if (TempVarsVecSize > 0) then
    begin
      SetLength(TempVarsVecArray, TempVarsVecSize);

      for i := 0 to pred(TempVarsVecSize) do
        TempVarsVecArray[i] := StringToTessUTF8(vars_vec[i]) + #0;
    end
   else
    TempVarsVecArray := nil;

  if (TempVarsValuesSize > 0) then
    begin
      SetLength(TempVarsValuesArray, TempVarsValuesSize);

      for i := 0 to pred(TempVarsValuesSize) do
        TempVarsValuesArray[i] := StringToTessUTF8(vars_values[i]) + #0;
    end
   else
    TempVarsValuesArray := nil;

  if assigned(data) and (data.Size > 0) then
    begin
      TempBufferSize := data.Size;
      TempBuffer     := AllocMem(TempBufferSize);
      data.Seek(0, soBeginning);
      data.ReadBuffer(TempBuffer^, TempBufferSize);
    end
   else
    begin
      TempBuffer     := nil;
      TempBufferSize := 0;
    end;

  Result := (TessBaseAPIInit5(FHandle,
                              TempBuffer,
                              TempBufferSize,
                              PUTF8Char(StringToTessUTF8(language)),
                              mode,
                              PPUTF8Char(TempConfigsArray),
                              TempConfigsSize,
                              PPUTF8Char(TempVarsVecArray),
                              PPUTF8Char(TempVarsValuesArray),
                              TempVarsVecSize,
                              set_only_non_debug_params) = 0);

  FInit := Result;       

  if not(FInit) then
    FErrorMessage := 'There was an issue initializing the Tesseract BaseAPI class.';

  if (TempBuffer <> nil) then
    FreeMem(TempBuffer);
end;


// TTesseractResultRenderer

constructor TTesseractResultRenderer.Create(aHandle : TessResultRenderer);
begin
  inherited Create;

  FHandle := aHandle;
end;

destructor TTesseractResultRenderer.Destroy;
begin
  if Initialized then
    begin
      TessDeleteResultRenderer(FHandle);
      FHandle := nil;
    end;

  inherited Destroy;
end;

function TTesseractResultRenderer.GetInitialized : boolean;
begin
  Result := (FHandle <> nil);
end;

function TTesseractResultRenderer.Insert(const next: TTesseractResultRenderer) : boolean;
begin
  if Initialized and assigned(next) and next.Initialized then
    begin
      TessResultRendererInsert(FHandle, next.Handle);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractResultRenderer.Next : TTesseractResultRenderer;
var
  TempHandle : TessResultRenderer;
begin
  Result := nil;

  if Initialized then
    begin
      TempHandle := TessResultRendererNext(FHandle);

      if assigned(TempHandle) then
        Result := TTesseractResultRenderer.Create(TempHandle);
    end;
end;

function TTesseractResultRenderer.BeginDocument(const title : string) : boolean;
begin
  Result := Initialized and
            TessResultRendererBeginDocument(FHandle, PUTF8Char(StringToTessUTF8(title)));
end;

function TTesseractResultRenderer.AddImage(const api : TTesseractBaseAPI) : boolean;
begin
  Result := Initialized and
            assigned(api) and
            api.Initialized and
            TessResultRendererAddImage(FHandle, api.Handle);
end;

function TTesseractResultRenderer.EndDocument : boolean;
begin
  Result := Initialized and
            TessResultRendererEndDocument(FHandle);
end;

function TTesseractResultRenderer.FileExtension : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessResultRendererExtention(FHandle))
   else
    Result := '';
end;

function TTesseractResultRenderer.Title : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessResultRendererTitle(FHandle))
   else
    Result := '';
end;

function TTesseractResultRenderer.ImageNum : integer;
begin
  if Initialized then
    Result := TessResultRendererImageNum(FHandle)
   else
    Result := 0;
end;


// TTesseractTextRenderer

constructor TTesseractTextRenderer.Create(const outputbase : string);
begin
  inherited Create(TessTextRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractHOcrRenderer

constructor TTesseractHOcrRenderer.Create(const outputbase : string);
begin
  inherited Create(TessHOcrRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;

constructor TTesseractHOcrRenderer.Create(const outputbase : string; font_info : boolean);
begin
  inherited Create(TessHOcrRendererCreate2(PUTF8Char(StringToTessUTF8(outputbase)), font_info));
end;


// TTesseractAltoRenderer

constructor TTesseractAltoRenderer.Create(const outputbase : string);
begin
  inherited Create(TessAltoRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractPAGERenderer

constructor TTesseractPAGERenderer.Create(const outputbase : string);
begin
  inherited Create(TessPAGERendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractTsvRenderer

constructor TTesseractTsvRenderer.Create(const outputbase : string);
begin
  inherited Create(TessTsvRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractPDFRenderer

constructor TTesseractPDFRenderer.Create(const outputbase, datadir : string; textonly : boolean);
begin
  inherited Create(TessPDFRendererCreate(PUTF8Char(StringToTessUTF8(outputbase)),
                                         PUTF8Char(StringToTessUTF8(datadir)),
                                         textonly));
end;


// TTesseractUnlvRenderer

constructor TTesseractUnlvRenderer.Create(const outputbase : string);
begin
  inherited Create(TessUnlvRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractBoxTextRenderer

constructor TTesseractBoxTextRenderer.Create(const outputbase : string);
begin
  inherited Create(TessBoxTextRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractLSTMBoxRenderer

constructor TTesseractLSTMBoxRenderer.Create(const outputbase : string);
begin
  inherited Create(TessLSTMBoxRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;


// TTesseractWordStrBoxRenderer

constructor TTesseractWordStrBoxRenderer.Create(const outputbase : string);
begin
  inherited Create(TessWordStrBoxRendererCreate(PUTF8Char(StringToTessUTF8(outputbase))));
end;

end.
