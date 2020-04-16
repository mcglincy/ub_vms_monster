[INHERIT ('MONCONST','MONTYPE','MONGLOBL')]

MODULE MonRooms(OUTPUT);

%include 'headers.txt'

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION LookupRoomName(S : String; VAR N : INTEGER;
                        Exact : BYTE_BOOL; Silent : Byte_Bool) : BYTE_BOOL;
VAR
  nam : longnamerec;
  good : byte_bool;
  Ind : IndexRec;
  found : byte_bool;
  loop, maybe, poss : integer;
BEGIN
  found := false;
  loop := 0;
  maybe := 0;
  good := getlongname(l_na_roomnam, nam) and getindex(i_room, ind);
  if (good) then
    found := lookupnameraw(nam.idents, ind, n, s, exact);
  if not(found) and not(silent) then
    writeln('I could not find room ', S, '.');
  lookuproomname := found;
END;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION OwnTrans(S : String) : String;

BEGIN
  IF S = '' THEN
    OwnTrans := '<public>'
  ELSE
  IF S = '*' THEN
    OwnTrans := '<disowned>'
  ELSE
    OwnTrans := S;
END;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
PROCEDURE PrintParticle(NamePrint : INTEGER; S : String ; 
			AllStats : AllMyStats;
			Hiding : BYTE_BOOL := FALSE);
BEGIN
  CASE NamePrint OF
    0: ;
    1: Write('You''re in ');
    2: Write('You''re at ');
    3: Write('You''re in the ');
    4: Write('You''re at the ');
    5: Write('You''re on ');
    6: Write('You''re on the ');
    OTHERWISE Writeln('Room name printing is damaged.');
  END;
  IF NamePrint <> 0 THEN
    Write(S);
  WITH AllStats.Stats DO
  BEGIN
    IF (Brief AND NOT Hiding AND NOT Privd) OR (Brief AND Hiding AND Privd) 
      OR (Brief AND Privd) THEN
	PrintBriefExits;
(*        ShowExits(AllStats.Exit.FoundExits, AllStats.MyHold, TRUE) *)
  END;
  WriteLn; 
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PrintBriefExits;
VAR
  i : INTEGER;
  found : BYTE_BOOL := FALSE;
BEGIN
  Write(' (');
  FOR i := 1 to MaxExit DO
    IF (HereDesc.Exits[i].ToLoc <> 0) AND (HereDesc.Exits[i].Hidden = 0) 
      AND (HereDesc.Exits[i].Alias = '') THEN
    BEGIN
      CASE HereDesc.Exits[i].Kind OF
        1,3,4,5,7: BEGIN
                  Write(DirectShort[i]);
                  found := TRUE;
                 END;
      END;
    END;
  IF NOT found THEN Write('none');
  WriteLn(')');
END;


[GLOBAL]
PROCEDURE ExitDefault(Dir, Kind, Toloc : INTEGER; VAR Nam : LongNameRec);

VAR
  RoomName : ShortString;

