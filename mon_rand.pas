[INHERIT('MONCONST','MONTYPE','MONGLOBL','sys$library:Starlet',
         'sys$library:pascal$lib_routines')]
         
PROGRAM Randoms(OUTPUT);

%include 'headers.txt'

(* -------------------------------------------------------------------------- *)

TYPE
  hateptr = ^haterec;
  haterec = RECORD
    log : integer;
    times : integer;
    killed : integer;
    died : integer;
    next : hateptr;
  END;

  wantptr = ^wantrec;
  wantrec = RECORD
    objnum : integer;
    times : integer;
    next : wantptr;
  end;

  hymie = RECORD
    hate : hateptr;
    want : wantptr;
    all : allmystats;
  END;

  RoomListPtr = ^RoomList;
  RoomList = RECORD        (* A listing of rooms a certain distance from *)
    DirFrom : INTEGER;     (* How did I get here (i.e. What direction) *)
    RoomNumber : INTEGER;  (* our origination room *)
    Next : RoomListPtr;    (* Joined in a linked list *)
    Parent : RoomListPtr;  (* This Nodes parent in the tree *)
    Children : ARRAY[1..MaxExit] OF RoomListPtr;
  END;

  ExitType = RECORD
    Where : INTEGER;
    Kind : INTEGER;
    Alias : String;
  END;

  RoomType = RECORD     (* A listing of all of the rooms *)
    Used : BYTE_BOOL;
    Exits : ARRAY [1..MaxExit] of ExitType;
  END;
  AllRoomType = ARRAY[1..MaxRoom] of RoomType;

(* -------------------------------------------------------------------------- *)

VAR
  Seed : [EXTERNAL] UNSIGNED;
  RDEBUG : BYTE_BOOL := FALSE;
(*  GlobalRandoms : ARRAY[1..100] OF RandRec; *)
(*  Here : Room; *)
  Passed : String;
  RandomNumber : INTEGER;
  Status : UNSIGNED;
  AllRooms : AllRoomType;

(* ======================================================================== *)
(* Section header: Smart movement for randoms.                              *)
(* ======================================================================== *)

FUNCTION ReadRooms(VAR Rooms : AllRoomType) : BYTE_BOOL;

VAR
  Index : IndexRec;
  SomeRoom : RoomDesc;
  ExitNum : INTEGER;
  Status : BYTE_BOOL;
  Loop : INTEGER;

BEGIN
  Writeln('Reading in rooms...');
  Status := GetIndex(I_ROOM, Index);
  IF Status THEN
  BEGIN
    FOR Loop := 1 TO Index.Top DO
      IF NOT Index.Free[Loop] THEN
      BEGIN
        Rooms[Loop].Used := FALSE;
        IF GetRoomDesc(Loop, SomeRoom) THEN
          FOR ExitNum := 1 TO MaxExit DO
          BEGIN
            Rooms[Loop].Exits[ExitNum].Where := SomeRoom.Exits[ExitNum].ToLoc;
            Rooms[Loop].Exits[ExitNum].Alias := SomeRoom.Exits[ExitNum].Alias;
            Rooms[Loop].Exits[ExitNum].Kind := SomeRoom.Exits[ExitNum].Kind;
          END
        ELSE
          Rooms[Loop].Used := TRUE;
      END
      ELSE
         Rooms[Loop].Used := TRUE;
    Writeln('All rooms read in.');
  END
  ELSE
    Writeln('Error reading in from room file.');
  ReadRooms := Status;
END;

(* ======================================================================== *)

PROCEDURE AddToNewList(VAR NewList : RoomListPtr; VAR OldList : RoomListPtr;
                       ThisRoom : INTEGER; DirFrom : INTEGER; Dest : INTEGER);

VAR
  Dummy : RoomListPtr;
  Loop : INTEGER;

