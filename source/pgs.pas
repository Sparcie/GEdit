unit pgs; {pack graphics system for lrs and hrs files packed using packer.pas
           by A Danson 2000}
{modified in 2010 to include collision detection between pictures}
{modified in 2013 to use the buffered reader.}
{modified in 2014 to read RLE files}
{modified in 2015 to be responsible for loading BGI drivers and initialising graph}
{modified in 2022 to move away from the BGI to my own graphics libraries}
{modified in 2025 to include editing functions for new graphics editor}

{$I defines.pas}

interface

uses buffer
{conditional defines for each graphics mode}
{$ifdef CGA}
,cga
{$ENDIF}
{$ifdef VGA}
,vga
{$endif}
{$ifdef EGA}
,ega
{$endif}
{$ifdef VESA}
,vesa
{$endif}
;

procedure loadpack(name: string);
{$ifdef CGA}
procedure initcga;
{$endif}
{$IFDEF EGA}
procedure initega;
{$endif}
{$ifdef VGA}
procedure initvga;
{$endif}
{$ifdef VESA}
procedure initvesa;
{$ENDIF}
procedure textscreen;
procedure draw(x,y:integer;puttype:word;image:integer);
procedure unloadpack;
function collision(x,y,f,x2,y2,f2 :integer ):boolean;
function spriteCount:integer;
procedure spriteSize(var sx,sy : integer);

{functions added for the purposes of the graphic editor so we can add/remove sprites}
{inserts a new item after the indexed location.}
procedure insert( i: byte);
{removes an item at the specified index}
procedure remove( i: byte);
{replaces an image in the stored index with one at a screen location}
procedure replace(x,y:word; i:byte);
{creates a new empty loaded pack with a single image, specifying the size}
procedure newPack(sx,sy:word);

const
   mCGA	    = 0; { 320x200 4 colour}
   mEGA	    = 1; { 640x200 16 colour }
   mVGA	    = 2; { 320x200 256 colour }
   mVESA    = 3; { 640x400 256 colour }
   copyput  = 0;
   xorput   = 1;
   transput = 2; {not implemented yet}

implementation

type
   bounds   = record
		 maxx,minx : integer;
		 maxy,miny : integer;
	      end;	   
   boundptr = ^bounds;

var pic		 : array[1..200] of pointer;
   picsize	 : array[1..200] of word;
   boundbox	 : array[1..200] of boundptr;
   loaded,inited : boolean;
   graphicsmode	 : byte;
   number	 : integer;
   ssx,ssy	 : integer; {size of the sprites in pixels}
   
   
   {creates a new empty loaded pack with a single image, specifying the size}
   procedure newPack(sx,sy:word);
   begin
        if loaded then exit; {do not erase already loaded data!}
        if not(inited) then exit; { can't create a new pack if we're not in graphics mode }
        loaded := true;
        ssx := sx;
        ssy := sy;
        number := 0;
        insert(0); {insert a new empty image at the first position.}
   end;

{inserts a new item after the indexed location.}
   procedure insert( i: byte);
   var
       c : word;
       box : bounds;
       s : boolean;
   begin
       if not(loaded) then exit;
       {check if we have space to add a new image}
       if number = 200 then exit; {max is 200}
       {create room for the new entry if the index is not the last one}
       if (i<number) then
       begin
           for c:= number downto i+1 do
           begin
                pic[c+1] := pic[c];
                picsize[c+1] := picsize[c];
                boundbox[c+1] := boundbox[c];
           end;
       end;
       inc(number);
       
       inc(i); { the new image is the one after the index i }
       case graphicsMode of
        {$ifdef VGA}
           mVGA : begin
              vga.filledBox(0,0,ssx-1,ssy-1,0);
              picsize[i] := vga.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              vga.getimage(0,0,ssx-1,ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef CGA}
           mCGA : begin
              cga.filledBox(0,0,ssx-1,ssy-1,0);
              picsize[i] := cga.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              cga.getimage(0,0,ssx-1,ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef EGA}
           mEGA : begin
              ega.filledBox(0,0,ssx-1,ssy-1,0);
              picsize[i] := ega.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              ega.getimage(0,0,ssx-1,ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef VESA}
           mVESA : begin
              vesa.filledBox(0,0,ssx-1,ssy-1,0);
              picsize[i] := vesa.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              vesa.getimage(0,0,ssx-1,ssy-1,pic[i]);
           end;
        {$endif}

        end;
       
       {sort out bounding-box (not really needed for editing)}
       box.maxx:=ssx; box.minx:=0;
       box.maxy:=ssy; box.miny:=0;
       new(boundbox[i]);
       boundbox[i]^:=box;

   end;
   
