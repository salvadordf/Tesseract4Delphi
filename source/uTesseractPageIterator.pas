unit uTesseractPageIterator;

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
  uTesseractTypes, uTesseractLibFunctions, uLeptonicaPix;

type
  /// <summary>
  /// <para>Class to iterate over tesseract page structure, providing access to all
  /// levels of the page hierarchy, without including any tesseract headers or
  /// having to handle any tesseract structures.</para>
  ///
  /// <para>WARNING! This class points to data held within the TessBaseAPI class, and
  /// therefore can only be used while the TessBaseAPI class still exists and
  /// has not been subjected to a call of Init, SetImage, Recognize, Clear, End
  /// DetectOS, or anything else that changes the internal PAGE_RES.</para>
  ///
  /// <para>See tesseract/publictypes.h for the definition of PageIteratorLevel.
  /// See also ResultIterator, derived from PageIterator, which adds in the
  /// ability to access OCR output with text-specific methods.</para>
  /// </summary>
  TTesseractPageIterator = class
    protected
      FHandle : TessPageIterator;

      function  GetInitialized : boolean;
      procedure CopyHandle(aHandle: TessPageIterator); virtual;

    public
      constructor Create(aHandle: TessPageIterator);
      destructor  Destroy; override;
      /// <summary>
      /// Moves the iterator to point to the start of the page to begin an iteration.
      /// </summary>
      procedure   Begin_;
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
      function    Next(level: TessPageIteratorLevel) : boolean; virtual;
      /// <summary>
      /// <para>Returns true if the iterator is at the start of an object at the given
      /// level.</para>
      /// <para>For instance, suppose an iterator it is pointed to the first symbol of the
      /// first word of the third line of the second paragraph of the first block in
      /// a page, then:</para>
      /// <code>
      ///   it.IsAtBeginningOf(RIL_BLOCK) = false
      ///   it.IsAtBeginningOf(RIL_PARA) = false
      ///   it.IsAtBeginningOf(RIL_TEXTLINE) = true
      ///   it.IsAtBeginningOf(RIL_WORD) = true
      ///   it.IsAtBeginningOf(RIL_SYMBOL) = true
      /// </code>
      /// </summary>
      function    IsAtBeginningOf(level: TessPageIteratorLevel) : boolean;
      /// <summary>
      /// <para>Returns whether the iterator is positioned at the last element in a
      /// given level. (e.g. the last word in a line, the last line in a block)</para>
      /// <code>
      ///     Here's some two-paragraph example
      ///   text.  It starts off innocuously
      ///   enough but quickly turns bizarre.
      ///     The author inserts a cornucopia
      ///   of words to guard against confused
      ///   references.
      /// </code>
      /// <para>Now take an iterator it pointed to the start of "bizarre."</para>
      /// <code>
      ///  it.IsAtFinalElement(RIL_PARA, RIL_SYMBOL) = false
      ///  it.IsAtFinalElement(RIL_PARA, RIL_WORD) = true
      ///  it.IsAtFinalElement(RIL_BLOCK, RIL_WORD) = false
      /// </code>
      /// </summary>
      function    IsAtFinalElement(level, element: TessPageIteratorLevel) : boolean;
      /// <summary>
      /// <para>Returns the bounding rectangle of the current object at the given level.
      /// See comment on coordinate system above.</para>
      /// <para>Returns false if there is no such object at the current position.</para>
      /// <para>The returned bounding box is guaranteed to match the size and position
      /// of the image returned by GetBinaryImage, but may clip foreground pixels
      /// from a grey image. The padding argument to GetImage can be used to expand
      /// the image to include more foreground pixels. See GetImage below.</para>
      /// </summary>
      function    BoundingBox(level: TessPageIteratorLevel; out left, top, right, bottom: Integer) : boolean; overload;
      /// <summary>
      /// <para>Returns the bounding rectangle of the current object at the given level.
      /// See comment on coordinate system above.</para>
      /// <para>Returns false if there is no such object at the current position.</para>
      /// <para>The returned bounding box is guaranteed to match the size and position
      /// of the image returned by GetBinaryImage, but may clip foreground pixels
      /// from a grey image. The padding argument to GetImage can be used to expand
      /// the image to include more foreground pixels. See GetImage below.</para>
      /// </summary>
      function    BoundingBox(level: TessPageIteratorLevel; out aRect: TRect) : boolean; overload;
      /// <summary>
      /// Returns the type of the current block.
      /// </summary>
      function    BlockType : TessPolyBlockType;
      /// <summary>
      /// <para>Returns a binary image of the current object at the given level.</para>
      /// <para>The position and size match the return from BoundingBoxInternal, and so
      /// this could be upscaled with respect to the original input image.</para>
      /// </summary>
      function    GetBinaryImage(level: TessPageIteratorLevel) : TLeptonicaPix;
      /// <summary>
      /// <para>Returns an image of the current object at the given level in greyscale
      /// if available in the input. To guarantee a binary image use BinaryImage.</para>
      /// <para>NOTE that in order to give the best possible image, the bounds are
      /// expanded slightly over the binary connected component, by the supplied
      /// padding, so the top-left position of the returned image is returned
      /// in (left,top). These will most likely not match the coordinates
      /// returned by BoundingBox.</para>
      /// <para>If you do not supply an original image, you will get a binary one.</para>
      /// </summary>
      function    GetImage(level: TessPageIteratorLevel; padding: Integer; const original_image: TLeptonicaPix; out left, top: Integer) : TLeptonicaPix;
      /// <summary>
      /// <para>Returns the baseline of the current object at the given level.</para>
      /// <para>The baseline is the line that passes through (x1, y1) and (x2, y2).</para>
      /// <para>WARNING: with vertical text, baselines may be vertical!</para>
      /// <para>Returns false if there is no baseline at the current position.</para>
      /// </summary>
      function    Baseline(level: TessPageIteratorLevel; out x1, y1, x2, y2: Integer) : boolean; overload;
      /// <summary>
      /// <para>Returns the baseline of the current object at the given level.</para>
      /// <para>The baseline is the line that passes through (x1, y1) and (x2, y2).</para>
      /// <para>WARNING: with vertical text, baselines may be vertical!</para>
      /// <para>Returns false if there is no baseline at the current position.</para>
      /// </summary>
      function    Baseline(level: TessPageIteratorLevel; out aBaseline : TTesseractBaseLine) : boolean; overload;
      /// <summary>
      /// <para>Returns orientation for the block the iterator points to.</para>
      /// <para>orientation, writing_direction, textline_order: see publictypes.h</para>
      /// <para>deskew_angle: after rotating the block so the text orientation is
      /// upright, how many radians does one have to rotate the block anti-clockwise for it to be level?</para>
      /// <para>-Pi/4 <= deskew_angle <= Pi/4</para>
      /// </summary>
      function    Orientation(out orientation_: TessOrientation; out writing_direction: TessWritingDirection; out textline_order: TessTextlineOrder; out deskew_angle: single) : boolean;
      /// <summary>
      /// <para>Returns information about the current paragraph, if available.</para>
      /// <para>justification -
      ///     LEFT if ragged right, or fully justified and script is left-to-right.
      ///     RIGHT if ragged left, or fully justified and script is right-to-left.
      ///     unknown if it looks like source code or we have very few lines.</para>
      /// <para>is_list_item -
      ///     true if we believe this is a member of an ordered or unordered list.</para>
      /// <para>is_crown -
      ///     true if the first line of the paragraph is aligned with the other
      ///     lines of the paragraph even though subsequent paragraphs have first
      ///     line indents.  This typically indicates that this is the continuation
      ///     of a previous paragraph or that it is the very first paragraph in
      ///     the chapter.</para>
      /// <para>first_line_indent -
      ///     For LEFT aligned paragraphs, the first text line of paragraphs of
      ///     this kind are indented this many pixels from the left edge of the
      ///     rest of the paragraph.
      ///     for RIGHT aligned paragraphs, the first text line of paragraphs of
      ///     this kind are indented this many pixels from the right edge of the
      ///     rest of the paragraph.
      ///     NOTE 1: This value may be negative.
      ///     NOTE 2: if *is_crown == true, the first line of this paragraph is
      ///             actually flush, and first_line_indent is set to the "common"
      ///             first_line_indent for subsequent paragraphs in this block
      ///             of text.</para>
      /// </summary>
      function    ParagraphInfo(out justification: TessParagraphJustification; out is_list_item: boolean; out is_crown: boolean; out first_line_indent: Integer) : boolean;

      property Handle       : TessPageIterator    read FHandle;
      /// <summary>
      /// Returns true when this instance is fully initialized.
      /// </summary>
      property Initialized  : boolean             read GetInitialized;
  end;


