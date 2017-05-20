unit GanServMain;

interface

//{$DEFINE NOPASS} {$DEFINE FORCECLOSE}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, AboutFrm, Utils_Misc, DB, ADODB, Utils_Base64,
  Utils_Date, Utils_Str, Utils_Files, ImgList, StdCtrls, ExtCtrls, TrayIcon,
  utils_Log;

type
  TMain = class(TForm)
    TrayIcon: TTrayIcon;
    pmMain: TPopupMenu;
    miExit: TMenuItem;
    miAbout: TMenuItem;
    miSeparator01: TMenuItem;
    miOptions: TMenuItem;
    miSeparator02: TMenuItem;
    ConnectionLocal: TADOConnection;
    ConnectionServer: TADOConnection;
    Query: TADOQuery;
    miCheck: TMenuItem;
    miSeparator03: TMenuItem;
    CheckTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure miOptionsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure miCheckClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState);
    procedure CheckTimerTimer(Sender: TObject);
  private
    UralSteelChangeTable: UINT;
    function  PerformOpenDataBase: Boolean;
    procedure TrayIconShowMenu(AMenu: Byte);
    procedure TrayIconTip(AWait: Boolean);

    function  SaveScaleInfo: Boolean;
    function  StartSendData: Boolean;
  public
    function  LoadSettings: Boolean;
    procedure ChangeCheckTimer;
    function  ShowOptions: Boolean;

    procedure DefaultHandler(var Message); override;
  end;

var
  Main: TMain;

implementation

uses GanServStrings, GanServOptions, GanServAdd, GanServLogin;

{$R *.dfm}

function TMain.PerformOpenDataBase: Boolean;
begin
   Result  :=  LoadSettings;
   If not Result then Exit;
   StartSendData;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
   TrayIconTip(False);
   WriteToLog(Format(rsLOGStartProgram, [GetFileVersion(Application.ExeName, False)]));
   Query.SQL.Add('');
   PerformOpenDataBase;
   UralSteelChangeTable  :=  RegisterWindowMessage('UralSteelChangeTable');
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  WriteToLog(rsLOGStopProgram);
end;

