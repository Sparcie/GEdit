{ The image editor component of the gedit program.
   It does not interact directly with pgs or gpack, rather it just edits
   an image that is currently on screen

   There will be an option to import both gfx and vga (old qbasic files)
   Also export the gfx files.

   The VGA back buffer will be a scratch space to store working data or to
   save the working screen while UI elements are active.
   A Danson 2025 }

unit imgedit;

interface


implementation

uses commonui, vga, bfont, buffer, keybrd;

var
   sx, sy   : word; {the size of the image we are currently editing }
   cc	    : byte; {the current colour we're drawing with - an index into the drawing palette array }
   pal	    : array[0..9] of byte; { the drawing palette - a set of colours you can choose from to aid in image editing. }
   pc	    : byte; { the colour of the current pixel behind the cursor }
   x,y	    : word; { the cursor location }
   undo	    : array[0..9] of pointer; {pointer to undo image}
   undoSize : array[0..9] of word;    {size of the undo image - 0 means no image.}
   undoPos  : integer; {the current undo image}
   
{ updates the current palette display on screen }
procedure drawPal;
var
   i : byte;
begin
   {clear the area where it is drawn}
   filledbox(300,0,319,110,0);

   {draw the colours }
   for i:= 0 to 9 do
   begin
      filledbox(309, i*10, 319, (i+1)*10, pal[i]);
   end;

   {draw a line to indicate which entry is currently in use}
   line(300, (cc*10) + 5, 308, (cc*10) + 5, 9);   
end;

{adds an image to the undo buffer}
procedure refreshUndo;
begin
   putpixel(x,y,pc);
   
   inc(undoPos); { move to next position }
   undoPos := undoPos mod 10; {make sure we don't exceed the array bounds}
   
   if undoSize[undoPos]>0 then freemem(undo[undoPos], undoSize[undoPos]); {free memory if needed}

   {get new undo img}
   undoSize[undoPos] := imageSize(sx,sy); 
   getmem(undo[undoPos], undoSize[undoPos]);
   getImage(0,0,sx-1,sy-1, undo[undoPos]);
end;

{replaces current image with last image in undo buffer}
procedure useUndo;
begin
   if undoSize[undoPos] = 0 then exit; {exit if there is no image}

   putimage(0,0,undo[undoPos]);

   { restore image size in case it changed the size  - stored in the image }
   sx := memw[seg(undo[undoPos]^) : ofs(undo[undoPos]^) ];
   sy := memw[seg(undo[undoPos]^) : ofs(undo[undoPos]^) + 2 ];

   {free the current image and mark the position as empty}
   freemem(undo[undoPos],undoSize[undoPos]);
   undoSize[undoPos] := 0;

   {move to previous image in undo buffer}
   dec(undoPos);
   if undoPos < 0 then undoPos:= 9;

   pc := getPixel(x,y);
end;

{copies an image from one location to another}
procedure copyImg(srcx, srcy, szx, szy, dx, dy : word);
var
   img	   : pointer;
   imgSize : word;
begin
   imgSize := imageSize(szx,szy);
   getmem(img, imgSize);
   getImage(srcx,srcy, szx-1, szy-1, img);
   putImage(dx, dy, img);
   freemem(img, imgsize);
end;
					       

procedure double;
var i,c,z,w,a : integer;
begin
   if ((sx>100) or (sy>100)) then exit;

   refreshUndo;

   {use the back buffer as scratch space}
   copyToBuffer; {copy the screen to the backbuffer}
   if not(setDrawMode(1)) then exit;
   
   putpixel(x,y,pc);
   for i:= 0 to sx-1 do
      for c:= 0 to sy-1 do
      begin
	 z:=(i*2)+100;
	 w:=(c*2);
	 a:= getpixel(i,c);
	 putpixel(z,w,a);
	 putpixel(z+1,w,a);
	 putpixel(z,w+1,a);
	 putpixel(z+1,w+1,a);
      end;
   sx:=sx*2;
   sy:=sy*2;  

   {copy the doubled image to working area}
   copyImg(100,0,sx,sy,0,0);

   {switch back to the screen an update the image}
   if setDrawMode(2) then copySegment(0,0,sx,sy,false);

   {update the stored colour for the cursor}
   pc:= getpixel(x,y);
end; { double }

procedure mirror;
var i,c,p : byte;
begin
   refreshUndo;

   {use the back buffer as scratch space}
   copyToBuffer; {copy the screen to the backbuffer}
   if not(setDrawMode(1)) then exit;

   copyImg(0,0,sx,sy, sx + 10,0);
   
   putpixel(x,y,pc);
   for i:= 0 to sx-1 do
      for c:= 0 to sy-1 do
	 begin
	    p := getpixel((2*sx)+9 - i,c);
	    putpixel(i,c,p);
	 end;

   {set the draw mode and update the image}
   if setDrawMode(2) then copySegment(0,0,sx,sy, false);
   
   pc:= getpixel(x,y);
end;

procedure rotate;
var
   i,c,p : byte;
   
begin
   refreshUndo;

   {use the back buffer as scratch space}
   copyToBuffer; {copy the screen to the backbuffer}
   if not(setDrawMode(1)) then exit;

   copyImg(0,0,sx,sy, sx + 10,0);

   putpixel(x,y,pc);
   for i:= 0 to sx-1 do
      for c:= 0 to sy-1 do
	 begin
	    p := getpixel((2*sx)+9 - c,i);
	    putpixel(i,c,p);
	 end;

   {set the draw mode and update the image}
   if setDrawMode(2) then copySegment(0,0,sx,sy, false);
   
   pc:= getpixel(x,y);
end;

{import a 10x10 image from my previous QBasic work}
procedure importVGA;
var
   f	     : string;
   inf	     : reader;
   i,c	     : byte;
   s	     : string;
   col, code : integer;
begin
   refreshUndo;
   f := fileSelector('vga', false);
   inf.open(f);
   for c:= 0 to 9 do
      for i:= 0 to 9 do
      begin
	 s:=inf.readln;
	 val(s,col,code);
	 putpixel(i,c,col);
      end;   
   inf.close;
   sx:=10;
   sy:=10;
   pc := getpixel(x,y);   
end;

{import a gfx file - these are the files generated by the old gedit}
procedure importGFX;
var
   f	 : string;
   b	 : reader;
   c	 : char;
   cx,cy : byte;
begin
   refreshUndo;
   f := fileSelector('gfx',false);
   b.open(f);
   sx := ord(b.readchar);
   sy := ord(b.readchar);
   for cy := 0 to sy-1 do
      for cx := 0 to sx-1 do
	 putpixel(cx,cy,ord(b.readchar));
   b.close;
   pc := getpixel(x,y);   
end;

{import a file - either gfx or vga formats}
procedure import;
var
   m : menudata;
   s : byte;
begin
   m.title := 'Load Image file type';
   m.items[1] := 'GFX files';
   m.items[2] := 'VGA files (QBasic)';
   m.count := 2;
   s:= menu(m);

   {act on selection}
   if s=1 then importGFX;
   if s=2 then importVGA;
   {otherwise do nothing}
end;

procedure exportGFX;
var
   f	 : string;
   w	 : writer;
   cx,cy : word;
begin
   f:= fileSelector('gfx',true);
   putpixel(x,y,pc);
   w.open(f);
   w.writeChar(chr(sx));
   w.writeChar(chr(sy));
   for cy:= 0 to sy-1 do
      for cx := 0 to sx-1 do
	 w.writechar(chr(getpixel(cx,cy)));
   w.close;
end;

procedure recursiveFill(cx,cy : integer; dc, cr: byte);
begin
   {check we are still in bounds}
   if cx<0 then exit;
   if cy<0 then exit;
   if cx>sx-1 then exit;
   if cy>sy-1 then exit;
   {check the current pixel is the colour we are replacing}
   if getpixel(cx,cy) <> cr then exit;
   {ok we have done the base checks we can replace the current pixel}
   putpixel(cx,cy,dc);

   {recursively check neighboring pixels}
   recursiveFill(cx+1,cy,dc,cr);
   recursiveFill(cx-1,cy,dc,cr);
   recursiveFill(cx,cy-1,dc,cr);
   recursiveFill(cx,cy+1,dc,cr);
end;

procedure randomFill;
var
   col	 : array[0..9] of byte;
   count : word;
   cx,cy : word;
   done	 : boolean;
   c	 : char;
begin
   randomize;
   {prepare by refreshing undo }
   refreshUndo;
   {this section will pick colours from the palette to use for the randomiser}
   copyToBuffer;
   textxy(210,105,4,9,'Select Colours');
   textxy(210,113,4,9,'for random fill');
   done := false;
   count := 0;
   while not(done) do
   begin
      drawPal;
      while not(keypressed) do;
      c:= readkey;
      if ((c='p') or (c='P')) then
      begin
	 copyToScreen;
	 pal[cc] := pickColor;
	 for cx := 0 to count do
	    filledbox(290, count*10, 300, (count+1)*10, col[count]);
      end;
      if c= chr(27) then done:= true; {escape pressed - finished picking colours}
      if c = chr(13) then {enter pressed - pick a colour}
      begin
	 col[count] := pal[cc];
	 if (count=9) then done:=true;
	 filledbox(290, count*10, 300, (count+1)*10, col[count]);
	 inc(count);
      end;
      {check for arrow keys}
      if c=chr(0) then
      begin
	 c:= readkey;
	 if ((c=chr(72)) and (cc>0)) then dec(cc);
	 if ((c=chr(80)) and (cc<9)) then inc(cc);
      end;      
   end;

   copyToScreen;
   {interactive part done - lets generate the random noise}
   for cy:= 0 to sy-1 do
      for cx := 0 to sx-1 do
	 putpixel(cx,cy,col[random(count)]);
   pc:= getpixel(x,y);
end;

begin
   for cc := 0 to 9 do
      pal[cc] := cc;
   cc := 0;
   for undoPos := 0 to 9 do
      undoSize[undoPos] := 0;
   undoPos := 0;
end.