BEGIN
  NEW(Dummy);
  Dummy^.RoomNumber := Dest;
  Dummy^.DirFrom := DirFrom;
  Dummy^.Parent := OldList;
  Dummy^.Next := NewList;
  FOR Loop := 1 TO MaxExit DO
    Dummy^.Children[Loop] := NIL;
  IF OldList = NIL THEN
    OldList := Dummy;
  IF DirFrom <> 0 THEN
    OldList^.Children[DirFrom] := Dummy;
  NewList := Dummy;
END;

(* ======================================================================== *)

FUNCTION CanPass(ExitKind : INTEGER; Privd : BYTE_BOOL := FALSE) : BYTE_BOOL;

BEGIN
  CASE ExitKind OF
    EK_NoExit : CanPass := FALSE;
    EK_Open : CanPass := TRUE;
    EK_NeedKey : CanPass := FALSE;
    EK_NeedNoKey : CanPass := TRUE;
    EK_RandomFail : CanPass := TRUE;
    EK_Acceptor : CanPass := FALSE;
    EK_NeedObject : CanPass := FALSE;
    EK_OpenClose : CanPass := FALSE;
    EK_Password : CanPass := FALSE;
    Otherwise CanPass := FALSE;
  END;
END;

(* ======================================================================== *)

PROCEDURE KillTree(VAR List : RoomListPtr);
VAR
  Loop : INTEGER;
BEGIN
  IF List <> NIL THEN
  BEGIN
    FOR Loop := 1 TO MaxExit DO
      KillTree(List^.Children[Loop]);
    DISPOSE(List);
  END;
END;

(* ======================================================================== *)

FUNCTION GetNextMove(Start : INTEGER; VAR List : RoomListPtr) : INTEGER;
BEGIN
  IF List = NIL THEN
    GetNextMove := 0
  ELSE
  BEGIN
    IF (List^.Parent^.RoomNumber = Start) THEN
      GetNextMove := List^.DirFrom
    ELSE
      GetNextMove := GetNextMove(Start, List^.Parent);
  END;
END;

(* ======================================================================== *)

FUNCTION FindShortestPath(Start, Finish : INTEGER;
                          VAR Next : INTEGER) : INTEGER;

VAR
  Top, OldList, NewList : RoomListPtr;
  Rooms : AllRoomType;
  Found : BYTE_BOOL;
  Loop : INTEGER;
  Dest : INTEGER;
  S : String;
  Count : INTEGER;
BEGIN
  Next := -1;
  FindShortestPath := -1;
  Count := 0;
  NewList := NIL;
  OldList := NIL;
  Rooms := AllRooms;
  Rooms[Start].Used := TRUE;
  AddToNewList(NewList,OldList,Start,0,Start);
  Top := NewList;
  Found := Start = Finish;
  WHILE ((OldList <> NIL) AND (NOT FOUND)) DO
  BEGIN
    NewList := NIL;
    WHILE ((OldList <> NIL) AND (NOT Found)) DO
    BEGIN
      Loop := 1;
      WHILE ((Loop <= MaxExit) AND (NOT Found)) DO
      BEGIN
        Dest := Rooms[OldList^.RoomNumber].Exits[Loop].Where;
        IF (Dest <> 0) THEN
        BEGIN
          IF (NOT Rooms[Dest].Used) THEN
          BEGIN
            IF CanPass(Rooms[Oldlist^.RoomNumber].Exits[Loop].Kind) THEN
            BEGIN
              IF (Dest = Finish) THEN
                Found := TRUE;
              AddToNewList(Newlist, Oldlist, Dest, Loop, Dest);
              Rooms[Dest].Used := TRUE;
            END;
          END;
        END;
        IF NOT Found THEN Loop := Loop + 1;
      END;   (* While there is still an exit left *)
      IF NOT Found THEN
        OldList := OldList^.Next;
    END;   (* While there is something left in the list and we are not done *)
    Count := Count + 1;

    IF NOT Found THEN OldList := NewList
    ELSE OldList := OldList^.Children[Loop];
  END;
  IF Found THEN
  BEGIN
    IF Count > 0 THEN Next := GetNextMove(Start, OldList)
    ELSE Next := -2;
    FindShortestPath := Count;
  END;
  KillTree(Top);
