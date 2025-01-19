{ Common UI functions for the graphics editor
    This unit contains common user interface elements that are used in many places accross the graphics editor.
  A Danson 2025}
  
  
unit commonui;

interface

type
   menudata	= record
	     title : string[20];
	     items : array[1..15] of string[20];
	     count : word;
	  end;	   
   helpdata	= record
	     pages  : array[1..16, 1..5] of string[45];
	     pcount : byte;
	  end;

{writes all the files with extension ext onto the screen - fills all but the first two lines
 does not preserve screen state }
procedure listfiles(ext : string);
{string input function using graphics text
 does not preserve screen state }
function ginput(x,y:integer):string;

{these function use the VGA back buffer to preserve screen state}
{basic ui to select a colour}
function pickcolor:byte;
{basic ui to select a square size}
procedure pickSize(var sizex, sizey :word);
{ file selector dialog, you can specify the extention and whether we are writing to the file.}
function fileSelector( ext:string; wr:boolean):string;
{ simple menu function - you specify the menu, returns the index if a selection is made 0 for cancel }
function menu(m : menudata):byte;
{ help display function - allows user to scroll through text }
procedure help(h : helpdata);
		    
implementation

uses bfont, bsystem, vga, dos, keybrd;


{ simple menu function - you specify the menu, returns the index if a selection is made 0 for cancel }
function menu(m : menudata):byte;
var
   selection : integer;
   done	     : boolean;
   c	     : char;
   i	     : word;
