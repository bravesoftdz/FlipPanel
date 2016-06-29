unit Comp_URegister;

interface

uses
  Comp_UFlipPanel;

procedure Register;

implementation

uses
  Classes;

procedure Register;
begin
  { Reg. Controls }
  RegisterComponents('SC Collection', [
      TScPanel,
      TScFlipPanel
    ]);

end;

end.
