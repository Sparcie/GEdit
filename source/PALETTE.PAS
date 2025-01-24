unit palette;

interface

type
  paltype = array [0..255,0..2] of byte;

procedure SetColor(number, r,g,b: byte);
procedure GetColor(number: byte; var r,g,b: byte);
procedure SetPalette(pal: paltype);
procedure GetPalette(var pal: paltype);
function  StepPalette( pal: paltype): boolean;

procedure savePalette(p : paltype; palfile: string);
procedure loadPalette(var p :paltype; palfile : string);

implementation

uses buffer;

procedure savePalette(p : paltype; palfile: string);
var
   i ,c	: word; {loop counters}
   wr	: writer; {file writer with buffer}
begin
   wr.open(palfile);
   for i:= 0 to 255 do
      for c:= 0 to 2 do
	 wr.writeChar(chr(p[i,c]));
   wr.close;
end;

procedure loadPalette(var p :paltype; palfile : string);
var
   i,c	  : word; {loop counters}
   re	  : reader; { buffered file reader }
begin
   re.open(palfile);
   for i:=0 to 255 do
      for c:= 0 to 2 do
	 p[i,c] := ord(re.readchar);
   re.close;
end;

procedure SetColor(number, r,g,b: byte);
begin
   port[$3c8]:=number;
   port[$3c9]:=r;
   port[$3c9]:=g;
   port[$3c9]:=b;
end;

procedure GetColor(number: byte; var r,g,b: byte);
begin
   port[$3c7]:=number;
   r:=port[$3c9];
   g:=port[$3c9];
   b:=port[$3c9];
end;

procedure SetPalette(pal: paltype);
var i: integer;
begin
   for i:=0 to 255 do SetColor(i,pal[i,0],pal[i,1],pal[i,2]);
end;

procedure GetPalette(var pal: paltype);
var i: integer;
begin
   for i:=0 to 255 do GetColor(i,pal[i,0],pal[i,1],pal[i,2]);
end;

function StepPalette( pal: paltype): boolean;
var
   i : integer;
   b : boolean;
   p : paltype;   
begin
   getPalette(p);
   b:=false;
   for i:=0 to 255 do
   begin
      if p[i,0]<pal[i,0] then begin inc(p[i,0]); b:=true; end;
      if p[i,0]>pal[i,0] then begin dec(p[i,0]); b:=true; end;
      if p[i,1]<pal[i,1] then begin inc(p[i,1]); b:=true; end;
      if p[i,1]>pal[i,1] then begin dec(p[i,1]); b:=true; end;
      if p[i,2]<pal[i,2] then begin inc(p[i,2]); b:=true; end;
      if p[i,2]>pal[i,2] then begin dec(p[i,2]); b:=true; end;
   end;
   StepPalette:=b;
   setPalette(p);
end;

end.
