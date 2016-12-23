unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLIntf, DateUtils;

type TPole = array of array of longint;

type TNode = record
   pole: TPole;
   rank: longint;
   level: longint;
   movex, movey: longint;
   childrenstart: longint;
   childrenend: longint;
   end; {record}

type ATNode = array of TNode;
type PATNode = ^ATNode;

type
  { TForm1 }
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    procedure adj_check(x,y: longint; pole: TPole);
    procedure adj_recolor(x,y: longint; pole: TPole);
    procedure gameEnd();
    procedure gamepole();
    procedure adjacent(x,y: longint; proc: string; pole: TPole);
    procedure FormShow(Sender: TObject);
    procedure drawhexa(x,y,t: longint);
    procedure Image1Click(Sender: TObject);
    function ismovelegal(x, y: longint; pole:TPole):boolean;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  xsize, ysize: longint;
  move: longint;


implementation

uses Unit2;

{$R *.lfm}

{ TForm1 }

function min(a,b:longint):longint; begin if (a < b) then result:=a else result:=b; end;
function max(a,b:longint):longint; begin if (a > b) then result:=a else result:=b; end;

var aa:longint;

var CURpole: TPole;
var ismycellnear: boolean;

var nodes: array of TNode;
    nodeslen: longint;


function getrank(pole: TPole):longint;
var a,b,i,j: longint;
begin
   a := 0;
   b := 0;
   for i := 0 to xsize-1 do
       for j := 0 to ysize-1 do
           begin
           if (pole[i, j] = 1) OR (pole[i, j] = 3) OR (pole[i, j] = 5) then
              a := a+1
           else if (pole[i, j] = 2) OR (pole[i, j] = 4) OR (pole[i, j] = 6) then
              b := b+1;
           end;
   result:=a-b;
end;

procedure AI_getnextnodes(var pole: TPole; level: longint);
var x,y,i,j: longint;
    newpole: TPole;
begin
   for x:=0 to xsize-1 do
       for y:=0 to ysize-1 do
           if (Form1.ismovelegal(x,y, pole)) then begin
              SetLength(newpole, xsize, ysize);
              for i:=0 to xsize-1 do
                  for j:=0 to ysize-1 do
                      newpole[i,j]:=pole[i,j];
              if (level mod 2 = 1) then // opponent move
                 newpole[x, y] := 5
                 else newpole[x, y] := 6;
              Form1.adjacent(x, y, 'recolor', newpole);
//              if (nodeslen mod 1000 = 0) then
//                 SetLength(nodes, nodeslen+1000);
              nodes[nodeslen].pole:=newpole;
              nodes[nodeslen].level:=level+1;
              nodes[nodeslen].movex:=x;
              nodes[nodeslen].movey:=y;
              nodes[nodeslen].childrenstart:=0;
              nodes[nodeslen].childrenend:=-1;
              nodeslen:=nodeslen+1;
           end;
end;

procedure AI_graph();
var curnodesstart, curnodesend:longint;
i:longint;
level, veryoldnodeslen, oldnodeslen: longint;
starttime: TDateTime;
begin
   SetLength(nodes, 1000000);
   // create current state node
   nodes[0].pole := CURpole;
   nodes[0].rank := 0;
   nodes[0].level := 0;
   nodes[0].childrenstart := 0;
   nodes[0].childrenend := -1;
   nodeslen:=1;
   curnodesstart:=0;
   curnodesend:=0;
   level:=0;
   
   // create graph
   starttime:=Now;
   while (curnodesend - curnodesstart >= 0)
     AND (level = 0) // otherwise it becomes slow
     AND (SecondsBetween(starttime, Now) < 5) do begin // AND time limit is not reached
     veryoldnodeslen:=nodeslen;
     // create children for every current node
     for i:=curnodesstart to curnodesend do
         begin
         oldnodeslen:=nodeslen;
         AI_getnextnodes(nodes[i].pole, level);
         // write info about children in node i
         nodes[i].childrenstart := oldnodeslen;
         nodes[i].childrenend := nodeslen-1;
         // we should not think for more then 5 seconds
         // but we must think for 1 move minimum
         if (SecondsBetween(starttime, Now) > 5) AND (level <> 0) then break;
         end;
     
     curnodesstart:=veryoldnodeslen;
     curnodesend:=nodeslen-1;
     level:=level+1;
   end;
