[inherit ('monconst','montype','sys$library:starlet')]

MODULE Monstring(OUTPUT);

%include 'headers.txt'

TYPE
  $UBYTE = [BYTE] 0..255;

(* -------------------------------------------------------------------------- *)

[asynchronous,external(str$trim)]
function str$trim(
  VAR destination_string:[class_s,VOLATILE] PACKED ARRAY [$l1..$u1:integer] of char;
  source_string : [CLASS_S] PACKED ARRAY [$l2..$u2:integer] OF CHAR;
  VAR resultant_length : [VOLATILE] $UWORD) : INTEGER;
external;

[asynchronous,external(lib$signal)]
function lib$signal (%ref status:[unsafe] unsigned):unsigned;
external;

[ASYNCHRONOUS] function lib$getjpi (
  item_code : INTEGER;
  VAR process_id : [VOLATILE] UNSIGNED := %IMMED 0;
  process_name : [CLASS_S] PACKED ARRAY [$l3..$u3:INTEGER] OF CHAR := %IMMED 0;
  %REF resultant_value : [VOLATILE,UNSAFE] ARRAY [$l4..$u4:INTEGER] OF $UBYTE := %IMMED 0;
  VAR resultant_string : [CLASS_S] PACKED ARRAY [$l5..$u5:INTEGER] OF CHAR := %IMMED 0;
  VAR resultant_length : [VOLATILE] $UWORD := %IMMED 0) : INTEGER; EXTERNAL;
 
(* -------------------------------------------------------------------------- *)

[ASYNCHRONOUS]
PROCEDURE SysCall(S : [UNSAFE] Unsigned);

BEGIN
  IF NOT ODD(S) THEN
    Lib$Signal(s);
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Spaces(num : INTEGER := 0) : String;
VAR
  i : INTEGER;
  st : String;
BEGIN
  st := '';
  FOR i := 0 TO num DO
    st := st + ' '; 
  Spaces := st;
END;

[ASYNCHRONOUS]
FUNCTION Slead(S : String) : String;

  (* take off leading spaces and tabs *)

VAR
  I : INTEGER;
  Going : BYTE_BOOL;

BEGIN 
  I  := 1;
  Going := TRUE;
  WHILE Going DO
  BEGIN
    IF I > Length(S) THEN
      Going := FALSE
    ELSE
    IF (S[I]=' ') OR (S[I]=chr(9)) THEN
      I := I + 1
    ELSE
      Going := FALSE;
  END;
  IF I > Length(S) THEN
    Slead := ''
  ELSE
    Slead := SubStr(S, I, Length(S)+1-I);
END;

[global]
procedure mytrim(var s : string);
var
  loop, cc, endd, indx : integer;
begin
  indx := 1;
  endd := s.length;
  while (((s[indx] = ' ') or (s[indx] = chr(9))) and (indx < s.length)) do
    indx := indx + 1;
  while (((s[endd] = ' ') or (s[endd] = chr(9))) and (endd > indx)) do
    endd := endd - 1;
  if (indx = 1) then
    s.length := endd
  else
  begin
    cc := 1;
    for loop := indx to endd do
    begin
      s[cc] := s[loop];
      cc := cc + 1;
    end;
    s.length := endd-indx+1;
  end;
end;

[GLOBAL]
FUNCTION Trim(S : String) : String;

  (* Take off leading/trailing spaces/tabs *)

VAR
  Tmp : String := '';

BEGIN
  S := Slead(S);
  SysCall(STR$Trim(Tmp.Body, S, Tmp.Length));
  Trim := Tmp;
END;

[GLOBAL]
FUNCTION Userid : String;

VAR
  Id : PACKED ARRAY[1..100] OF Char;
  Length : $UWORD;

BEGIN
  SysCall(LIB$GetJpi(JPI$_USERNAME, , , , Id, Length));
  Userid := Trim(SubStr(Id, 1, Length));
END;

[GLOBAL]
FUNCTION Bite(VAR S : String) : String;

(* Return the first word (space terminated) in bite, and the rest of the *)
(* string in S *)

VAR
  I : INTEGER := 0;

BEGIN
  IF Length(S) <> 0 THEN
    I := Index(S,' ');
  CASE I OF
    0 : BEGIN
          Bite := S;
          S := '';
        END;
    OTHERWISE BEGIN
                Bite := SubStr(S, 1, I-1);
                S := Trim(SubStr(S, I+1, Length(S)-I));
              END;
  END;
END;
 
[GLOBAL]
FUNCTION LowCase(S : String) : String;