procedure TMain.TrayIconShowMenu(AMenu: Byte);
// AMenu: 0 - Close, 1 - About, 2 - Options
begin
   TrayIcon.Enabled := False;
   Try
      Case AMenu of
      0:
      {$IFNDEF FORCECLOSE}
      If MsgBoxYesNo(rsQuestionClose) then
      {$ENDIF}
      Close;
      1: begin
            WriteToLog('ABOUT');
            ShowAbout(18, 1, 3, #0, nil, rsAddComp, #0, #0, rsCopyright);
         end;
      2: If ShowOptions then
            begin
               ChangeCheckTimer;
               SaveScaleInfo;
            end;
      end;
   finally
      TrayIcon.Enabled := True;
   end;
end;

function TMain.ShowOptions: Boolean;
begin
   {$IFNDEF NOPASS}
   Result := ShowLogin;
   If not Result then Exit;
   {$ENDIF}
   With TfrmOptions.Create(Application) do
      try
         Result := ShowModal = mrOk;
      finally
         Free;
      end;
end;

procedure TMain.miExitClick(Sender: TObject);
begin
   TrayIconShowMenu(0);
end;

procedure TMain.miAboutClick(Sender: TObject);
begin
   TrayIconShowMenu(1);
end;

procedure TMain.miOptionsClick(Sender: TObject);
begin
   TrayIconShowMenu(2);
end;

function TMain.LoadSettings: Boolean;
var
   i: Integer;
   SettingsFile: String;
   SettingsList: TStringList;
   function GetSettingsList(var Index: Integer): String;
   begin
      Result := SettingsList[i]; Inc(i);
   end;
begin
   Result := False;
   SettingsFile := ChangeFileExt(Application.ExeName, '.cfg');
   SettingsList := TStringList.Create;
   Try
   Try
      Result := FileExists(SettingsFile);
      If not Result then
         begin
            ErrorSaveLoad(acLoad, ctLocal, rsErrorSLSettings, rsErrorSettingsNotExists + rsErrorCloseApp, True, True);
            Exit;
         end;
      SettingsList.LoadFromFile(SettingsFile);
      SettingsList.Text := String(Decrypt(AnsiString(SettingsList[0]), CFGKEY));
      Result := SettingsList[SettingsList.Count - 1] = CFGOK;
      If not Result then
         begin
            ErrorSaveLoad(acLoad, ctLocal, rsErrorSLSettings, rsErrorSettingsBad + rsErrorCloseApp, True, True);
            Exit;
         end;
      With Settings do
         begin
            i := 0;
            LocalDB :=       GetSettingsList(i);
            LocalUser :=     GetSettingsList(i);
            LocalPass :=     GetSettingsList(i);

            Scales :=        SToI(GetSettingsList(i));
            Place :=         GetSettingsList(i);
            TypeS :=         GetSettingsList(i);
            SClass :=        GetSettingsList(i);
            DClass :=        GetSettingsList(i);

            ServerIP :=      GetSettingsList(i);
            ServerPort :=    GetSettingsList(i);
            ServerUser :=    GetSettingsList(i);
            ServerPass :=    GetSettingsList(i);

            ProgramPass :=   GetSettingsList(i);
            CheckTimer :=    TCheckTimer(SToI(GetSettingsList(i)));
            ChangeCheckTimer;
         end;
      Result := True;
   except
      on E: Exception do
         begin
            Result := False;
            ErrorSaveLoad(acLoad, ctLocal, rsErrorSLSettings, rsErrorSettingsBad + rsErrorCloseApp, True, True);
         end;
   end;
   finally
      SettingsList.Free;
      If not Result then Application.Terminate;
   end;
end;

function TMain.SaveScaleInfo: Boolean;
var
   ATableName, AFields, AValues, AError, ALog: String;
   FirstTick: LongWord;
begin
   StartTimer(FirstTick);

   TrayIcon.Enabled := False;
   Try
   With Settings do
   Try
      Result := OpenConnections;
      If not Result then Exit;
      If not CanServer then Exit;

      ATableName := rsTableServerScalesInfo;
      AFields := rsSQLServerScalesInfo;
      AValues := SQLFormatValues([ Scales,                    // Номер весов
                                 DTToWTime(Now),            // Системное время начала связи
                                 DTToSQLStr(Now),           // Дата и время начала связи
                                                            // Системное время окончания связи
                                                            // Дата и время окончания связи
                                                            // Системное время окончания последнего взвешивания
                                 GetLocalIP,                // ИП-адрес весов
                                 TypeS,                     // Тип весов
                                 SClass,                    // Класс точности в статике
                                 DClass,                    // Класс точности в динамике
                                 Place,                     // Место установки весов
                                 2010                       // Тип весов
                                 ]);
      AError := rsErrorSLScaleInfo;
      ALog := rsLOGScaleInfoSave;

      SelectConnection(ctServer);


      SQLExec(SQLDelete(ATableName, WhereScalesIndex(Scales)));
//      MsgBox(SQLInsert(ATableName, AFields, AValues)); Exit;
      SQLExec(SQLInsert(ATableName, AFields, AValues));
   except
      on E: Exception do
         begin
            Result := False;
            ErrorSaveLoad(acSave, ctLocal, AError, E.Message);
         end;
   end;
   finally
      CloseConnections;
      TrayIcon.Enabled := True;
      WriteToLog(ALog + GetTimerCount(FirstTick));
   end;
end;

function  TMain.StartSendData: Boolean;
var
   FirstTick: LongWord;
   DataBrutto: TStringList;

   function CheckExit: Boolean;
   begin
      Result := Application.Terminated;
   end;

   function CheckData: Boolean;
   var
      SendCount: Integer;
   begin
      SendCount := -1;
      SelectConnection(ctLocal);
      With Main.Query do
         try // except
            SQLOpen(SQLSelect(rsTableLocal, rsSQLCount, SQLNameEqualValue(rsSQLLocalSend, 0)));
            Try
               SendCount := Fields[0].AsInteger;
               Result := SendCount > 0;
            finally
               Close;
            end;
         except
            on E: Exception do
               begin
                  Result := False;
                  ErrorSaveLoad(acLoad, ctLocal, rsErrorSLVans, E.Message);
               end;
         end;
      WriteToLog(Format(rsLOGDataCheck, [SendCount]));
   end;

   function PerformLoadData: Boolean;
   var
      WTime: LongWord;
   begin
      Result := True;
      SelectConnection(ctLocal);
      With Main.Query do
         try // except
            SQLOpen(SQLSelect(rsTableLocal, rsSQLLocalMeasures, SQLNameEqualValue(rsSQLLocalSend, 0)) +
                               SQLOrderBy([rsLocalOrderBy], [True]));
            Try
               While not Eof do
                  begin
                     WTime := DTToWTime(Fields[01].AsDateTime);
                     DataBrutto.AddObject(SQLFormatValues([
                              Settings.Scales,              // № весов
                              Fields[00].AsInteger,         // № вагона пп (ID)
                              WTime,                        // Системное время начала взвешивания
                              DTToSQLStr(
                                 Fields[01].AsDateTime),    // Дата и время начала взвешивания (DTWeigh)
                              SToF(Fields[02].AsString),    // Брутто (Brutto)
                              SToF(Fields[03].AsString),    // Тара (Tara)
                              SToF(Fields[04].AsString)     // Нетто (Netto)
                              ]), TObject(WTime));
                     ProcMess;
                     If CheckExit then Break;
                     Next;
                  end;
            finally
               Close;
            end;
         except
            on E: Exception do
               begin
                  Result := False;
                  ErrorSaveLoad(acLoad, ctLocal, rsErrorSLVans, E.Message);
               end;
         end;
      WriteToLog(Format(rsLOGDataRead, [DataBrutto.Count]));
   end;

   function PerformSaveData: Boolean;
   var
      i: Integer;
      AConnectionType: TConnectionType;
      ATableName, AFields, AWhere, AError: String;
   begin
      Result := True;

      ATableName := rsTableServerVans;
      AFields := rsSQLServerMeasures;
      AError := rsErrorSLVans;

      If DataBrutto.Count = 0 then Exit;
      AConnectionType := ctServer;
      With Main.Query do
         try
            Try
               For i := 0 to DataBrutto.Count - 1 do
                  begin
                     AConnectionType := ctServer;
                     SelectConnection(AConnectionType);
                     AWhere := WhereScalesAndDateIndex(Settings.Scales, DTToSQLStr(WTimeToDT(Integer(DataBrutto.Objects[i]))));
//                     MsgBox(SQLDelete(ATableName, AWhere));
                     SQLExec(SQLDelete(ATableName, AWhere));
                     ProcMess;
//                     MsgBox(SQLInsert(ATableName, AFields, DataBrutto[i]));
                     SQLExec(SQLInsert(ATableName, AFields, DataBrutto[i]));
                     ProcMess;
                     AConnectionType := ctLocal;
                     SelectConnection(AConnectionType);
//                     MsgBox(SQLUpdate(rsTableLocal, [rsSQLLocalSend], [1],
//                        SQLNameEqualValue(rsLocalDateIndex, WTimeToDT(Integer(DataBrutto.Objects[i])))));
                     SQLExec(SQLUpdate(rsTableLocal, [rsSQLLocalSend], [1],
                        SQLNameEqualValue(rsLocalDateIndex, WTimeToDT(Integer(DataBrutto.Objects[i])))));
                     ProcMess;
                     If CheckExit then Break;
                  end;
            finally
               Close;
            end;
         except
            on E: Exception do
               begin
                  Result := False;
                  ErrorSaveLoad(acSave, AConnectionType, AError, E.Message);
               end;
         end;
   end;
begin
   Result := True;
   StartTimer(FirstTick);
   TrayIconTip(False);
   DataBrutto := TStringList.Create;
   Try
      Result := OpenConnections;
      If not Result then Exit;
      Result := CanServer;
      If not Result then Exit;
      Result := CheckData;
      If not Result then Exit;
      If CheckExit then Exit;
      Result := PerformLoadData;
      If not Result then Exit;
      If CheckExit then Exit;
      Result := PerformSaveData;
   finally
      CloseConnections;
      DataBrutto.Free;
      If Result then Result := not CheckExit;
      TrayIconTip(True);
      WriteToLog(rsLOGDataSave + GetTimerCount(FirstTick));
   end;
end;

procedure TMain.DefaultHandler(var Message);
begin
   With TMessage(Message) do
      begin
         If Msg = UralSteelChangeTable then
            begin
               WriteToLog(rsLOGLocalChangeTable);
            end
         else
            inherited DefaultHandler(Message);
      end;
end;

procedure TMain.TrayIconTip(AWait: Boolean);
begin
   CheckTimer.Enabled := AWait;
   miCheck.Enabled := AWait;
   TrayIcon.Tip := rsTrayIconTip;
   If AWait then
      begin
         TrayIcon.Icon.Handle := LoadImage(HInstance, PChar('MAINICON'), IMAGE_ICON, 16, 16, 0);
         TrayIcon.Tip := TrayIcon.Tip + rsTrayIconWait;
      end
   else
      begin
         TrayIcon.Icon.Handle := LoadImage(HInstance, PChar('STOPICON'), IMAGE_ICON, 16, 16, 0);
         TrayIcon.Tip := TrayIcon.Tip + rsTrayIconWork;
      end;
end;

procedure TMain.miCheckClick(Sender: TObject);
begin
   StartSendData;
end;

procedure TMain.TrayIconDblClick(Sender: TObject; Button: TMouseButton; Shift: TShiftState);
begin
   If (Button = mbLeft) and (Shift = []) then miCheck.Click;
end;

procedure TMain.CheckTimerTimer(Sender: TObject);
begin
   StartSendData;
end;

procedure TMain.ChangeCheckTimer;
begin
   With CheckTimer do
      case Settings.CheckTimer of
      ctOff:   Interval := 0;
      ct1:     Interval := 60000;
      ct5:     Interval := 300000;
      ct10:    Interval := 600000;
      ct15:    Interval := 900000;
      ct20:    Interval := 1200000;
      ct30:    Interval := 1800000;
      end;
end;

end.
