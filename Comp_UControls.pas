unit Comp_UControls;

interface

uses
  Controls, Graphics, Types, Messages, Classes, ExtCtrls, Windows,

  Comp_UIntf, Comp_UTypes;

type

  TPaintState = set of (ptPainting);

  { TScUserControl }
  TScUserControl = class(TCustomControl, IViewOwner)
  private
{$IFNDEF PADDING}
    FPadding: TPadding;
    FMargins: TMargins;
    procedure SetPadding(const Value: TPadding);
    procedure SetMargins(const Value: TMargins);
{$ENDIF}
  protected
    FPaintingState: TPaintState;                                                // что за свойство ???
    { IViewOwner }
    function GetCanvas: TCanvas;
    function GetHandle: THandle;
  protected
    function CanFocusParent: Boolean;
    procedure DoPaddingChange(Sender: TObject); virtual;
    procedure EraseRect(Rect: TRect);
    { Invalidation Methods }
    procedure ValidateRect(const Source: TRect);
    procedure InvalidateRect(const Source: TRect);
    { Messages }
    procedure WMEraseBkGnd(var Message: TWMEraseBkGnd); message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Action;
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Hint;
{$IFNDEF PADDING}                                                               // для компилятора выше ver120
    property Margins: TMargins read FMargins write SetMargins;
    property Padding: TPadding read FPadding write SetPadding;
{$ELSE}
    property Margins;
    property Padding;
{$ENDIF}
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
{$IFDEF GESTURES}
    property Touch;
{$ENDIF}
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
{$IFDEF GESTURES}
    property OnGesture;
{$ENDIF}
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  { TScControl }
  TScControl = class(TScUserControl)
  private
    { Property Fields }
    FBorderColor: TColor;
    FBorderSize: Integer;
    FBorderStyle: TScBorderStyle;
    FHintLocation: TPoint;
    FHintPauseTimer: TTimer;
    FHintText: WideString;
    FHintWindow: THintWindow;
    FOnPaint: TNotifyEvent;
    FTagString: string;
    function GetPaddingRect: TRect;
    { Property Acessors }
    procedure SetBorderColor(const Value: TColor);
    procedure SetBorderSize(const Value: Integer);
    procedure SetBorderStyle(const Value: TScBorderStyle);
  protected
    procedure ActivateHint(Location: TPoint; Text: WideString);
    procedure DeactivateHint;
    procedure DoHintPauseTimer(Sender: TObject);
    procedure DoPaint; dynamic;
    procedure EraseBkGnd(const Source: TRect);
    procedure PaintWindow(DC: HDC); override;
    { Delphi Messages }
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    { Win32 Messages }
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    { Properties }
    property PaddingRect: TRect read GetPaddingRect;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BorderColor: TColor read FBorderColor write SetBorderColor default clBtnShadow;
    property BorderSize: Integer read FBorderSize write SetBorderSize default 0;
    property BorderStyle: TScBorderStyle read FBorderStyle write SetBorderStyle default btSolid;
    property TagString: string read FTagString write FTagString;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;

  { TScStyledControl6 }
  IScStyledControl = interface
    ['{8C2B9330-60A2-4F08-901F-07B704705EF3}']
    function CanStyle(Option: TScStyleOption): Boolean;
    function GetStyleOptions: TScStyleOptions;
    procedure SetStyleOptions(const Value: TScStyleOptions);
    property StyleOptions: TScStyleOptions read GetStyleOptions write SetStyleOptions;
  end;

  { IScColorSchemedControl }
  IScColorSchemedControl = interface
    ['{52D010ED-732E-4D12-8EF0-7147D4017980}']
    procedure Invalidate;
  end;

  TScStyledControl = class(TScControl, IScStyledControl, IScColorSchemedControl)
  private
    FStyleOptions: TScStyleOptions;
    function GetStyleOptions: TScStyleOptions;
    procedure SetStyleOptions(const Value: TScStyleOptions);
  protected
    procedure StyleChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    function CanStyle(Option: TScStyleOption): Boolean;
  published
    property StyleOptions: TScStyleOptions read GetStyleOptions write SetStyleOptions
      default [soNativeStyles];
{$IFDEF STYLE_SERVICES}
    property StyleElements;
{$ENDIF}
  end;

implementation

uses
  Forms, SysUtils;

{$REGION 'TScUserControl'}
{ TScUserControl }

function TScUserControl.CanFocusParent: Boolean;
var
  Form: TWinControl;
begin
  Form := GetParentForm(Self);
  Result := Assigned(Form) and Form.Showing;
end;

