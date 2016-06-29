unit Comp_UFlipPanel;

interface

uses
  Controls, Messages, Classes, Windows, Graphics, Types,
  Comp_UControls, Comp_UTypes, Comp_UIntf;

const
  szFlipPanelHeaderHeight = 20;

  { Padding }
  pdStandard = 2;
  pdDouble = pdStandard * 2;
  pdEditToText = 4;
  pdTextToIcon = 4;
  pdHorz = 2;
  pdVert = 1;

type

  TScCollectionControl = class(TScControl)  //class(TScStyledControl)
  private
    FAlpha: Byte;
    function GetControlName: string;
    procedure SetAlpha(const Value: Byte);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    { Windows Messages }
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Assign(Source: TPersistent); override;
    { Properties }
    property DoubleBuffered;
  published
    property Alpha: Byte read FAlpha write SetAlpha default 255;
    property ControlName: string read GetControlName;
  end;

  TScBorders = set of (bdBottom, bdLeft, bdRight, bdTop);
  TScPanelStyle = (pnSolid, pnGradient, pnInverseGradient);

  TScPanel = class(TScCollectionControl)
  private
    FBorders: TScBorders;
    FCaption: WideString;
    FEffects: TScPaintEffects;
    FPen: TPen;
    procedure SetBorders(const Value: TScBorders);
    procedure SetCaption(const Value: WideString);
    procedure SetEffects(const Value: TScPaintEffects);
    procedure SetPen(const Value: TPen);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoCaptionChange; virtual;
    procedure DoChange(Sender: TObject);
    function GetPanelRect: TRect; virtual;
    procedure Paint; override;
    { Windows Messages }
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Methods }
    procedure Assign(Source: TPersistent); override;
  published
    { Properties }
    property Borders: TScBorders read FBorders write SetBorders default [bdBottom, bdLeft, bdRight, bdTop];
    property Caption: WideString read FCaption write SetCaption;
    property Effects: TScPaintEffects read FEffects write SetEffects default [];
    property Pen: TPen read FPen write SetPen;
  end;

  TScHeaderLayout = (hlLeftToRight, hlRightToLeft);
  TScFlipChangeArea = (faButton, faHeader, faNone);
  TScGlyphPosition = (gpBeforeText, gpAfterText);

  TScFlipPanel = class(TScPanel, ITogglable)
  private
    FExpanded: Boolean;
    FFlipChangeArea: TScFlipChangeArea;
    FFullHeight: Integer;
    FGlyph: TPicture;
    FGlyphCollapse: TBitmap;
    FGlyphExpand: TBitmap;
    FGlyphPosition: TScGlyphPosition;
    FHeaderBorderColor: TColor;
    FHeaderColor: TColor;
    FHeaderFont: TFont;
    FHeaderHeight: Integer;
    FHeaderIndent: Integer;
    FHeaderLayout: TScHeaderLayout;
    FHeaderState: TScButtonState;
    FHeaderStyle: TScAppearanceStyle;
    FHeaderStyleOptions: TScStyleOptions;
    FHotTrack: Boolean;
    FPanelPadding: TPadding;
    FParentHeaderFont: Boolean;
    FShowHeader: Boolean;
    FShowToggleButton: Boolean;
    FToggleButtonStyle: TScToggleButtonStyle;
    function GetToggleButtonStyle: TScToggleButtonStyle;
    function GetToggleSize: TSize;
    procedure SetExpanded(const Value: Boolean);
    procedure SetGlyph(const Value: TPicture);
    procedure SetGlyphCollapse(const Value: TBitmap);
    procedure SetGlyphExpand(const Value: TBitmap);
    procedure SetGlyphPosition(const Value: TScGlyphPosition);
    procedure SetHeaderBorderColor(const Value: TColor);
    procedure SetHeaderColor(const Value: TColor);
    procedure SetHeaderFont(const Value: TFont);
    procedure SetHeaderHeight(const Value: Integer);
    procedure SetHeaderIndent(const Value: Integer);
    procedure SetHeaderLayout(const Value: TScHeaderLayout);
    procedure SetHeaderState(const Value: TScButtonState);
    procedure SetHeaderStyle(const Value: TScAppearanceStyle);
    procedure SetHeaderStyleOptions(const Value: TScStyleOptions);
    procedure SetHotTrack(const Value: Boolean);
    procedure SetPanelPadding(const Value: TPadding);
    procedure SetParentHeaderFont(const Value: Boolean);
    procedure SetShowHeader(const Value: Boolean);
    procedure SetShowToggleButton(const Value: Boolean);
    procedure SetToggleStyle(const Value: TScToggleButtonStyle);
  protected
    { Event Handlers }
    procedure DoChange; dynamic;
    procedure DoCaptionChange; override;
    procedure DoHeaderChange(Sender: TObject);
    procedure DoHeaderFontChange(Sender: TObject);
    procedure DoInnerPaddingChange(Sender: TObject);
    procedure DoPaddingChange(Sender: TObject); override;
    function GetHeaderRect: TRect; virtual;
    function GetPanelRect: TRect; override;
    function GetToggleRect: TRect; virtual;
    { Stream Methods }
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadFullHeight(Reader: TReader);
    procedure WriteFullHeight(Writer: TWriter);
    { Overrided Methods }
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    { Methods }
    procedure InvalidateHeader;
    procedure PaintHeader(HeaderRect: TRect); virtual;
    procedure PaintToggle(X: Integer);
    { Delphi Messages }
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    { WinApi Messages }
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Methods }
    procedure Assign(Source: TPersistent); override;
    procedure Flip;
    { Properties }
    property ToggleRect: TRect read GetToggleRect;
    property ToggleSize: TSize read GetToggleSize;
    property HeaderState: TScButtonState read FHeaderState write SetHeaderState;
  published
    { Properties }
    property Expanded: Boolean read FExpanded write SetExpanded default True;
    property FlipChangeArea: TScFlipChangeArea read FFlipChangeArea write FFlipChangeArea default faButton;
    property Glyph: TPicture read FGlyph write SetGlyph;
    property GlyphCollapse: TBitmap read FGlyphCollapse write SetGlyphCollapse;
    property GlyphExpand: TBitmap read FGlyphExpand write SetGlyphExpand;
    property GlyphPosition: TScGlyphPosition read FGlyphPosition write SetGlyphPosition default gpBeforeText;
    property HeaderBorderColor: TColor read FHeaderBorderColor write SetHeaderBorderColor default clBtnShadow;
    property HeaderColor: TColor read FHeaderColor write SetHeaderColor default clBtnFace;
    property HeaderFont: TFont read FHeaderFont write SetHeaderFont;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default szFlipPanelHeaderHeight;
    property HeaderLayout: TScHeaderLayout read FHeaderLayout write SetHeaderLayout default hlLeftToRight;
    property HeaderStyle: TScAppearanceStyle read FHeaderStyle write SetHeaderStyle
      default stNative;
    property HeaderStyleOptions: TScStyleOptions read FHeaderStyleOptions
      write SetHeaderStyleOptions default [soNativeStyles, soVCLStyles];
    property HeaderIndent: Integer read FHeaderIndent write SetHeaderIndent default pdDouble;
    property HotTrack: Boolean read FHotTrack write SetHotTrack default False;
    property PanelPadding: TPadding read FPanelPadding write SetPanelPadding;
    property ParentHeaderFont: Boolean read FParentHeaderFont write SetParentHeaderFont default True;
    property ShowHeader: Boolean read FShowHeader write SetShowHeader default True;
    property ShowToggleButton: Boolean read FShowToggleButton write SetShowToggleButton default True;
    property ToggleButtonStyle: TScToggleButtonStyle read GetToggleButtonStyle write SetToggleStyle default tsSquare;
  end;

