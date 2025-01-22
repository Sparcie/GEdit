{ The package editor component of the Gedit program.
  This unit is mostly UI code to connect other units to edit the package files.

  Editing individual images is done with the imgedit unit - this works with images on the screen.

  The pgs unit will load a package file, stores the images, and has basic functions for modifying the package
  stored in memory.

  gpack is purely an output unit. It takes the sprite data and puts it into a package file. Compression is used
  (RLE) if it would make the stored size smaller.
  A Danson 2025
}

unit pgsedit;

interface

{start a new package file}
procedure newPackage(sizex, sizey : word);
{load a package file }
procedure loadPackage(pfile : string);
{edit the package - the ui }
procedure editPgs;
{file extension selector for package files }
function selectFileExtension:string;
				  
implementation

uses bfont, vga, commonui, keybrd, imgedit, pgs, gpack;

var
   packageFile : string; {name of the current package file }
   sx,sy       : integer; {image size - each one will occupy this space plus some padding so there can be a border}
   page	       : byte; { the current display page}
   pos	       : word; { the position of the edit cursor on the current page}
   

{some simple functions to figure out where on screen an image at position i in this page will be displayed}
   
function columnsPerPage:word;
begin
   columnsPerPage := 320 div (sx+5);
end;

function rowsPerPage:word;
begin
   rowsPerPage:= 200 div (sy+5);
end;

procedure screenLocation(i : word; var lx, ly : word );
begin
   lx := ((i mod columnsPerPage) * (sx + 5)) + 1;
   ly := ((i div columnsPerPage) * (sy + 5)) + 1;
end;

function imagesPerPage:word;
var
   pageStart : word;
   ipp	     : word; {temp storage for the function}
begin
   ipp := (columnsPerPage * rowsPerPage) -1;
   imagesPerPage := ipp;
   pageStart := (ipp * page); {always start at 1 otherwise }
   if (spriteCount - pageStart) < ipp then
      ImagesPerPage := spriteCount-pageStart -1;
end;

{simple display functions }

{draw an image i at location p for the current page - highlights the current cursor position }
procedure drawImg(i, p : word);
var
   lx,ly : word; {location on screen for the image}
begin
   screenLocation(p, lx, ly);
   if (p=pos) then
      filledbox(lx-1,ly-1,lx+sx,ly+sy,10)
   else
      filledbox(lx-1,ly-1,lx+sx,ly+sy,8);
   draw(lx,ly,copyput,i);
end;

{ draws the entire page of images including cursor highlight }
procedure drawPage;
var
   pageStart : word; {first image for this page}
   i	     : word; {loop counter}
begin
   pageStart := (imagesPerPage * page) + 1; {always start at 1 otherwise }
   for i:= 0 to imagesPerPage do
      drawImg(pageStart+i, i); 
end;

{ updated the display for the cursor to a new location }
procedure updateCursor(newPos : word);
var
   oldPos    : word; {old cursor location }
   pageStart : word; {first image for this page }
begin
   pageStart := (imagesPerPage * page) + 1; {always start at 1 otherwise }
   oldPos := pos;
   pos:= newPos;
   drawImg(pageStart+oldPos, oldPos);
   drawImg(pageStart+newPos, newPos);
end;

{start a new package file}
procedure newPackage(sizex, sizey : word);
begin
   sx:= sizex;
   sy:= sizey;
   pgs.newPack(sx,sy);
   packageFile := '';
   pos:=0;
   page:=0;
end;

{load a package file }
procedure loadPackage(pfile : string);
begin
   packageFile := pfile;
   pgs.loadpack(pfile);
   pgs.spriteSize(sx,sy);
   pos:=0;
   page:=0;
end;