BEGIN
  IF ((Toloc > 0) AND (ToLoc < MaxRoom)) THEN
    RoomName := Nam.Idents[ToLoc]
  ELSE
    RoomName := 'faulty';
  CASE Kind OF
      2 : Writeln('There is a locked door leading ',Direct[dir],' to the ',roomname,'.');
      5 : CASE Dir OF
            north,
            south,
            east,
            west : Writeln('A note on the ',direct[dir],' wall says "Your exit here."');
            up   : Writeln('A note on the ceiling says "Your exit here."');
            down : Writeln('A note on the floor says "Your exit here."');
          END;
       OTHERWISE IF Dir < 5 THEN
                   Writeln('To the ',Direct[Dir],' is ',roomname,'.')
                 ELSE
                   Writeln('The ',roomname,' is ',direct[dir],' from here.');
  END; (* CASE *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ShowExits(VAR FoundExit : FoundExitType; VAR MyHold : HoldObj;
			ShortHand : BYTE_BOOL := FALSE);

(* Routine called when a LOOK is done - or someone enters a new room *)

VAR
  I : INTEGER;
  One, CanSee : BYTE_BOOL;
  Nam : LongNameRec;

BEGIN
  One := FALSE;
  IF ShortHand THEN Write('  [ ');
  IF GetLongName(l_NA_RoomNam, Nam) THEN
  BEGIN
    FOR I := 1 TO MaxExit DO
    BEGIN
      IF (HereDesc.Exits[I].Toloc <> 0) OR (HereDesc.Exits[I].Kind = EK_ACCEPTOR) THEN
      BEGIN
        IF (HereDesc.Exits[I].Hidden = 0) OR (FoundExit[I]) THEN
          CanSee := TRUE
        ELSE
          CanSee := FALSE;
        IF HereDesc.Exits[I].Kind = EK_NEEDOBJECT THEN
        BEGIN
          IF ObjHold(HereDesc.Exits[I].ObjReq, MyHold) THEN
            CanSee := TRUE
          ELSE
            CanSee := FALSE;
        END;
        IF CanSee THEN
        BEGIN
          IF (HereDesc.Exits[I].ExitDesc = DEFAULT_DESC) AND NOT ShortHand THEN
          BEGIN
            ExitDefault(I, HereDesc.Exits[I].Kind, 
			Heredesc.Exits[I].Toloc, Nam);
            One := TRUE;
          END
          ELSE
            IF HereDesc.Exits[I].ExitDesc <> 0 THEN
            BEGIN
              IF NOT ShortHand THEN
                PrintDesc(HereDesc.Exits[I].ExitDesc)
	      ELSE
                Write(UpCase(DirectShort[I]),' ');
              One := TRUE;
           END;
        END;
      END;
    END;
    IF ShortHand THEN Write(']');
    IF One THEN Writeln;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ListRooms(S : ShortString; Indx : IndexRec; Own : LongNameRec;
                    Nam : LongNameRec);

VAR
  First : BYTE_BOOL;
  I, J, Posit, NumRooms : INTEGER;

BEGIN
  NumRooms := 0;
  First := TRUE;
  Posit := 0;
  FOR I := 1 TO Indx.Top DO
  BEGIN
    IF (NOT Indx.free[I]) AND (Own.Idents[I] = S) THEN
    BEGIN
      Numrooms := NumRooms + 1;
      IF Posit = 3 THEN
      BEGIN
        Posit := 0;
        Writeln;
      END
      ELSE
        Posit := Posit + 1;
      IF First THEN
      BEGIN
        First := FALSE;
        Writeln(OwnTrans(s),':');
      END;
      WriteNice(Nam.idents[i],20);
    END;
  END;
  IF Posit <> 3 THEN
    Writeln;
  IF First THEN
    Writeln('No rooms owned by ',OwnTrans(s))
  ELSE
  BEGIN
    Writeln;
    Writeln('Total rooms: ',NumRooms:0);
    Writeln;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ListAllRooms(Indx : IndexRec; Own, Nam : LongNameRec);

VAR
  I, J : INTEGER;
  Tmp : PACKED ARRAY [1..MaxRoom] OF BYTE_BOOL;

BEGIN
  Tmp := Zero;
  ListRooms('', Indx, Own, Nam);    { public rooms first }
  ListRooms('*', Indx, Own, Nam);  { disowned rooms next }
  FOR I := 1 TO Indx.Top DO
  BEGIN
    IF NOT(Indx.Free[I]) AND NOT(Tmp[I]) and
       (Own.Idents[I] <> '') AND (Own.Idents[I] <> '*') THEN
    BEGIN
      ListRooms(Own.Idents[I], Indx, Own, Nam);  { player rooms }
      FOR J := 1 to Indx.Top DO
        IF Own.Idents[J] = Own.Idents[I] THEN
          Tmp[J] := TRUE;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoRooms(S : String; VAR AllStats : AllMyStats);

VAR
  Cmd : String;
  Id : VeryShortString;
  ListAll : BYTE_BOOL;
  Indx : IndexRec;
  Nam, Own : LongNameRec;

BEGIN
  IF GetLongName(l_na_roomnam, Nam) THEN
  BEGIN
    IF GetLongName(l_na_roomown, Own) THEN
    BEGIN
      IF GetIndex(I_Room, Indx) THEN
      BEGIN
        ListAll := FALSE;
        S := Lowcase(S);
        Cmd := Bite(S);
        IF Cmd = '' THEN Id := AllStats.Stats.UserId
        ELSE
        IF Cmd = 'public' THEN id := ''
        ELSE
        IF Cmd = 'disowned' THEN id := '*'
        ELSE
        IF Cmd = '<public>' THEN id := ''
        ELSE
        IF Cmd = '<disowned>' THEN id := '*'
        ELSE
        IF Cmd = '*' THEN ListAll := TRUE
        ELSE
        IF Length(Cmd) > VeryShortLen THEN
          Id := SubStr(Cmd,1,VeryShortLen)
        ELSE Id := Cmd;
        IF ListAll THEN
          IF AllStats.Stats.Privd THEN
            ListAllRooms(Indx, Own, Nam)
          ELSE Writeln('You may not obtain a list of all the rooms.')
        ELSE
          IF AllStats.Stats.Privd OR (AllStats.Stats.Userid = Id) OR
            (Id = '') OR (Id = '*') THEN
            ListRooms(Id, Indx, Own, Nam)
          ELSE
            Writeln('You may not list rooms that belong to another player.');
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

END.