var
  UnicodeSupported: Boolean;

implementation

uses
  SysUtils, Forms, Math, Comp_UGraphics;

{$REGION 'TScCollectionControl'}
{ TScCollectionControl }

procedure TScCollectionControl.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TScCollectionControl then
  begin
    Alpha := TScCollectionControl(Source).Alpha;
  end;
end;

constructor TScCollectionControl.Create(AOwner: TComponent);
begin
  inherited;
  FAlpha := 255;
end;

procedure TScCollectionControl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  with Params do
  begin
    if Alpha < 255 then ExStyle := ExStyle or WS_EX_TRANSPARENT;
  end;
end;

function TScCollectionControl.GetControlName: string;
begin
  Result := ClassName;
end;

procedure TScCollectionControl.Paint;
begin
  inherited;
  if Alpha < 255 then
  begin
    EraseBackground(Self, Canvas);
  end;
end;

procedure TScCollectionControl.SetAlpha(const Value: Byte);
var
  Update: Boolean;
begin
  if Value <> FAlpha then
  begin
    { Not solid anymore }
    Update := FAlpha = 255;

    FAlpha := Value;

    { Call CreateParams }
    if Update then RecreateWnd;

    Invalidate;
  end;
end;

procedure TScCollectionControl.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TScCollectionControl.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  inherited;
  if Alpha < 255 then Invalidate;
