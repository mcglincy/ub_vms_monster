[inherit('montype', 'monconst', 'monglobl', 'sys$library:starlet')]

MODULE MonEvent(input,output);

%include 'headers.txt'

[global]
procedure setallevent(var allstats : allmystats);
var
  earray : eventarray;
begin
  getevent(numeventrec, earray, false);
  allstats.stats.alleventnum := earray.point;
end;

[global]
procedure setevent(var allstats : allmystats);
var
  earray : eventarray;
begin
  getevent((allstats.stats.location mod (numeventrec-1))+1, earray, false);
  allstats.stats.eventnum := earray.point;
end;

[global]
procedure resetevent;
var
  earray : eventarray;
  myevent : integer;
begin
  getevent(numeventrec, earray, false);
  myevent := earray.point + 1;
  if myevent > numevents then myevent := 1;
end;

[GLOBAL]
PROCEDURE LogEvent(Send, SendLog , Act, Targ, TargLog, P1, P2  : INTEGER;
                   S : String; TheRoom : INTEGER; Emsg : ShortString := '';
                   P3 : INTEGER := 0; P4 : INTEGER := 0; P5 : INTEGER := 0;
                   P6 : INTEGER := 0; P7 : INTEGER := 0);
VAR
  earray : EventArray;
  eventrecnum : integer;

BEGIN
  IF Debug[DEBUG_LogEvent] THEN
  BEGIN
    Writeln('Send: ',Send:0,'SendLog : ',SendLog:0,' Act/Targ: ',Act:0,'/',Targ:0,
            ' P(1..2) ',P1:0,' ',P2:0,' Room: ',TheRoom:0);
    Writeln('String: ',S);
  END;

  if theroom = r_allrooms then    (* last record is for global events *)
    eventrecnum := numeventrec
  else
    eventrecnum := (theroom mod (numeventrec-1))+1;
  if getevent(eventrecnum, earray, false, true) then
  begin
    earray.point := earray.point + 1;
    if earray.point > numevents then earray.point := 1;
    earray.events[earray.point].Send     := Send;
    earray.events[earray.point].SendLog  := SendLog;
    earray.events[earray.point].Action   := Act;
    earray.events[earray.point].Targ     := Targ;
    earray.events[earray.point].TargLog  := TargLog;
    earray.events[earray.point].Param[1] := P1;
    earray.events[earray.point].Param[2] := P2;
    earray.events[earray.point].EParam[1] := P3;
    earray.events[earray.point].EParam[2] := P4;
    earray.events[earray.point].EParam[3] := P5;
    earray.events[earray.point].EParam[4] := P6;
    earray.events[earray.point].EParam[5] := P7;
    earray.events[earray.point].Msg	 := S;
    earray.events[earray.point].EMsg	 := Emsg;
    earray.events[earray.point].Loc	 := TheRoom;
    if (saveevent(eventrecnum, earray, false, true)) then ;
  end;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE TimeBufferEvent(TheEvent : AnEvent; VAR TimeEvent : TimeEventType);

VAR
  I : INTEGER := 1;
  Found : BYTE_BOOL := FALSE;

BEGIN
  WHILE (I <= MaxTimedEvents) AND (NOT Found) DO
  IF TimeEvent[I].Action = 0 THEN
  BEGIN
    TimeEvent[I] := TheEvent;
    Found := TRUE;
  END
  ELSE I := I + 1;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ClearTimedEvent(I : INTEGER; VAR TimeEvent : TimeEventType);
{Tells other people to get rid of i.e. trap in room}
BEGIN
  WITH TimeEvent[I] do
    LogEvent(Send, SendLog, E_CLEAR, Targ, TargLog, Param[1], Param[2],
             Msg, Loc);
END;

(* -------------------------------------------------------------------------- *)

END.
