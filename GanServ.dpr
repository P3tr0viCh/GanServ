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
	Result:=FindWindow(PChar('TApplication'), PChar('Передача данных на сервер')) <> 0;
end;

begin
	If AlreadyRun then Exit;
  Application.Initialize;
  Application.Title := 'Передача данных на сервер';
  Application.ShowMainForm:=False;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