end;

procedure AI_calc();
var i,j:longint;
begin
   for i:=nodeslen-1 downto 0 do
   begin
       if (nodes[i].childrenend - nodes[i].childrenstart < 0) then begin
          // no children -- game end
          nodes[i].rank := getrank(nodes[i].pole);
          continue;
       end;
       // there are children
       nodes[i].rank:=nodes[nodes[i].childrenstart].rank;
       for j:=nodes[i].childrenstart+1 to nodes[i].childrenend do
       begin
          if (nodes[i].level mod 2 = 0) then // our move
             nodes[i].rank :=
               max(nodes[i].rank, nodes[j].rank)
             else nodes[i].rank :=
               min(nodes[i].rank, nodes[j].rank);
       end;
   end;
end;

procedure AI_clean();
var i:longint;
begin
   for i:=1 to nodeslen-1 do
       SetLength(nodes[i].pole, 0, 0);
   SetLength(nodes, 0);
end;

procedure TForm1.gameEnd();
var rank: longint;
begin
   rank:=getrank(CURpole);
   if (rank > 0) then
      ShowMessage('Виграв перший (зелений) гравець!'+#13#10+
                  'Він має на '+IntToStr(rank)+' клітинок більше.')
      else if (rank < 0) then
              ShowMessage('Виграв другий (червоний) гравець!'+#13#10+
                          'Він має на '+IntToStr(-rank)+' клітинок більше.')
              else ShowMessage('Нічия!');
   Form1.Hide;
   Form2.Show;
end;

procedure TForm1.gamepole();
var x,y:longint;
begin
   for x:=0 to xsize-1 do
       for y:=0 to ysize-1 do
           if (x mod 2 = 0) then
              drawhexa(trunc(x*aa*1.5) + trunc(aa*1.5),
                trunc(y*aa*sqrt(3)) + trunc(aa*sqrt(3)),
                CURpole[x,y])
           else
              drawhexa(trunc(x*aa*1.5) + trunc(aa*1.5),
                trunc(y*aa*sqrt(3)+aa*sqrt(3)/2) + trunc(aa*sqrt(3)),
                CURpole[x,y]);
   Image1.Refresh;
end;

procedure TForm1.adj_check(x,y: longint; pole: TPole);
begin
   if (move mod 2 = 0) AND (pole[x,y] in [1,3,5])
      then ismycellnear:=true;
   if (move mod 2 = 1) AND (pole[x,y] in [2,4,6])
      then ismycellnear:=true;
end;

procedure TForm1.adj_recolor(x,y: longint; pole: TPole);
begin
   if (move mod 2 = 0) then
      case (pole[x,y]) of
            0: pole[x,y]:=3;
            4: pole[x,y]:=3;
            6: pole[x,y]:=5;
            7: pole[x,y]:=8;
            8: pole[x,y]:=8;
            9: pole[x,y]:=8;
           10: pole[x,y]:=11;
           11: pole[x,y]:=11;
           12: pole[x,y]:=11;
      end; {case}
   if (move mod 2 = 1) then
      case (pole[x,y]) of
            0: pole[x,y]:=4;
            3: pole[x,y]:=4;
            5: pole[x,y]:=6;
            7: pole[x,y]:=9;
            8: pole[x,y]:=9;
            9: pole[x,y]:=9;
           10: pole[x,y]:=12;
           11: pole[x,y]:=12;
           12: pole[x,y]:=12;
      end; {case}
end;

