program gedit;
{$M 65520,0,655360}
{$G+}

uses pgs, vga, bfont, commonui, imgedit, pgsedit;

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

procedure startPgsEdit;
var
   m	 : menudata;
   r	 : byte;
   sx,sy : word;
   ext	 : string[12];
begin
   m.title:= 'Package Editor';
   m.items[1] := 'New Package';
   m.items[2] := 'Load Package';
   m.count := 2;

   r:= menu(m);

   if r=1 then
   begin
      pickSize(sx,sy);
      newPackage(sx,sy);
      editPgs;
   end;
   if r=2 then
   begin
      ext := pgsedit.selectFileExtension;
      ext := fileSelector(ext,false);
      if ext<>'' then
      begin
	 pgsedit.loadPackage(ext);
	 editPgs;
      end;      
   end;
end;

procedure chooseEditor;
var
   m	: menuData;
   r	: byte;
   done	: boolean;
begin
   m.title := 'GEdit';
   m.items[1] := 'Image Editor';
   m.items[2] := 'Package Editor';
   m.items[3] := 'Palette Editor';
   m.items[4] := 'Exit';
   m.count := 4;

   done:= false;

   while not(done) do
   begin
      cls;
      r := menu(m);

      case r of
	1 : startImgEdit;
	2 : startPgsEdit;
	{3 not done yet}
	4 : done := true;
      end;
   end;
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
   
   chooseEditor;

   textscreen;
end.
