program bin2ch;

{$APPTYPE CONSOLE}

uses
  SysUtils;
var
  f1,f2:file of byte;
  fo: text;
  tb1, tb2, i:byte;
  res:integer;
begin
  writeln('BITMAP 0.1 by Yuri Prokushev');
  if (paramstr(1)='') and (paramstr(2)='') and (paramstr(3)='') then
  begin
   writeln('Use bitmap infile1 infile1 outfile');
   halt;
  end;
  assignfile(f1,paramstr(1));
  {$I-}
  reset(f1);
  {$I+}
  res := IOResult;
  if res<>0 then
  begin
   writeln('Error open file '+paramstr(1));
   halt;
  end;

  assignfile(f2,paramstr(2));
  {$I-}
  reset(f2);
  {$I+}
  res := IOResult;
  if res<>0 then
  begin
   writeln('Error open file '+paramstr(2));
   halt;
  end;

  assignfile(fo,paramstr(3));
  {$I-}
  rewrite(fo);
  {$I+}
    res := IOResult;
  if res<>0 then
  begin
   writeln('Error create file '+paramstr(3));
   halt;
  end;

  i:=0;
  while not eof(f1) do
  begin
   if i=0 then write(fo, #9'db'#9);
   read(f1,tb1);
   read(f2,tb2);
   if tb1<>tb2 then write(fo,'1') else write(fo,'0');
   inc(i);
   if i=8 then 
   begin
    writeln(fo,'b');
	i:=0;
   end;
  end;

  if i<>0 then
  begin
    while i<>8 do
    begin
     write(fo,'0');
     inc(i);
    end;
    writeln(fo,'b');
  end;
  
  closefile(f1);
  closefile(f2);
  closefile(fo);
  
  write('Done. ');
end.
