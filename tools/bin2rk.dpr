program bin2rk;

{$APPTYPE CONSOLE}

uses
  SysUtils;
var
f,f1:file of byte;
  i,size,start:word;
  tb,u,te:byte;
  cs:word;
  err:integer;
  res:integer;
begin
  writeln('Bin2rk 2.0 by Kakos_nonos');
  if (Paramstr(1)<>'') and (Paramstr(2)<>'') then
  begin
   val(paramstr(3),start,err);
  end
  else start:=0;
  if (paramstr(1)='') and (paramstr(2)='') then
  begin
   writeln('Use bin2rk infile outfile [addr]');
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
   cs:=cs+tb+(tb shl 8);
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
  u:=start div 256; write(f,u);
  u:=start mod 256; write(f,u);
  u:=(start+size) div 256; write(f,u);
  u:=(start+size) mod 256; write(f,u);

  assignfile(f1,paramstr(1));
  reset(f1);
  while not eof(f1) do
  begin
   read(f1,tb);
   write(f,tb);
  end;
  closefile(f1);
  u:=0; write(f,u);
  write(f,u);
  u:=$e6; write(f,u);
  u:=cs div 256; write(f,u);
  u:=cs mod 256; write(f,u);
  closefile(f);
  write('Done. ');
  write(size);
    writeln(' bytes.');
end.
