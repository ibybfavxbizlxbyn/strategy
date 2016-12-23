unit Unit2;

// TODO: Кубарев Илья: украсить форму

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons;

type

  { TForm2 }

  TForm2 = class(TForm)
    BitBtnStart: TBitBtn;
    CmbMode: TComboBox;
    CmbMode1: TComboBox;
    Image1: TImage;
    Label4: TLabel;
    Label5: TLabel;
    TextX: TEdit;
    TextK: TEdit;
    TextY: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure BitBtnStartClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TextXKeyPress(Sender: TObject; var Key: char);
    procedure TextYKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;

implementation

uses Unit1;

{$R *.lfm}

{ TForm2 }

procedure TForm2.BitBtnStartClick(Sender: TObject);
begin
   begin
     if ((TextX.Text = '') OR (TextY.Text = '')
     OR  (TextK.Text = '') OR (CmbMode.Text = '...' )) then
        begin
        ShowMessage('Прохання заповнити усі поля.');
        exit;
        end;
     if(StrToInt(TextX.Text) < 6) OR (StrToInt(TextX.Text) > 50)
     OR (StrToInt(TextY.Text) < 6) OR (StrToInt(TextY.Text) > 50)
     OR (StrToInt(TextK.Text) < 1) OR (StrToInt(TextK.Text) > StrToInt(TextX.Text)*StrToInt(TextY.Text)) then
        begin
        ShowMessage('Прохання, ввести натуральні числа від 6 до 50.');
        exit;
        end;
     if (CmbMode.Text = 'I''m too young to die')
     OR (CmbMode.Text = 'Hey, not too rough!') then
        begin
        Form2.Hide;
        Form1.Show;
        end else ShowMessage('Вибачне, цей режим не реалізовано. Оберіть, будь ласка, інший.');
   end;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
   Image1.SendToBack;
   TextX.BringToFront;
   TextY.BringToFront;
   TextK.BringToFront;
   CmbMode.BringToFront;
   Label1.BringToFront;
   Label2.BringToFront;
   Label3.BringToFront;
   Label4.BringToFront;
end;


procedure TForm2.TextXKeyPress(Sender: TObject; var Key: char);
begin
   if not (key in['0'..'9', #8]) then key:=#0;
end;

procedure TForm2.TextYKeyPress(Sender: TObject; var Key: char);
begin
   if not (key in['0'..'9', #8]) then key:=#0;
end;

end.