end;

procedure TScCollectionControl.WMWindowPosChanging(var Message: TWMWindowPosChanging);
begin
  inherited;
  if Alpha < 255 then Invalidate;
end;
{$ENDREGION}

{$REGION 'TScPanel'}
{ TScPanel }

procedure TScPanel.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TScPanel then
  begin
    Borders := TScPanel(Source).Borders;
    Pen.Assign(TScPanel(Source).Pen);
  end;
end;

constructor TScPanel.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents,
    csDoubleClicks, csReplicatable, csSetCaption];

  FBorders := [bdBottom, bdLeft, bdRight, bdTop];
  FEffects := [];
  FPen := TPen.Create;
end;

procedure TScPanel.CreateParams(var Params: TCreateParams);
begin
  inherited;
  with Params do
  begin
    with WindowClass do Style := Style and not CS_HREDRAW and not CS_VREDRAW;
  end;
end;

destructor TScPanel.Destroy;
begin
  FreeAndNil(FPen);
  inherited;
end;

procedure TScPanel.DoCaptionChange;
begin

end;

procedure TScPanel.DoChange(Sender: TObject);
begin
  Invalidate;
end;

function TScPanel.GetPanelRect: TRect;
begin
  Result := ClientRect;
end;

procedure TScPanel.Paint;
var
  FillColor: TColor;
begin
  inherited;

  { Panel (content) paint }
  if RectInRect(ClientRect, GetPanelRect) then
  begin
    { Default, no style }
    FillColor := Color;

    { Only Delphi Style can have own color }
//    if CanStyle(soVCLStyles) then
//    begin
//      FillColor := TScPanelPaintStyle.GetFillColor(Self, FillColor);
//    end;

    { Fill with Color }
    ColorOverlay(Canvas, GetPanelRect, FillColor, Alpha);

    { Apply Filters & Effects }
    PaintEffects(Canvas, GetPanelRect, Effects);
  end;
end;

procedure TScPanel.SetBorders(const Value: TScBorders);
begin
  if Value <> FBorders then
  begin
    FBorders := Value;
    Invalidate;
  end;
end;

procedure TScPanel.SetCaption(const Value: WideString);
begin
  if Value <> FCaption then
  begin
    FCaption := Value;

    { Virtual }
    DoCaptionChange;
  end;
end;

procedure TScPanel.SetEffects(const Value: TScPaintEffects);
begin
  if Value <> FEffects then
  begin
    FEffects := Value;
    Invalidate;
  end;
end;

procedure TScPanel.SetPen(const Value: TPen);
begin
  FPen.Assign(Value);

  if Assigned(FPen)
    then FPen.OnChange := DoChange;

  Invalidate;
