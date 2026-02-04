unit uTesseractTypes;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF TARGET_64BITS}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 4}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Types,
  {$ELSE}
    Types,
  {$ENDIF}
  uLeptonicaTypes;

type
  TFileDescriptor = type integer;
  PFileDescriptor = ^TFileDescriptor;

  PPUTF8Char = ^PUTF8Char;
  PPInteger  = ^PInteger;

  TessResultRenderer  = Pointer;
  TessBaseAPI         = Pointer;
  TessPageIterator    = Pointer;
  TessResultIterator  = Pointer;
  TessMutableIterator = Pointer;
  TessChoiceIterator  = Pointer;
  PETEXT_DESC         = Pointer;

  /// <summary>
  /// <para>When Tesseract/Cube is initialized we can choose to instantiate/load/run
  /// only the Tesseract part, only the Cube part or both along with the combiner.
  /// The preference of which engine to use is stored in tessedit_ocr_engine_mode.</para>
  ///
  /// <para>ATTENTION: When modifying this enum, please make sure to make the
  /// appropriate changes to all the enums mirroring it (e.g. OCREngine in
  /// cityblock/workflow/detection/detection_storage.proto). Such enums will
  /// mention the connection to OcrEngineMode in the comments.</para>
  /// </summary>
  TessOcrEngineMode = (/// <summary>
                       /// Run Tesseract only - fastest; deprecated
                       /// </summary>
                       OEM_TESSERACT_ONLY,
                       /// <summary>
                       /// Run just the LSTM line recognizer.
                       /// </summary>
                       OEM_LSTM_ONLY,
                       /// <summary>
                       /// Run the LSTM recognizer, but allow fallback to
                       /// Tesseract when things get difficult. deprecated
                       /// </summary>
                       OEM_TESSERACT_LSTM_COMBINED,
                       /// <summary>
                       /// Specify this mode when calling init_*(),
                       /// to indicate that any of the above modes
                       /// should be automatically inferred from the
                       /// variables in the language-specific config,
                       /// command-line configs, or if not specified
                       /// in any of the above should be set to the
                       /// default OEM_TESSERACT_ONLY.
                       /// </summary>
                       OEM_DEFAULT,
                       /// <summary>
                       /// Number of OEMs
                       /// </summary>
                       OEM_COUNT);

  /// <summary>
  /// Possible modes for page layout analysis. These *must* be kept in order
  /// of decreasing amount of layout analysis to be done, except for OSD_ONLY,
  /// so that the inequality test macros below work.
  /// </summary>
  TessPageSegMode = (/// <summary>
                     /// Orientation and script detection only.
                     /// </summary>
                     PSM_OSD_ONLY,
                     /// <summary>
                     /// Automatic page segmentation with orientation and script detection. (OSD)
                     /// </summary>
                     PSM_AUTO_OSD,
                     /// <summary>
                     /// Automatic page segmentation, but no OSD, or OCR.
                     /// </summary>
                     PSM_AUTO_ONLY,
                     /// <summary>
                     /// Fully automatic page segmentation, but no OSD.
                     /// </summary>
                     PSM_AUTO,
                     /// <summary>
                     /// Assume a single column of text of variable sizes.
                     /// </summary>
                     PSM_SINGLE_COLUMN,
                     /// <summary>
                     /// Assume a single uniform block of vertically aligned text.
                     /// </summary>
                     PSM_SINGLE_BLOCK_VERT_TEXT,
                     /// <summary>
                     /// Assume a single uniform block of text. (Default.)
                     /// </summary>
                     PSM_SINGLE_BLOCK,
                     /// <summary>
                     /// Treat the image as a single text line.
                     /// </summary>
                     PSM_SINGLE_LINE,
                     /// <summary>
                     /// Treat the image as a single word.
                     /// </summary>
                     PSM_SINGLE_WORD,
                     /// <summary>
                     /// Treat the image as a single word in a circle.
                     /// </summary>
                     PSM_CIRCLE_WORD,
                     /// <summary>
                     /// Treat the image as a single character.
                     /// </summary>
                     PSM_SINGLE_CHAR,
                     /// <summary>
                     /// Find as much text as possible in no particular order.
                     /// </summary>
                     PSM_SPARSE_TEXT,
                     /// <summary>
                     /// Sparse text with orientation and script det.
                     /// </summary>
                     PSM_SPARSE_TEXT_OSD,
                     /// <summary>
                     /// Treat the image as a single text line, bypassing hacks that are Tesseract-specific.
                     /// </summary>
                     PSM_RAW_LINE,
                     /// <summary>
                     /// Number of enum entries.
                     /// </summary>
                     PSM_COUNT);

  /// <summary>
  /// enum of the elements of the page hierarchy, used in ResultIterator
  /// to provide functions that operate on each level without having to
  /// have 5x as many functions.
  /// </summary>
  TessPageIteratorLevel = (/// <summary>
                           /// Block of text/image/separator line.
                           /// </summary>
                           RIL_BLOCK,
                           /// <summary>
                           /// Paragraph within a block.
                           /// </summary>
                           RIL_PARA,
                           /// <summary>
                           /// Line within a paragraph.
                           /// </summary>
                           RIL_TEXTLINE,
                           /// <summary>
                           /// Word within a textline.
                           /// </summary>
                           RIL_WORD,
                           /// <summary>
                           /// Symbol/character within a word.
                           /// </summary>
                           RIL_SYMBOL);

  /// <summary>
  /// Possible types for a POLY_BLOCK or ColPartition.
  /// Must be kept in sync with kPBColors in polyblk.cpp and PTIs*Type functions
  /// below, as well as kPolyBlockNames in layout_test.cc.
  /// Used extensively by ColPartition, and POLY_BLOCK.
  /// </summary>
  TessPolyBlockType = (/// <summary>
                       /// Type is not yet known. Keep as the first element.
                       /// </summary>
                       PT_UNKNOWN,
                       /// <summary>
                       /// Text that lives inside a column.
                       /// </summary>
                       PT_FLOWING_TEXT,
                       /// <summary>
                       /// Text that spans more than one column.
                       /// </summary>
                       PT_HEADING_TEXT,
                       /// <summary>
                       /// Text that is in a cross-column pull-out region.
                       /// </summary>
                       PT_PULLOUT_TEXT,
                       /// <summary>
                       /// Partition belonging to an equation region.
                       /// </summary>
                       PT_EQUATION,
                       /// <summary>
                       /// Partition has inline equation.
                       /// </summary>
                       PT_INLINE_EQUATION,
                       /// <summary>
                       /// Partition belonging to a table region.
                       /// </summary>
                       PT_TABLE,
                       /// <summary>
                       /// Text-line runs vertically.
                       /// </summary>
                       PT_VERTICAL_TEXT,
                       /// <summary>
                       /// Text that belongs to an image.
                       /// </summary>
                       PT_CAPTION_TEXT,
                       /// <summary>
                       /// Image that lives inside a column.
                       /// </summary>
                       PT_FLOWING_IMAGE,
                       /// <summary>
                       /// Image that spans more than one column.
                       /// </summary>
                       PT_HEADING_IMAGE,
                       /// <summary>
                       /// Image that is in a cross-column pull-out region.
                       /// </summary>
                       PT_PULLOUT_IMAGE,
                       /// <summary>
                       /// Horizontal Line.
                       /// </summary>
                       PT_HORZ_LINE,
                       /// <summary>
                       /// Vertical Line.
                       /// </summary>
                       PT_VERT_LINE,
                       /// <summary>
                       /// Lies outside of any column.
                       /// </summary>
                       PT_NOISE,
                       /// <summary>
                       /// Number of enum entries.
                       /// </summary>
                       PT_COUNT);

  /// <summary>
  /// <para>Orientation Example:</para>
  ///
  /// <para>To left is a diagram of some (1) English and (2) Chinese text and a
  /// (3) photo credit.</para>
  ///
  /// <para>Upright Latin characters are represented as A and a.
  /// '<' represents a latin character rotated anti-clockwise 90 degrees.</para>
  ///
  /// <para>Upright Chinese characters are represented C and c.</para>
  ///
  /// <para>NOTA BENE: enum values here should match goodoc.proto
  /// <code>
  ///  +------------------+
  ///  | 1 Aaaa Aaaa Aaaa |
  ///  | Aaa aa aaa aa    |
  ///  | aaaaaa A aa aaa. |
  ///  |                2 |
  ///  |   #######  c c C |
  ///  |   #######  c c c |
  ///  | < #######  c c c |
  ///  | < #######  c   c |
  ///  | < #######  .   c |
  ///  | 3 #######      c |
  ///  +------------------+
  /// </code>
  /// <para>If you orient your head so that "up" aligns with Orientation,
  /// then the characters will appear "right side up" and readable.</para>
  ///
  /// <para>In the example above, both the English and Chinese paragraphs are oriented
  /// so their "up" is the top of the page (page up).  The photo credit is read
  /// with one's head turned leftward ("up" is to page left).</para>
  ///
  /// <para>The values of this enum match the convention of Tesseract's osdetect.h</para>
  /// </summary>
  TessOrientation = (ORIENTATION_PAGE_UP,
                     ORIENTATION_PAGE_RIGHT,
                     ORIENTATION_PAGE_DOWN,
                     ORIENTATION_PAGE_LEFT);

  /// <summary>
  /// <para>NOTA BENE: Fully justified paragraphs (text aligned to both left and right
  ///    margins) are marked by Tesseract with JUSTIFICATION_LEFT if their text
  ///    is written with a left-to-right script and with JUSTIFICATION_RIGHT if
  ///    their text is written in a right-to-left script.</para>
  ///
  /// <para>Interpretation for text read in vertical lines:
  ///   "Left" is wherever the starting reading position is.</para>
  /// </summary>
  TessParagraphJustification = (/// <summary>
                                /// The alignment is not clearly one of the other options.
                                /// This could happen for example if there are only one or
                                /// two lines of text or the text looks like source code or poetry.
                                /// </summary>
                                JUSTIFICATION_UNKNOWN,
                                /// <summary>
                                /// Each line, except possibly the first, is flush to the same left tab stop.
                                /// </summary>
                                JUSTIFICATION_LEFT,
                                /// <summary>
                                /// The text lines of the paragraph are centered about a line going down through their middle of the text lines.
                                /// </summary>
                                JUSTIFICATION_CENTER,
                                /// <summary>
                                /// Each line, except possibly the first, is flush to the same right tab stop.
                                /// </summary>
                                JUSTIFICATION_RIGHT);

  /// <summary>
  /// <para>The grapheme clusters within a line of text are laid out logically
  /// in this direction, judged when looking at the text line rotated so that
  /// its Orientation is "page up".</para>
  ///
  /// <para>For English text, the writing direction is left-to-right.  For the
  /// Chinese text in the above example, the writing direction is top-to-bottom.</para>
  /// </summary>
  TessWritingDirection = (WRITING_DIRECTION_LEFT_TO_RIGHT,
                          WRITING_DIRECTION_RIGHT_TO_LEFT,
                          WRITING_DIRECTION_TOP_TO_BOTTOM);

  /// <summary>
  /// <para>The text lines are read in the given sequence.</para>
  ///
  /// <para>In English, the order is top-to-bottom.</para>
  /// <para>In Chinese, vertical text lines are read right-to-left.  Mongolian is
  /// written in vertical columns top to bottom like Chinese, but the lines
  /// order left-to right.</para>
  ///
  /// <para>Note that only some combinations make sense. For example,
  /// WRITING_DIRECTION_LEFT_TO_RIGHT implies TEXTLINE_ORDER_TOP_TO_BOTTOM</para>
  /// </summary>
  TessTextlineOrder = (TEXTLINE_ORDER_LEFT_TO_RIGHT,
                       TEXTLINE_ORDER_RIGHT_TO_LEFT,
                       TEXTLINE_ORDER_TOP_TO_BOTTOM);

  /// <summary>
  /// <para>Single character.</para>
  /// <para>It should be noted that the format for char_code for version 2.0 and beyond
  /// is UTF8 which means that ASCII characters will come out as one structure
  /// but other characters will be returned in two or more instances of this
  /// structure with a single byte of the  UTF8 code in each, but each will have
  /// the same bounding box. Programs which want to handle languages with
  /// different characters sets will need to handle extended characters
  /// appropriately, but *all* code needs to be prepared to receive UTF8 coded
  /// characters for characters such as bullet and fancy quotes.</para>
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/tesseract-ocr/tesseract/blob/main/include/tesseract/ocrclass.h">Tesseract source file: /include/tesseract/ocrclass.h (EANYCODE_CHAR)</see></para>
  /// </remarks>
  EANYCODE_CHAR = record
    /// <summary>
    /// character itself
    /// </summary>
    char_code  : word;
    /// <summary>
    /// of char (-1)
    /// </summary>
    left       : Smallint;
    /// <summary>
    /// of char (-1)
    /// </summary>
    right      : Smallint;
    /// <summary>
    /// of char (-1)
    /// </summary>
    top        : Smallint;
    /// <summary>
    /// of char (-1)
    /// </summary>
    bottom     : Smallint;
    /// <summary>
    /// what font (0)
    /// </summary>
    font_index : Smallint;
    /// <summary>
    /// 0=perfect, 100=reject (0/100)
    /// </summary>
    confidence : byte;
    /// <summary>
    /// of char, 72=i inch, (10)
    /// </summary>
    point_size : byte;
    /// <summary>
    /// no of spaces before this char (1)
    /// </summary>
    blanks     : Shortint;
    /// <summary>
    /// char formatting (0)
    /// </summary>
    formatting : byte;
  end;

  CANCEL_FUNC    = function(cancel_this: Pointer; words: Integer): Boolean; cdecl;
  PROGRESS_FUNC  = function(progress, left, right, top, bottom: Integer): Boolean; cdecl;
  PROGRESS_FUNC2 = function(ths: PETEXT_DESC; left, right, top, bottom: Integer): Boolean; cdecl;

  TessCancelFunc   = type CANCEL_FUNC;
  TessProgressFunc = type PROGRESS_FUNC2;

  /// <summary>
  /// Status of TTesseractLoader.
  /// </summary>
  TTesseractLoaderStatus = (tlsLoading,
                            tlsInitialized,
                            tlsShuttingDown,
                            tlsUnloaded,
                            tlsErrorMissingFiles,
                            tlsErrorDLLVersion,
                            tlsErrorWindowsVersion,
                            tlsErrorLoadingLibrary,
                            tlsErrorInitializingLibrary);

  TTesseractBaseLine = array[0..1] of TPoint;

implementation

end.