implementation

uses
  {$IFDEF LINUXFPC}lcltype,{$ENDIF}
  uTesseractLoader;

constructor TTesseractPageIterator.Create(aHandle: TessPageIterator);
begin
  inherited Create;

  CopyHandle(aHandle);
end;

destructor TTesseractPageIterator.Destroy;
begin
  if Initialized then
    begin
      TessPageIteratorDelete(FHandle);
      FHandle := nil;
    end;

  inherited Destroy;
end;

procedure TTesseractPageIterator.CopyHandle(aHandle: TessPageIterator);
begin
  if assigned(GlobalTesseractLoader) and GlobalTesseractLoader.Initialized then
    FHandle := TessPageIteratorCopy(aHandle)
   else
    FHandle := nil;
end;

function TTesseractPageIterator.GetInitialized : boolean;
begin
  Result := (FHandle <> nil);
end;

procedure TTesseractPageIterator.Begin_;
begin
  if Initialized then
    TessPageIteratorBegin(FHandle);
end;

function TTesseractPageIterator.Next(level: TessPageIteratorLevel) : boolean;
begin
  Result := Initialized and
            TessPageIteratorNext(FHandle, level);
end;

function TTesseractPageIterator.IsAtBeginningOf(level: TessPageIteratorLevel) : boolean;
begin
  Result := Initialized and
            TessPageIteratorIsAtBeginningOf(FHandle, level);