begin
   copyToBuffer;
   with m do {just to make things a little shorter/easier}
   begin
      {draw the menu in it's initial state}
      {clear an area for the menu.}
      filledbox(70,0,250,199,0);
      line(70,0,70,199,7);
      line(250,0,250,199,7);
      textxy(80,25,4,9,title);
      {draw all the menu items}
      for i:= 1 to count do
	 textxy(80,35 + (i*10),4,7,items[i]);
      selection := 1;
      done := false;

      {menu loop}
      while not(done) do
      begin
	 {draw current selection}
	 textxy(80,35 + (selection*10),4,12,items[selection]);

	 {wait for a keypress}
	 while not(keypressed) do ;

	 {clear selection display in case we change seleciton}
	 textxy(80,35 + (selection*10),4,7,items[selection]);

	 {read a key and do what is needed}
	 c := readkey;

	 {escape key}
	 if c = chr(27) then
	 begin
	    selection := 0; {the escape state}
	    done:= true;
	 end;
	 {enter key}
	 if c = chr(13) then
	    done:= true; {return the current selection}

	 {check for arrow keys}
	 if c = chr(0) then
	 begin
	    c:= readkey;

	    if ((c = chr(72)) and (selection > 1)) then dec(selection);
	    if ((c = chr(80)) and (selection < count)) then inc(selection);	    
	 end;	 
      end;
   end;
   menu := selection;
   copyToScreen;
end;

{ help display function - allows user to scroll through text }
procedure help(h : helpdata);
var
   page	: byte;
   i	: byte;
   c	: char;
   new	: boolean;
   done	: boolean;
begin
   copyToBuffer;
   page := 1;
   new := true;
   with h do
      while not(done) do
      begin
	 {update the screen if we need to}
	 if new then
	 begin
	    cls;
	    line(0,0,319,0,7);
	    line(319,0,319,199,7);
	    line(319,199,0,199,7);
	    line(0,199,0,0,7);

	    for i:= 1 to 16 do
	       textxy(25,5 + (i*10),4,7, pages[i, page]);
	    new := false;
	 end;

	 {wait for a keypress}
	 while not(keypressed) do ;

	 {read the key and process it}
         c :=readkey;

	 if c = chr(27) then done:=true;
	 if c = chr(0) then
	 begin
	    c:= readkey;
	    if ((c=char(81)) and (page<pcount)) then begin page:=page+1;new:=true; end;
	    if ((c=char(73)) and (page>1)) then begin page:=page-1;new:=true; end;
	 end;
      end;
   copyToScreen;
end;

function fileSelector( ext:string; wr:boolean):string;
var
   pge   :byte;
   pattern:string[12];
   list   :array[0..200] of string[12];
   count  :byte;
   pos    :byte;
   maxPos :byte;
   DirInfo:SearchRec;
   x, y   :word;
   k      :char;
   done   :boolean;
begin
   copyToBuffer;
    {First make a list of all the files with the extension}
    {prepare variables}
    pattern := '*.'+ext;
    count := 0;
    if wr then {if we are writing a file we may need to input a new file name}
    begin
        {make an entry for a new file}
        list[0] := 'New File';
        count :=1;
    end;
    {now build the list}
    FindFirst(pattern, 0, DirInfo);
    while DosError = 0 do
    begin
       if count < 201 then
       begin
           list[count] := DirInfo.name;
           inc(count);
       end;
       FindNext(DirInfo);
    end;

    {check if there were no files found }
    fileSelector := '';
    if ((count=0) and not(wr)) then exit;
   
    {Ok now we can do a file selection dialog box with the info we have}
    
    pge := 0;
    cls;
    if wr then
       textxy(0,0,4,12,'Select a file to write')
    else
       textxy(0,0,4,9,'Select a file to read');
    
    x:=0; y:=16;
    pos:=0;
    {we can display at most 69 files per page at most}
    while ((pos<70) and (pos<count)) do
    begin
        textxy(x,y,4,7,list[pos]);
        inc(pos);
        x:= (pos mod 3) * 104;
        y:= ((pos div 3) * 8) + 16;
    end;
    maxPos := pos - 1;
    pos:=0;
    
    done := false;
    {ok now we should be able to have a basic menu!}
    while not(done) do
    begin
        {highlight current position}
        x:= (pos mod 3) * 104;
        y:= ((pos div 3) * 8) + 16;
        textxy(x,y,4,10,list[pos + (pge*69)]);
        
        while not(keypressed) do ; {wait for a keypress!}
        
        {hide current selection}
        x:= (pos mod 3) * 104;
        y:= ((pos div 3) * 8) + 16;
        textxy(x,y,4,7,list[pos + (pge*69)]);
        
        {read and process keys}
        k := readkey;
        if k = chr(13) then
        begin {enter key pressed - do actions related to that!}
           pattern := list[pos + (pge*69)];
           if ((wr) and (pos=0) and (pge=0)) then
           begin
               filledbox(0,0,200,15,0);
               textxy(0,0,4,9,'Enter new file...');
               pattern := ginput(0,8) + '.' + ext;               
           end;
           if wr then
           begin
              if (canWriteTo(pattern)) then done := true
              else
              begin
                 filledbox(160,0,319,16,0);
                 textxy(160,0,4,12,'Cannot write to '+pattern);
              end;
           end
           else
              done:=true;
           fileSelector := pattern;
        end;
        if k = chr(27) then
        begin {escape key pressed - no file selected!}
           fileSelector:= '';
	   done:=true;
        end; 
        if k = chr(0) then {special key!}
        begin
           k := readkey; {read next key code...}
           
           {arrow keys}
           if ( (k = chr(75)) and (pos > 0)) then dec(pos);
           if ( (k = chr(72)) and (pos > 2)) then pos := pos - 3;
           if ( (k = chr(77)) and (pos < maxPos)) then inc(pos);
           if ( (k = chr(80)) and (pos < maxPos-2)) then pos := pos + 3;
           
           {deal with page-up/pagedown}
           if ( (k = chr(73)) or (k = chr(81))) then
           begin
              if ((pge>0) and (k = chr(73))) then dec(pge);
              if ((pge< (count div 69)) and (k = chr(81))) then inc(pge);

              filledbox(0,16,319,199,0);
              x:=0; y:=16;
              pos:=0;
              {we can display at most 69 files per page at most}
              while ((pos<70) and ((pos + (pge*69)) <count)) do
              begin
                 textxy(x,y,4,7,list[pos + (pge*69)]);
                 inc(pos);
                 x:= (pos mod 3) * 104;
                 y:= ((pos div 3) * 8) + 16;
             end;
             maxPos := pos - 1;
             pos:=0;                            
           end;
           
        end;
               
    end;
   copyToScreen;
end;


procedure pickSize(var sizex, sizey :word);
var c	 : char;
    s,t	 : string;
    done : boolean;
begin
   copyToBuffer;
   sizex:=10;
   sizey:=10;
   line(sizex,0,sizex,sizey,15);
   line(0,sizey,sizex,sizey,15);
   str(sizex,s);
   t := 'Size: '+s;
   str(sizey,s);
   t:= t + ',' +s;
   textxy(sizex,sizey,4,9,t);
   
   done := false;
   while not(done) do
   begin
      while not(keypressed) do;
      c := readkey;
      
      line(sizex,0,sizex,sizey,0);
      line(0,sizey,sizex,sizey,0);
      str(sizex,s);
      t := 'Size: '+s;
      str(sizey,s);
      t:= t + ',' +s;
      textxy(sizex,sizey,4,0,t);        
        
      if c = chr(13) then done:=true;
      if c = chr(0) then
      begin
	 c:=readkey;
	 if ((c=chr(72)) and (sizey>1)) then dec(sizey);
	 if ((c=chr(80)) and (sizey<200)) then inc(sizey);
	 if ((c=chr(75)) and (sizex>1)) then dec(sizex);
	 if ((c=chr(77)) and (sizex<320)) then inc(sizex);

	 {faster keys}
	 if ((c=chr(73)) and (sizey>11)) then sizey := sizey-10;
	 if ((c=chr(81)) and (sizey<189)) then sizey := sizey+10;;
	 if ((c=chr(71)) and (sizex>11)) then sizex := sizex-10;
	 if ((c=chr(79)) and (sizex<309)) then sizex:= sizex+10;
      end;

      line(sizex,0,sizex,sizey,15);
      line(0,sizey,sizex,sizey,15);
      str(sizex,s);
      t := 'Size: '+s;
      str(sizey,s);
      t:= t + ',' +s;
      textxy(sizex,sizey,4,9,t);
   end;
   copyToScreen;
end;

function pickcolor:byte;
var c:byte;
	d:boolean;
	a:char;
	i:byte;
        s:string;
begin
   copyToBuffer;
   for i:= 0 to 255 do
   begin
      line(i,190,i,199,i);
   end;
   c:=0;
   putpixel(c,189,15);
   textxy(280,190,4,15,'0'); 
   textxy(10,170,4,15,'Select colour');
   d:=false;
   while not(d) do
   begin
      while not(keypressed) do;
      a:=readkey;
      putpixel(c,189,0);
      str(c,s);
      textxy(280,190,4,0,s); 
      if a='.' then c:=c+1;
      if a=',' then c:=c-1;
      if a='>' then c:=c+10;
      if a='<' then c:=c-10;
      if c<0 then c:=255;
      if c>255 then c:=0;
      if a=char(13) then d:=true;
      putpixel(c,189,15);
      filledBox(260,190,270,199,c);
      str(c,s);
      textxy(280,190,4,15,s); 
   end;
   pickcolor:=c;
   copyToScreen;
end;

procedure listfiles(ext : string);
var  DirInfo : SearchRec;
     x,y     : integer;
begin
   ext := '*.' + ext;
   x:=0; y:=16;
   FindFirst(ext, 0, DirInfo);
   while DosError = 0 do
   begin
      textxy(x,y,4,7,DirInfo.Name);
      x:=x+(13*8);
      if (x>(320-96)) then
      begin
	 x:=0;
	 y:=y+8;
      end;
      FindNext(DirInfo);
   end;
end; { listfiles }

function ginput(x,y:integer):string;
var z,s : string;
   done : boolean;
   a    : char;
   i    : integer;
begin
   z:='';
   done:=false;
   while not(done) do
   begin
      while not(keypressed) do;
      a:=readkey;
      s:=z+'_';
      textxy(x,y,4,0,s);
      if not((a=char(13)) or (a=char(8)) ) then z:=z+a;
      if a=char(13) then done:=true;
      if a=char(8) then
      begin
	 s:=z;
	 z:='';
	 for i:= 1 to length(s)-1 do z :=z + s[i];
      end;
      s:=z+'_';
      textxy(x,y,4,7,s);
   end;
   ginput:=z;
end;

end.
