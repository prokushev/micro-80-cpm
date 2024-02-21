program bin2ch;

{$APPTYPE CONSOLE}

uses
  SysUtils;
var
f,f1:file of byte;
  size:word;
  tb,u:byte;
  cs:word=0;
  res:integer;
begin
  writeln('BIN2CH 1.0 by Yuri Prokushev based on bin2rk by Kakos_nonos');
  if (paramstr(1)='') and (paramstr(2)='') then
  begin
   writeln('Use bin2ch infile outfile');
   halt;
  end;
  assignfile(f,paramstr(1));
  {$I-}
  reset(f);
  {$I+}
  res := IOResult;
  if res<>0 then
  begin
   writeln('Error open file '+paramstr(1));
   halt;
  end;
  size:=0;
  while not eof(f) do
  begin
   read(f,tb);
   inc(size);
   cs:=cs+tb;
  end;
  closefile(f);
  assignfile(f,paramstr(2)(*ChangeFileExt(paramstr(1),'.rk')*));
  {$I-}
  rewrite(f);
  {$I+}
    res := IOResult;
  if res<>0 then
  begin
   writeln('Error create file '+paramstr(2)(*ChangeFileExt(paramstr(1),'.rk')*));
   halt;
  end;
  u:=cs mod 256; write(f,u);
  u:=cs div 256; write(f,u);
  u:=size mod 256; write(f,u);
  u:=size div 256; write(f,u);

  assignfile(f1,paramstr(1));
  reset(f1);
  while not eof(f1) do
  begin
   read(f1,tb);
   write(f,tb);
  end;
  closefile(f1);
  closefile(f);
  write('Done. ');
  write(size);
    writeln(' bytes.');
end.
