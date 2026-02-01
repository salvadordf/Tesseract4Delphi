unit uLeptonicaTypes;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF TARGET_64BITS}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 1}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Types;
  {$ELSE}
    Types;
  {$ENDIF}

type
  {$IF NOT DECLARED(PUTF8Char)}
  PUTF8Char = ^AnsiChar;
  {$IFEND}

  {$IF NOT DECLARED(NativeUInt)}
  NativeUInt  = Cardinal;
  {$IFEND}

  /// <summary>
  /// return 0 if OK, 1 on error
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_ok)</see></para>
  /// </remarks>
  l_ok      = Integer;
  /// <summary>
  /// signed 8-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_int8)</see></para>
  /// </remarks>
  l_int8    = ShortInt;
  /// <summary>
  /// unsigned 8-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_uint8)</see></para>
  /// </remarks>
  l_uint8   = byte;
  pl_uint8  = ^l_uint8;
  /// <summary>
  /// signed 16-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_int16)</see></para>
  /// </remarks>
  l_int16   = SmallInt;
  /// <summary>
  /// unsigned 16-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_uint16)</see></para>
  /// </remarks>
  l_uint16  = Word;
  /// <summary>
  /// signed 32-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_int32)</see></para>
  /// </remarks>
  l_int32   = Integer;
  pl_uint32 = ^l_uint32;
  /// <summary>
  /// unsigned 32-bit value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_uint32)</see></para>
  /// </remarks>
  l_uint32  = Cardinal;
  /// <summary>
  /// 32-bit floating point value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_float32)</see></para>
  /// </remarks>
  l_float32 = Single;
  /// <summary>
  /// 64-bit floating point value
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/environ.h">Leptonica source file: /src/environ.h (l_float64)</see></para>
  /// </remarks>
  l_float64 = Double;
  l_atomic  = Integer;

  /// <summary>
  /// Colormap of a Pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (PixColormap)</see></para>
  /// </remarks>
  TPixColormap = record
    /// <summary>
    /// colormap table (array of TRGBA_Quad)
    /// </summary>
    arr    : Pointer;
    /// <summary>
    /// of pix (1, 2, 4 or 8 bpp)
    /// </summary>
    depth  : l_int32;
    /// <summary>
    /// number of color entries allocated
    /// </summary>
    nalloc : l_int32;
    /// <summary>
    /// number of color entries used
    /// </summary>
    n      : l_int32;
  end;
  PPixColormap = ^TPixColormap;

  /// <summary>
  /// Colormap of a Pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (RGBA_Quad)</see></para>
  /// </remarks>
  TRGBA_Quad = record
    /// <summary>
    /// blue value
    /// </summary>
    blue  : l_uint8;
    /// <summary>
    /// green value
    /// </summary>
    green : l_uint8;
    /// <summary>
    /// red value
    /// </summary>
    red   : l_uint8;
    /// <summary>
    /// alpha value
    /// </summary>
    alpha : l_uint8;
  end;

  /// <summary>
  /// Basic Pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Pix)</see></para>
  /// </remarks>
  TPix = record
    /// <summary>
    /// width in pixels
    /// </summary>
    w        : l_uint32;
    /// <summary>
    /// height in pixels
    /// </summary>
    h        : l_uint32;
    /// <summary>
    /// depth in bits (bpp)
    /// </summary>
    d        : l_uint32;
    /// <summary>
    /// number of samples per pixel
    /// </summary>
    spp      : l_uint32;
    /// <summary>
    /// 32-bit words/line
    /// </summary>
    wpl      : l_uint32;
    /// <summary>
    /// reference count (1 if no clones)
    /// </summary>
    refcount : l_atomic;
    /// <summary>
    /// image res (ppi) in x direction. (use 0 if unknown)
    /// </summary>
    xres     : l_int32;
    /// <summary>
    /// image res (ppi) in y direction. (use 0 if unknown)
    /// </summary>
    yres     : l_int32;
    /// <summary>
    /// input file format, IFF_*
    /// </summary>
    informat : l_int32;
    /// <summary>
    /// special instructions for I/O, etc
    /// </summary>
    special  : l_int32;
    /// <summary>
    /// text string associated with pix
    /// </summary>
    text     : PUTF8Char;
    /// <summary>
    /// colormap (may be null)
    /// </summary>
    colormap : PPixColormap;
    /// <summary>
    /// the image data
    /// </summary>
    data     : pl_uint32;
  end;
  PPix = ^TPix;
  PPPix = ^PPix;

  /// <summary>
  /// Basic rectangle
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Box)</see></para>
  /// </remarks>
  TBox = record
    /// <summary>
    /// left coordinate
    /// </summary>
    x        : l_int32;
    /// <summary>
    /// top coordinate
    /// </summary>
    y        : l_int32;
    /// <summary>
    /// box width
    /// </summary>
    w        : l_int32;
    /// <summary>
    /// box height
    /// </summary>
    h        : l_int32;
    /// <summary>
    /// reference count (1 if no clones)
    /// </summary>
    refcount : l_atomic;
  end;
  PBox = ^TBox;
  PPBox = ^PBox;

  /// <summary>
  /// Array of Box
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Boxa)</see></para>
  /// </remarks>
  TBoxa = record
    /// <summary>
    /// number of box in ptr array
    /// </summary>
    n        : l_int32;
    /// <summary>
    /// number of box ptrs allocated
    /// </summary>
    nalloc   : l_int32;
    /// <summary>
    /// reference count (1 if no clones)
    /// </summary>
    refcount : l_atomic;
    /// <summary>
    /// box ptr array
    /// </summary>
    box      : PPBox;
  end;
  PBoxa = ^TBoxa;

  /// <summary>
  /// Array of pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Pixa)</see></para>
  /// </remarks>
  TPixa = record
    /// <summary>
    /// number of Pix in ptr array
    /// </summary>
    n        : l_int32;
    /// <summary>
    /// number of Pix ptrs allocated
    /// </summary>
    nalloc   : l_int32;
    /// <summary>
    /// reference count (1 if no clones)
    /// </summary>
    refcount : l_atomic;
    /// <summary>
    /// the array of ptrs to pix
    /// </summary>
    pix      : PPPix;
    /// <summary>
    /// array of boxes
    /// </summary>
    boxa     : PBoxa;
  end;
  PPixa = ^TPixa;

  /// <summary>
  /// Image formats.
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/imageio.h">Leptonica source file: /src/imageio.h</see></para>
  /// </remarks>
  TLeptonicaImageFormat = (
    IFF_UNKNOWN        = 0,
    IFF_BMP            = 1,
    IFF_JFIF_JPEG      = 2,
    IFF_PNG            = 3,
    IFF_TIFF           = 4,
    IFF_TIFF_PACKBITS  = 5,
    IFF_TIFF_RLE       = 6,
    IFF_TIFF_G3        = 7,
    IFF_TIFF_G4        = 8,
    IFF_TIFF_LZW       = 9,
    IFF_TIFF_ZIP       = 10,
    IFF_PNM            = 11,
    IFF_PS             = 12,
    IFF_GIF            = 13,
    IFF_JP2            = 14,
    IFF_WEBP           = 15,
    IFF_LPDF           = 16,
    IFF_TIFF_JPEG      = 17,
    IFF_DEFAULT        = 18,
    IFF_SPIX           = 19
  );


  /// <summary>
  /// Status of TLeptonicaLoader.
  /// </summary>
  TLeptonicaLoaderStatus = (llsLoading,
                            llsInitialized,
                            llsShuttingDown,
                            llsUnloaded,
                            llsErrorMissingFiles,
                            llsErrorDLLVersion,
                            llsErrorWindowsVersion,
                            llsErrorLoadingLibrary,
                            llsErrorInitializingLibrary);


  TRectArray    = array of TRect;
  TIntegerArray = array of Integer;
  TBooleanArray = array of boolean;

implementation

end.