end;

procedure TScPanel.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TScPanel.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  inherited;

end;
{$ENDREGION}

{$REGION 'TScFlipPanel'}
{ TScFlipPanel }

procedure TScFlipPanel.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  Inc(Rect.Top, FHeaderHeight + FPanelPadding.Top);
  Inc(Rect.Left, FPanelPadding.Left);
  Dec(Rect.Bottom, FPanelPadding.Bottom);
  Dec(Rect.Right, FPanelPadding.Right);
end;

procedure TScFlipPanel.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TScFlipPanel then
  begin
    Expanded := TScFlipPanel(Source).Expanded;
    FlipChangeArea := TScFlipPanel(Source).FlipChangeArea;
    Glyph.Assign(TScFlipPanel(Source).Glyph);
    GlyphCollapse.Assign(TScFlipPanel(Source).Glyph);
    GlyphExpand.Assign(TScFlipPanel(Source).Glyph);
    GlyphPosition := TScFlipPanel(Source).GlyphPosition;
    HeaderBorderColor := TScFlipPanel(Source).HeaderBorderColor;
    HeaderColor := TScFlipPanel(Source).HeaderColor;
    HeaderFont.Assign(TScFlipPanel(Source).HeaderFont);
    HeaderHeight := TScFlipPanel(Source).HeaderHeight;
    HeaderIndent := TScFlipPanel(Source).HeaderIndent;
    HeaderStyle := TScFlipPanel(Source).HeaderStyle;
    HotTrack := TScFlipPanel(Source).HotTrack;
    ParentHeaderFont := TScFlipPanel(Source).ParentHeaderFont;
    ShowHeader := TScFlipPanel(Source).ShowHeader;
    ShowToggleButton := TScFlipPanel(Source).ShowToggleButton;
    ToggleButtonStyle := TScFlipPanel(Source).ToggleButtonStyle;
  end;
end;

procedure TScFlipPanel.CMDialogChar(var Message: TCMDialogChar);
begin
  inherited;
  with Message do
  begin
    if IsAccel(CharCode, Caption) then
    begin
      Flip;
      Result := 1;
    end else inherited;
  end;
end;

procedure TScFlipPanel.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if ParentHeaderFont then
  begin
    HeaderFont.OnChange := nil;
    HeaderFont := Font;
  end;
end;

procedure TScFlipPanel.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  HeaderState := HeaderState - [bsHover];
end;

procedure TScFlipPanel.CMTextChanged(var Message: TMessage);
begin
  inherited;
end;

constructor TScFlipPanel.Create(AOwner: TComponent);
begin
  inherited;
  FExpanded := True;
  FFlipChangeArea := faButton;
  FGlyph := TPicture.Create;
  FGlyph.OnChange := DoHeaderChange;
  FGlyphCollapse := TBitmap.Create;
  FGlyphCollapse.OnChange := DoHeaderChange;
  FGlyphExpand := TBitmap.Create;
  FGlyphExpand.OnChange := DoHeaderChange;
  FGlyphPosition := gpBeforeText;
  FHeaderBorderColor := clBtnShadow;
  FHeaderColor := clBtnFace;
  FHeaderFont := TFont.Create;
  FHeaderFont.OnChange := DoHeaderFontChange;
  FHeaderHeight := szFlipPanelHeaderHeight;
  FHeaderIndent := pdDouble;
  FHeaderLayout := hlLeftToRight;
  FHeaderState := [];
  FHeaderStyle := stNative;
  FHeaderStyleOptions := [soNativeStyles, soVCLStyles];
  FHotTrack := False;
  FPanelPadding := TPadding.Create(nil);
  FPanelPadding.OnChange := DoInnerPaddingChange;
  FParentHeaderFont := True;
  FShowToggleButton := True;
  FShowHeader := True;
  FToggleButtonStyle := tsSquare;
  Height := 128;
  Width := 128;
end;

procedure TScFlipPanel.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    with WindowClass do Style := Style or CS_HREDRAW or CS_VREDRAW;
  end;
