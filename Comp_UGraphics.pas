unit Comp_UGraphics;

interface

uses
  Controls, Types, Windows, Messages, Graphics, Classes,
  Comp_UTypes;

procedure EraseBackground(Control: TCustomControl; Canvas: TCanvas);
function RectInRect(Container, Target: TRect): Boolean;
procedure AlphaBlend(Canvas: TCanvas; Bitmap: TBitmap; const X, Y: Integer);
procedure ColorOverlay(Canvas: TCanvas; Source: TRect; Color: TColor; const Alpha: Byte);
procedure PaintEffects(Canvas: TCanvas; Dest: TRect; Effects: TScPaintEffects);
procedure DrawShadow(Canvas: TCanvas; InnerRct: TRect; Size: Integer); overload;
procedure DrawShadow(Canvas: TCanvas; Inner: TRect; Orientation: TScOrientation); overload;
function IsColorLight(Color: TColor): Boolean;
function DarkerColor(Color: TColor; Percent: Byte): TColor;
function LighterColor(Color: TColor; Percent: Byte): TColor;
procedure FillPadding(Canvas: TCanvas; Color: TColor; Dest: TRect; Padding: TPadding);
function ColorOf(E: TScColorSchemeElement; Scheme: TScColorScheme = csDefault): TColor;
procedure DrawTextRect(Canvas: TCanvas; TextRect: TRect; Alignment: TAlignment;
  VertAlignment: TVerticalAlignment; Text: WideString; WrapKind: TScWrapKind);

var
  UnicodeSupported: Boolean;

implementation

uses
  Math;

function ColorOf(E: TScColorSchemeElement; Scheme: TScColorScheme = csDefault): TColor;
begin
  if Scheme = csDefault then Scheme := ColorScheme;
  Result := SchemeColor[Scheme, E];
end;

procedure EraseBackground(Control: TCustomControl; Canvas: TCanvas);
var
  Shift, Pt: TPoint;
  DC: HDC;
begin
  if Control.Parent = nil then Exit;
  if Control.Parent.HandleAllocated then
  begin
    DC := Canvas.Handle;
    Shift.X := 0;
    Shift.Y := 0;
    Shift := Control.Parent.ScreenToClient(Control.ClientToScreen(Shift));
    SaveDC(DC);
    try
      OffsetWindowOrgEx(DC, Shift.X, Shift.Y, nil);
      GetBrushOrgEx(DC, Pt);
      SetBrushOrgEx(DC, Pt.X + Shift.X, Pt.Y + Shift.Y, nil);
      Control.Parent.Perform(WM_ERASEBKGND, WParam(DC), 0);
      Control.Parent.Perform(WM_PAINT, WParam(DC), 0);
    finally
      RestoreDC(DC, -1);
    end;
  end;
end;

function RectInRect(Container, Target: TRect): Boolean;
begin
  Result := PtInRect(Container, Target.TopLeft)
    and PtInRect(Container, Point(Pred(Target.Right), Pred(Target.Bottom)));
end;

procedure AlphaBlend(Canvas: TCanvas; Bitmap: TBitmap; const X, Y: Integer);
var
  Func: TBlendFunction;
begin
  { Blending Params }
  Func.BlendOp := AC_SRC_OVER;
  Func.BlendFlags := 0;
  Func.SourceConstantAlpha := 255;
  Func.AlphaFormat := AC_SRC_ALPHA;

  { Do Blending }
  Windows.AlphaBlend(Canvas.Handle, X, Y, Bitmap.Width, Bitmap.Height, Bitmap.Canvas.Handle,
    0, 0, Bitmap.Width, Bitmap.Height, Func);
end;

procedure ColorOverlay(Canvas: TCanvas; Source: TRect; Color: TColor; const Alpha: Byte);
var
  Row, Col: Integer;
  Pixel: PQuadColor;
  Mask: TBitmap;
begin
  if Alpha = 255 then
  begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(Source);

    { Skip complex computings }
    Exit;
  end;

  { Convert SystemColor }
  if Integer(Color) < 0 then Color := GetSysColor(Color and $000000FF);

  { 10/26/11: We create an Alpha Mask TBitmap here which
              will be aplied into Canvas }
  Mask := TBitmap.Create;

  with Mask do
  begin
    { Important for AlphaBlend Func }
    PixelFormat := pf32bit;
    { Set Size of Mask }
    Width := Source.Right - Source.Left;
    Height := Source.Bottom - Source.Top;
  end;

  for Row := 0 to Pred(Mask.Height) do
  begin
    { Read first Pixel in row }
    Pixel := Mask.Scanline[Row];

    for Col := 0 to Pred(Mask.Width) do
    begin
      Pixel.Red := GetRValue(Color);
      Pixel.Green := GetGValue(Color);
      Pixel.Blue := GetBValue(Color);

      { Set Alpha }
      Pixel.Alpha := Alpha;

      { Premultiply R, G & B }
      Pixel.Red := MulDiv(Pixel.Red, Pixel.Alpha, $FF);
      Pixel.Green := MulDiv(Pixel.Green, Pixel.Alpha, $FF);
      Pixel.Blue := MulDiv(Pixel.Blue, Pixel.Alpha, $FF);

      { Move to next Pixed }
      Inc(Pixel);

    end; { for Col }

  end; { for Row }

  { Call Blending Func }
  AlphaBlend(Canvas, Mask, Source.Left, Source.Top);

  { Release }
  Mask.Free;
