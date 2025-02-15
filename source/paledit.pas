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
var
   i	 : word; {counter for loops}
   cc	 : byte; { the current colour we are modifying }
   ch	 : byte; { the channel we are modifying R G B }
   m	 : byte; { menu result }
   r,g,b : byte; { colour channels for the current colour }
   c	 : char; { current keyboard input }
   s	 : string; {string for working with text to display}
   done	 : boolean; {are we finished with the editor }
   p	 : paltype; { data storage for palette when we save it }
begin
   cls;
   {display the range of colours at the top of the screen }
   for i:= 0 to 255 do
      line(i,0,i,15,i);

   cc := 0; { set initial state }
   ch := 0;
   done := false;

   while not(done) do
   begin
      {get initial colour channel values }
      getColor(cc, r,g,b);

      {display the current state }
      line(cc,16,cc,25,9); {colour cursor }

      { display the current colour }
      filledbox(10,30,20,40,cc); 
      str(cc,s);
      s := 'Colour :'+s;
      textxy(30,30,4,9,s);

      {display the channel values and channel cursor}
      line(0,45 + (ch*10),10, 45 + (ch*10),9);
      str(r,s);
      s:= 'Red :'+s;
      textxy(20,40,4,9,s);
      str(g,s);
      s:= 'Green :'+s;
      textxy(20,50,4,9,s);
      str(b,s);
      s:= 'Blue :'+s;
      textxy(20,60,4,9,s);

      { wait for a keypress }
      while not(keypressed) do;

      {clear the current state }
      line(cc,16,cc,25,0); {colour cursor }

      { display the current colour }
      str(cc,s);
      s := 'Colour :'+s;
      textxy(30,30,4,0,s);

      {display the channel values and channel cursor}
      line(0,45 + (ch*10),10, 45 + (ch*10),0);
      str(r,s);
      s:= 'Red :'+s;
      textxy(20,40,4,0,s);
      str(g,s);
      s:= 'Green :'+s;
      textxy(20,50,4,0,s);
      str(b,s);
      s:= 'Blue :'+s;
      textxy(20,60,4,0,s);

      { ok now read a key and update any values }
      c:= readkey;
      
      case c of
	',','<'	: begin
	   case ch of
	     0 : begin
		    dec(r);
		    if r>63 then r:= 63;
		 end;
	     1 : begin
		    dec(g);
		    if g>63 then g:=63;
		 end;
	     2 : begin
		    dec(b);
		    if b>63 then b:=63;
		 end;
	   end;
	   setColor(cc,r,g,b);
	end;
	'.','>'	: begin
	   case ch of
	     0	: begin
		    inc(r);
		    if r>63 then r:= 0;
		 end;
	     1	: begin
		    inc(g);
		    if g>63 then g:=0;
		 end;
	     2	: begin
		    inc(b);
		    if b>63 then b:=0;
		 end;
	   end;
	   setColor(cc,r,g,b);
	end;
	chr(27)	: begin
	   {quiting the editor }
	   m := exitMenu;
	   case m of
	     1 : begin
		    s := fileSelector('pal',true);
		    if not(s = '') then
		    begin
		       getPalette(p);
		       savePalette(p,s);
		       done:=true;
		    end;
		 end;
	     2 : done := true;
	   end;
	end;
	chr(0) : begin
	   { extended keys! }
	   c := readkey;

	   case c of
	     chr(60) : begin
		s := fileSelector('pal',true);
		if not(s = '') then
		begin
		   getPalette(p);
		   savePalette(p,s);
		end;	       
	     end;
	     chr(61) : loadCustomPal;
	     chr(72) : begin
		dec(ch);
		if ch>2 then ch:=2;
	     end;
	     chr(80) : begin
		inc(ch);
		if ch=3 then ch:=0;
	     end;
	     chr(75) : dec(cc);
	     chr(77) : inc(cc);
	   end;
	end;
      end;
   end;
end;

end.