end;

procedure TScFlipPanel.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('FullHeight', ReadFullHeight, WriteFullHeight, True);
end;

destructor TScFlipPanel.Destroy;
begin
  FreeAndNil(FGlyph);
  FreeAndNil(FGlyphCollapse);
  FreeAndNil(FGlyphExpand);
  FreeAndNil(FHeaderFont);
  FreeAndNil(FPanelPadding);
  inherited;
end;

procedure TScFlipPanel.DoCaptionChange;
begin
  InvalidateHeader;
end;

procedure TScFlipPanel.DoChange;
begin

end;

procedure TScFlipPanel.DoHeaderChange(Sender: TObject);
begin
  InvalidateHeader;
end;

procedure TScFlipPanel.DoHeaderFontChange(Sender: TObject);
begin
  if not (csLoading in ComponentState) then
  begin
    FParentHeaderFont := False;
  end;

  InvalidateHeader;
end;

procedure TScFlipPanel.DoInnerPaddingChange(Sender: TObject);
begin
  Invalidate;
  Realign;
end;

procedure TScFlipPanel.DoPaddingChange(Sender: TObject);
begin
  inherited;
  Invalidate;
end;

procedure TScFlipPanel.Flip;
begin
  Expanded := not Expanded;
end;

function TScFlipPanel.GetToggleButtonStyle: TScToggleButtonStyle;
begin
  Result := FToggleButtonStyle;
end;

function TScFlipPanel.GetToggleRect: TRect;
var
  Y: Integer;
begin
  Y := Ceil(HeaderHeight / 2) - Ceil(ToggleSize.cy / 2);

  case FHeaderLayout of
    hlLeftToRight: Result := Bounds(FHeaderIndent, Y, ToggleSize.cx, ToggleSize.cy);
    hlRightToLeft: Result := Bounds(ClientWidth - FHeaderIndent - ToggleSize.cx, Y, ToggleSize.cx, ToggleSize.cy);
  end;
end;

function TScFlipPanel.GetToggleSize: TSize;
var
  D: Integer;
begin
  case FToggleButtonStyle of
    tsStyleNative: Result := Size(9, 9);
    tsTriangle:
    begin
      D := Round(HeaderHeight / 2.66);
      Result := Size(D, D);
    end;
    tsSquare: Result := Size(9, 9);
    tsGlyph:
    begin
      if Expanded and Assigned(GlyphCollapse)
        then Result := Size(GlyphCollapse.Width, GlyphCollapse.Height)
      else if Assigned(GlyphExpand)
        then Result := Size(GlyphExpand.Width, GlyphExpand.Height);
    end;
  end;
end;

function TScFlipPanel.GetHeaderRect: TRect;
begin
  Result := Bounds(0, 0, ClientWidth, HeaderHeight);
end;

function TScFlipPanel.GetPanelRect: TRect;
begin
  Result := inherited GetPanelRect;
  Inc(Result.Top, HeaderHeight);
end;

procedure TScFlipPanel.InvalidateHeader;
begin
  InvalidateRect(GetHeaderRect);
end;

procedure TScFlipPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if PtInRect(GetHeaderRect, Point(X, Y))
    then HeaderState := HeaderState + [bsPressed];
end;

procedure TScFlipPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if HotTrack and PtInRect(GetHeaderRect, Point(X, Y))
  then
    HeaderState := HeaderState + [bsHover]
  else
    HeaderState := HeaderState - [bsHover];
end;

procedure TScFlipPanel.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  CanFlip: Boolean;
begin
  inherited;

  CanFlip := False;

  case FlipChangeArea of
    faButton: CanFlip := ShowToggleButton and PtInRect(GetToggleRect, Point(X, Y));
    faHeader: CanFlip := PtInRect(GetHeaderRect, Point(X, Y));
    faNone: ;
  end;

  { Set Expanded }
  if CanFlip then Flip;

  HeaderState := HeaderState - [bsPressed];
