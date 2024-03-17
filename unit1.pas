unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, StdCtrls, PopupNotifier, Windows, ShellApi, IniFiles, Process,
  StrUtils;

type
 TWindowPos = packed record
   hwnd: HWND; {Identifies the window.}
   hwndInsertAfter: HWND; {Window above this one}
   x: Integer; {Left edge of the window}
   y: Integer; {Right edge of the window}
   cx: Integer; {Window width}
   cy: Integer; {Window height}
   flags: UINT; {Window-positioning options.}
 end;

  { TForm1 }

  TForm1 = class(TForm)
    IdleTimer1: TIdleTimer;
    ImageList1: TImageList;
    imBox: TImage;
    laBox: TLabel;
    MenuItem1: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    miUpdate: TMenuItem;
    miSet: TMenuItem;
    MenuItem2: TMenuItem;
    miView: TMenuItem;
    miClose: TMenuItem;
    miClear: TMenuItem;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    PopupNotifier1: TPopupNotifier;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    TrayIcon1: TTrayIcon;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure miUpdateClick(Sender: TObject);
    procedure miClearClick(Sender: TObject);
    procedure miSetClick(Sender: TObject);
    procedure miCloseClick(Sender: TObject);
    procedure miViewClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

Const VBSUpdate= 'Option Explicit'#13+
                 'WScript.Sleep(30)'#13+
                 'Dim vOldFile : vOldFile = "***OLDFILE***"'#13+               //ChangeFileExt(ParamStr(0),'.OLD')
                 'Dim vLocalFile : vLocalFile = "***LOCALFILE***"'#13+         //ParamStr(0)
                 'Dim vServerFile : vServerFile = "***SERVERFILE***"'#13+      //LocalSetupFile
                 'If (fFileExists(vOldFile)) And (fDeleteFile(vOldFile)) Or (Not fFileExists(vOldFile)) Then'#13+
                 '	If fMoveFile(vLocalFile, vOldFile) Then'#13+
                 '		If fMoveFile(vServerFile, vLocalFile) Then'#13+
                 '			sRunFile(vLocalFile)'#13+
                 '		End If'#13+
                 '	End If'#13+
                 'End If'#13+
                 ''#13+
                 'Function fFileExists(vFile)'#13+
                 '	Dim pvFileSystemObject'#13+
                 '	Set pvFileSystemObject = CreateObject("Scripting.FileSystemObject")'#13+
                 '	fFileExists = pvFileSystemObject.FileExists(vFile)'#13+
                 '	Set pvFileSystemObject = Nothing'#13+
                 'End Function'#13+
                 ''#13+
                 'Function fDeleteFile(vFile)'#13+
                 '	Dim pvFileSystemObject, pvFile'#13+
                 '	If fFileExists(vFile) Then'#13+
                 '		Set pvFileSystemObject = CreateObject("Scripting.FileSystemObject")'#13+
                 '		Set pvFile = pvFileSystemObject.GetFile(vFile)'#13+
                 '		pvFile.Delete'#13+
                 '		If fFileExists(vFile) Then'#13+
                 '			fDeleteFile = False'#13+
                 '		Else'#13+
                 '			fDeleteFile = True'#13+
                 '		End If'#13+
                 '	Else'#13+
                 '		fDeleteFile = False'#13+
                 '	End If'#13+
                 'End Function'#13+
                 ''#13+
                 'Function fMoveFile(vFromFile, vToFile)'#13+
                 '	Dim vLocation :	Set vLocation = CreateObject("Scripting.FileSystemObject")'#13+
                 '	If (Not fFileExists(vFromFile)) Or (fFileExists(vToFile)) Then'#13+
                 '		fMoveFile = False'#13+
                 '	Else'#13+
                 '		vLocation.MoveFile vFromFile, vToFile'#13+
                 '		If (fFileExists(vFromFile)) Or (Not fFileExists(vToFile)) Then'#13+
                 '			fMoveFile = False'#13+
                 '		Else'#13+
                 '			fMoveFile = True'#13+
                 '		End If'#13+
                 '	End If'#13+
                 '	Set vLocation = Nothing'#13+
                 'End Function'#13+
                 ''#13+
                 'Sub sRunFile(vFile)'#13+
                 '    Dim vShell : Set vShell = WScript.CreateObject("WScript.Shell")'#13+
                 '    Dim s, i'#13+
                 '    s = ""'#13+
                 '    For i = 1 To WScript.Arguments.Count'#13+
                 '        s = s & " " & WScript.Arguments(i - 1)'#13+
                 '    Next'#13+
                 '    vShell.Run Chr(34) & vFile & Chr(34) & "-n" & s, 6, True'#13+
                 '    Set vShell = Nothing'#13+
                 'End Sub';