END;

(* ======================================================================== *)

PROCEDURE ActSearch(Slot, Targ : INTEGER; VAR Here : Room;
                    VAR AllStats : AllMyStats);

VAR
  Tries, SSlot : INTEGER;
  Found : BYTE_BOOL;
BEGIN
  IF (Here.People[AllStats.Stats.Slot].Hiding = 0) THEN
  BEGIN
    Tries := 0;
    REPEAT
      Tries := Tries + 1;
      SSlot := RND(10);
      Found := (Here.People[SSlot].Kind <> 0) AND
               (Here.People[SSlot].Hiding > 0) AND
               (RND(MaxHide) >= Here.People[SSlot].Hiding);
      IF Found THEN 
      BEGIN
        Here.People[SSlot].Hiding := 0;
        IF SaveRoom(AllStats.Stats.Location, Here) THEN
          LogEvent(AllStats.Stats.Slot, 0, E_FOUNDYOU, SSlot, Targ,
                 0,0, AllStats.Stats.Name, AllStats.Stats.Location);
      END;
    UNTIL Found OR (Tries > 10);
    Allstats.Tick.TkEvent := GetTicks + ROUND(AllStats.Stats.MoveSpeed/10);
  END;
  IF (NOT Found) THEN
    LogEvent(AllStats.Stats.Slot, 0, E_SEARCH, 0,0, 0,0,
             AllStats.Stats.Name, AllStats.Stats.Location);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActAttack(Slot, Targ : INTEGER; VAR Here : Room;
                    VAR AllStats : AllMyStats);

(* In this future, this should be modified to use the routines from *)
(* monattk *)

VAR
  Damage : INTEGER;
  Weapon : String := 'claws';

BEGIN
  Damage := AllStats.MyHold.BaseDamage + RND(AllStats.MyHold.RandomDamage);
  IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
  BEGIN
    Here.People[AllStats.Stats.Slot].Hiding := 0;
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0,0, 0,0, 'Surprise!',
             AllStats.Stats.Location);
    Damage := AllStats.MyHold.BaseDamage + AllStats.MyHold.RandomDamage;
  END;
  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_ATTACK, Slot, Targ,
           Damage, 0, Weapon, AllStats.Stats.Location);
  Allstats.Tick.TkEvent := GetTicks + ROUND(AllStats.Stats.AttackSpeed/10);
END;

(* -------------------------------------------------------------------------- *)

FUNCTION LookUpLog(Log : INTEGER; Here : Room) : INTEGER;

VAR
  Loop : INTEGER;
  Temp : INTEGER := 0;

BEGIN
  FOR Loop := 1 TO MaxPeople DO
   IF Here.People[Loop].Kind = Log THEN
     IF Temp = 0 THEN
       Temp := Loop;
  LookupLog := Temp;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActFighter(VAR Here : Room; Slot : INTEGER; Targ : INTEGER;
                     VAR AllStats : AllMyStats);

BEGIN
  IF Slot <> 0 THEN
    IF Here.People[Slot].Hiding > 0 THEN
      ActSearch(Slot, Targ, Here, AllStats)
    ELSE
      ActAttack(Slot, Targ, Here, AllStats);
END;

(* -------------------------------------------------------------------------- *)

FUNCTION IsPlaying(Log : INTEGER) : BYTE_BOOL;
VAR
  Indx : IndexRec;
BEGIN
  IF GetIndex(I_ASLEEP, Indx) THEN
    IsPlaying := NOT Indx.Free[Log]
  ELSE
    IsPlaying := FALSE;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActMonster(Targ : INTEGER; Dir : INTEGER; VAR AllStats : AllMyStats);