procedure TForm1.adjacent(x,y: longint; proc: string; pole: TPole);
begin
if (proc = 'check') then
   begin

   if (x mod 2 <> 0) then
      begin
      if (y <> 0) AND ((pole[x, y-1] <> 5) OR (pole[x, y-1] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_check(x, y-1, pole);
      if (y <> ysize-1) AND ((pole[x, y+1] <> 5) OR (pole[x, y+1] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_check(x, y+1, pole);
      if (x <> 0) AND ((pole[x-1, y] <> 5) OR (pole[x-1, y] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_check(x-1, y, pole);
      if (x <> xsize-1) AND ((pole[x+1, y] <> 5) OR (pole[x+1, y] <> 1) OR (pole[x+1, y] <> 2)) then
         adj_check(x+1, y, pole);
      if (y <> ysize-1) AND (x <> xsize-1) AND ((pole[x+1, y+1] <> 5) OR (pole[x+1, y+1] <> 1) OR (pole[x+1, y+1] <> 2)) then
         adj_check(x+1, y+1, pole);
      if (y <> ysize-1) AND (x <> 0) AND ((pole[x-1, y+1] <> 5) OR (pole[x-1, y+1] <> 1) OR (pole[x-1, y+1] <> 2)) then
         adj_check(x-1, y+1, pole);
      end
   else
      begin
      if (y <> 0) AND ((pole[x, y-1] <> 6) OR (pole[x, y-1] <> 2) OR (pole[x, y-1] <> 1)) then
         adj_check(x, y-1, pole);
      if (y <> ysize) AND ((pole[x, y+1] <> 6) OR (pole[x, y+1] <> 2) OR (pole[x, y+1] <> 1)) then
         adj_check(x, y+1, pole);
      if (x <> 0) AND ((pole[x-1, y] <> 6) OR (pole[x-1, y] <> 2) OR (pole[x-1, y] <> 1)) then
         adj_check(x-1, y, pole);
      if (x <> xsize) AND ((pole[x+1, y] <> 6) OR (pole[x+1, y] <> 2) OR (pole[x+1, y] <> 1)) then
         adj_check(x+1, y, pole);
      if (y <> 0) AND (x <> 0) AND ((pole[x-1, y-1] <> 6) OR (pole[x-1, y-1] <> 2) OR (pole[x-1, y-1] <> 1)) then
         adj_check(x-1, y-1, pole);
      if (y <> 0) AND (x <> xsize) AND ((pole[x+1, y-1] <> 6) OR (pole[x+1, y-1] <> 2) OR (pole[x+1, y-1] <> 1)) then
         adj_check(x+1, y-1, pole);
      end;

   end else begin

      if (x mod 2 <> 0) then
      begin
      if (y <> 0) AND ((pole[x, y-1] <> 5) OR (pole[x, y-1] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_recolor(x, y-1, pole);
      if (y <> ysize-1) AND ((pole[x, y+1] <> 5) OR (pole[x, y+1] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_recolor(x, y+1, pole);
      if (x <> 0) AND ((pole[x-1, y] <> 5) OR (pole[x-1, y] <> 1) OR (pole[x, y-1] <> 2)) then
         adj_recolor(x-1, y, pole);
      if (x <> xsize-1) AND ((pole[x+1, y] <> 5) OR (pole[x+1, y] <> 1) OR (pole[x+1, y] <> 2)) then
         adj_recolor(x+1, y, pole);
      if (y <> ysize-1) AND (x <> xsize-1) AND ((pole[x+1, y+1] <> 5) OR (pole[x+1, y+1] <> 1) OR (pole[x+1, y+1] <> 2)) then
         adj_recolor(x+1, y+1, pole);
      if (y <> ysize-1) AND (x <> 0) AND ((pole[x-1, y+1] <> 5) OR (pole[x-1, y+1] <> 1) OR (pole[x-1, y+1] <> 2)) then
         adj_recolor(x-1, y+1, pole);
      end
   else
      begin
      if (y <> 0) AND ((pole[x, y-1] <> 6) OR (pole[x, y-1] <> 2) OR (pole[x, y-1] <> 1)) then
         adj_recolor(x, y-1, pole);
      if (y <> ysize) AND ((pole[x, y+1] <> 6) OR (pole[x, y+1] <> 2) OR (pole[x, y+1] <> 1)) then
         adj_recolor(x, y+1, pole);
      if (x <> 0) AND ((pole[x-1, y] <> 6) OR (pole[x-1, y] <> 2) OR (pole[x-1, y] <> 1)) then
         adj_recolor(x-1, y, pole);
      if (x <> xsize) AND ((pole[x+1, y] <> 6) OR (pole[x+1, y] <> 2) OR (pole[x+1, y] <> 1)) then
         adj_recolor(x+1, y, pole);
      if (y <> 0) AND (x <> 0) AND ((pole[x-1, y-1] <> 6) OR (pole[x-1, y-1] <> 2) OR (pole[x-1, y-1] <> 1)) then
         adj_recolor(x-1, y-1, pole);
      if (y <> 0) AND (x <> xsize) AND ((pole[x+1, y-1] <> 6) OR (pole[x+1, y-1] <> 2) OR (pole[x+1, y-1] <> 1)) then
         adj_recolor(x+1, y-1, pole);
      end;

   end;
end;

procedure TForm1.drawhexa(x,y,t: longint);
begin
   // TODO: Волосников Коля: в зависимости от t зарисовывать шестиугольника
   case t of
         // 0 -- пусто
         0: Image1.Canvas.Brush.Color := rgb(  0,  0,  0);
        //  1 -- город 1-го игрока
         1: Image1.Canvas.Brush.Color := rgb(0,255,  0);
        //  2 -- город 2-го игрока
         2: Image1.Canvas.Brush.Color := rgb(255,0,  0);
        //  3 -- смежная с городом или крепостью 1-го игрока
         3: Image1.Canvas.Brush.Color := rgb(0  , 174,  0);
        //  4 -- смежная с городом или крепостью 2-го игрока
         4: Image1.Canvas.Brush.Color := rgb( 174,  0,  0);
        //  5 -- крепость 1-го игрока
         5: Image1.Canvas.Brush.Color := rgb(37  ,232,  37);
        //  6 -- крепость 2-го игрока
         6: Image1.Canvas.Brush.Color := rgb(232,  37,  37);
        //  7 -- река ничья
         7: Image1.Canvas.Brush.Color := rgb(  0,  0, 255);
        //  8 -- река 1-го игрока
         8: Image1.Canvas.Brush.Color := rgb(  54, 234,250);
        //  9 -- река 2-го игрока
         9: Image1.Canvas.Brush.Color := rgb( 0,  150,163);
        // 10 -- гора ничья
        10: Image1.Canvas.Brush.Color := rgb(127,127,127);
        // 11 -- гора 1-го игрока
        11: Image1.Canvas.Brush.Color := rgb(74,73,73);
        // 12 -- гора 2-го игрока
        12: Image1.Canvas.Brush.Color := rgb(97,94,94);
   end;

   Image1.Canvas.Pen.Color := rgb(255,254,253);
   Image1.Canvas.MoveTo(trunc(x-aa/2), trunc(y-aa*sqrt(3)/2));
   Image1.Canvas.LineTo(trunc(x+aa/2), trunc(y-aa*sqrt(3)/2));
   Image1.Canvas.LineTo(trunc(x+aa), trunc(y));
   Image1.Canvas.LineTo(trunc(x+aa/2), trunc(y+aa*sqrt(3)/2));
   Image1.Canvas.LineTo(trunc(x-aa/2), trunc(y+aa*sqrt(3)/2));
   Image1.Canvas.LineTo(trunc(x-aa), trunc(y));
   Image1.Canvas.LineTo(trunc(x-aa/2), trunc(y-aa*sqrt(3)/2));

   Image1.Canvas.floodfill(x,y,rgb(255,254,253),fsBorder);
end;

function TForm1.ismovelegal(x,y:longint; pole: TPole):boolean;
begin
   ismycellnear:=false;
   adjacent(X, Y, 'check', pole);
   if (ismycellnear
      OR ((move mod 2 = 0) AND (pole[X,Y] in [3]))
      OR ((move mod 2 = 1) AND (pole[X,Y] in [4]))
   ) AND (
         ((move mod 2 = 0) AND (pole[X,Y] in [0,3,4]))
      OR ((move mod 2 = 1) AND (pole[X,Y] in [0,3,4]))
   ) then result:=true else result:=false;
end;

procedure TForm1.Image1Click(Sender: TObject);
var theX, theY: longint;
x,y: longint;
pt: TPoint;
i, bestnode: longint;
anylegalmove: boolean;
begin
   // convert click coordinates into pole coordinates
   pt := Mouse.CursorPos;
   pt := ScreenToClient(pt);
   pt.x := pt.x - Form1.Image1.Left;
   pt.y := pt.y - Form1.Image1.Top;
   pt.x := trunc(pt.x - aa/2);
   pt.y := trunc(pt.y - aa*sqrt(3)/2);
   if (pt.x >= 0)
   AND(pt.y >= 0)
   AND(pt.x <= trunc(xsize*aa*3/2 + aa/2))
   AND(pt.y <= trunc(ysize*aa*sqrt(3) + aa*sqrt(3)/2)) then
      if (pt.x - trunc(pt.x / (1.5*aa))*(1.5*aa) > aa/2) then // rectangle
         begin
         theX := trunc(pt.x / (1.5*aa));
         if (theX mod 2 = 0) then theY := trunc(pt.y / (aa*sqrt(3)))
            else theY := trunc((pt.y-aa*sqrt(3)/2) / (aa*sqrt(3)));
         end else exit; // triangle

   if (theX < 0) OR (theY < 0)
   OR (theX >= xsize) OR (theY >= ysize) then exit;

   // determine if move is legal and make user move
   if ismovelegal(TheX, They, CURpole) then begin
      if (move mod 2 = 0) then
         CURpole[TheX, TheY] := 5
         else CURpole[TheX, TheY] := 6;
      adjacent(theX, theY, 'recolor', CURpole);
      move := move+1;
      end else exit;

   gamepole();
   if (move/2 >= StrToInt(Form2.TextK.Text)) then
      gameEnd();

   // if AI is turned on
   if (Form2.CmbMode1.Text = 'гравець-комп''ютер') then
      begin
      AI_graph();
      AI_calc();
      //AI_clean();
      if nodeslen <= 1 then begin gameEnd(); exit; end;
      bestnode:=1;
      assert(nodes[bestnode].level = 1);
      for i:=2 to nodeslen do
          begin
          if (nodes[i].level <> 1) then break;
          if (nodes[i].rank < nodes[bestnode].rank) then
             begin
             bestnode:=i;
             end;
          end;
      assert(ismovelegal(nodes[bestnode].movex, nodes[bestnode].movey, CURpole));

      if (move mod 2 = 0) then
         CURpole[nodes[bestnode].movex, nodes[bestnode].movey] := 5
         else CURpole[nodes[bestnode].movex, nodes[bestnode].movey] := 6;
      adjacent(nodes[bestnode].movex, nodes[bestnode].movey, 'recolor', CURpole);
      move:=move+1;

      gamepole();
      if (move/2 >= StrToInt(Form2.TextK.Text)) then
         gameEnd();
      end;

   anylegalmove:=false;
   for x:=0 to xsize-1 do
       begin
       for y:=0 to ysize-1 do
           if (Form1.ismovelegal(x,y, CURpole)) then
              begin anylegalmove:=true; break; end;
       if anylegalmove then break;
       end;
   if not anylegalmove then gameEnd();
end;

procedure TForm1.FormShow(Sender: TObject);
var cor1, cor2: TPoint;
var n, i: longint;
var a, b: longint;
var x, y:longint;
begin
   randomize();

   Form1.DoubleBuffered := true;
   xsize:=StrToInt(Form2.TextX.Text);
   ysize:=StrToInt(Form2.TextY.Text);
   SetLength(CURpole, xsize, ysize);

   if ((780 / (1.5*xsize + 1.5)) < (600 / (ysize*sqrt(3) + 1.5*sqrt(3)))) then
      aa:=trunc(780 / (1.5*xsize + 1.5))
      else aa:=trunc(600 / (ysize*sqrt(3) + 1.5*sqrt(3)));

   repeat
     cor1.x := random(xsize);
     cor1.y := random(ysize);
     cor2.x := random(xsize);
     cor2.y := random(ysize);
   until (abs(cor2.x-cor1.x)>2) AND (abs(cor2.y-cor1.y)>2);

   for x:=0 to xsize-1 do
       for y:=0 to ysize-1 do
           CURpole[x ,y] := 0;

   CURpole[cor1.x, cor1.y] := 1;
   CURpole[cor2.x, cor2.y] := 2;

   move := 0;
   adjacent(cor1.x, cor1.y, 'recolor', CURpole);
   move := 1;
   adjacent(cor2.x, cor2.y, 'recolor', CURpole);
   move := 0;

   if (Form2.CmbMode.Text <> 'I''m too young to die') then
      begin
      n := trunc(0.1*xsize*ysize);
      for i := 1 to n do
          begin
          repeat
             a := random(xsize);
             b := random(ysize);
          until (CURpole[a, b] = 0);
          CURpole[a,b] := 7;
          end;
      for i := 1 to n do
          begin
          repeat
             a := random(xsize);
             b := random(ysize);
          until (CURpole[a, b] = 0);
          CURpole[a,b] := 10;
          end;
      end;

   Image1.Canvas.Draw(0,0,Image2.Picture.Bitmap);
   gamepole();
end;

end.

