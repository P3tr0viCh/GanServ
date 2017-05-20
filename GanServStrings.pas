unit GanServStrings;

interface

resourcestring
   rsCopyright = '� �3��0���� (�.�. ������, ���� ����, 2004-2014)|�� ��������� �������� ���������� ��������������� � ������';
   rsAddComp   = '� ���� ������ Access, �������� � ������ Microsoft� Office,'#13#10 +
                 '  � ���������� ����������, 2003.'#13#10 +
                 '� MySQL ODBC 3.51, � MySQL AB, 2005.';

   rsConnectionLocal  = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=%s;Persist Security Info=False;User ID=Admin;Jet OLEDB:Database Password="%s";';
   rsConnectionServer = 'DRIVER={MySQL ODBC 3.51 Driver};SERVER=%s;PORT=%s;DATABASE=wdb3;USER=%s;PASSWORD=%s;OPTION=3;';

   rsTrayIconTip      = '�������� ������ �� ������: ';
   rsTrayIconWait     = '��������';
   rsTrayIconWork     = '�������� ������';

   rsDateTimeFormatSQL  = 'yyyy"-"mm"-"dd" "hh":"nn":"ss';
   rsDateTimeFormatMDB  = '#M"/"d"/"yyyy" "h":"m":"s#'; 

   rsQuestionClose = '������� ��������� � ���������� �������� ������ �� ������?';

   rsErrorLocalNotExists   = '���� ������ "������" (%s) �� ���������� ��� ���������� � ������ ������';
   rsErrorServerNotExists  = '��������� ������ �� ����� �������� ������� ���� ������:'#13#10 +
                             '"%s"';
   rsErrorLocalOpen        = '��������� ������ �� ����� �������� ���� ������ "������":'#13#10 +
                             '"%s"';
   rsErrorSettingsNotExists= '���� ������ � ����������� �� ����������';
   rsErrorSettingsBad      = '���� ������ � ����������� ����������';
   rsErrorCloseApp         = '.'#13#10#13#10'������ ���� ���������� ��� ������, ������� ��������� �����������';
   rsErrorCheckPass     = '��������� ������ �� ���������. ��������� ���� ������ ������ � ��� ������������';
   rsErrorPassword      = '������ ������?'#13#10#13#10 +
                          '������� ������ ������.'#13#10 +
                          '��������� ������������ ������������� �������� � ��������� ����������';

   rsErrorSaveLoad      = '�� ������� %s, ��� ��� ��������� ������:'#13#10#13#10'%s';
   rsErrorOpen          = '������� ��%s%s';
   rsErrorSave          = '��������� %s � %s ���� ������';
   rsErrorLoad          = '��������� %s �� %s ���� ������';
   rsErrorDelete        = '������� %s �� %s ���� ������';
   rsErrorLocalDB       = '���������';
   rsErrorServerDB      = '�������';
   rsErrorSLSettings    = '���������';
   rsErrorSLScaleInfo   = '������ � �����';
   rsErrorSLVans        = '���������';

   rsTableLocal            = 'Measures';
   rsTableServerScalesInfo = 'scalesinfo';
   rsTableServerVans       = 'kanatb';

   rsSQLServerScalesInfo   = 'scales, ctime, cdatetime, ipaddr, type, sclass, dclass, place, tag1';
   rsSQLLocalMeasures      = 'ID, DTWeigh, Brutto, Tara, Netto';
   rsSQLServerMeasures     = 'scales, num, wtime, bdatetime, brutto, tare, netto';
   rsSQLLocalSend          = 'Send';

   rsSQLInsert    = 'INSERT INTO %s (%s) VALUES (%s)';
   rsSQLUpdate    = 'UPDATE %s SET %s WHERE %s';
   rsSQLDelete    = 'DELETE FROM %s';
   rsSQLSelect    = 'SELECT %s FROM %s';
   rsSQLWhere     = ' WHERE ';
   rsSQLOrder     = ' ORDER BY ';
   rsSQLLimitOne  = ' LIMIT 1';
   rsSQLOrderDesc = ' DESC';
   rsSQLCount     = 'COUNT(*)';
   rsSQLNull      = 'NULL';

   rsNameEqualValue = '%s=%s';
   rsSQLAnd         = ' AND ';

   rsLocalIndex      = 'ID';
   rsLocalDateIndex  = 'DTWeigh';
   rsScalesIndex     = 'scales';
   rsScalesDateIndex = 'bdatetime';
   rsLocalOrderBy    = 'DTWeigh';

   rsLOGStartProgram    = '<><><><><><><>< START PROGRAM GanServ %s ><><><><><><><>';
   rsLOGStopProgram     = 'STOP PROGRAM';
   rsLOGError              = 'ERROR: ';
   rsLOGSettingsSave       = 'save settings';
   rsLOGScaleInfoSave      = 'save scale info';
   rsLOGFormOptions        = 'options';
   rsLOGDataCheck          = 'check data, need send=%d';
   rsLOGDataRead           = 'read data, brutto=%d';
   rsLOGDataSave           = 'save data end';
   rsLOGLocalChangeTable   = 'change table message';
   rsLOGErrorPassword      = 'options password error';

implementation

end.
