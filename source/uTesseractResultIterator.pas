unit uTesseractResultIterator;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows,{$ENDIF} System.Classes,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes,
  {$ENDIF}
  uTesseractTypes, uTesseractLibFunctions, uTesseractPageIterator,
  uTesseractChoiceIterator;

type
  /// <summary>
  /// <para>Class to iterate over tesseract results, providing access to all levels
  /// of the page hierarchy, without including any tesseract headers or having
  /// to handle any tesseract structures.</para>
  ///
  /// <para>WARNING! This class points to data held within the TessBaseAPI class, and
  /// therefore can only be used while the TessBaseAPI class still exists and
  /// has not been subjected to a call of Init, SetImage, Recognize, Clear, End
  /// DetectOS, or anything else that changes the internal PAGE_RES.</para>
  ///
  /// <para>See tesseract/publictypes.h for the definition of PageIteratorLevel.
  /// See also base class PageIterator, which contains the bulk of the interface.
  /// LTRResultIterator adds text-specific methods for access to OCR output.</para>
  /// </summary>
  TTesseractResultIterator = class(TTesseractPageIterator)
    protected
      function  GetPageIterator : TTesseractPageIterator;
      function  GetChoiceIterator : TTesseractChoiceIterator;

      procedure CopyHandle(aHandle: TessPageIterator); override;

    public
      /// <summary>
      /// <para>Moves to the start of the next object at the given level in the
      /// page hierarchy, and returns false if the end of the page was reached.
      /// NOTE that RIL_SYMBOL will skip non-text blocks, but all other
      /// PageIteratorLevel level values will visit each non-text block once.</para>
      /// <para>Think of non text blocks as containing a single para, with a single line,
      /// with a single imaginary word.</para>
      /// <para>Calls to Next with different levels may be freely intermixed.
      /// This function iterates words in right-to-left scripts correctly, if
      /// the appropriate language has been loaded into Tesseract.</para>
      /// </summary>
      function Next(level: TessPageIteratorLevel) : boolean; override;
      /// <summary>
      /// Returns the text string for the current object at the given level.
      /// </summary>
      function GetText(level: TessPageIteratorLevel) : string;
      /// <summary>
      /// Returns the mean confidence of the current object at the given level.
      /// The number should be interpreted as a percent probability. (0.0f-100.0f)
      /// </summary>
      function Confidence(level: TessPageIteratorLevel) : single;
      /// <summary>
      /// Return the name of the language used to recognize this word.
      /// </summary>
      function WordRecognitionLanguage : string;
      /// <summary>
      /// <para>Returns the font attributes of the current word. If iterating at a higher
      /// level object than words, eg textlines, then this will return the
      /// attributes of the first word in that textline.</para>
      /// <para>The actual return value is a string representing a font name. It points
      /// to an internal table and SHOULD NOT BE DELETED. Lifespan is the same as
      /// the iterator itself, ie rendered invalid by various members of
      /// TessBaseAPI, including Init, SetImage, End or deleting the TessBaseAPI.
      /// Pointsize is returned in printers points (1/72 inch.)</para>
      /// </summary>
      function WordFontAttributes(out is_bold, is_italic, is_underlined, is_monospace, is_serif, is_smallcaps: boolean; out pointsize, font_id: Integer) : string;
      /// <summary>
      /// Returns true if the current word was found in a dictionary.
      /// </summary>
      function WordIsFromDictionary : boolean;
      /// <summary>
      /// Returns true if the current word is numeric.
      /// </summary>
      function WordIsNumeric : boolean;
      /// <summary>
      /// Returns true if the current symbol is a superscript.
      /// If iterating at a higher level object than symbols, eg words, then
      /// this will return the attributes of the first symbol in that word.
      /// </summary>
      function SymbolIsSuperscript : boolean;
      /// <summary>
      /// Returns true if the current symbol is a subscript.
      /// If iterating at a higher level object than symbols, eg words, then
      /// this will return the attributes of the first symbol in that word.
      /// </summary>
      function SymbolIsSubscript : boolean;
      /// <summary>
      /// Returns true if the current symbol is a dropcap.
      /// If iterating at a higher level object than symbols, eg words, then
      /// this will return the attributes of the first symbol in that word.
      /// </summary>
      function SymbolIsDropcap : boolean;
      /// <summary>
      /// Returns a TTesseractPageIterator instance. It's a copy of this iterator.
      /// It must be destroyed.
      /// </summary>
      property PageIterator     : TTesseractPageIterator     read  GetPageIterator;
      /// <summary>
      /// Returns a new TTesseractChoiceIterator instance.
      /// It must be destroyed.
      /// </summary>
      property ChoiceIterator   : TTesseractChoiceIterator   read  GetChoiceIterator;
  end;

