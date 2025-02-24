{ Online help for Gedit. This is Generally very simple, it mostly is
  just the contents of the help.

  A Danson 2025 }

unit help;

interface

procedure imgHelp;

procedure pgsHelp;

procedure palHelp;

implementation

uses commonui;

procedure imgHelp;
var
   help	: helpdata;
   i,c	: byte;
begin
   {clear the help so unused pages/lines don't appear corrupt}
   for i:=1 to 16 do
      for c:= 1 to 5 do
	 help.pages[i,c] := '';
   with help do
      begin
	 { help text for the image editor }
	 pages[1,1] := '  Image Editor Key Reference';
	 pages[2,1] := ' F1   - This help menu';
	 pages[3,1] := ' F2   - Special functions';
	 pages[4,1] := ' F3   - Tool Selection';
	 pages[5,1] := ' P    - Select a colour';
	 pages[6,1] := ' <or> - Change palette selection';
	 pages[7,1] := ' G    - Get colour from image';
	 pages[8,1] := 'Enter - Toggle continuous draw';
	 pages[9,1] := 'Space - Use tool';
	 pages[10,1]:= ' U    - Undo operation';
	 pages[11,1]:= ' M    - Manually save to undo buffer';
	 pages[12,1]:= 'Q,Esc - Quit menu';
	 pages[13,1]:= 'Arrows- Move cursor';
	 pages[15,1]:= ' number keys (1-0) quick selects a colour';
	 pcount := 1;
      end;
   commonui.help(help);   
end;

procedure pgsHelp;
var
   help	: helpdata;
   i,c	: byte;
begin
   {clear the help so unused pages/lines don't appear corrupt}
   for i:=1 to 16 do
      for c:= 1 to 5 do
	 help.pages[i,c] := '';
   with help do
      begin
	 { help text for the image editor }
	 pages[1,1] := '  Package Editor Key Reference';
	 pages[2,1] := ' F1   - This help menu';
	 pages[3,1] := ' F2   - File functions';
	 pages[4,1] := ' F3   - Edit functions';
	 pages[5,1] := ' F4   - Image information';

	 pages[7,1] := 'Arrows- Select Image';
	 pages[8,1] := 'PgUp  - Previous page';
	 pages[9,1] := 'PgDwn - Next page';

	 pages[11,1]:= ' Esc  - Exit menu ';
	 pcount := 1;
      end;
   commonui.help(help);   
end;

procedure palHelp;
var
   help	: helpdata;
   i,c	: byte;
begin
   {clear the help so unused pages/lines don't appear corrupt}
   for i:=1 to 16 do
      for c:= 1 to 5 do
	 help.pages[i,c] := '';
   with help do
      begin
	 { help text for the image editor }
	 pages[1,1] := '  Palette Editor Key Reference';
	 pages[2,1] := ' F1   - This help menu';
	 pages[3,1] := ' F2   - Save Palette to file';
	 pages[4,1] := ' F3   - Load from file';

	 pages[6,1] := 'Left and Right - Selects colour';
	 pages[7,1] := 'Up and Down    - Selects channel';

	 pages[10,1]:= ' <    - decrease value';
	 pages[11,1]:= ' >    - increase value';

	 pages[13,1]:= ' Esc  - Quit menu';
	 pcount := 1;
      end;
   commonui.help(help);   
end;

end.