CONST
  Diff = 32;   (* The diff in ascii value between 'a' and 'A' *)

VAR
  Sprime : String;
  Index : INTEGER;

BEGIN
  Sprime := S;
  FOR Index := 1 to LENGTH(S) DO
    IF Sprime[Index] IN ['A'..'Z'] THEN
       Sprime[Index] := CHR(ORD(Sprime[Index])+Diff);
  LowCase := Sprime;
END;

[GLOBAL]
FUNCTION UpCase(S : String) : String;

CONST
  Diff = 32;   (* The diff in ascii value between 'a' and 'A' *)

VAR
  Sprime : String;
  Index : INTEGER;

BEGIN
  Sprime := S;
  FOR Index := 1 to LENGTH(S) DO
    IF Sprime[Index] IN ['a'..'z'] THEN
       Sprime[Index] := CHR(ORD(Sprime[Index])-Diff);
  UpCase := Sprime;
END;

[GLOBAL]
FUNCTION IsValid(S : String; SType : INTEGER := vt_alphanum) : BYTE_BOOL;

VAR
   i : INTEGER;
BEGIN
   IsValid := TRUE;
   FOR i := 1 TO Length(S) DO
   BEGIN
     CASE SType OF
(*        vt_alphanum: 
       vt_numeric:  *)
       vt_alpha:
          IF NOT( (S[i] IN ['a'..'z']) OR
		  (S[i] IN ['A'..'Z']) OR
                  (S[i] = ' ') ) THEN
		IsValid := FALSE;
     END; (* Case *)
   END; (* FOR *)
END; (* Is Valid *)

[GLOBAL]
FUNCTION IsNum(S : String) : BYTE_BOOL;

VAR
  Temp : INTEGER;

BEGIN
  Readv(S, Temp, ERROR := CONTINUE);
  IsNum := StatusV = 0;
END;

[GLOBAL]
FUNCTION Number(S : String) : INTEGER;

(* Assumption : S is a valid integer.  Example - (1234) or (-121)  *)

VAR
  THENumber : INTEGER;

BEGIN
  Readv(S, THENumber);
  Number := THENumber;
END;

[GLOBAL]
FUNCTION SysTime : String;

VAR
  HourString : String;
  Hours : INTEGER;
  TheTime : PACKED ARRAY[1..11] OF CHAR;
  DayOrNite : String;

BEGIN
  Time(TheTime);
  IF TheTime[1] = ' ' THEN
     Hours := ORD(TheTime[2]) - ORD('0')
  ELSE
     Hours := (ORD(TheTime[1]) - ORD('0'))*10 + (ORD(TheTime[2]) -ORD('0'));
  IF Hours < 12 THEN
     DayOrNite := 'am'
  ELSE
     DayOrNite := 'pm';
  IF Hours >= 13 THEN
     Hours := Hours - 12;
  IF Hours = 0 THEN
     Hours := 12;
  Writev(HourString, Hours:2);
  SysTime := HourString + ':' + TheTime[4] + TheTime[5] + DayOrNite;
END;

[GLOBAL]
FUNCTION SysDate : String;

VAR
  TheDate : PACKED ARRAY[1..11] OF CHAR;

BEGIN
  Date(TheDate);
  SysDate := TheDate;
END;

[GLOBAL]
FUNCTION Styler(S : String; Style : INTEGER := 0) : String;
BEGIN
   CASE Style OF
	Style_Normal:
	  Styler := S;
	Style_Capitalized:
	  Styler := Capitalize(S);   { currently unsupported }
	Style_AllCaps:
	  Styler := UpCase(S);
	Style_AllLower:
	  Styler := LowCase(S);
    OTHERWISE Styler := '%Styler: Unknown Style';
    END;
END;

[GLOBAL]
FUNCTION Capitalize(S : String; AllWords : BYTE_BOOL := TRUE) : String;
(* Will either capitalize the first word in S or all of the words in S *)

CONST
  Diff = 32;   (* The diff in ascii value between 'a' and 'A' *)

VAR
  Sprime : String;
  Index : INTEGER;
  First : BYTE_BOOL;

BEGIN
  First := FALSE;
  Sprime := S;
  FOR Index := 1 to LENGTH(S) DO
    IF (Sprime[Index] IN ['a'..'z']) AND (First = FALSE) THEN
    BEGIN
       Sprime[Index] := CHR(ORD(Sprime[Index])-Diff);
       First := TRUE;
    END;
  Capitalize := Sprime;
END;
  

END.