end;

function TTesseractPageIterator.IsAtFinalElement(level, element: TessPageIteratorLevel) : boolean;
begin
  Result := Initialized and
            TessPageIteratorIsAtFinalElement(FHandle, level, element);
end;

function TTesseractPageIterator.BoundingBox(level: TessPageIteratorLevel; out left, top, right, bottom: Integer) : boolean;
begin
  Result := Initialized and
            TessPageIteratorBoundingBox(FHandle, level, left, top, right, bottom);
end;

function TTesseractPageIterator.BoundingBox(level: TessPageIteratorLevel; out aRect: TRect) : boolean;
var
  TempLeft, TempTop, TempRight, TempBottom: Integer;
begin
  Result       := False;
  aRect.Left   := 0;
  aRect.Top    := 0;
  aRect.Right  := 0;
  aRect.Bottom := 0;

  if BoundingBox(level, TempLeft, TempTop, TempRight, TempBottom) then
    begin
      aRect.Left   := TempLeft;
      aRect.Top    := TempTop;
      aRect.Right  := TempRight;
      aRect.Bottom := TempBottom;
      Result       := True;
    end;
end;

function TTesseractPageIterator.BlockType : TessPolyBlockType;
begin
  if Initialized then
    Result := TessPageIteratorBlockType(FHandle)
   else
    Result := PT_UNKNOWN;
end;

function TTesseractPageIterator.GetBinaryImage(level: TessPageIteratorLevel) : TLeptonicaPix;
var
  TempPix : Pointer;
begin
  Result := nil;

  if Initialized then
    begin
      TempPix := TessPageIteratorGetBinaryImage(FHandle, level);

      if assigned(TempPix) then
        Result := TLeptonicaPix.Create(TempPix);
    end;
end;

function TTesseractPageIterator.GetImage(level: TessPageIteratorLevel; padding: Integer; const original_image: TLeptonicaPix; out left, top: Integer) : TLeptonicaPix;
var
  TempPix : Pointer;
begin
  Result := nil;

  if Initialized then
    begin
      TempPix := TessPageIteratorGetImage(FHandle, level, padding, original_image.Pix, left, top);

      if assigned(TempPix) then
        Result := TLeptonicaPix.Create(TempPix);
    end;
end;

function TTesseractPageIterator.Baseline(level: TessPageIteratorLevel; out x1, y1, x2, y2: Integer) : boolean;
begin
  Result := Initialized and
            TessPageIteratorBaseline(FHandle, level, x1, y1, x2, y2);
end;

function TTesseractPageIterator.Baseline(level: TessPageIteratorLevel; out aBaseline : TTesseractBaseLine) : boolean;
var
  x1, y1, x2, y2: Integer;
begin
  Result         := False;
  aBaseline[0].x := 0;
  aBaseline[0].y := 0;
  aBaseline[1].x := 0;
  aBaseline[1].y := 0;

  if Baseline(level, x1, y1, x2, y2) then
    begin
      aBaseline[0].x := x1;
      aBaseline[0].y := y1;
      aBaseline[1].x := x2;
      aBaseline[1].y := y2;
      Result         := True;
    end;
end;

function TTesseractPageIterator.Orientation(out orientation_: TessOrientation; out writing_direction: TessWritingDirection; out textline_order: TessTextlineOrder; out deskew_angle: single) : boolean;
begin
  if Initialized then
    begin
      TessPageIteratorOrientation(FHandle, orientation_, writing_direction, textline_order, deskew_angle);
      Result := True;
    end
   else
    Result := False;
end;

function TTesseractPageIterator.ParagraphInfo(out justification: TessParagraphJustification; out is_list_item: boolean; out is_crown: boolean; out first_line_indent: Integer) : boolean;
var
  TempIsListItem, TempIsCrown : BOOL;
begin
  if Initialized then
    begin
      TessPageIteratorParagraphInfo(FHandle, justification, TempIsListItem, TempIsCrown, first_line_indent);
      is_list_item := TempIsListItem;
      is_crown     := TempIsCrown;
      Result       := True;
    end
   else
    Result := False;
end;

end.
