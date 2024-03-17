program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Windows, Interfaces, // this includes the LCL widgetset
  Forms, GetOpts, Dialogs, Unit1
  { you can add units after this };

{$R *.res}

Const MaxParam= 2;
      Param: Array [1..MaxParam] Of Record
                                      Name: String;
                                      Has_Arg: Integer;
                                    End= ((Name: 'Folder'  ; Has_Arg: 1),        //  1
                                          (Name: 'NoUpdate'; Has_Arg: 0));       //  2

Var Ex, i, OptIndex: Integer;
    c: Char;
    Opts: Array[1..MaxParam] Of TOption;

begin
  RequireDerivedFormResource := True;
  Application.Initialize;

  Ex:= GetWindowLong(FindWindow(Nil, PChar(Application.Title)), GWL_EXSTYLE);
  SetWindowLong(FindWindow(Nil, PChar(Application.Title)), GWL_EXSTYLE, Ex Or WS_EX_TOOLWINDOW And Not WS_EX_APPWINDOW);

  Application.CreateForm(TForm1, Form1);

  For i:= 1 To MaxParam Do
    With Opts[i] Do
      Begin
        Name   := Param[i].Name;
        Has_Arg:= Param[i].Has_Arg;
        Flag   := Nil;
        Value  := #0;
      End;

  c:= #0;
  OptIndex:= 0;
  _Folder:= '';
  _Update:= True;

  Repeat
    c:= GetLongOpts('f:n1', @Opts[1], OptIndex);
    Case c Of
      'f': _Folder:= OptArg;
      'n': _Update:= False;
    End;
  Until c= EndOfOptions;

  If _Update Then
    Form1.miUpdateClick(Form1);

  If Length(_Folder)= 0 Then
    Form1.miSetClick(Form1);

  Application.Run;
end.