end;

function IsColorLight(Color: TColor): Boolean;
begin
  Color := ColorToRGB(Color);
  Result := ((Color and $FF) + (Color shr 8 and $FF) + (Color shr 16 and $FF))>= $180;
end;

function DarkerColor(Color: TColor; Percent: Byte): TColor;
var
  r, g, b: Byte;
begin
  Color := ColorToRGB(Color);
  r := GetRValue(Color);
  g := GetGValue(Color);
  b := GetBValue(Color);
  r := r - MulDiv(r, Percent, 100); //Percent% closer to black
  g := g - MulDiv(g, Percent, 100);
  b := b - MulDiv(b, Percent, 100);
  Result := RGB(r, g, b);
end;

function LighterColor(Color: TColor; Percent: Byte): TColor;
var
  r, g, b: Byte;
begin
  Color := ColorToRGB(Color);
  r := GetRValue(Color);
  g := GetGValue(Color);
  b := GetBValue(Color);
  r := r + MulDiv(255 - r, Percent, 100);
  g := g + MulDiv(255 - g, Percent, 100);
  b := b + MulDiv(255 - b, Percent, 100);
  Result := RGB(r, g, b);
end;

procedure FillPadding(Canvas: TCanvas; Color: TColor; Dest: TRect; Padding: TPadding);
begin
  with Canvas, Padding do
  begin
    Brush.Color := Color;

    FillRect(Rect(Dest.Left + Left, Dest.Top, Dest.Right - Right, Dest.Top + Top));
    FillRect(Rect(Dest.Left, Dest.Top, Dest.Left + Left, Dest.Bottom));
    FillRect(Rect(Dest.Right - Right, Dest.Top, Dest.Right, Dest.Bottom));
    FillRect(Rect(Dest.Left + Left, Dest.Bottom - Bottom, Dest.Right - Right, Dest.Bottom));
  end;
end;

function GetTextSize(Handle: HDC; TextRect: TRect; Text: WideString): TSize;
var
  Flags: Integer;
{$IFNDEF UNICODE}
  StringText: string;
{$ENDIF}
begin
  Flags := DT_NOPREFIX or DT_VCENTER or DT_END_ELLIPSIS or DT_EXTERNALLEADING
    or DT_CALCRECT or DT_WORDBREAK;
  case UnicodeSupported of
    True:
      DrawTextW(Handle, PWideChar(Text), Length(Text), TextRect, Flags);
    False:
      begin
        {$IFDEF UNICODE}
        DrawText(Handle, PWideChar(Text), Length(Text), TextRect, Flags);
        {$ELSE}
        StringText := Text;
        DrawText(Handle, PAnsiChar(StringText), Length(StringText), TextRect, Flags);
        {$ENDIF}
      end;
  end;
  with Result do
  begin
    cx := TextRect.Right - TextRect.Left;
    cy := TextRect.Bottom - TextRect.Top;
  end;
end;

procedure DrawTextRect(Canvas: TCanvas; TextRect: TRect; Alignment: TAlignment;
  VertAlignment: TVerticalAlignment; Text: WideString; WrapKind: TScWrapKind);
var
  Flags: Integer;
{$IFNDEF UNICODE}
  StringText: string;
{$ENDIF}
  TextSize: TSize;
