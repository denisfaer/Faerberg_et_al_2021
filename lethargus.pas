program wt_moltsandstages;

const
  k = 125;
  red = 30;
  smoothk = 10000;
  max = 650000;
  step = 2.5;
  stepnum = 20;
  limit = 150;

var
  fin, fout, fout1, fout2, fout3, fout4, fout5: text;
  minimum, point, ts, temp, x1, y1, x2, y2: real;
  j, i, memb, last, t, q, shift, Ad, track, y, b1, b2: integer;
  perm: array[1..max]of boolean;
  val: array[1..max]of real;
  mini, minval: array[1..4]of real;
  l, lt: array[1..4]of integer;
  mid, dur, trb: array[1..4, 1..stepnum + 1]of real;
  trust: array[1..4]of integer;
  miss: array[1..4]of real;
  ltolt: string;
  first: boolean;

begin
  assign(fout, 'globmin.csv');
  rewrite(fout);
  writeln(fout, '"L1/L2","L2/L3","L3/L4","L4/A"');
  assign(fout1, 'testing.csv');
  rewrite(fout1);
  assign(fout2, 're' + red + 'smooth' + smoothk / 1000 + 'stages.csv');
  rewrite(fout2);
  writeln(fout2, '"L1","L2","L3","L4","Total"');
  assign(fout3, 'testing_2.csv');
  rewrite(fout3);
  assign(fout4, 'frameloss.csv');
  rewrite(fout4);
  writeln(fout4, '"L1","L2","L3","L4","Total"');
  assign(fout5, 'trouble.csv');
  rewrite(fout5);
  for j := 1 to k do
  begin
    if(j = 1) then
      t := Milliseconds;
    if(j = 2) then
    begin
      ts := (k - 1) * (Milliseconds - t) / 1000;
      writeln('Estimated completion time: ', ts, ' s');
    end;
    for q := 1 to round(90000 / red) do
      perm[q] := false;
    for q := (round(90000 / red) + 1) to max do
      perm[q] := true;
    for q := 1 to 4 do
    begin
      mini[q] := 99999;
      l[q] := 0;
      assign(fin, InttoStr(j) + 're' + InttoStr(red) + 'smooth' + IntToStr(round(smoothk / red)) + '.csv');
      reset(fin);
      i := 0;
      while(not (eof(fin))) do
      begin
        readln(fin, point);
        inc(i);
        val[i] := point;
        if((mini[q] > point) and (perm[i])) then
        begin
          mini[q] := point;
          l[q] := i;
        end;
      end;
      track := i;
      for i := (l[q] - round(32400 / red)) to (l[q] + round(32400 / red)) do
        perm[i] := false;
      close(fin);
    end;
    ltolt := '';
    for q := 1 to 4 do
    begin
      lt[q] := min(l[1], l[2], l[3], l[4]);
      for i := 1 to 4 do
        if(l[i] = lt[q]) then
        begin
          l[i] := max + 1;
          ltolt := ltolt + IntToStr(i);
        end;
    end;
    minval[1] := mini[StrToInt(ltolt[1])];
    minval[2] := mini[StrToInt(ltolt[2])];
    minval[3] := mini[StrToInt(ltolt[3])];
    minval[4] := mini[StrToInt(ltolt[4])];
    //calculate durations and midpoints
    for q := 1 to stepnum do
      for y := 1 to 4 do
      begin
        first := true;
        for i := 1 to round(limit * 180 / red) do
          if((first) and (val[lt[y] - i] > (minval[y] + step * q))) then
          begin
            first := false;
            b1 := lt[y] - i;
          end;
        if(first) then b1 := lt[y] - i;
        first := true;
        for i := lt[y] to round(lt[y] + limit * 180 / red) do
          if((first) and (val[i] > (minval[y] + step * q))) then
          begin
            first := false;
            b2 := i;
          end;
        if(first) then b2 := i;
        mid[y, q] := (b1 + b2) / 2;
        dur[y, q] := b2 - b1;
        trb[y, q] := b1;
      end;
    //write testing files
    for y := 1 to 4 do
    begin
      for q := 1 to stepnum do
        write(fout1, mid[y, q], ',');
      if(y < 4) then
        write(fout1, ',')
      else writeln(fout1, ',')
    end;
    for y := 1 to 4 do
    begin
      for q := 1 to stepnum do
        write(fout3, dur[y, q], ',');
      if(y < 4) then
        write(fout3, ',')
      else writeln(fout3, ',')
    end;
    for y := 1 to 4 do
    begin
      for q := 1 to stepnum do
        write(fout5, trb[y, q], ',');
      if(y < 4) then
        write(fout5, ',')
      else writeln(fout5, ',')
    end;
    //exclude durations over limit
    for y := 1 to 4 do
    begin
      trust[y] := stepnum;
      for q := stepnum to 1 do
        if(dur[y, q] > (limit * 180 / red)) then
          trust[y] := (q - 1);
    end;
    //calculate average of midpoints
    for y := 1 to 4 do
    begin
      mid[y, stepnum + 1] := 0;
      for q := 1 to trust[y] do
        mid[y, stepnum + 1] := mid[y, stepnum + 1] + mid[y, q];
      mid[y, stepnum + 1] := mid[y, stepnum + 1] / trust[y];
    end;
    //count missing frames
    for i := 1 to 4 do
      miss[i] := 0;
    assign(fin, IntToStr(j) + '.txt');
    reset(fin);
    readln(fin, x1, y1);
    i := 1;
    while(i <= (lt[4] * red + smoothk / 2)) do
    begin
      readln(fin, x2, y2);
      i := i + 1;
      if((x2 = 0) or (x1 = 0) or (y2 = 0) or (y1 = 0) or (x2 = 1) or (x1 = 1) or (y2 = 1) or (y1 = 1)) then
      begin
        i := i - 1;
        if(i <= (lt[1] * red + smoothk / 2)) then
          miss[1] := miss[1] + 1
        else
        if(i <= (lt[2] * red + smoothk / 2)) then
          miss[2] := miss[2] + 1
        else
        if(i <= (lt[3] * red + smoothk / 2)) then
          miss[3] := miss[3] + 1
        else
        if(i <= (lt[4] * red + smoothk / 2)) then
          miss[4] := miss[4] + 1;
      end;
      x1 := x2;
      y1 := y2;
    end;
    close(fin);
    writeln(fout4, miss[1], ',', miss[2], ',', miss[3], ',', miss[4], ',', (miss[1] + miss[2] + miss[3] + miss[4]));
    for i := 1 to 4 do
      miss[i] := miss[i] / red;
    //write output files
    writeln(fout, mid[1, stepnum + 1] * red / 180, ',', mid[2, stepnum + 1] * red / 180, ',', mid[3, stepnum + 1] * red / 180, ',', mid[4, stepnum + 1] * red / 180);
    writeln(fout2, (mid[1, stepnum + 1] + smoothk / (2 * red) + miss[1]) * red / 180, ',', (mid[2, stepnum + 1] - mid[1, stepnum + 1] + miss[2]) * red / 180, ',', (mid[3, stepnum + 1] - mid[2, stepnum + 1] + miss[3]) * red / 180, ',', (mid[4, stepnum + 1] - mid[3, stepnum + 1] + miss[4]) * red / 180, ',', (mid[4, stepnum + 1] + smoothk / (2 * red) + miss[1] + miss[2] + miss[3] + miss[4]) * red / 180);
  end;
  close(fout);
  close(fout1);
  close(fout2);
  close(fout3);
  close(fout4);
  close(fout5);
end.