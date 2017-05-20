unit GanServAdd;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Utils_FileIni, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Utils_Str, Utils_Misc,
  Utils_Files, Utils_Date, DateUtils, StrUtils, DB, ADODB, Utils_Log;

const
   CFGKEY      = 21834;
   CFGOK       = 'P3tr0viCh1310';

type
   TProcessAction    = (acOpen, acLoad, acSave, acDelete);
   TConnectionType   = (ctLocal, ctServer);
   TCheckTimer       = (ctOff, ct1, ct5, ct10, ct15, ct20, ct30);

   TSettings = record
      Scales:        SmallInt;      // ����� �����
      Place:         String;   // ����� ���������
      TypeS:         String;    // ��� �����
      SClass:        String;     // �������� � �������
      DClass:        String;     // �������� � ��������

      LocalDB:       String;        // ���� ������ "������"
      LocalUser:     String;    // ������������ �� "������"
      LocalPass:     String;    // ������ ������������ �� "������"

      ServerIP:      String;    // IP ������� MySQL
      ServerPort:    String;     // ���� ������� MySQL
      ServerUser:    String;    // ������������ �� �������
      ServerPass:    String;    // ������ ������������ �� �������

      ProgramPass:   String;    // ������ ��� ����� � ���������
      CheckTimer:    TCheckTimer;   // ������ �������� ������
   end;

var
   Settings: TSettings;

function  CanServer: Boolean;
function  OpenConnections: Boolean;
procedure CloseConnections;
procedure SelectConnection(AConnectionType: TConnectionType);

procedure SetQuerySQL(ASQLString: String);

procedure SQLOpen(ASQLString: String);
procedure SQLExec(ASQLString: String);
function  SQLSelect(ATableName, AWhat, AWhere: String): String;
function  SQLInsert(ATableName, AFields, AValues: String): String;
function  SQLUpdate(ATableName: String; AColumns: array of String; AValues: array of Variant; AWhere: String): String;
function  SQLDelete(ATableName, AWhere: String): String;
function  SQLWhere(AWhere: String): String;
function  SQLOrderBy(AOrderBy: array of String; AOrderDesc: array of Boolean): String;

function  SQLFormatValue(AValue: Variant): String;
function  SQLFormatValues(AValues: array of Variant): String;
function  SQLNameEqualValue(AName: String; AValue: Variant): String;
function  SQLNamesEqualValues(AColumns: array of String; AValues: array of Variant): String;

function  WhereScalesIndex(AScales: SmallInt): String;
function  WhereScalesAndDateIndex(AScales: SmallInt; ADateTime: String): String;

procedure ErrorSaveLoad(ProcessAction: TProcessAction; ConnectionType: TConnectionType; AWhat, AError: String;
   CloseConnections: Boolean = True; ShowMessage: Boolean = False);

function  DTToSQLStr  (ADateTime: TDateTime): String;
function  DTToMDBStr(ADateTime: TDateTime): String;
function  DTToWTime(ADateTime: TDateTime): LongWord;
function  WTimeToDT(AWTime: LongWord): TDateTime;

function  GetTimerCount(AFirstTick: LongWord): String;
function  SToF(Value: String): Double;

implementation

uses GanServStrings, GanServMain;

function CanConnectServer: Boolean;
begin
   With Settings do Result := (Scales <> 0) and (ServerIP <> '');
end;

function CanServer: Boolean;
begin
   Result := CanConnectServer;
   If Result then Result := Main.ConnectionServer.Connected;
end;

function OpenConnections: Boolean;
var
   LocalDB, sError, sErrorE: String;
begin
   Result := False;
   sError := '';
   Try
      LocalDB := Settings.LocalDB;
      If not FileExists(LocalDB) then
         begin
            sError := Format(rsErrorLocalNotExists, [LocalDB]);
            Exit;
         end;
      If not Main.ConnectionLocal.Connected then
         begin
            Main.ConnectionLocal.ConnectionString :=
               Format(rsConnectionLocal, [LocalDB{, Settings.LocalUser}, Settings.LocalPass]);
            Try
               Main.ConnectionLocal.Open;
            except
               on E: Exception do sErrorE := E.Message;
            end;
            If not Main.ConnectionLocal.Connected then
               begin
                  sError := Format(rsErrorLocalOpen, [sErrorE]);
                  Exit;
               end;
         end;

      Result := sError = '';

      If Result and CanConnectServer then
         begin
            If not Main.ConnectionServer.Connected then
               begin
                  With Settings do
                     Main.ConnectionServer.ConnectionString := Format(rsConnectionServer,
                        [ServerIP, ServerPort, ServerUser, ServerPass]);
                  Try
                     Main.ConnectionServer.Open;
                  except
                     on E: Exception do sErrorE := E.Message;
                  end;
                  If not Main.ConnectionServer.Connected then sError := Format(rsErrorServerNotExists, [sErrorE]);
               end;
         end;
   finally
      If sError <> '' then ErrorSaveLoad(acOpen, ctLocal, '', sError, True, False);
   end;
end;

procedure CloseConnections;
begin
   Main.ConnectionLocal.Close;
   Main.ConnectionServer.Close;
end;

procedure SelectConnection(AConnectionType: TConnectionType);
var
   ADOConnection: TADOConnection;
begin
   Case AConnectionType of
   ctServer:   ADOConnection := Main.ConnectionServer;
   ctLocal:    ADOConnection := Main.ConnectionLocal;
   else        ADOConnection := nil;
   end;
   Main.Query.Connection := ADOConnection;
end;

procedure SetQuerySQL(ASQLString: String);
begin
   Main.Query.SQL[0] := ASQLString;
end;

