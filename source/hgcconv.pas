{vga packed graphics to Hercules packed graphics converter}
{ created for adding Hercules support to bobsfury.
  this code is basically meant to generate a scaffold from CGA
  data that would be close. In much the same way many people
  support hercules by using CGA graphics data.}
{A Danson 2026}
{$G+ 286 instructions}
{$N+ co-processor enabled}
{$E+ co-processor emulation if needed} 

program hgcconv;

uses pgs, vga, gpack;

var
   sx,sy	: integer;
   num, current	: integer;
   s		: string;


procedure convertSprite(sp:integer);
var
   i,c	    : integer;
   pix	    : byte;
   nsx, nsy : integer;
   pa,pb    : byte;
begin
   draw(0,0,copyput,sp);

   nsx:= sx * 2;
   nsy:= sy + (sy shr 1);
   
   for c:= 0 to sy-1 do
      for i:= 0 to sx-1 do
      begin
	 pix:=getPixel(i,c);
	 pa := 0;
	 pb := 0;

	 if (pix and 1) > 0 then pb := 7;
	 if (pix and 2) > 0 then pa := 7;
	 if (c mod 2) = 0 then
	 begin
	    putPixel((i*2), (c+(c shr 1))+(sy+5), pa);
	    putPixel((i*2) + 1, (c+(c shr 1))+(sy+5), pb);
	 end
	 else
	 begin
	    putPixel((i*2), (c+(c shr 1))+(sy+5), pb);
	    putPixel((i*2) + 1, (c+(c shr 1))+(sy+5), pa);
	    putPixel((i*2), (c+(c shr 1))+(sy+5)+1, pa);
	    putPixel((i*2) + 1, (c+(c shr 1))+(sy+5)+1, pb);
	 end;
      end;

   for c:= 0 to nsy-1 do
      for i:= 0 to nsx-1 do
	 begin
	    pix := getPixel(i,c + (sy+5));
	    spriteData(chr(pix));
	 end;   
end;

begin
   {check the params and make sure we have some}
   if (paramCount < 2) then
   begin
      writeln(' Vga to Hercules packed graphics converter');
      writeln(' A J Danson 2026');
      writeln('usage:egaconv infile outfile');
      halt(0);
   end;
   initVGA;
   loadpack(paramstr(1));
   num := spriteCount;
   spriteSize(sx,sy);
   newfile(paramstr(2),num, sx*2, sy + (sy shr 1));
   {start converting graphics!}
   for current := 1 to num do
   begin
      convertSprite(current);
   end;
   {done!}
   unloadpack;
   textscreen;
   str(num,s);
   writeln('Sprites - '+s);
   num := closeFile;
   str(num,s);
   writeln('Compressed - '+s+' sprites');
   str(monoCount,s);
   writeln('Monochrome - '+s+' sprites');
end.
