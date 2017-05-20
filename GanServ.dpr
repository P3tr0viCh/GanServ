program GanServ;

uses
  Forms,
  Windows,
  GanServMain in 'GanServMain.pas' {Main},
  GanServStrings in 'GanServStrings.pas',
  GanServOptions in 'GanServOptions.pas' {frmOptions},
  GanServAdd in 'GanServAdd.pas',
  GanServLogin in 'GanServLogin.pas' {frmLogin};

{$R *.res}
{$R GanServAdd.res}

function AlreadyRun : Boolean;
begin
	Result:=FindWindow(PChar('TApplication'), PChar('�������� ������ �� ������')) <> 0;
end;

begin
	If AlreadyRun then Exit;
  Application.Initialize;
  Application.Title := '�������� ������ �� ������';
  Application.ShowMainForm:=False;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