{export the current package using gpack to a file - assumes the file name is already selected }
procedure savePackage;
var
   cx,cy : word; {current location in current image}
   i	 : word; {current image we're working on }
   comp	 : word; {count of images that were compressed using RLE }
   s	 : string;
   c	 : char;
begin
   gpack.newFile(packageFile, pgs.spriteCount, sx, sy);

   {now go through each image - draw it to the screen, and send the data to gpack}
   for i:= 1 to pgs.spriteCount do
   begin
      pgs.draw(0,0,copyput,i);
      for cy := 0 to sy-1 do
	 for cx := 0 to sx-1 do
	    gpack.spriteData(chr(getPixel(cx,cy)));      
   end;

   {ok now the data is sent to gpack we can close the file...}
   comp := gpack.closeFile;

   {output the number of compressed images - out of interest!}
   str(comp,s);
   s:= 'Compressed : '+s;
   filledBox(100,35,220,65,8);
   textxy(110,40,4,9,s);
   str(pgs.spriteCount, s);
   s:= 'Total : '+s;
   textxy(110,50,4,9,s);

   {wait for a keypress}
   while not(keypressed) do;
   {read the key input so it doesn't register in editor elsewhere}
   c:= readkey;
   if c = chr(0) then c:= readkey;
end;

function selectFileExtension:string;
var
   m : menudata;
   r : byte;
begin
   m.title := 'Select file extension';
   m.items[1] := 'pgs';
   m.items[2] := 'lrp';
   m.items[3] := 'hrp';
   m.items[4] := 'ega';
   m.items[5] := 'cga';
   m.count := 5;
   r:= menu(m);
   selectFileExtension := 'pgs';
   case r of
     2 : selectFileExtension := 'lrp';
     3 : selectFileExtension := 'hrp';
     4 : selectFileExtension := 'ega';
     5 : selectFileExtension := 'cga';
   end;
end;

procedure fileMenu;
var
   m   : menudata;
   r   : byte;
   ext : string[12];
begin
   m.title := 'File actions';
   m.items[1] := 'Save';
   m.items[2] := 'Save As';
   m.items[3] := 'Load';
   m.count := 3;
   r:= menu(m);
   case r of
     1 : if packageFile <> '' then
	    begin
	       savePackage;
	       cls;
	       drawPage;
	    end
         else
	    begin
	       ext := selectFileExtension;
	       packageFile := fileSelector(ext, true);
	       if packageFile <> '' then savePackage;
	       cls;
	       drawPage;
	    end;
     2 : begin
	    ext := selectFileExtension;
	    packageFile := fileSelector(ext,true);
	    if packageFile <> '' then savePackage;
	    cls;
	    drawPage;
	 end;
     3 : begin
	    ext := selectFileExtension;
	    ext := fileSelector(ext,false);
	    if ext <> '' then loadPackage(ext);
	    cls;
	    drawPage;
	 end;
   end;
end;

procedure actionMenu;
var
   m : menudata;
   r : byte;
begin

end;

procedure extendedKeys;
var
   c : char;
begin
   c:= readkey;
   case c of
     chr(72) : 	if pos>=columnsPerPage then updateCursor(pos - columnsPerPage);
     chr(80) : if pos< (int(imagesPerPage)-columnsPerPage)+1 then updateCursor(pos + columnsPerPage);
     chr(75) : if pos>0 then updateCursor(pos-1);
     chr(77) : if pos<(imagesPerPage) then updateCursor(pos+1);
     chr(60) : fileMenu;
     chr(61) : actionMenu;
   end;
end;

{edit the package - the ui }
procedure editPgs;
var
   done	: boolean;
   c	: char;
   r	: byte;
   ext	: string[12];
begin
   page:= 0;
   pos:=0;
   done := false;

   {initialise the display}
   cls;
   drawPage;

   while not(done) do
   begin
      while not(keypressed) do;

      c:= readkey;
      case c of
	chr(27)	: begin
	   r := exitMenu;
	   if r = 1 then
	   begin {save and exit}
	      done:=true;
	      if packageFile <> '' then
		 savePackage
	      else
	      begin
		 ext := selectFileExtension;
		 packageFile := fileSelector(ext, true);
		 if packageFile <> '' then savePackage else done:=false;
	      end;
	   end;
	   if r=2 then
	   begin {discard and exit}
	      unloadpack;
	      done:=true;
	   end;
	end;
	chr(0)	: extendedKeys;
      end;
   end; 

end;

begin
   packageFile := '';
   sx:= 10;
   sy:= 10;
   page := 0;
   pos:=0;
end.
