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
				  
implementation

uses bfont, vga, commonui, keybrd, imgedit, pgs, gpack;

var
   packageFile : string; {name of the current package file }
   sx,sy       : word; {image size - each one will occupy this space plus some padding so there can be a border}
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
begin
   pageStart := (imagesPerPage * page); {always start at 1 otherwise }
   imagesPerPage := columnsPerPage * rowsPerPage;
   if (spriteCount - pageStart) < imagesPerPage then
      ImagesPerPage := spriteCount-pageStart;
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
   pageStart : word; {first image for this page}
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
end;

{load a package file }
procedure loadPackage(pfile : string);
begin
   packageFile := pfile;
   pgs.loadpack(pfile);
   pgs.spriteSize(sx,sy);
end;

procedure fileMenu;
begin

end;

procedure actionMenu;
begin

end;

procedure extendedKeys;
var
   c : char;
begin
   c:= readkey;
   case c of
     chr(72) : 	if pos>columnsPerPage then updateCursor(pos - columnsPerPage);
     chr(80) : if pos<imagesPerPage-columnsPerPage then updateCursor(pos + columnsPerPage);
     chr(75) : if pos>1 then updateCursor(pos-1);
     chr(77) : if pos<imagesPerPage then updateCursor(pos+1);
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
begin
   page:= 0;
   pos:=0;

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
		 {------ insert save routine here -----}
	      done:=true;
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
