[INHERIT ('sys$library:starlet','monconst','MonType','monglobl')]

MODULE MonMisc (INPUT,OUTPUT);

%include 'headers.txt'

[HIDDEN]
CONST
  Short_Wait = 0.10;

[HIDDEN]
TYPE
  $uquad = RECORD
    i1,i2 : INTEGER;
  END;
  SysTimeType = $uquad;
  $deftyp = [unsafe] integer;    (* For lib$stat_timer *)
  $defptr = [unsafe] ^$deftyp;   (* For lib$stat_timer *)
  $ubyte = [byte] 0 .. 255;

VAR
  timercontext:unsigned;
  save_dcl_ctrl:unsigned;
  Out_Chan : $UWORD;
  seed : [GLOBAL] INTEGER;
  logfile : TEXT;

(* ----------- External declerations for the library routines ------------ *)

[ASYNCHRONOUS]
function lib$spawn (
  command_string : [CLASS_S] PACKED ARRAY [$l1..$u1:INTEGER] OF CHAR := %IMMED 0;
  input_file : [CLASS_S] PACKED ARRAY [$l2..$u2:INTEGER] OF CHAR := %IMMED 0;
  output_file : [CLASS_S] PACKED ARRAY [$l3..$u3:INTEGER] OF CHAR := %IMMED 0;
  flags : UNSIGNED := %IMMED 0;
  process_name : [CLASS_S] PACKED ARRAY [$l5..$u5:INTEGER] OF CHAR := %IMMED 0;
  VAR process_id : [VOLATILE] UNSIGNED := %IMMED 0;
  %IMMED completion_status_address : $DEFPTR := %IMMED 0;
  byte_integer_event_flag_num : $UBYTE := %IMMED 0;
  %IMMED [UNBOUND, ASYNCHRONOUS] PROCEDURE AST_address := %IMMED 0;
  %IMMED varying_AST_argument : [UNSAFE] INTEGER := %IMMED 0;
  prompt_string : [CLASS_S] PACKED ARRAY [$l11..$u11:INTEGER] OF CHAR := %IMMED 0;
  cli : [CLASS_S] PACKED ARRAY [$l12..$u12:INTEGER] OF CHAR := %IMMED 0) : INTEGER; EXTERNAL;

[asynchronous]
function lib$cvtf_from_internal_time(operation:unsigned;
	var resultant_time:[volatile] single;
	input_time: $uquad):unsigned;
external;

[asynchronous,external(lib$signal)]
function lib$signal (%ref status:[unsafe] unsigned):unsigned;
external;

[asynchronous]
function lib$init_timer(
	var context:[volatile] unsigned  := %immed 0):unsigned;
external;

[asynchronous]
function lib$stat_timer(code:integer;
  %ref value_argument:[volatile,unsafe] array [$l2..$u2:integer] of $ubyte;
  handle_address:$defptr := %immed 0): unsigned; external;

[asynchronous, external (lib$disable_ctrl)]
function lib$disable_ctrl (
  %ref disable_mask:unsigned;
  %ref old_mask:unsigned := %immed 0):unsigned;
external;

[asynchronous]
function lib$sub_times(time1:$uquad; time2:$uquad;
  var resultant_time:[volatile] $uquad):unsigned;
external;

[asynchronous,external(lib$enable_ctrl)]
function lib$enable_ctrl(
  %ref enable_mask:unsigned;
  %ref old_mask:unsigned := %immed 0):unsigned;
external;

[external]
function lib$wait(seconds:[reference] real):integer;
external;
 
[ASYNCHRONOUS] function lib$getjpi (
  item_code : INTEGER;
  VAR process_id : [VOLATILE] UNSIGNED := %IMMED 0;
  process_name : [CLASS_S] PACKED ARRAY [$l3..$u3:INTEGER] OF CHAR := %IMMED 0;
  %REF resultant_value : [VOLATILE,UNSAFE] ARRAY [$l4..$u4:INTEGER] OF $UBYTE := %IMMED 0;
  VAR resultant_string : [CLASS_S] PACKED ARRAY [$l5..$u5:INTEGER] OF CHAR := %IMMED 0;
  VAR resultant_length : [VOLATILE] $UWORD := %IMMED 0) : INTEGER; EXTERNAL;

