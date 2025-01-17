program gedit;
{$M 65520,0,655360}
{$G+}

uses pgs, vga, bfont, commonui, imgedit;

var drawCheck:boolean;

procedure startImgEdit;
var
   m	 : menudata;
   r	 : byte;
   sx,sy : word;
   save	 : boolean;
begin
   m.title := 'Image Editor';
   m.items[1] := 'New Image';
   m.items[2] := 'Load Image';
   m.count := 2;

   r:= menu(m);

   if r=0 then exit;
   if r=1 then
   begin
      pickSize(sx,sy);
   end;

   if r=2 then
   begin
      importGFX;
      clearUndo;
      getSize(sx,sy);
   end;

   save := editImg(sx,sy);

   if save then exportGFX;   
end;

begin
   pgs.initvga;
   bfont.loadFont('litt.chr');
   if not(setDrawMode(2)) then
   begin
      textscreen;
      writeln('Not enough memory for back buffer');
      halt(1);
   end;
   
   startImgEdit;

   textscreen;
end.