begin
  Flags := DT_NOPREFIX or DT_EXTERNALLEADING;

  if WrapKind <> wkWordWrap then
  begin
    Flags := Flags or DT_SINGLELINE;
  end;

  { Vert Alignment }
  case VertAlignment of
    taAlignTop: Flags := Flags or DT_TOP;
    taAlignBottom: Flags := Flags or DT_BOTTOM;
    taVerticalCenter: Flags := Flags or DT_VCENTER;
  end;

  { Wrapping }
  case WrapKind of
    wkNone: ;
    wkEllipsis: Flags := Flags or DT_END_ELLIPSIS;
    wkPathEllipsis: Flags := Flags or DT_PATH_ELLIPSIS;
    wkWordEllipsis: Flags := Flags or DT_WORD_ELLIPSIS;
    wkWordWrap:
    begin
      Flags := Flags or DT_WORDBREAK or DT_TOP;
      if VertAlignment <> taAlignTop then
      begin
        TextSize := GetTextSize(Canvas.Handle, TextRect, Text);
        case VertAlignment of
          taVerticalCenter: OffsetRect(TextRect, 0, Floor(RectHeight(TextRect) / 2 - TextSize.cy / 2));
          taAlignBottom: TextRect.Top := TextRect.Bottom - RectHeight(TextRect);
        end;
      end;
    end;
  end;

  { Horz Alignment }
  case Alignment of
    taLeftJustify: Flags := Flags or DT_LEFT;
    taRightJustify: Flags := Flags or DT_RIGHT;
    Classes.taCenter: Flags := Flags or DT_CENTER;
  end;

  { Draw Text }
  with Canvas.Brush do
  begin
    Style := bsClear;
    case UnicodeSupported of
      True: DrawTextW(Canvas.Handle, PWideChar(Text), Length(Text), TextRect, Flags);
      else
      begin
        {$IFDEF UNICODE}
        DrawText(Canvas.Handle, PWideChar(Text), Length(Text), TextRect, Flags);
        {$ELSE}
        StringText := Text;
        DrawText(Canvas.Handle, PAnsiChar(StringText), Length(StringText), TextRect, Flags);
        {$ENDIF}
      end;
    end;
    Style := bsSolid;
  end;
end;

procedure DrawShadow(Canvas: TCanvas; InnerRct: TRect; Size: Integer);
begin
  { Draw Horz Shadow }
  DrawShadow(Canvas, Rect(InnerRct.Left, InnerRct.Bottom, InnerRct.Right + Size, InnerRct.Bottom + Size), orHorizontal);

  { Draw Vert Shadow }
  DrawShadow(Canvas, Rect(InnerRct.Right, InnerRct.Top, InnerRct.Right + Size, InnerRct.Bottom + Size - 1), orVertical);
end;

procedure DrawShadow(Canvas: TCanvas; Inner: TRect; Orientation: TScOrientation);
var
  Row, Col: Integer;
  Alpha: Single;
  Pixel: PQuadColor;
  AlphaByte: Byte;
  Mask: TBitmap;
begin
  { 10/26/11: We create an Alpha Mask TBitmap here which
              will be aplied into Canvas }
  Mask := TBitmap.Create;

  with Mask do
  begin
    { Important for AlphaBlend Func }
    PixelFormat := pf32bit;
    { Set Size of Mask }
    Width := Inner.Right - Inner.Left;
    Height := Inner.Bottom - Inner.Top;
  end;

  for Row := 0 to Pred(Mask.Height) do
  begin
    { Read first Pixel in row }
    Pixel := Mask.Scanline[Row];

    for Col := 0 to Pred(Mask.Width) do
    begin
      Pixel.Red := 0;
      Pixel.Green := 0;
      Pixel.Blue := 0;

      { Determine Alpha Level }
      case Orientation of
        orHorizontal:
          begin
            Alpha := (Mask.Height - Row) / Mask.Height;
            if Col < Mask.Height then Alpha := Alpha * (Col / Mask.Height)
            else if Col > Mask.Width - Mask.Height then
            begin
              Alpha := Alpha * ((Mask.Width - Col) / Mask.Height);
            end;
          end;
        else
          begin
            Alpha := (Mask.Width - Col) / Mask.Width;
            if Row < Mask.Width then Alpha := Alpha * (Row / Mask.Width)
            else if Row > Mask.Height - Mask.Width then
            begin
              Alpha := 0;//Alpha * ((Mask.Height - Row) / Mask.Width);
            end;
          end;
      end;

      Alpha := Alpha * 0.20;

      { Convert 0-1 to 0-255 }
      AlphaByte := Round(Alpha * 255.0);

      { Set Alpha }
      Pixel.Alpha := AlphaByte;

      { Premultiply R, G & B }
      Pixel.Red := Round(Pixel.Red * Alpha);
      Pixel.Green := Round(Pixel.Green * Alpha);
      Pixel.Blue := Round(Pixel.Blue * Alpha);

      { Move to next Pixed }
      Inc(Pixel);

    end; { for Col }

  end; { for Row }

  { Call Blending Func }
  AlphaBlend(Canvas, Mask, Inner.Left, Inner.Top);

  { Release }
  Mask.Free;
end;

procedure DrawLight(Canvas: TCanvas; InnerRct: TRect; Size: Integer); overload;
var
  Row, Col, Middle: Integer;
  Alpha: Single;
  Pixel: PQuadColor;
  AlphaByte: Byte;
  Mask: TBitmap;