end;

procedure TScFlipPanel.Paint;
var
  PanelRect: TRect;
  PaddingColor: TColor;
begin
  inherited Paint;
  if csDesigning in ComponentState then
  begin
    PanelRect := ClientRect;
    Inc(PanelRect.Top, FHeaderHeight);

    PaddingColor := IfThen(IsColorLight(Color), DarkerColor(Color, 5), LighterColor(Color, 25));

    FillPadding(Canvas, PaddingColor, PanelRect, PanelPadding);

  end;
  PaintHeader(GetHeaderRect);
end;

procedure TScFlipPanel.PaintToggle(X: Integer);
var
  Y, C: Integer;
  Bitmap: TBitmap;
begin
  Y := FHeaderHeight div 2;

  with Canvas do
    case FToggleButtonStyle of
      tsStyleNative:
        begin
          TScTreeStyledView.PaintToggle(Canvas, Self.Handle, ToggleRect,
            Expanded, HeaderState, HeaderStyleOptions);
        end;

      tsTriangle:
        if Expanded then
        begin
          Y := Y - ToggleSize.cy div 2;

          if bsHover in FHeaderState then
          begin
            Brush.Color := ColorOf(seMenu);
          end else
          begin
            Brush.Color := $00444444;
          end;
          Pen.Color := Brush.Color;

          C := ToggleSize.cy - 1;

          Polygon([
            Point(X, Y + C),
            Point(X + C, Y + C),
            Point(X + C, Y),
            Point(X, Y + C)
          ]);
        end else
        begin
          Y := Y - Pred(ToggleSize.cy);

          if bsHover in FHeaderState then
          begin
            Brush.Color := ColorOf(seBtnFramePressed);
            Pen.Color := Brush.Color;
          end else
          begin
            Brush.Color := clWhite;
            Pen.Color := $00888683;
          end;

          Polygon([
            Point(X, Y),
            Point(X + ToggleSize.cx - 2, Y + ToggleSize.cx - 2),
            Point(X, Y + (ToggleSize.cx - 2) * 2),
            Point(X, Y)
          ]);
        end;
      tsSquare:
      begin
        Pen.Color := clGray;
        Brush.Color := HeaderColor;
        Rectangle(ToggleRect);

        C := Floor(ToggleSize.cx / 2);
        Polyline([
          Point(ToggleRect.Left + 2, ToggleRect.Top + C),
          Point(ToggleRect.Right - 2, ToggleRect.Top + C)
        ]);
        if not Expanded then
          Polyline([
            Point(ToggleRect.Left + C, ToggleRect.Top + 2),
            Point(ToggleRect.Left + C, ToggleRect.Bottom - 2)
          ]);
      end;
      tsGlyph:
      begin
        Bitmap := nil;

        Y := Floor(HeaderHeight / 2) - Floor(ToggleSize.cy / 2);
        if Expanded and Assigned(GlyphCollapse)
          then Bitmap := GlyphCollapse
        else if Assigned(GlyphExpand)
          then Bitmap := GlyphExpand;

        if Assigned(Bitmap) then
        begin
          Bitmap.TransparentColor := Bitmap.Canvas.Pixels[0, Bitmap.Height - 1];
          Bitmap.Transparent := True;
          Draw(X, Y, Bitmap);
        end;
      end;
    end;
end;

procedure TScFlipPanel.PaintHeader(HeaderRect: TRect);
var
  Location, GlyphLocation: TPoint;
  CaptionRect: TRect;
  CaptionAlignment: TAlignment;
