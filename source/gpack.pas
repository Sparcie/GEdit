{ packer/compression unit for creating packed graphics files
  this is to replace the old packer program that does not support compression
  it is written in a unit so the the EGA converter and CGA converter can use
  it for compression.}

{A Danson 2014}

unit gpack;

interface

procedure newFile(pf : string; sc,sx,sy:byte);
procedure spriteData(data : char);
function closeFile:integer; {returns the number of compressed sprites}

var
   monoCount : integer;

implementation

uses buffer;

var
   sprite      : array[0..4096] of char; {buffer for the current sprite}
   dataCount   : integer; {amount of data gathered for current sprite}
   sizeX,sizeY : integer; {the size of all the sprites}
   RLEcount    : integer; {the number of RLE sprites}
   w	       : writer; {the buffer writer for writing the file}
   monoColour  : byte;   { the colour used in a sprite that is determined to be monochrome }

function closeFile:integer;
begin
   w.flush;
   w.close;
   closeFile:=RLEcount;
end;

procedure newFile(pf:string; sc,sx,sy:byte);
begin
   w.open(pf);
   sizeX := sx;
   sizeY := sy;
   w.writeChar(chr(sc));
   w.writeChar(chr(sx));
   w.writeChar(chr(sy));
   dataCount := 0;
   RLEcount := 0;
   monoCount := 0;
end;

function colourCount:integer;
var
   cols	 : array[0..17] of byte; {max of 18}
   count : integer;
   i,c	 : integer;
   found : boolean;
begin
   count:=1;
   cols[0] := 0; {colour 0 is always counted}
   for i:= 0 to dataCount-1 do
   begin
      found := false;
      if ord(sprite[i]) > 0 then monoColour := ord(sprite[i]); {record the mono colour if needed }
      for c:= 0 to count-1 do
	 if cols[c] = ord(sprite[i]) then found := true;
      if not(found) then
      begin
	 cols[count] := ord(sprite[i]);
	 inc(count);
      end;
      if count=18 then
      begin
	 colourCount := 18;
	 exit;
      end;
   end;
   colourCount := count;
end;

function RLESize:integer;
var
   data	 : char;
   count : byte;
   size	 : integer;
   i	 : integer;
begin
   data:= chr($FF);
   count := 0;
   size:=1; {include the identifying byte $FF}
   for i:=0 to dataCount-1 do
   begin
      if ((data = sprite[i]) and not(count=$FF)) then
      begin
	 inc(count);
      end
      else
      begin
	 if (count>0) then size := size + 2;
	 data := sprite[i];
	 count:= 1;
      end;
   end;
   if count>0 then size:=size + 2;
   RLESize := size;
end;

procedure writeRaw;
var
   i : integer;
begin
   for i:=0 to dataCount-1 do
      w.writeChar(sprite[i]);
end;

procedure writeMono(col	: byte);
var			
   data	: byte;
   bit	: byte;
   x,y	: byte;
begin
   inc(monoCount);
   { write the data out in a monochrome bit format (very compact!)}
   w.writeChar(chr($FE));
   w.writeChar(chr(col));
   data := 0; {initial state }
   bit := $80; {first bit in a byte (graphically)}
   for y:= 0 to sizey-1 do
   begin
      {set up write data}
      for x:= 0 to sizex-1 do
      begin
	 if ord(sprite[x + (y*sizex)]) = col then data := data or bit; {add a bit if there is some colour}
	 bit := bit shr 1;
	 if bit=0 then { we've finished a byte }
	 begin
	    w.writeChar(chr(data));
	    data :=0;
	    bit := $80;
	 end;
      end;
   end;
   { if the last 'write' didn't fill a byte and write it - write the remaining bits.}
   if not(bit = $80) then
   begin
      w.writeChar(chr(data));
   end;
end;

procedure writeRLE;
var
   data	 : char;
   count : byte;
   i	 : integer;
begin
   data:= chr($FF);
   count := 0;
   w.writeChar(chr($FF));
   for i:=0 to dataCount-1 do
   begin
      if ((data = sprite[i]) and not(count=$FF)) then
      begin
	 inc(count);
      end
      else
      begin
	 if (count>0) then
	 begin
	    w.writeChar(data);
	    w.writeChar(chr(count));
	 end;
	 data := sprite[i];
	 count:= 1;
      end;
   end;
   if (count>0) then
   begin
      w.writeChar(data);
      w.writeChar(chr(count));
   end;
   inc(RLEcount);
end;

procedure writeSprite;
begin
   {determine which encoding we should use - prefer the smallest possible.}
   if colourCount = 2 then
      writeMono(monoColour) {monochrome if there is only 2 colours (black and another)}
   else if RLESize < (sizeX*sizeY) then
      writeRLE    { RLE encoding - if the encoding is smaller than the raw sprite}
   else
      writeRaw;   { the raw sprite as a fallback }
   dataCount:=0;
end;

procedure spriteData(data : char);
begin
   sprite[dataCount] := data;
   inc(dataCount);
   if (dataCount = (sizeX*sizeY)) then writeSprite;
end;

end.
