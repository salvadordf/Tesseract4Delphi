unit uLeptonicaConstants;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

interface

const
  /// <summary>
  /// Default reduction factor used by pixDeskew
  /// </summary>
  DEFAULT_REDUCTION_FACTOR = 0;

  /// <summary>
  /// Registry entries used to check if the Microsoft Visual C++ 2017 Redistributable package ins installed.
  /// </summary>
  /// <remarks>
  /// <para><see href="https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170#install-the-redistributable-packages">See the article about redistributing Visual C++ files</see></para>
  /// </remarks>
  VCPPREG_PATH1_32BITS = 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86';
  VCPPREG_PATH1_64BITS = 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';
  VCPPREG_PATH2_32BITS = 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86';
  VCPPREG_PATH2_64BITS = 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';

  CRLF = #13 + #10;

implementation

end.