procedure SQLOpen(ASQLString: String);
begin
   SetQuerySQL(ASQLString);
   Main.Query.Open;
end;

procedure SQLExec(ASQLString: String);
begin
   SetQuerySQL(ASQLString);
   Main.Query.ExecSQL;
end;

function  SQLSelect(ATableName, AWhat, AWhere: String): String;
begin
   Result := Format(rsSQLSelect, [AWhat, ATableName]);
   If AWhere <> '' then Result := Result + SQLWhere(AWhere);
end;

function  SQLInsert(ATableName, AFields, AValues: String): String;
begin
   Result := Format(rsSQLInsert, [ATableName, AFields, AValues]);
end;

function  SQLUpdate(ATableName: String; AColumns: array of String; AValues: array of Variant; AWhere: String): String;
begin
   Result := Format(rsSQLUpdate, [ATableName, SQLNamesEqualValues(AColumns, AValues), AWhere]);
end;

function  SQLDelete(ATableName, AWhere: String): String;
begin
   Result := Format(rsSQLDelete, [ATableName]) + SQLWhere(AWhere);
end;

function  SQLWhere(AWhere: String): String;
begin
   Result := rsSQLWhere + AWhere;
end;

function  SQLOrderBy(AOrderBy: array of String; AOrderDesc: array of Boolean): String;
var
   i: Integer;
   S: String;
begin
   For i := Low(AOrderBy) to High(AOrderBy) do
      begin
         S := AOrderBy[i];
         If i in [Low(AOrderDesc)..High(AOrderDesc)] then
            begin
               If AOrderDesc[i] then S := S + rsSQLOrderDesc;
            end;
         Result := ConcatStrings(Result, S, ', ');
      end;
   Result := rsSQLOrder + Result;
end;

function  SQLFormatValue(AValue: Variant): String;
begin
  Result := VarToStr(AValue);
  case VarType(AValue) of
  varDate:   Result := DTToMDBStr(VarToDateTime(AValue));
  varUString,
  varString: //if Result <> rsSQLNull then
      Result := AddQuotes(
        StringReplace(StringReplace(StringReplace(Result,
          '\',  '\\',  [rfReplaceAll]),
          '"',  '\"',  [rfReplaceAll]),
          '''', '\''', [rfReplaceAll]));
  varDouble:  Result := StringReplace(Result, COMMA, DOT, []);
  varNull:    Result := rsSQLNull;
  end;
end;

function  SQLFormatValues(AValues: array of Variant): String;
var
  I: Integer;
begin
  Result := '';
  for I := Low(AValues) to High(AValues) do
    Result := ConcatStrings(Result, SQLFormatValue(AValues[i]), ', ');
end;

function  SQLNameEqualValue(AName: String; AValue: Variant): String;
begin
   Result := Format(rsNameEqualValue, [AName, SQLFormatValue(AValue)]);
end;

function  SQLNamesEqualValues(AColumns: array of String; AValues: array of Variant): String;
var
   i: Integer;
begin
   Result := '';
   For i := Low(AColumns) to High(AColumns) do
      Result := ConcatStrings(Result, SQLNameEqualValue(AColumns[i], AValues[i]), ', ');
end;

function  WhereScalesIndex(AScales: SmallInt): String;
begin
   Result := SQLNameEqualValue(rsScalesIndex, AScales);
end;

function  WhereScalesAndDateIndex(AScales: SmallInt; ADateTime: String): String;
begin
   Result := SQLNameEqualValue(rsScalesIndex, AScales) + rsSQLAnd + SQLNameEqualValue(rsScalesDateIndex, ADateTime);
end;

procedure ErrorSaveLoad(ProcessAction: TProcessAction; ConnectionType: TConnectionType;
   AWhat, AError: String; CloseConnections: Boolean = True; ShowMessage: Boolean = False);
var
   S, SAction, SDB: String;
begin
   If CloseConnections then
      begin
         Main.ConnectionLocal.Close;
         Main.ConnectionServer.Close;
      end;
   Case ConnectionType of
   ctLocal:    SDB := rsErrorLocalDB;
   ctServer:   SDB := rsErrorServerDB;
   end;
   Case ProcessAction of
   acOpen:     begin SAction := rsErrorOpen; SDB := ''; end;
   acLoad:     SAction := rsErrorLoad;
   acSave:     SAction := rsErrorSave;
   acDelete:   SAction := rsErrorDelete;
   end;
   S := Format(rsErrorSaveLoad, [Format(SAction, [AWhat, SDB]), AError]);
   WriteToLog(rsLOGError + S);
   If ShowMessage then MsgBoxErr(S);
end;

function GetTimerCount(AFirstTick: LongWord): String;
begin
   Result := ' (' + MyFormatTime(ExtractHMSFromMS(GetTickCount - AFirstTick), True) + ')';
end;

function  DTToSQLStr(ADateTime: TDateTime): String;
begin
   Result := FormatDateTime(rsDateTimeFormatSQL, ADateTime);
end;

function  DTToMDBStr(ADateTime: TDateTime): String;
begin
   Result := FormatDateTime(rsDateTimeFormatMDB, ADateTime);
end;

function  DTToWTime(ADateTime: TDateTime): LongWord;
begin
//   Result := Integer(DateTimeToUnix(IncHour(ADateTime, -4)));
   Result := Integer(DateTimeToUnix(ADateTime));
end;

function  WTimeToDT(AWTime: LongWord): TDateTime;
begin
//   Result := IncHour(UnixToDateTime(AWTime), 4);
   Result := UnixToDateTime(AWTime);
end;

function  SToF(Value: String): Double;
begin
   If Value = '' then Result := 0
                 else Result := StrToFloat(Value);
end;

end.