implementation

uses              
  {$IFDEF LINUXFPC}lcltype,{$ENDIF}
  uTesseractMiscFunctions, uTesseractLoader;

procedure TTesseractResultIterator.CopyHandle(aHandle: TessPageIterator);
begin
  if assigned(GlobalTesseractLoader) and GlobalTesseractLoader.Initialized then
    FHandle := TessResultIteratorCopy(TessResultIterator(aHandle))
   else
    FHandle := nil;
end;

function TTesseractResultIterator.GetPageIterator : TTesseractPageIterator;
var
  TempHandle : TTesseractPageIterator;
begin
  Result := nil;

  if Initialized then
    begin
      TempHandle := TTesseractPageIterator(TessResultIterator(FHandle));

      if assigned(TempHandle) then
        Result := TTesseractPageIterator.Create(TempHandle);
    end;
end;

function TTesseractResultIterator.GetChoiceIterator : TTesseractChoiceIterator;
var
  TempHandle : TessChoiceIterator;
begin
  Result := nil;

  if Initialized then
    begin
      TempHandle := TessResultIteratorGetChoiceIterator(TessResultIterator(FHandle));

      if assigned(TempHandle) then
        Result := TTesseractChoiceIterator.Create(TempHandle);
    end;
end;

function TTesseractResultIterator.GetText(level: TessPageIteratorLevel) : string;
begin
  if Initialized then
    Result := TessUTF8ToString(TessResultIteratorGetUTF8Text(TessResultIterator(FHandle), level))
   else
    Result := '';
end;

function TTesseractResultIterator.Next(level: TessPageIteratorLevel) : boolean;
begin
  Result := Initialized and
            TessResultIteratorNext(TessResultIterator(FHandle), level);
end;

function TTesseractResultIterator.Confidence(level: TessPageIteratorLevel) : single;
begin
  if Initialized then
    Result := TessResultIteratorConfidence(TessResultIterator(FHandle), level)
   else
    Result := 0;
end;

function TTesseractResultIterator.WordRecognitionLanguage : string;
begin
  // The code comments for LTRResultIterator::WordRecognitionLanguage explicitly say that this
  // function must NOT delete the returned pointer.
  if Initialized then
    Result := TessUTF8ToString(TessResultIteratorWordRecognitionLanguage(TessResultIterator(FHandle)), False)
   else
    Result := '';
end;

function TTesseractResultIterator.WordFontAttributes(out is_bold, is_italic, is_underlined, is_monospace, is_serif, is_smallcaps: boolean; out pointsize, font_id: Integer) : string;
var
  TempIsBold, TempIsItalic, TempIsUnderlined, TempIsMonospace, TempIsSerif, TempIsSmallcaps : BOOL;
begin
  if Initialized then
    begin
      // The code comments for LTRResultIterator::WordFontAttributes explicitly say that this
      // function must NOT delete the returned pointer.
      Result := TessUTF8ToString(TessResultIteratorWordFontAttributes(TessResultIterator(FHandle),
                                                                      TempIsBold,
                                                                      TempIsItalic,
                                                                      TempIsUnderlined,
                                                                      TempIsMonospace,
                                                                      TempIsSerif,
                                                                      TempIsSmallcaps,
                                                                      pointsize,
                                                                      font_id), False);

      is_bold       := TempIsBold;
      is_italic     := TempIsItalic;
      is_underlined := TempIsUnderlined;
      is_monospace  := TempIsMonospace;
      is_serif      := TempIsSerif;
      is_smallcaps  := TempIsSmallcaps;
    end
   else
    Result := '';
end;

function TTesseractResultIterator.WordIsFromDictionary : boolean;
begin
  Result := Initialized and
            TessResultIteratorWordIsFromDictionary(TessResultIterator(FHandle));
end;

function TTesseractResultIterator.WordIsNumeric : boolean;
begin
  Result := Initialized and
            TessResultIteratorWordIsNumeric(TessResultIterator(FHandle));
end;

function TTesseractResultIterator.SymbolIsSuperscript : boolean;
begin
  Result := Initialized and
            TessResultIteratorSymbolIsSuperscript(TessResultIterator(FHandle));
end;

function TTesseractResultIterator.SymbolIsSubscript : boolean;
begin
  Result := Initialized and
            TessResultIteratorSymbolIsSubscript(TessResultIterator(FHandle));
end;

function TTesseractResultIterator.SymbolIsDropcap : boolean;
begin
  Result := Initialized and
            TessResultIteratorSymbolIsDropcap(TessResultIterator(FHandle));
end;

end.