(* ------------- END external lib routines declerations ----------------- *)

[ASYNCHRONOUS]
PROCEDURE SysCall(S : [UNSAFE] Unsigned);

BEGIN
  IF NOT ODD(S) THEN
    Lib$Signal(s);
END;

[GLOBAL]
PROCEDURE Spawn(S : String);

BEGIN
  SysCall(Lib$Spawn(S));
END;

[GLOBAL]
FUNCTION GetRealTime : SysTimeType;

VAR
  Time : [UNSAFE] SysTimeType;

BEGIN
  SysCall($GetTim(Time));
  GetRealTime := Time;
END;

[GLOBAL]
FUNCTION DiffInSecs(Time1, Time2 : [UNSAFE] SysTimeType) : INTEGER;

VAR
  ResultTime : SysTimeType;
  RealTime : REAL;

BEGIN
  SysCall(LIB$Sub_Times(Time1,Time2,ResultTime));
  SysCall(LIB$Cvtf_From_Internal_Time(LIB$K_Delta_Seconds_F,
                                      RealTime,ResultTime));
  DiffInSecs := TRUNC(RealTime);
END;

[GLOBAL]
FUNCTION GetTicks : INTEGER;

TYPE 
  QuadRec = RECORD
    I1 : INTEGER;
    I2 : INTEGER;
  END;

VAR
  TimeValue : [UNSAFE, VOLATILE] QuadRec;
  Secs : REAL;

BEGIN
  LIB$Stat_Timer (1, TimeValue, TimerContext);
  LIB$Cvtf_From_Internal_Time(LIB$K_Delta_Seconds_F, Secs, TimeValue);
  GetTicks := TRUNC (Secs*10);
END;

[GLOBAL]
FUNCTION Rnd(MaxValue : INTEGER := MAXINT) : INTEGER;
{ Returns a value between 1 and MaxValue }

BEGIN
  Rnd := ROUND(MTH$Random(Seed)*(MaxValue-1)) + 1;
END;

[GLOBAL]
PROCEDURE Wait(Seconds : REAL);

BEGIN
  LIB$Wait(Seconds);
END;