begin
  with Canvas do
  begin

    { Background }
    if (not HotTrack)
      or (FHeaderState <> []) then
    begin

      case FHeaderStyle of
        stNative:
          if SupportStyle(HeaderStyleOptions) then
          begin
            TScHeaderStyle.Paint(Canvas, Self.Handle, HeaderRect,
              HeaderState, HeaderStyleOptions);
          end else
          begin
            Brush.Color := HeaderColor;
            FillRect(HeaderRect);
          end;

        stUserDefined:
        begin
          Brush.Color := HeaderColor;
          Pen.Color := HeaderBorderColor;
          Rectangle(HeaderRect);
        end;

        stModern:
        begin
          Brush.Color := HeaderColor;

          if bsHover in FHeaderState
            then Brush.Color := ColorOf(seBtnFace);

          if bsPressed in FHeaderState
            then Brush.Color := ColorOf(seBtnFacePressed);

          if Expanded then
          begin
            Pen.Color := ColorOf(seBtnFacePressed);
            Rectangle(HeaderRect);
          end
          else FillRect(HeaderRect);
        end;

      end;

    end else
    begin
      Brush.Color := Color;
      FillRect(HeaderRect);
    end;

    case FHeaderLayout of
      hlLeftToRight: Location := Point(FHeaderIndent, 0);
      hlRightToLeft: Location := Point(ClientWidth - FHeaderIndent, 0);
    end;

    { Button }
    if ShowToggleButton then
    begin

      if FHeaderLayout = hlRightToLeft then Dec(Location.X, ToggleSize.cx);

      PaintToggle(Location.X);

      case FHeaderLayout of
        hlLeftToRight: Inc(Location.X, pdDouble + ToggleSize.cx);
        hlRightToLeft: Dec(Location.X, pdDouble);
      end;

    end;

    { Icon }

    if Assigned(FGlyph)
      and Assigned(FGlyph.Graphic)
      and not FGlyph.Graphic.Empty then
    begin

      GlyphLocation := Location;

      case GlyphPosition of
        gpAfterText:
        begin
          case FHeaderLayout of
            hlLeftToRight: GlyphLocation.X := HeaderRect.Right - FGlyph.Width - pdDouble;
            hlRightToLeft: GlyphLocation.X := pdDouble;
          end;
        end;

        gpBeforeText:
        begin
          if FHeaderLayout = hlRightToLeft
            then Dec(GlyphLocation.X, FGlyph.Width);

          case FHeaderLayout of
            hlLeftToRight: Inc(Location.X, FGlyph.Width + pdDouble);
            hlRightToLeft: Dec(Location.X, FGlyph.Width + pdDouble);
          end;
        end;

      end;

      GlyphLocation.Y := HeaderHeight div 2 - FGlyph.Height div 2;

      Canvas.Draw(GlyphLocation.X, GlyphLocation.Y, FGlyph.Graphic);

    end;

    { Title }
    Font.Assign(HeaderFont);

    case FHeaderLayout of
      hlLeftToRight:
      begin
        CaptionRect := Rect(Location.X, 0, ClientWidth, FHeaderHeight);
        CaptionAlignment := taLeftJustify;
      end;
      else
      begin
        CaptionRect := Rect(0, 0, Location.X, FHeaderHeight);
        CaptionAlignment := taRightJustify;
      end;
    end;

    DrawTextRect(Canvas, CaptionRect, CaptionAlignment, taVerticalCenter, Caption, wkEllipsis);

  end;

end;

procedure TScFlipPanel.ReadFullHeight(Reader: TReader);
begin
  FFullHeight := Reader.ReadInteger;
  if not FExpanded then
  begin
    Height := FHeaderHeight;
  end else Height := FFullHeight;
end;

procedure TScFlipPanel.SetExpanded(const Value: Boolean);
begin
  if Value <> FExpanded then
  begin
    FExpanded := Value;

    InvalidateHeader;

    if FExpanded then
    begin
      ClientHeight := FFullHeight;
    end else
    begin
      FFullHeight := ClientHeight;
      ClientHeight := HeaderHeight;
    end;

  end;

end;

procedure TScFlipPanel.SetGlyph(const Value: TPicture);
begin
  FGlyph.Assign(Value);

  if Assigned(FGlyph)
    then FGlyph.OnChange := DoHeaderChange;
end;

