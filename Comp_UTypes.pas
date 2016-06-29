unit Comp_UTypes;

interface

uses
  Controls, Graphics, Types;

const
  teTreeView = 'treeview';
  teHeader = 'header';

  { teHeader }
  tcHeader = 1;
  tiHeaderNormal = 1;
  tiHeaderHover = 2;
  tiHeaderDown = 3;
  tiHeaderPasive = 7;

  tiCollapsed = 1;
  tiExpanded = 2;

  tcExpandingButton = 2;

  { Effects }
  szShadowSize = 3;
  szReflectionSize = 20;

type
  // Стиль кнопки-переключателя
  TScToggleButtonStyle = (tsStyleNative, tsTriangle, tsSquare, tsGlyph);
  // Стиль границы
  TScBorderStyle = (btSolid, btLowered, btRaised);

  TScStyleOption = (soNativeStyles, soVCLStyles);
  TScStyleOptions = set of TScStyleOption;

  TScPaintEffects = set of (efBevel, efInnerShadow, efLight, efReflection, efShadow, efShine);

  TScButtonState = set of (bsHover, bsChecked, bsFocused, bsPressed, bsSelected, bsDisabled);

  TScAppearanceStyle = (stNative, stModern, stUserDefined);

  TScWrapKind = (wkNone, wkEllipsis, wkPathEllipsis, wkWordEllipsis, wkWordWrap);

  TScOrientation = (orHorizontal, orVertical);

  TScPanelPaintStyle = class
  public
    class function GetFillColor(Control: TControl; DefaultColor: TColor): TColor;
  end;

  TScTreeStyledView = class
    class procedure PaintToggle(Canvas: TCanvas; Handle: THandle; Dest: TRect;
      Expanded: Boolean; State: TScButtonState; Options: TScStyleOptions);
  end;

  TScHeaderStyle = class
//    class function GetTextColor(Control: TControl; Color: TColor;
//      State: TNxButtonState): TColor;
    class procedure Paint(Canvas: TCanvas; Handle: THandle; Dest: TRect;
      State: TScButtonState; Options: TScStyleOptions);
//    class procedure PaintInactive(Canvas: TCanvas; Handle: THandle; Dest: TRect;
//      Options: TNxStyleOptions);
  end;

  TQuadColor = packed record
    case Boolean of
      True: (Blue, Green, Red, Alpha: Byte);
      False: (Quad: Cardinal);
    end;

  PQuadColor = ^TQuadColor;
  PPQuadColor = ^PQuadColor;

  TScColorSchemeElement = (
    seAppWorkSpace,
    seBtnFace,
    seBtnFaceChecked,
    seBtnFacePressed,
    seBtnFrame,
    seBtnFramePressed,
    seDivider,
    seHighlight,
    seMenu,
    seTabFace,
    seTabFaceHot,
    seTabText,
    seTabBtnFace,
    seStatusBtnFace,
    seStatusBtnFacePressed,
    seStatusText,
    seTrackBar,
    seWindowFrame
  );

  { Color Schemes }
  TScColorScheme = (csDefault,
    csExcel, csOutlook, csPowerPoint, csWord,
    csVisualStudioBlue);

  TScColorSchemes = csExcel..csVisualStudioBlue;

function Size(cx, cy: Integer): TSize;
procedure SetPadding(var Rect: TRect; Padding: TPadding);
function SupportStyle(Options: TScStyleOptions): Boolean;
function Themed: Boolean;


var
  SchemeColor: array[TScColorScheme, TScColorSchemeElement] of TColor;
  ColorScheme: TScColorSchemes = csOutlook;

implementation

uses
  UxTheme, Math;

function Size(cx, cy: Integer): TSize;
begin
  Result.cx := cx;
  Result.cy := cy;
end;

procedure SetPadding(var Rect: TRect; Padding: TPadding);
begin
  Inc(Rect.Left, Padding.Left);
  Inc(Rect.Top, Padding.Top);
  Dec(Rect.Right, Padding.Right);
  Dec(Rect.Bottom, Padding.Bottom);
end;

function Themed: Boolean;
begin
  Result := IsThemeActive;
end;

function StyleServicesEnabled: Boolean;
begin
{$IFDEF STYLE_SERVICES}
  Result := StyleServices.Enabled and StyleServices.Available;
{$ELSE}
  Result := False;
{$ENDIF}
end;

function SupportStyle(Options: TScStyleOptions): Boolean;
begin
  Result := False;
  if (soVCLStyles in Options)
    and StyleServicesEnabled then
  begin
    Result := True;
    Exit;
  end;
  if (soNativeStyles in Options)
    and Themed then
  begin
    Result := True;
    Exit;
  end;
end;

{ TScPanelStyle }

class function TScPanelPaintStyle.GetFillColor(Control: TControl;
  DefaultColor: TColor): TColor;
{$IFDEF STYLE_SERVICES}
var
  OutColor: TColor;
  Detail: TThemedPanel;
{$ENDIF}
begin
  Result := DefaultColor;
  if SupportStyle([soVCLStyles]) then
  begin
{$IFDEF STYLE_SERVICES}
    if seClient in Control.StyleElements then
    begin
      with StyleServices do
      begin
        Detail := tpPanelBackground;
        if GetElementColor(GetElementDetails(Detail), ecFillColor, OutColor) then
        begin
          if Result <> clNone then Result := OutColor;
        end;
      end;
    end;
{$ENDIF}
  end;