var
  Form1: TForm1;
  _Folder: String;
  _Update: Boolean;

implementation

{$R *.lfm}

{ TForm1 }

Const icoDisable= 0;
      icoGreen= 1;
      icoRed= 2;

Var OldX, OldY: Integer;
    MoveOn: Boolean;
    sL: TStringList;
    TerminateApplication: Boolean= False;
    NewVersion, ServerVersion, LocalVersion: String;
    SilenceUpdate: Boolean= False;

(*
procedure SetTranslucent(ThehWnd: Longint; Color: Longint; nTrans: Integer);
Var Attrib: Longint;
Begin
  { SetWindowLong and SetLayeredWindowAttributes are API functions, see MSDN for details }
  Attrib := GetWindowLongA(ThehWnd, GWL_EXSTYLE);
  SetWindowLongA (ThehWnd, GWL_EXSTYLE, attrib Or WS_EX_LAYERED);
  { anything with color value color will completely disappear if flag = 1 or flag = 3  }
  SetLayeredWindowAttributes (ThehWnd, Color, nTrans, 1);
End;
*)

procedure TForm1.miCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.miViewClick(Sender: TObject);
begin
  WinExec(PChar('explorer.exe /e, '+ Form1.Hint), SW_SHOWNORMAL);
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
begin
  miView.Enabled:= DirectoryExists(Form1.Hint);
  miClear.Enabled:= miView.Enabled;
  miClose.Enabled:= sL.Count= 0;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MoveOn := True;
  OldX := X;
  OldY := Y;
end;

procedure TForm1.FormCreate(Sender: TObject);
Var FileDate: Integer;
begin
  ForceDirectories(GetAppConfigDir(False)); { creare director }

  With TIniFile.Create(IncludeTrailingPathDelimiter(GetAppConfigDir(False))+ ChangeFileExt(ApplicationName, '.ini')) Do
    Begin
      NewVersion:= ReadString('Version', 'Update', '\\servername\updates$\anchor\Anchor.ver');
      FileDate := FileAge(Application.ExeName);
      If FileDate > -1 Then
        LocalVersion:= FormatDateTime('yyyymmdd-hhnn', FileDateToDateTime(FileDate));
      //lbAppCurrentVersion.Caption:= LocalVersion;
      //lbAppServerVersion.Caption:= LocalVersion;
    End;

  Form1.AllowDropFiles:= False;
  Form1.Hint:= '';
  laBox.Caption:= 'No destination';

  Form1.Width:= Panel1.Width;
  Form1.Height:= Panel1.Height;

  laBox.Left:= (Panel1.Width- laBox.Width) Div 2;
  imBox.Left:= (Panel1.Width- imBox.Width) Div 2;

  imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
  ImageList1.GetBitmap(icoDisable, imBox.Picture.Bitmap);

  //Randomize;
  //Form1.Color:= RGB(Random(255), Random(255), Random(255));
  //Form1.Color:= clGray;
  Panel1.Color:= Form1.Color;
  (*
  SetTranslucent (Form1.Handle, Form1.Color, 0);
  *)
  sL:= TStringList.Create;
end;