procedure TScFlipPanel.SetGlyphCollapse(const Value: TBitmap);
begin
  if FGlyphCollapse <> Value then
  begin
    FGlyphCollapse.Assign(Value);

    if Assigned(FGlyphCollapse)
      then FGlyphCollapse.OnChange := DoHeaderChange;
  end;
end;

procedure TScFlipPanel.SetGlyphExpand(const Value: TBitmap);
begin
  if FGlyphExpand <> Value then
  begin
    FGlyphExpand.Assign(Value);

    if Assigned(FGlyphExpand)
      then FGlyphExpand.OnChange := DoHeaderChange;
  end;
end;

procedure TScFlipPanel.SetGlyphPosition(const Value: TScGlyphPosition);
begin
  if Value <> FGlyphPosition then
  begin
    FGlyphPosition := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderBorderColor(const Value: TColor);
begin
  if Value <> FHeaderBorderColor then
  begin
    FHeaderBorderColor := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderColor(const Value: TColor);
begin
  if Value <> FHeaderColor then
  begin
    FHeaderColor := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderFont(const Value: TFont);
begin
  FHeaderFont.Assign(Value);
  FHeaderFont.OnChange := DoHeaderFontChange;
end;

procedure TScFlipPanel.SetHeaderHeight(const Value: Integer);
begin
  if Value <> FHeaderHeight then
  begin
    FHeaderHeight := Value;
    Invalidate;
    Realign;
  end;
end;

procedure TScFlipPanel.SetHeaderIndent(const Value: Integer);
begin
  if Value <> FHeaderIndent then
  begin
    FHeaderIndent := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderState(const Value: TScButtonState);
begin
  if Value <> FHeaderState then
  begin
    FHeaderState := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderStyle(const Value: TScAppearanceStyle);
begin
  if Value <> FHeaderStyle then
  begin
    FHeaderStyle := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderStyleOptions(const Value: TScStyleOptions);
begin
  if Value <> FHeaderStyleOptions then
  begin
    FHeaderStyleOptions := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHeaderLayout(const Value: TScHeaderLayout);
begin
  if Value <> FHeaderLayout then
  begin
    FHeaderLayout := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetHotTrack(const Value: Boolean);
begin
  if Value <> FHotTrack then
  begin
    FHotTrack := Value;
    Invalidate;
  end;
end;

procedure TScFlipPanel.SetPanelPadding(const Value: TPadding);
begin
  FPanelPadding := Value;
  FPanelPadding.OnChange := DoInnerPaddingChange;
end;

procedure TScFlipPanel.SetParentHeaderFont(const Value: Boolean);
begin
  if FParentHeaderFont <> Value then
  begin
    FParentHeaderFont := Value;

    if FParentHeaderFont
      then FHeaderFont.Assign(Font);

    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.SetShowToggleButton(const Value: Boolean);
begin
  if Value <> FShowToggleButton then
  begin
    FShowToggleButton := Value;
    Invalidate;
  end;
end;

procedure TScFlipPanel.SetShowHeader(const Value: Boolean);
begin
  if Value <> FShowHeader then
  begin
    FShowHeader := Value;
    Invalidate;
  end;
end;

procedure TScFlipPanel.SetToggleStyle(const Value: TScToggleButtonStyle);
begin
  if Value <> FToggleButtonStyle then
  begin
    FToggleButtonStyle := Value;
    InvalidateHeader;
  end;
end;

procedure TScFlipPanel.WMSize(var Message: TWMSize);
var
  OldHeaderHeight: Integer;
begin
  inherited;
  if not Expanded then
  begin
    OldHeaderHeight := HeaderHeight;
    HeaderHeight := ClientHeight;
    Inc(FFullHeight, HeaderHeight - OldHeaderHeight);
  end else
  begin
    FFullHeight := ClientHeight;
  end;
end;

procedure TScFlipPanel.WriteFullHeight(Writer: TWriter);
begin
  Writer.WriteInteger(FFullHeight);
end;

end.