{removes an item at the specified index}
   procedure remove( i: byte);
   var
       c : word;
   begin
       if not(loaded) then exit;
       {check that the index specified is valid}
       if (i>number) or (i<1) then exit;
       {dispose of the relevant data for the image to be deleted}
       dispose(boundbox[i]);
       freemem(pic[i],picsize[i]);
       {if it isn't the last image then we need to move the others along.}
       if (i < number) then
       begin
           for c:= i to number do
           begin
               pic[c] := pic[c+1];
               picsize[c] := picsize[c+1];
               boundbox[c] := boundbox[c+1];
           end;
       end;
       dec(number);
   end;
   
   {replaces an image in the stored index with one at a screen location}
   procedure replace(x,y:word; i:byte);
   begin
        if not(loaded) then exit;
        {check the index is valid}
        if (i<1) or (i>number) then exit;
        {dispose of the old image to be replaced. - don't worry about bound-boxes }
        freemem(pic[i],picsize[i]);
        case graphicsMode of
        {$ifdef VGA}
           mVGA : begin
              picsize[i] := vga.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              vga.getimage(x,y,x+ssx-1,y+ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef CGA}
           mCGA : begin
              picsize[i] := cga.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              cga.getimage(x,y,x+ssx-1,y+ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef EGA}
           mEGA : begin
              picsize[i] := ega.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              ega.getimage(x,y,x+ssx-1,y+ssy-1,pic[i]);
           end;
        {$endif}
        {$ifdef VESA}
           mVESA : begin
              picsize[i] := vesa.imagesize(ssx,ssy);
              getmem(pic[i], picsize[i]);
              vesa.getimage(x,y,x+ssx-1,y+ssy-1,pic[i]);
           end;
        {$endif}

        end;
   end;

   procedure spriteSize(var sx,sy : integer);
   begin
      if not(loaded) then exit;
      sx:= ssx;
      sy:= ssy;
   end;

   function spriteCount:integer;
   begin
      spriteCount :=0;
      if not(loaded) then exit;
      spriteCount:= number;
   end;

   function collision(x,y,f,x2,y2,f2 :integer ):boolean;
   var
      rx,ry :integer ;
   begin
      if not(loaded) then exit;
      collision:=true;
      x:= x-x2;
      y:= y-y2;
      with boundbox[f]^ do
      begin
	 rx:=x + maxx;
	 ry:=y + maxy;
      end;
      with boundbox[f2]^ do
      begin
	 if ((rx<minx) or (ry<miny)) then
	 begin
	    collision:=false;
	    exit;
	 end;
      end;
      with boundbox[f]^ do
      begin
	 rx:=x + minx;
	 ry:=y + miny;
      end;
      with boundbox[f2]^ do
      begin
	 if ((rx>maxx) or (ry>maxy)) then
	 begin
	    collision:=false;
	    exit;
	 end;
      end;
   end;

{$ifdef CGA}
procedure initcga;
begin
   cga.init;
   inited:=true;
   graphicsmode := mCGA;
end;
{$endif}

{$ifdef EGA}
procedure initega;
begin
   ega.init;
   inited:=true;
   graphicsmode := mEGA;
end;
{$endif}

{$ifdef VGA}
procedure initvga ;
begin
   vga.init;
   inited:=true;
   graphicsmode := mVGA;
end;
{$endif}

{$ifdef VESA}
procedure initvesa;
begin
   vesa.init;
   graphicsmode := mVESA;
   inited:=true;
end;
{$ENDIF}

procedure draw(x,y:integer; puttype:word;image:integer);
begin
   if not(loaded and (image <=number) and (image>0) ) then exit;
   case graphicsmode of
     {$ifdef CGA}
     mCGA : begin
	      case puttype of
		copyput	: cga.putImage(x,y,pic[image]);
		xorput	: cga.putImageXor(x,y,pic[image]);
	      end;
	   end;
     {$endif}
     {$ifdef EGA}
     mEGA : begin
	      case puttype of
		copyput	: ega.putImage(x,y,pic[image]);
		xorput	: ega.putImageXor(x,y,pic[image]);
	      end;
	   end;
     {$endif}
     {$ifdef VGA}
     mVGA : begin
	      case puttype of
		copyput	: vga.putImage(x,y,pic[image]);
		xorput	: vga.putImageXor(x,y,pic[image]);
	      end;
	   end;
     {$endif}
     {$ifdef VESA}
     mVESA : begin
	       case puttype of
		 copyput : vesa.putImage(x,y,pic[image]);
		 xorput	 : vesa.putImageXor(x,y,pic[image]);
	      end;
	   end;
     {$endif}
   end;
end;

procedure loadImageRLE(var r : reader; var box:bounds);
var
   i,c	 : integer;
   data	 : byte;
   count : byte;
begin
   data := ord(r.readchar);
   count := ord(r.readchar);   
   for c:= 0 to ssy-1 do
      for i:= 0 to ssx-1 do
      begin
	 if count=0 then
	 begin
	    data := ord(r.readchar);
	    count := ord(r.readchar);
	 end;
	 case graphicsmode of
	   {$ifdef CGA}
	   mCGA	: cga.putpixel(i,c,data);
	   {$endif}
	   {$ifdef EGA}
	   mEGA	: ega.putpixel(i,c,data);
	   {$endif}
	   {$ifdef VGA}
	   mVGA	: vga.putpixel(i,c,data);
	   {$endif}
	   {$ifdef VESA}
	   mVESA: vesa.putpixel(i,c,data);
	   {$endif}
	 end;
	 if data>0 then
	 begin
	    if box.maxx<i then box.maxx:=i+1;
	    if box.minx>i then box.minx:=i-1;
	    if box.maxy<c then box.maxy:=c+1;
	    if box.miny>c then box.miny:=c-1;
	 end;
	 dec(count);
      end;
end;

procedure loadImageRaw(var r : reader; var box: bounds);
var
   i,c : integer;
   a   : char;
begin
   {check for compression}
   a:= r.readChar;
   if (a=chr($FF)) then
   begin
      loadImageRLE(r,box);
      exit;
   end;
   {read the data raw}
   for c:= 0 to ssy-1 do
      for i:= 0 to ssx-1 do
      begin
	 if ((i>0) or (c>0)) then
	    a:= r.readChar;
	 case graphicsmode of
	   {$ifdef CGA}
	   mCGA	: cga.putpixel(i,c,ord(a));
	   {$endif}
	   {$ifdef EGA}
	   mEGA	: ega.putpixel(i,c,ord(a));
	   {$endif}
	   {$ifdef VGA}
	   mVGA : vga.putpixel(i,c,ord(a));
	   {$endif}
	   {$ifdef VESA}
	   mVESA : vesa.putpixel(i,c,ord(a));
	   {$endif}
	 end;
	 if ord(a)>0 then
	 begin
	    if box.maxx<i then box.maxx:=i+1;
	    if box.minx>i then box.minx:=i-1;
	    if box.maxy<c then box.maxy:=c+1;
	    if box.miny>c then box.miny:=c-1;
	 end;
      end;   
end;

procedure drawProgressBar(current, total : integer);
var
   percent : real;
begin
   percent := (current / total) * 320;
   case graphicsmode of
     {$ifdef CGA}
     mCGA  : begin
		cga.filledBox(0,180, trunc(percent), 185, 1);
		cga.copySegment(0,179,319,6, false);
	    end;
     {$endif}
     {$ifdef EGA}
     mEGA  : begin
		ega.filledBox(0,180, trunc(percent), 185, 1);
	    end;
     {$endif}
     {$ifdef VGA}
     mVGA  : begin
		vga.filledBox(0,180, trunc(percent), 185, 9);
		vga.copySegment(0,179,319,6, false);
	    end;
     {$endif}
     {$ifdef VESA}
     mVESA : begin
		vesa.filledBox(0,370, trunc(percent * 2), 380, 246);
	     end;
     {$endif}
   end;
end;
					 
procedure loadpack(name:string);
       var imf			  : reader;
	  a			  : char;
	  b,c,d,e,xsize,ysize,num : integer;
	  box			  : bounds;
begin
   if inited then
   begin
      imf.open(name);
      a:= imf.readChar;
      number:=ord(a);
      a:= imf.readChar;
      ssx:=ord(a);
      a:= imf.readChar;
      ssy:=ord(a);
      num:=1;
      while num<=number do
      begin
	 box.maxx:=0; box.minx:=xsize;
	 box.maxy:=0; box.miny:=ysize;
	 loadImageRaw(imf,box);
	 new(boundbox[num]);
	 boundbox[num]^:=box;
	 case graphicsmode of
	   {$ifdef CGA}
	   mCGA : begin
		    picsize[num] := cga.imagesize(ssx,ssy);
		    getmem(pic[num],picsize[num]);
		    cga.getimage(0,0,ssx-1,ssy-1,pic[num]);
		 end;
	   {$endif}
	   {$ifdef EGA}
	   mEGA : begin
		    picsize[num] := ega.imagesize(ssx,ssy);
		    getmem(pic[num],picsize[num]);
		    ega.getimage(0,0,ssx-1,ssy-1,pic[num]);
		 end;
	   {$endif}
	   {$ifdef VGA}
	   mVGA : begin
		    picsize[num] := vga.imagesize(ssx,ssy);
		    getmem(pic[num],picsize[num]);
		    vga.getimage(0,0,ssx-1,ssy-1,pic[num]);
		 end;
	   {$endif}
	   {$ifdef VESA}
	   mVESA : begin
		    picsize[num] := vesa.imagesize(ssx,ssy);
		    getmem(pic[num],picsize[num]);
		    vesa.getimage(0,0,ssx-1,ssy-1,pic[num]);
		 end;
	   {$endif}
	 end;
	 drawProgressBar(num,number);
	 num:=num+1;
      end;
      imf.close;
      loaded:=true;
   end;
end;

procedure unloadpack;
var num:integer;
begin
   if not(loaded) then exit;
   num:=1;
   while num<=number do
   begin
      dispose(boundbox[num]);
      freemem(pic[num],picsize[num]);
      num:=num+1;
   end;
   loaded:=false;
end;

procedure textscreen;
begin
   if not(inited) then exit;
   case graphicsmode of
     {$ifdef CGA}
     mCGA : cga.shutdown;
     {$endif}
     {$ifdef EGA}
     mEGA : ega.shutdown;
     {$endif}
     {$ifdef VGA}
     mVGA : vga.shutdown;
     {$endif}
     {$ifdef VESA}
     mVESA: vesa.shutdown;
     {$endif}
   end;
end;

begin
   loaded:=false;
   inited:=false;
end.