end;

class procedure TScTreeStyledView.PaintToggle(Canvas: TCanvas; Handle: THandle;
  Dest: TRect; Expanded: Boolean; State: TScButtonState;
  Options: TScStyleOptions);
var
{$IFDEF STYLE_SERVICES}
  Detail: TThemedTreeview;
{$ENDIF}
  Index, C: Integer;
  Theme: HTHEME;
begin
  if (soVCLStyles in Options) and StyleServicesEnabled then
  begin
{$IFDEF STYLE_SERVICES}
    if Expanded then
      Detail := ttGlyphOpened
    else
      Detail := ttGlyphClosed;
    StyleServices.DrawElement(Canvas.Handle, StyleServices.GetElementDetails(Detail), Dest);
{$ENDIF}
  end else if (soNativeStyles in Options) and Themed then
  begin
    Theme := OpenThemeData(Handle, teTreeView);
    if Expanded then Index := tiExpanded else Index := tiCollapsed;
    DrawThemeBackground(Theme, Canvas.Handle, tcExpandingButton, Index, Dest, nil);
    CloseThemeData(Theme);
  end else
  begin
    with Canvas do
    begin
      Pen.Color := clGray;
      Brush.Color := clWhite;
      Rectangle(Dest);
      C := Floor(RectWidth(Dest) / 2);
      Polyline([
        Point(Dest.Left + 2, Dest.Top + C),
        Point(Dest.Right - 2, Dest.Top + C)
      ]);
      if not Expanded then
        Polyline([
          Point(Dest.Left + C, Dest.Top + 2),
          Point(Dest.Left + C, Dest.Bottom - 2)
        ]);
    end;
  end;
end;

{ TScHeaderStyle }

class procedure TScHeaderStyle.Paint(Canvas: TCanvas; Handle: THandle;
  Dest: TRect; State: TScButtonState; Options: TScStyleOptions);
var
{$IFDEF STYLE_SERVICES}
  Detail: TThemedHeader;
{$ENDIF}
  Index: Integer;
  Theme: HTHEME;
begin
  if (soVCLStyles in Options) and StyleServicesEnabled then
  begin
{$IFDEF STYLE_SERVICES}
    Detail := thHeaderItemNormal;
    if bsHover in State then Detail := thHeaderItemHot;
    if bsPressed in State then Detail := thHeaderItemPressed;
    StyleServices.DrawElement(Canvas.Handle, StyleServices.GetElementDetails(Detail), Dest);
{$ENDIF}
  end else if (soNativeStyles in Options) and Themed then
  begin
    Theme := OpenThemeData(Handle, teHeader);
    Index := tiHeaderNormal;
    if bsHover in State then Index := tiHeaderHover;
    if bsPressed in State then Index := tiHeaderDown;
    DrawThemeBackground(Theme, Canvas.Handle, tcHeader, Index, Dest, nil);
    CloseThemeData(Theme);
  end else
  begin

  end;
end;

