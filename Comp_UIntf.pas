unit Comp_UIntf;

interface

uses
  Comp_UTypes, Graphics, Types;

type

  { IViewOwner }
  IViewOwner = interface
    ['{1FBB192B-8F43-468D-B949-4AD97FB2BD4C}']
    function GetCanvas: TCanvas;
    function GetHandle: THandle;
    procedure InvalidateRect(const Source: TRect);
    property Canvas: TCanvas read GetCanvas;
    property Handle: THandle read GetHandle;
  end;

  { ITogglable }
  ITogglable = interface
    ['{1D562094-09E1-4C9C-8BF1-C4EEA03EF02F}']
    function GetToggleButtonStyle: TScToggleButtonStyle;
    property ToggleButtonStyle: TScToggleButtonStyle read GetToggleButtonStyle;
  end;

implementation

end.