constructor TScUserControl.Create(AOwner: TComponent);
begin
  inherited;
  FPaintingState := [];
{$IFNDEF PADDING}
  FMargins := TMargins.Create(Self);
  FPadding := TPadding.Create(Self);
{$ENDIF}
  Padding.OnChange := DoPaddingChange;
{$IFDEF GESTURES}
  ControlStyle := ControlStyle + [csGestures];
{$ENDIF}
end;

destructor TScUserControl.Destroy;
begin
{$IFNDEF PADDING}
  FMargins.Free;
  FPadding.Free;
{$ENDIF}
  inherited;
end;

procedure TScUserControl.DoPaddingChange(Sender: TObject);
begin
  Realign;
end;

procedure TScUserControl.EraseRect(Rect: TRect);
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect);
end;

function TScUserControl.GetCanvas: TCanvas;
begin
  Result := Canvas;
end;

function TScUserControl.GetHandle: THandle;
begin
  Result := Handle;
end;

procedure TScUserControl.InvalidateRect(const Source: TRect);
begin
  if HandleAllocated and not(ptPainting in FPaintingState) then
{$IFDEF UNSAFE}
  Windows.InvalidateRect(Handle, @Source, False);
{$ELSE}
  Windows.InvalidateRect(Handle, Source, False);
{$ENDIF}
end;

{$IFNDEF PADDING}
procedure TScUserControl.SetMargins(const Value: TMargins);
begin
  FMargins.Assign(Value);
end;

procedure TScUserControl.SetPadding(const Value: TPadding);
begin
  FPadding.Assign(Value);
  FPadding.OnChange := DoPaddingChange;
end;
{$ENDIF}

procedure TScUserControl.ValidateRect(const Source: TRect);
begin
  if HandleAllocated then
{$IFDEF UNSAFE}
  Windows.ValidateRect(Handle, @Source);
{$ELSE}
  Windows.ValidateRect(Handle, Source);
{$ENDIF}
end;

procedure TScUserControl.WMEraseBkGnd(var Message: TWMEraseBkGnd);
begin
  Message.Result := 1;
end;
{$ENDREGION}

{$REGION 'TScControl'}
{ TScControl }

procedure TScControl.ActivateHint(Location: TPoint; Text: WideString);
begin
  if Text = ''
    then Exit;

  FHintLocation := Location;
  FHintText := Text;

  { Should pause? }
  if not Assigned(FHintWindow) then
  begin
    FHintPauseTimer := TTimer.Create(Self);
    FHintPauseTimer.Interval := Application.HintPause;
    FHintPauseTimer.OnTimer := DoHintPauseTimer;
  end else
    DoHintPauseTimer(Self); { Call now }
end;

procedure TScControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  DeactivateHint;
end;

constructor TScControl.Create(AOwner: TComponent);
begin
  inherited;
  FBorderColor := clBtnShadow;
  FBorderSize := 0;
  FBorderStyle := btSolid;
  FTagString := EmptyStr;
end;

procedure TScControl.DeactivateHint;
begin
  { Stop & Destroy }
  FreeAndNil(FHintPauseTimer);

  if Assigned(FHintWindow) then
  begin
    FHintWindow.ReleaseHandle;
    { Destroy }
    if Assigned(FHintWindow) then FreeAndNil(FHintWindow);
  end;
end;

destructor TScControl.Destroy;
begin
  { Destroy Obj. }
  DeactivateHint;
  inherited;
end;

procedure TScControl.DoHintPauseTimer(Sender: TObject);
var
  HintRect: TRect;
begin
  { Release previous? }
  DeactivateHint;

  { Create Hint Window }
  FHintWindow := HintWindowClass.Create(nil);
  FHintWindow.Color := clInfoBk;

  { Set Position & Activate }

  { Calculate Rect }
  HintRect := FHintWindow.CalcHintRect(Screen.Width, FHintText, nil);

  { Cordinates must be "Screen" }
  HintRect.TopLeft := ClientToScreen(FHintLocation);

  HintRect.Bottom := HintRect.Top + HintRect.Bottom;
  HintRect.Right := HintRect.Left + HintRect.Right;

  { Show Hint }
  FHintWindow.ActivateHint(HintRect, FHintText);
end;

procedure TScControl.DoPaint;
begin
  if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure TScControl.EraseBkGnd(const Source: TRect);
begin
  with Canvas do
  begin
    Brush.Color := Color;
    FillRect(Source);
  end;
end;

function TScControl.GetPaddingRect: TRect;
begin
  Result := ClientRect;
  Comp_UTypes.SetPadding(Result, Padding);