initialization
  { ColorSchemes }
  SchemeColor[csOutlook, seAppWorkSpace] := $00ffffff;
  SchemeColor[csOutlook, seMenu] := $00c67200;
  SchemeColor[csOutlook, seBtnFace] := $00f7e6cd;
  SchemeColor[csOutlook, seBtnFrame] := $00ababab; { shared }
  SchemeColor[csOutlook, seBtnFramePressed] := $00d48d2a;
  SchemeColor[csOutlook, seBtnFacePressed] := $00e0c092;
  SchemeColor[csOutlook, seBtnFaceChecked] := $00f0d6b1;
  SchemeColor[csOutlook, seDivider] := $00e1e1e1; { shared }
  SchemeColor[csOutlook, seHighlight] := $00f7e6cd;
  SchemeColor[csOutlook, seTabBtnFace] := $00ffffff;
  SchemeColor[csOutlook, seTabFace] := $00ffffff;
  SchemeColor[csOutlook, seTabFaceHot] := $00f7e6cd;
  SchemeColor[csOutlook, seTabText] := $00000000;
  SchemeColor[csOutlook, seStatusText] := clWhite;
  SchemeColor[csOutlook, seTrackBar] := clLime;
  SchemeColor[csOutlook, seWindowFrame] := $00b5aca5;

  SchemeColor[csWord, seAppWorkSpace] := $00ffffff;
  SchemeColor[csWord, seMenu] := $009a572b; //
  SchemeColor[csWord, seBtnFace] := $00f2e1d5; //       $00F2E1D5
  SchemeColor[csWord, seBtnFrame] := $00ababab; { shared }
  SchemeColor[csWord, seBtnFramePressed] := $00b56d3e; //
  SchemeColor[csWord, seBtnFacePressed] := $00e3bda3; //      $00E3BDA3
  SchemeColor[csWord, seBtnFaceChecked] := $00f2d5c2; // $00F2D5C2
  SchemeColor[csWord, seDivider] := $00e1e1e1; { shared }
  SchemeColor[csWord, seHighlight] := $00f2e1d5; //
  SchemeColor[csWord, seTabBtnFace] := $00ffffff;
  SchemeColor[csWord, seTabFace] := $00ffffff;
  SchemeColor[csWord, seTabFaceHot] := $00f2e1d5;
  SchemeColor[csWord, seTabText] := $00000000;
  SchemeColor[csWord, seStatusBtnFace] := $00b56d3e;
  SchemeColor[csWord, seStatusBtnFacePressed] := $008a4719;
  SchemeColor[csWord, seStatusText] := clWhite;
  SchemeColor[csWord, seTrackBar] := $00d9b298;
  SchemeColor[csWord, seWindowFrame] := $00b5aca5;    //b5aca5

  SchemeColor[csPowerPoint, seAppWorkSpace] := $00ffffff;
  SchemeColor[csPowerPoint, seMenu] := $002647d2; //
  SchemeColor[csPowerPoint, seBtnFace] := $00dce4fc; //
  SchemeColor[csPowerPoint, seBtnFrame] := $00ababab; { shared }
  SchemeColor[csPowerPoint, seBtnFramePressed] := $009dbaf5;
  SchemeColor[csPowerPoint, seBtnFacePressed] := $009dbaf5; //
  SchemeColor[csPowerPoint, seBtnFaceChecked] := $00b6cdfc; //
  SchemeColor[csPowerPoint, seDivider] := $00e1e1e1; { shared }
  SchemeColor[csPowerPoint, seHighlight] := $00dce4fc; //
  SchemeColor[csPowerPoint, seTabBtnFace] := $00ffffff;
  SchemeColor[csPowerPoint, seTabFace] := $00ffffff;
  SchemeColor[csPowerPoint, seTabFaceHot] := $00dce4fc;
  SchemeColor[csPowerPoint, seTabText] := $00000000;
  SchemeColor[csPowerPoint, seStatusBtnFace] := $003e62f0;
  SchemeColor[csPowerPoint, seStatusBtnFacePressed] := $001d3bb8;
  SchemeColor[csPowerPoint, seStatusText] := clWhite;
  SchemeColor[csPowerPoint, seTrackBar] := clLime;
  SchemeColor[csPowerPoint, seWindowFrame] := $00b5aca5;

  SchemeColor[csExcel, seAppWorkSpace] := $00ffffff;
  SchemeColor[csExcel, seMenu] := $00467321;
  SchemeColor[csExcel, seBtnFace] := $00e0f0d3;
  SchemeColor[csExcel, seBtnFrame] := $00ababab; { shared }
  SchemeColor[csExcel, seBtnFramePressed] := $00679443;
  SchemeColor[csExcel, seBtnFacePressed] := $00a0bf86;
  SchemeColor[csExcel, seBtnFaceChecked] := $00b7d59f;
  SchemeColor[csExcel, seDivider] := $00e1e1e1; { shared }
  SchemeColor[csExcel, seHighlight] := $00dce4fc;
  SchemeColor[csExcel, seTabBtnFace] := $00ffffff;
  SchemeColor[csExcel, seTabFace] := $00ffffff;
  SchemeColor[csExcel, seTabFaceHot] := $00e0f0d3;
  SchemeColor[csExcel, seTabText] := $00000000;
  SchemeColor[csExcel, seStatusBtnFace] := $00679443;
  SchemeColor[csExcel, seStatusBtnFacePressed] := $0032630a;
  SchemeColor[csExcel, seStatusText] := clWhite;
  SchemeColor[csExcel, seTrackBar] := $00b0cc99;
  SchemeColor[csExcel, seWindowFrame] := $00b5aca5;

  SchemeColor[csVisualStudioBlue, seAppWorkSpace] := $00553929;
  SchemeColor[csVisualStudioBlue, seMenu] := $00553929;
  SchemeColor[csVisualStudioBlue, seBtnFace] := $00bff4fd;
  SchemeColor[csVisualStudioBlue, seBtnFrame] := $0065c3e5;
  SchemeColor[csVisualStudioBlue, seBtnFramePressed] := $0065c3e5;
  SchemeColor[csVisualStudioBlue, seBtnFacePressed] := $009df2ff;
  SchemeColor[csVisualStudioBlue, seBtnFaceChecked] := $009df2ff;
  SchemeColor[csVisualStudioBlue, seDivider] := $00e1e1e1; { shared }
  SchemeColor[csVisualStudioBlue, seHighlight] := $00bff4fd;
  SchemeColor[csVisualStudioBlue, seTabFace] := $006f4e36;
  SchemeColor[csVisualStudioBlue, seTabFaceHot] := $0099715b;
  SchemeColor[csVisualStudioBlue, seTabText] := $00ffffff;
  SchemeColor[csVisualStudioBlue, seTabBtnFace] := $00f4fcff;
  SchemeColor[csVisualStudioBlue, seTrackBar] := clLime;
  SchemeColor[csVisualStudioBlue, seWindowFrame] := $00b5aca5;

end.
