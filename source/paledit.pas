{ Palette editor/loader for the gedit program
   This allows you to use a different colour palette to the standard VGA Palette
   You will also be able to load a couple of standard colour sets such as
     The standard VGA palette (to reset to the initial state)
     and color sets for the various CGA colour palettes so you can work with
       CGA packages and see what they should look like on a CGA.

   EGA colours are a part of the standard VGA colour palette, so using that
   will show EGA packages/images correctly.
  A Danson 2025 }

unit paledit;

interface

uses palette;

{ a menu to choose and load one of the standard palettes
  contains VGA and CGA choices }
procedure standardPal;

{ loads a palette from disk }
procedure loadCustomPal;

{ editor that will modify the current palette
   has options to save/load and modify the colours }
procedure editPal;

implementation

uses commonui, vga, bfont, keybrd, vgapal;

{ a menu to choose and load one of the standard palettes
  contains VGA and CGA choices }
procedure standardPal;
var
   m : menudata;
   r : byte;
begin
   m.title := 'Select a colour palette';
   m.items[1] := 'EGA/VGA';
   m.items[2] := 'CGA int grn red ylw';
   m.items[3] := 'CGA int cyn mga wht';
   m.items[4] := 'CGA grn red brwn';
   m.items[5] := 'CGA cyn mga gry';
   m.count := 5;

   r := menu(m);

   case r of
     1 : setPalette(stdpal);
     2 : begin
	    setPalette(stdpal);
	    setColor(1, stdpal[10 ,0], stdpal[10,1], stdpal[10,2]);
	    setColor(2, stdpal[12 ,0], stdpal[12 ,1], stdpal[12 ,2]);
	    setColor(3, stdpal[14 ,0], stdpal[14 ,1], stdpal[14 ,2]);
	 end;
     3 : begin
	    setPalette(stdpal);
	    setColor(1, stdpal[11 ,0], stdpal[11,1], stdpal[11,2]);
	    setColor(2, stdpal[13 ,0], stdpal[13 ,1], stdpal[13 ,2]);
	    setColor(3, stdpal[15 ,0], stdpal[15 ,1], stdpal[15 ,2]);
	 end;
     4 : begin
	    setPalette(stdpal);
	    setColor(1, stdpal[2 ,0], stdpal[2,1], stdpal[2,2]);
	    setColor(2, stdpal[4 ,0], stdpal[4 ,1], stdpal[4 ,2]);
	    setColor(3, stdpal[6 ,0], stdpal[6 ,1], stdpal[6 ,2]);	    
	 end;
     5 : begin
	    setPalette(stdpal);
	    setColor(1, stdpal[3 ,0], stdpal[3,1], stdpal[3,2]);
	    setColor(2, stdpal[5 ,0], stdpal[5 ,1], stdpal[5 ,2]);
	    setColor(3, stdpal[7 ,0], stdpal[7 ,1], stdpal[7 ,2]);
	 end;
   end;

end;

{ loads a palette from disk }
procedure loadCustomPal;
var
   palFile : string;
   p	   : paltype;
begin
   palFile := fileSelector('pal', false);
   if palFile = '' then exit; {no file selection was made!}
   loadPalette(p,palfile);
   setPalette(p);
end;

{ editor that will modify the current palette
   has options to save/load and modify the colours }
procedure editPal;
begin

end;

end.