end;

procedure TScControl.PaintWindow(DC: HDC);
begin
  inherited;
  DoPaint;
end;

procedure TScControl.SetBorderColor(const Value: TColor);
begin
  if Value <> FBorderColor then
  begin
    FBorderColor := Value;
    Perform(CM_BORDERCHANGED, 0, 0);
  end;
end;

procedure TScControl.SetBorderSize(const Value: Integer);
begin
  if Value <> FBorderSize then
  begin
    FBorderSize := Value;
    Perform(CM_BORDERCHANGED, 0, 0);
  end;
end;

procedure TScControl.SetBorderStyle(const Value: TScBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    Perform(CM_BORDERCHANGED, 0, 0);
  end;
end;

procedure TScControl.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  Params: PNCCalcSizeParams;
begin
  inherited;
  Params := Message.CalcSize_Params;
  with Params^ do
  begin
    InflateRect(rgrc[0], -Integer(FBorderSize), -Integer(FBorderSize));
  end;
end;

procedure TScControl.WMNCPaint(var Message: TMessage);
var
  Device: HDC;
  Pen: HPEN;
  i: Integer;
  R: TRect;
  P: array[0..2] of TPoint;
  HightlightColor, ShadowColor: TColor;
begin
  { Required for scrollbars }
  inherited;

  { Can draw? }
  if BorderSize > 0 then
  begin
    case BorderStyle of
      btSolid:
      begin
        HightlightColor := FBorderColor;
        ShadowColor := FBorderColor;
      end;
      btLowered:
      begin
        HightlightColor := clBtnHighlight;
        ShadowColor := clBtnShadow;
      end;
      else
      begin
        HightlightColor := clBtnShadow;
        ShadowColor := clBtnHighlight;
      end;
    end;

    Device := GetWindowDC(Handle);
    try
      GetWindowRect(Handle, R);
      OffsetRect(R, -R.Left, -R.Top);

      Pen := CreatePen(PS_SOLID, 1, ColorToRGB(ShadowColor));
      try
        SelectObject(Device, Pen);

        P[0] := Point(R.Left, R.Bottom - 1);
        P[1] := R.TopLeft;
        P[2] := Point(R.Right, R.Top);

        Polyline(Device, P, 3);

        for i := 2 to BorderSize do
        begin
          Inc(P[0].X);
          Dec(P[0].Y);
          Inc(P[1].X);
          Inc(P[1].Y);
          Dec(P[2].X);
          Inc(P[2].Y);

          Polyline(Device, P, 3);
        end;

      finally
        DeleteObject(Pen);
      end;

      Pen := CreatePen(PS_SOLID, 1, ColorToRGB(HightlightColor));
      try
        SelectObject(Device, Pen);

        P[0] := Point(R.Left + 1, R.Bottom - 1);
        P[1] := Point(R.Right - 1, R.Bottom - 1);
        P[2] := Point(R.Right - 1, R.Top);

        Polyline(Device, P, 3);

        for i := 2 to BorderSize do
        begin
          Inc(P[0].X);
          Dec(P[0].Y);
          Dec(P[1].X);
          Dec(P[1].Y);
          Dec(P[2].X);
          Inc(P[2].Y);

          Polyline(Device, P, 3);
        end;

      finally
        DeleteObject(Pen);
      end;

    finally
      ReleaseDC(Handle, Device);
    end;

  end;

end;
{$ENDREGION}

{$REGION 'TScStyledControl'}
{ TScStyledControl }

function TScStyledControl.CanStyle(Option: TScStyleOption): Boolean;
begin
  case Option of
    soVCLStyles:
    begin
      Result := False;
      if not(csDesigning in ComponentState) then
        if (soVCLStyles in FStyleOptions) then
        begin
          Result := SupportStyle([soVCLStyles]);
        end;
    end;
    soNativeStyles: Result := (soNativeStyles in FStyleOptions) and Themed;

    else Result := False;
  end;
end;

constructor TScStyledControl.Create(AOwner: TComponent);
begin
  inherited;
  FStyleOptions := [soNativeStyles];
end;

function TScStyledControl.GetStyleOptions: TScStyleOptions;
begin
  Result := FStyleOptions;
end;

procedure TScStyledControl.SetStyleOptions(const Value: TScStyleOptions);
begin
  if Value <> FStyleOptions then
  begin
    FStyleOptions := Value;
    StyleChanged;
  end;
end;

procedure TScStyledControl.StyleChanged;
begin
  Invalidate;
end;
{$ENDREGION}

end.
