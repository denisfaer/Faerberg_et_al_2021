program wt_smooth;

uses System;

const
  k = 125;          //number of worms             
  smoothk = 10000;  //smoothing coefficient
  red = 30;         //reduction coefficient
  scale = 10.53;    //AU-to-um conversion
  rounding = false;

var
  fin, fd, sup, fin1, fin2, fout: text;
  x1, y1, x2, y2, delta, supdelta, old, ts: real;
  i, j, t, n: integer;

begin
  for j := 1 to k do
  begin
    if(j = 1) then
      t := Milliseconds;
    if(j = 2) then
    begin
      ts := (k - 1) * (Milliseconds - t) / 1000;
      writeln('Estimated completion time: ', ts, ' s');
    end;
    assign(fin, InttoStr(j) + '.txt');       
    assign(fd, InttoStr(j) + 're' + InttoStr(red) + 'disp.csv');        
    assign(sup, InttoStr(j) + 're' + InttoStr(red) + 'sup.txt');
    reset(fin);
    rewrite(fd);
    rewrite(sup);
    read(fin, x1);
    read(fin, y1);
    if(rounding) then
    begin
      x1 := round(x1);
      y1 := round(y1);
    end;
    i := 0;
    while(not eof(fin)) do
    begin
      read(fin, x2);
      read(fin, y2);
      if(rounding) then
      begin
        x2 := round(x2);
        y2 := round(y2);
      end;
      inc(i);
      if(i = 1) then
      begin
        if((not ((x1 = 1) or (x2 = 1) or (y1 = 1) or (y2 = 1))) and (not ((x1 = 0) or (x2 = 0) or (y1 = 0) or (y2 = 0)))) then     
        begin
          delta := scale * sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)); 
          writeln(fd, delta);
          writeln(sup, delta);
        end;
        x1 := x2;
        y1 := y2;
      end;
      if(i = red) then i := 0;
    end;
    close(fin);
    close(fd);
    close(sup);
    n := round(smoothk / red);
    assign(fin1, InttoStr(j) + 're' + InttoStr(red) + 'disp.csv');          
    assign(fin2, InttoStr(j) + 're' + InttoStr(red) + 'sup.txt');    
    assign(fout, InttoStr(j) + 're' + InttoStr(red) + 'smooth' + InttoStr(n) + '.csv'); 
    reset(fin1);
    reset(fin2);
    rewrite(fout);
    supdelta := 0;
    i := 0;
    while(not eof(fin1)) do
    begin
      inc(i);
      readln(fin1, delta);
      supdelta := supdelta + delta;
      if(i >= n) then
      begin
        readln(fin2, old);
        writeln(fout, supdelta / n);
        supdelta := supdelta - old;
      end;
    end;
    close(fin1);
    close(fin2);
    close(fout);
  end;
end.