begin
  { 10/26/11: We create an Alpha Mask TBitmap here which
              will be aplied into Canvas }
  Mask := TBitmap.Create;

  Middle := ((InnerRct.Right - InnerRct.Left) div 3) * 2;

  if Middle = 0 then Exit;

  with Mask do
  begin
    { Important for AlphaBlend Func }
    PixelFormat := pf32bit;

    { Set Size of Mask }
    Width := InnerRct.Right - InnerRct.Left;
    Height := InnerRct.Bottom - InnerRct.Top;
  end;

  for Row := 0 to Pred(Mask.Height) do
  begin
    { Read first Pixel in row }
    Pixel := Mask.Scanline[Row];

    for Col := 0 to Pred(Mask.Width) do
    begin
      Pixel.Red := 255;
      Pixel.Green := 255;
      Pixel.Blue := 255;

      { Determine Alpha Level }
      Alpha := (Middle - Row) / Middle;

      { Convert 0-1 to 0-255 }
      AlphaByte := Round(Alpha * 255.0);

      if Col + Row > Middle then AlphaByte := 0;

      { Set Alpha }
      Pixel.Alpha := AlphaByte;

      { Premultiply R, G & B }
      Pixel.Red := Round(Pixel.Red * Alpha);
      Pixel.Green := Round(Pixel.Green * Alpha);
      Pixel.Blue := Round(Pixel.Blue * Alpha);

      { Move to next Pixed }
      Inc(Pixel);

    end; { for Col }

  end; { for Row }

  { Call Blending Func }
  AlphaBlend(Canvas, Mask, InnerRct.Left, InnerRct.Top);

  { Release }
  Mask.Free;
end;

procedure FlipVert(Source: TBitmap);
var
  Col, Row: integer;
  PixelSrc, PixelDest: PQuadColor;
begin
  for Row := 0 to Pred(Source.Height) do
  begin
    PixelSrc := Source.ScanLine[Row];;
    PixelDest := Source.ScanLine[Source.Height - 1 - Row];
    for Col := 0 to Pred(Source.Width) do
    begin
      PixelSrc.Red := PixelDest.Red;
      PixelSrc.Green := PixelDest.Green;
      PixelSrc.Blue := PixelDest.Blue;

      Inc(PixelSrc);
      Inc(PixelDest);
    end;
  end;
end;

procedure DrawReflection(Canvas: TCanvas; InnerRct: TRect; Size: Integer);
var
  Row, Col: Integer;
  Alpha: Single;
  Pixel: PQuadColor;
  AlphaByte: Byte;
  Mask: TBitmap;
begin
  { 10/26/11: We create an Alpha Mask TBitmap here which
              will be aplied into Canvas }
  Mask := TBitmap.Create;

  with Mask do
  begin
    { Important for AlphaBlend Func }
    PixelFormat := pf32bit;
    { Set Size of Mask }
    Width := InnerRct.Right - InnerRct.Left;
    Height := InnerRct.Bottom - InnerRct.Top;
  end;

  { Copy TRect from Canvas into Bitmap }
  Mask.Canvas.CopyRect(Rect(0, 0, Mask.Width, Mask.Height), Canvas, InnerRct);

  { Flip Bitmap }
  FlipVert(Mask);

  for Row := 0 to Pred(Mask.Height) do
  begin
    { Read first Pixel in row }
    Pixel := Mask.Scanline[Row];

    for Col := 0 to Pred(Mask.Width) do
    begin
      if Row < Size
        then Alpha := (Size - Row) / Size
        else Alpha := 0;

      { Convert 0-1 to 0-255 }
      AlphaByte := Round(Alpha * 255.0);

      { Set Alpha }
      Pixel.Alpha := AlphaByte;

      { Premultiply R, G & B }
      Pixel.Red := Round(Pixel.Red * Alpha);
      Pixel.Green := Round(Pixel.Green * Alpha);
      Pixel.Blue := Round(Pixel.Blue * Alpha);

      { Move to next Pixed }
      Inc(Pixel);

    end; { for Col }

  end; { for Row }

  { Call Blending Func }
  AlphaBlend(Canvas, Mask, InnerRct.Left, InnerRct.Bottom + 1);

  { Release }
  Mask.Free;
end;

procedure PaintEffects(Canvas: TCanvas; Dest: TRect; Effects: TScPaintEffects);
begin
  { Add Shadow }
  if efShadow in Effects then
  begin
    { Add Right & Bottom Shadow }
    DrawShadow(Canvas, Dest, szShadowSize);
  end;

  { Add Light }
  if efLight in Effects then
  begin
    DrawLight(Canvas, Dest, szReflectionSize);
  end;

  { Add Reflection }
  if efReflection in Effects then
  begin
    DrawReflection(Canvas, Dest, szReflectionSize);
  end;
end;

end.