VAR
  Here : Room;
  HereDesc : RoomDesc;
  Loc : IntArray;
  Slot : INTEGER;
  Next : INTEGER;
  Num : INTEGER;

BEGIN
  IF Targ = 0 THEN
  BEGIN
    CASE AllStats.Stats.Group OF
      OTHERWISE    AllStats.Tick.TkEvent := GetTicks + 20;
    END;
  END
  ELSE
  BEGIN
    IF GetInt(N_LOCATION, Loc) THEN
    BEGIN
      IF Loc[Targ] = AllStats.Stats.Location THEN
      BEGIN
        IF GetRoom(AllStats.Stats.Location, Here) THEN
        BEGIN
          Slot := LookupLog(Targ, Here);
          CASE AllStats.Stats.Group OF
            RM_FIGHTER : ActFighter(Here, Slot, Targ, AllStats);
            OTHERWISE    ActFighter(Here, Slot, Targ, AllStats);
          END;
        END;
      END
      ELSE
      BEGIN
        IF Dir > 0 THEN
        BEGIN
          IF GetRoom(AllStats.Stats.Location, Here) AND
             GetRoomDesc(AllStats.Stats.Location, HereDesc) THEN
            DoGo(Direct[Dir], , AllStats);
        END;
      END;
    END;
  END;
END;

(* ------------------------------------------------------------------------ *)
(* ------------------------------------------------------------------------ *)
(* Following is the code to determine a randoms target.                     *)
(* AddTarget adds a person to a Randoms Hate List.                          *)
(* ------------------------------------------------------------------------ *)

PROCEDURE AddTarget(VAR This : Hymie; Log : INTEGER);
VAR
  Walk, Back : hateptr;
  Found, Done : BYTE_BOOL;
BEGIN
  Walk := This.Hate;
  Back := NIL;
  Done := Walk = NIL;
  Found := FALSE;
  WHILE (NOT DONE) DO
  BEGIN
    IF Walk^.Log = Log THEN
    BEGIN
     Done := TRUE;
     Found := TRUE;
     Walk^.Times := Walk^.Times + 1;
    END
    ELSE
    BEGIN
      Back := Walk;
      Walk := Walk^.Next;
    END;
    IF Walk = NIL THEN Done := TRUE;
  END;
  IF (NOT FOUND) THEN
  BEGIN
    New(Walk);
    Walk^.Next := NIL;
    Walk^.Log := Log;
    Walk^.Times := 1;
    IF Back = NIL THEN
      This.Hate := Walk
    ELSE
      Back^.Next := Walk;
  END;
END;

(* ------------------------------------------------------------------------ *)
(* Pick a target for this random, given his hate list.                      *)
(* ------------------------------------------------------------------------ *)

FUNCTION PickTarget(This : Hymie; VAR Dir : INTEGER) : INTEGER;
VAR
  temp : hateptr;
  level, dist : integer;
  num, next, hate, times, loop : integer;
  asleep : indexrec;
  where : intarray;
  me : integer;

BEGIN
  me := this.all.stats.log;
  GetIndex(I_ASLEEP, Asleep);
  GetInt(N_LOCATION, Where);
  hate := 0;
  level := -1;
  dist := 100;
  for loop := 1 to asleep.top do
  begin
    if ((not (asleep.free[loop])) and (loop <> me)) then
    begin
      temp := this.hate;
      times := 0;
      while temp <> nil do
      begin
        if (temp^.log = loop) then
          times := temp^.times;
        temp := temp^.next;
      end;
      num := FindShortestPath(this.all.stats.location, where[loop], Next);
      if (num >= 0) THEN
        if (num < dist) then
(*        if times > level then *)
        begin
          dist := num;
          hate := loop;
          level := times;
          dir := next;
        end;
    end;
  end;
  picktarget := hate;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE HandEvent(e : anevent; var a : hymie);
VAR
  TEMPI : INTEGER;