[GLOBAL]
FUNCTION Get_Pid(Parent : BYTE_BOOL := FALSE) : INTEGER;
PE   IL3 = RECORD     buflen:$uword;     itm:$uword;      baddr:unsigned;      laddr:unsigned;    END;   VAR    PidLen : UNSIGNED;   Il : ARRAY[1..2] OF IL3;   Pid : INTEGER;   BEGIN    IL := ZERO;    IF NOT Parent THEN     il[1].itm := jpi$_pid    ELSE!     il[1].itm := jpi$_master_pid;    il[1].buflen := size(pid);   il[1].baddr := iaddress(pid); "   il[1].laddr := iaddress(pidlen);   syscall($getjpiw(,,,il));    get_pid := ord(pid); END;   [GLOBAL] PROCEDURE BoostPriority;   VAR    MyPid : UNSIGNED;    BEGIN    MyPid := GET_PID;    $setpri(mypid,,6);   MyPid := GET_PID(TRUE);    $setpri(mypid,,6); END;   [GLOBAL]9 PROCEDURE Freeze(Secs : REAL; VAR AllStats : AllMyStats);    VAR    TimeEnd : INTEGER;    DidCheck : BYTE_BOOL := FALSE;   BEGIN '   TimeEnd := TRUNC(10*Secs) + GetTicks;    WHILE GetTicks < TimeEnd DO    BEGIN /     IF GetTicks > AllStats.Tick.TkAllEvent THEN *       AllEvents(TRUE, DidCheck, AllStats);     Wait(short_wait);    END;   IF NOT DidCheck THEN/      CheckEvents(FALSE, TRUE, FALSE, AllStats);  END;    [GLOBAL]. PROCEDURE PutChars(S : VARYING [$t1] OF CHAR);   VAR %   Msg : PACKED ARRAY[1..128] OF CHAR;    Len : INTEGER;   BEGIN    Msg := S;    Len := LENGTH(S); 0   $Qiow(,Out_Chan,IO$_WritevBlk,,,,Msg,Len,,,,); END;    [GLOBAL] FUNCTION KeyGet : INTEGER;   VAR    Status : UNSIGNED;   Key : INTEGER;   Letter : $UWORD;1   Qfunc : INTEGER  := IO$_READVBLK + IO$M_EXTEND;    First : INTEGER;+   Inp : PACKED ARRAY[1..6] OF CHAR := ZERO;    I : INTEGER;   Iosb : IosbType;   Temp : INTEGER;    Pic : CHAR := ZERO;    BEGIN I (* Get the input with the function Code of READ_VIRTUAL_BLOCK with the *) I (* extended options.                                                   *)   '   List[7].Buffer_Length := length(pic); %   List[7].Item_code := trm$_picstrng; '   List[7].Buffer_Addr := iaddress(pic);    List[7].Return_Addr := 0;      Temp := 0;   Inp := ZERO;:   Status := $qiow(,IN_chan,qfunc,iosb,,,inp,length(inp),,,)                   %REF List, size(List)); '   IF (Iosb.Status = SS$_OPINCOMPL) THEN    BEGIN &     (* Writeln('AST interruption!') *)   END    ELSE%   IF (Iosb.Status = SS$_TIMEOUT) THEN      Iosb.Word2 := 0    ELSE   IF NOT(ODD(Status)) THEN   BEGIN "     Writeln('Status = ',Status:0);     LIB$SIGNAL(Status);    END;   IF Iosb.Word2 <> 0 THEN    BEGIN      First := iosb.word2 + 256;   END    ELSE   BEGIN      First := 0;    END;M (* Based on this first value, most keys can be determined.  If the first   *) M (* character is the escape character (character 27), then further checking *) M (* must take place.  These keys are define in monmailbox.pas.              *)    IF (First = 27) THEN   BEGIN      FOR I := 1 TO NumKeys DO	     BEGIN &       IF (Ord(Inp[2]) = Code[i,1]) AND&          (Ord(Inp[3]) = Code[i,2]) AND&          (Ord(Inp[4]) = Code[i,3]) AND&          (Ord(Inp[5]) = Code[i,4]) AND'          (Ord(Inp[6]) = Code[i,5]) THEN        BEGIN          Temp := Name[i];
       END;     END;     KeyGet := Temp;    END    ELSE   BEGIN      KeyGet := First;   END; END;  B procedure logcommand(s : packed array [$l1..$l2:integer] of char); begin    extend(logfile);   writeln(logfile, s); end;   [GLOBAL]A PROCEDURE GrabLine(Prompt : String; VAR S : VARYING[$l1] OF CHAR; G                    VAR AllStats : AllMyStats; Echo : BYTE_BOOL := TRUE; +                    MaxLen : INTEGER := 78);    VAR    KeyCode : INTEGER;   Line : String;   msg : varying [200] of char;     PROCEDURE ResetLine;   BEGIN /     PutChars(CHR(13)+CHR(27)+'[K'+Prompt+Line);    END;     PROCEDURE FixPrompt;   BEGIN      IF Echo THEN#       PutChars(CHR(10)+Prompt+Line)      ELSE       PutChars(CHR(10)+Prompt);    END;  8   FUNCTION NextKey(VAR AllStats : AllMyStats) : INTEGER;      VAR      Dummy : BYTE_BOOL;     KeyCode : INTEGER := 0;      Ticks : INTEGER;     BEGIN 
     REPEAT#       IF AllStats.Stats.InGame THEN        BEGIN          Ticks := GetTicks;-         IF Ticks > AllStats.Tick.TkEvent THEN 4           CheckEvents(FALSE, TRUE, FALSE, AllStats);0         IF Ticks > AllStats.Tick.TkAllEvent THEN&           AllEvents(,Dummy, AllStats);&         IF AllStats.Stats.Printed THEN         BEGIN            FixPrompt;*           AllStats.Stats.Printed := FALSE;         END;
       END;       KeyCode := KeyGet;     UNTIL KeyCode <> 0;      NextKey := KeyCode;    END;   BEGIN    PutChars(chr(10)+Prompt);    Line.Length := 0;    KeyCode := 0;    WHILE (KeyCode <> 13) DO   BEGIN !     KeyCode := NextKey(AllStats);        CASE KeyCode OF        8, 127 : BEGIN$                  CASE Line.Length OF                    0 : ;                    OTHERWISE                    BEGIN4                      Line.Length := Line.Length - 1;1                      PutChars(CHR(8)+' '+CHR(8));                     END;                   END;                 END;        21 : BEGIN              Line.Length := 0;              ResetLine;             END;        23 : ResetLine; A       32 : IF ((Line.Length < MaxLen) AND (Line.Length > 0)) THEN             BEGIN*              Line.Length := Line.Length+1;4              Line.Body[Line.Length] := CHR(KeyCode);1              IF Echo THEN PutChars(CHR(KeyCode));             END;        33..126 : BEGIN .                   IF Line.Length < MaxLen THEN                   BEGIN 1                     Line.Length := Line.Length+1; ;                     Line.Body[Line.Length] := CHR(KeyCode);                       IF Echo THEN-                       PutChars(CHR(KeyCode));                    END;                 END;       2 : BEGIN              BoostPriority;*             Writeln('Boosting priority!');             Writeln;             ResetLine;           END;       otherwise        begin 0          writeln('Key pressed was ', keycode:0);
       end;     END;   END;  (* END While LOOP *)     PutChars(CHR(13));   S := Trim(Line); (*9   if allstats.stats.privd or allstats.stats.sysmaint then    begin H     Writev(msg, AllStats.Stats.realid, ' as ', allstats.stats.name, '(',=            allstats.stats.userid,') did [', s, '] at room #', &            allstats.stats.location:0);     LogCommand(msg);   end; *) END;   [GLOBAL] PROCEDURE Setup_Guts;    VAR    Mask : UNSIGNED;   BEGIN    Seed := Clock;*   SysCall($Assign('Sys$Output',Out_Chan));   CreateKeyboard;    TimerContext := 0;    LIB$Init_Timer(TimerContext); 7   Mask := %x'02000000';        { ctrl/y  just for dcl } 1   SysCall(LIB$Disable_Ctrl(Mask, Save_Dcl_Ctrl)); B   mask := %x'02000008';        { nuke ctrl/y & ctrl/c completely }N   open(logfile, 'mon_disk:masmonst.log', history:=unknown,sharing:=readwrite); END;    [GLOBAL] PROCEDURE Finish_Guts; BEGIN H   SysCall(LIB$Enable_Ctrl(Save_Dcl_Ctrl));       { re-enable dcl ctrls } END;   [GLOBAL]# PROCEDURE Grab_Num(Prompt : String;  		   VAR Num : INTEGER; $ 		   Min : INTEGER := -MAXINT DIV 2;# 		   Max : INTEGER := MAXINT DIV 2;  		   Default : INTEGER := 0;.                    VAR AllStats : AllMyStats);   VAR    S : String;    BEGIN     GrabLine(Prompt, S, AllStats);   IF IsNum(S) THEN   BEGIN      Num := Number(S); &     IF (Num < Min) OR (Num > Max) THEN        Num := Default;   END    ELSE     Num := Default;      END;   [GLOBAL]I FUNCTION GrabYes(Prompt : String; VAR AllStats : AllMyStats) : BYTE_BOOL;    VAR    S : String;    BEGIN    GrabYes := FALSE;    GrabLine(Prompt,S,AllStats);   IF (Length(S) > 0) THEN !     If (LowCase(S[1]) = 'y') THEN        GrabYes := TRUE; END;   [GLOBAL]. FUNCTION ReadYes(Prompt : String) : BYTE_BOOL;   VAR    S : String;    BEGIN    ReadYes := FALSE;    Write(Prompt);!   Readln(S, ERROR := CONTINUE);      IF (Length(S) > 0) THEN !     IF (LowCase(S[1]) = 'y') THEN        ReadYes := TRUE;   Reset(INPUT);  END;   END.