procedure TForm1.FormActivate(Sender: TObject);
Var Path: String;
begin
  Form1.Left:= Screen.Width- Form1.Width- 5;
  Form1.Top:= 5;

  //If ParamCount= 0 Then
{  If Not Application.HasOption('f', 'folder') Then
    miSetClick(Sender)
  Else }
    Begin
      Form1.AllowDropFiles:= True;
      Form1.Hint:= _Folder;
      Path:= Form1.Hint;
      If Length(Path)> 12 Then
        Delete(Path, 1, LastDelimiter('\', Path));
      If Length(Path)> 12 Then
        Path:= Copy(Path, 1, 12)+ '...';

      laBox.Caption:= Path;
      imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
      ImageList1.GetBitmap(icoGreen, imBox.Picture.Bitmap);

      laBox.Left:= (Panel1.Width- laBox.Width) Div 2;
      imBox.Left:= (Panel1.Width- imBox.Width) Div 2;

      If Not DirectoryIsWritable(Form1.Hint) Then
        MessageDlg('Destination folder is not writeable!', mtWarning, [mbOk], 0);
    End;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  sL.Free;
end;

procedure TForm1.FormDropFiles(Sender: TObject; Const FileNames: Array Of String);
Var i: Integer;
    b: Boolean;
begin
  If DirectoryExists(Form1.Hint) And DirectoryIsWritable(Form1.Hint) Then
    Begin
      b:= False;
      For i:= Low(FileNames) To High(FileNames) Do
        If Not FileExists(FileNames[i]) Then
          Begin
            b:= True;
            Break;
          End;
      If b Then
        MessageDlg('Unable to send folders!', mtWarning, [mbOk], 0)
      Else
        For i:= Low(FileNames) To High(FileNames) Do
          sL.Add(FileNames[i]);
      IdleTimer1.Enabled:= True;
    End
  Else
    MessageDlg('Destination folder is not writeable', mtWarning, [mbOk], 0);
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  If MoveOn Then
    Begin
      Left := (Left - OldX) + X;
      Top := (Top - OldY) + Y;
    End;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MoveOn := False;
end;

Function CopyDir(Const fromDir, toDir: String): Boolean;
Var fos: TSHFileOpStruct;
Begin
  ZeroMemory(@fos, SizeOf(fos));
  With fos Do
    Begin
      wFunc  := FO_COPY;
      fFlags := FOF_FILESONLY;
      pFrom  := PChar(fromDir + #0);
      pTo    := PChar(toDir);
    End;
  Result := (0 = ShFileOperation(fos));
End;

procedure TForm1.IdleTimer1Timer(Sender: TObject);
Var Path: String;
begin
  IdleTimer1.Enabled:= False;
  If sL.Count> 0 Then
    Begin
      imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
      ImageList1.GetBitmap(icoRed, imBox.Picture.Bitmap);
      If FileExists(sL[0]) Then
        Begin
          Path:= IncludeTrailingPathDelimiter(Form1.Hint)+ ExtractFileName(sL[0]);
          If FileExists(Path) Then
            If MessageDlg('File exists'#13+
                          Path+ #13+
                          'Overwrite?', mtConfirmation, [mbYes, mbNo], 0)= mrYes Then
              DeleteFile(PChar(Path));
          If Not FileExists(Path) Then
            If CopyFile(PChar(sL[0]), PChar(Path), True) Then
              sL.Delete(0)
            Else
              If MessageDlg('Unable to copy file'#13+
                            ExtractFileName(sL[0]+#13+
                            'Try to copy again?'), mtError, [mbYes, mbNo], 0)= mrNo Then
                sL.Delete(0)
              Else
          Else
            sL.Delete(0);
        End
      Else If DirectoryExists(sL[0]) Then
        If CopyDir(sL[0], Form1.Hint) Then
          sL.Delete(0)
        Else
          Begin
            Path:= sL[0];
            Delete(Path, 1, LastDelimiter('\', Path));
            If MessageDlg('Unable to copy folder'#13+
                          Path+ #13+
                          'Try to copy again?', mtError, [mbYes, mbNo], 0)= mrNo Then
              sL.Delete(0);
          End;
      IdleTimer1.Enabled:= True;
    End
  Else
    Begin
      imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
      ImageList1.GetBitmap(icoGreen, imBox.Picture.Bitmap);
    End;
end;

Function DownloadFile(SourceFile, DestFile: String): Boolean;
Begin
  Result:= False;
  If SourceFile= '' Then
    Result:= False
  Else
    If AnsiStartsText('http://', SourceFile) Then
      Begin
        //Try
        //  Result:= UrlDownloadToFile(Nil, PChar(SourceFile), PChar(DestFile), 0, Nil)= 0;
        //Except
          Result:= False;
        //End;
      End
    Else If (AnsiStartsText('\\', SourceFile)) Or (Pos(':\', SourceFile)= 2) Then
      If FileExists(SourceFile) Then
        Result:= CopyFile(PChar(SourceFile), PChar(DestFile), False);  //  False = cfOverwrite
End;

procedure TForm1.miUpdateClick(Sender: TObject);
Var tsVBS, tsUpdates: TStringList;
    IniFile: TIniFile;
    s, LocalSetupFile, ServerFile, ListOfChanges, GetTempDirectory: String;
    _VBSUpdate: AnsiString;
    i: Integer;
    RunUpdate: Boolean;
    AProcess: TProcess;
begin
  If Sender Is TMenuItem Then
    SilenceUpdate:= False
  Else
    SilenceUpdate:= True;
  TerminateApplication:= True;

  If TerminateApplication Then
    Form1.Enabled:= False;
  tsUpdates:= TStringList.Create;
  RunUpdate:= False;

  ForceDirectories(GetAppConfigDir(False)); { creare director }
  GetTempDirectory:= IncludeTrailingBackslash(GetAppConfigDir(False));

  If DownloadFile(NewVersion, GetTempDirectory+ 'update.ver') Then
    Begin
      IniFile:= TIniFile.Create(GetTempDirectory+ 'update.ver');
      Try
        ServerVersion:= IniFile.ReadString ('Version', 'Last', '0');
        //Form1.lbAppServerVersion.Caption:= ServerVersion;

        ServerFile   := IniFile.ReadString ('Version', 'Executable', '');
        IniFile.ReadSection('Updates', tsUpdates);
        ListOfChanges:= '';
        For i:= 1 To tsUpdates.Count Do
          ListOfChanges:= ListOfChanges+ #13+ tsUpdates.Strings[i- 1];
      Finally
        IniFile.Free;
      End;
      LocalSetupFile:= GetTempDirectory+ 'setup.exe';

      If ServerVersion> LocalVersion Then
        Begin
          If DownloadFile(ServerFile, LocalSetupFile) Then
            Begin
              If SilenceUpdate Then
                RunUpdate:= True
              Else
                If MessageDlg('New version available '+ QuotedStr(ServerVersion)+ #13#13+
                              '('+ IntToStr(tsUpdates.Count)+ ' changes)'#13+
                              'Update?', mtConfirmation, [mbYes, mbNo], 0)= mrYes Then
                  RunUpdate:= True
                Else
                  RunUpdate:= False;
              If RunUpdate Then
                Begin
                  tsVBS:= TStringList.Create;
                  _VBSUpdate:= StringReplace( VBSUpdate, '***OLDFILE***'   , ChangeFileExt(ParamStr(0),'.OLD'), [rfReplaceAll, rfIgnoreCase]);
                  _VBSUpdate:= StringReplace(_VBSUpdate, '***LOCALFILE***' , ParamStr(0)                      , [rfReplaceAll, rfIgnoreCase]);
                  _VBSUpdate:= StringReplace(_VBSUpdate, '***SERVERFILE***', LocalSetupFile                   , [rfReplaceAll, rfIgnoreCase]);
                  tsVBS.Add(_VBSUpdate);
                  tsVBS.SaveToFile(GetTempDirectory+ 'update.vbs');

                  //WinExec(PChar('WScript "'+ GetTempDirectory+ 'update.vbs'+ '"'), SW_ShowNormal);
                  AProcess:= TProcess.Create(Nil);
                  AProcess.Executable:= PAnsiChar('cmd');
                  s:= '';
                  If Length(_Folder)> 0 Then
                    s:= ' -f '+ _Folder;
                  AProcess.Parameters.Add('/k "'+ GetTempDirectory+ 'update.vbs'+ '"'+ s);
                  AProcess.Options:= AProcess.Options+ [poNoConsole];
                  AProcess.Execute;
                  AProcess.Free;

                  tsVBS.Free;
                  If TerminateApplication Then
                    Application.Terminate;
                End
            End
          Else
            If Not SilenceUpdate Then
              MessageDlg('Unable to download new version.', mtWarning, [mbOk], 0);
        End
      Else
        If Not SilenceUpdate Then     // la pornirea aplicatiei, Sender=Form1
          MessageDlg('No new version.', mtInformation, [mbOk], 0);
    End
  Else If Not SilenceUpdate Then
    MessageDlg('Unable to connect to update server.', mtWarning, [mbOk], 0);

  tsUpdates.Free;
  If TerminateApplication Then
    Form1.Enabled:= True;
  //RunUpdate;
end;

procedure TForm1.miClearClick(Sender: TObject);
begin
  If MessageDlg('Clear destination folder?', mtConfirmation, [mbYes, mbNo], 0)= mrYes Then
    Begin
      Form1.AllowDropFiles:= False;
      Form1.Hint:= '';

      laBox.Caption:= 'No destination';
      imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
      ImageList1.GetBitmap(icoDisable, imBox.Picture.Bitmap);

      laBox.Left:= (Panel1.Width- laBox.Width) Div 2;
      imBox.Left:= (Panel1.Width- imBox.Width) Div 2;
    End;
end;

procedure TForm1.miSetClick(Sender: TObject);
Var Path: String;
begin
  If SelectDirectoryDialog1.Execute Then
    Begin
      Form1.AllowDropFiles:= True;
      Form1.Hint:= SelectDirectoryDialog1.FileName;
      Path:= SelectDirectoryDialog1.FileName;
      If Length(Path)> 12 Then
        Delete(Path, 1, LastDelimiter('\', Path));
      If Length(Path)> 12 Then
        Path:= Copy(Path, 1, 12)+ '...';

      laBox.Caption:= Path;
      imBox.Picture.Bitmap.SetSize(ImageList1.Width, ImageList1.Height);
      ImageList1.GetBitmap(icoGreen, imBox.Picture.Bitmap);

      laBox.Left:= (Panel1.Width- laBox.Width) Div 2;
      imBox.Left:= (Panel1.Width- imBox.Width) Div 2;

      If Not DirectoryIsWritable(SelectDirectoryDialog1.FileName) Then
        MessageDlg('Destination folder is not writeable!', mtWarning, [mbOk], 0);
    End;
end;

end.