BEGIN
  CASE e.action OF
    E_ATTACK:
      IF e.Targ = a.all.stats.slot THEN
      BEGIN
        Writeln('Someone tried to hit me! (', e.SendLog:0, ')');
        AddTarget(a, e.SendLog);
        a.All.Stats.LastHit := e.sendlog;
        a.All.Stats.LastHitString := here.people[e.send].name+'''s '+e.msg;
        tempi := a.all.stats.deaths;
        TakeHit(e.param[1], TRUE, a.all);
        if (tempi <> a.all.stats.deaths) then begin
          a.all.stats.wealth := a.all.stats.bank;
          writeln('I died...!!!!');
        end;
      END
      ELSE
        Writeln('Someone hit someone else..(', e.SendLog:0, ')->(',
                e.TargLog:0, ')');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ReadEvent(var a : hymie);

VAR
  ea : eventarray;
  slot, myev : integer;

BEGIN
  IF GetTicks >= a.all.tick.tkrandomevent THEN
  BEGIN
    a.all.tick.tkrandomevent := a.all.tick.tkrandomevent + 40;
    RndEvent(a.all);
    TimeUnwho(a.all.Stats.Log, a.all.stats.location, FALSE);
  END;
  slot := a.all.stats.location mod (numeventrec-1) + 1;
  if (getevent(slot, ea, false)) then
  begin
    myev := a.all.stats.eventnum;
    while ((ea.point <> a.all.stats.eventnum) and (myev = a.all.stats.eventnum)) do
    begin
      a.all.stats.eventnum := a.all.stats.eventnum + 1;
      myev := myev + 1;
      if (myev > numevents) then
        myev := 1;
      if a.all.stats.eventnum > numevents then
        a.all.stats.eventnum := 1;
      IF (ea.events[a.all.stats.eventnum].Loc = A.all.Stats.Location) AND
         (ea.events[a.all.stats.eventnum].SendLog <> A.all.stats.Log) AND
        ((ea.events[a.all.stats.eventnum].TargLog = A.all.Stats.Log) or
         (ea.events[a.all.stats.eventnum].TargLog = 0)) THEN
      BEGIN
        handevent(ea.events[a.all.stats.eventnum], a);
      END;
    end;
  end;
END;

(* -------------------------------------------------------------------------- *)

VAR
  TimerContext : UNSIGNED := 0;

PROCEDURE SetupGuts;
BEGIN
  LIB$INIT_TIMER(TimerContext);
  Seed := Clock;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE MoveRandoms(User : String := 'orc');
VAR
  this : hymie;
  NextEvent : INTEGER;
  Targ, ack : integer;
  Dir : INTEGER;

BEGIN
  This.All.Stats.Log := -1;
  Setup_Guts;
  Finish_guts;
  Init(This.All);
  Writeln('Entered in Random Playing mode.');
  NextEvent := MAXINT;
  This.All.Stats.Name := user;
  This.All.Stats.Userid := user;
  IF ReadRooms(AllRooms) THEN
  BEGIN
    IF EnterUniverse(, This.All) THEN;
    This.Hate := NIL;
    This.Want := NIL;
    ack := 0;
    This.All.Stats.Brief := TRUE;
    REPEAT
      IF GetTicks > This.All.Tick.TkEvent THEN
      BEGIN
        Targ := PickTarget(This, Dir);
        ActMonster(Targ, Dir, This.All);
        ReadEvent(This);
      END;
      Wait((This.All.Tick.TkEvent-GetTicks)/10);
    UNTIL FALSE;
  END;
END;

(* -------------------------------------------------------------------------- *)

BEGIN
  Status := LIB$Get_foreign(Passed.Body,,Passed.Length);
  IF NOT ODD(Status) THEN
    LIB$SIGNAL(Status);
  Passed := lowcase(Passed);
  if (passed.length = 0) THEN MoveRandoms
  else MoveRandoms(passed);
END.
