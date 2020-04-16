[INHERIT ('MONCONST','MONGLOBL','MONTYPE')]

MODULE MonMove(OUTPUT);

%include 'headers.txt'

[external] PROCEDURE FollowMe(VAR AllStats : AllMyStats;
                              Dir : INTEGER); extern;

(* ----------------------------------------------------------------- *)
(* TakeToken reads in the current room, removes a player from it and *)
(* save the changes.                                                 *)
(* ----------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE TakeToken(RoomNo : INTEGER; Log : INTEGER);

VAR
  Loop : INTEGER;
  Here : Room;
BEGIN
  IF GetRoom(RoomNo, Here) THEN
  BEGIN
    FOR Loop := 1 TO MaxPeople DO
      IF Here.People[Loop].Kind = Log THEN
        Here.People[Loop].Kind := 0;
    SaveRoom(RoomNo, Here);
  END;
END;

(* ------------------------------------------------------------------------ *)
[EXTERNAL] FUNCTION PutRandomMonsterToken(Loc : INTEGER;
                                      RandType : INTEGER) : BYTE_BOOL; extern;
(* ------------------------------------------------------------------------ *)
(* Puttoken reads in the new room record and the new roomdesc. *)
(* ----------------------------------------------------------- *)

[GLOBAL]
FUNCTION PutToken(NewLoc : INTEGER; VAR HideLev : INTEGER; 
                  VAR AllStats : AllMyStats) : BYTE_BOOL;

 VAR
  I : INTEGER := 1;
  J, Z : INTEGER;
  Found : BYTE_BOOL := FALSE;
  Healing, MonsterNum : INTEGER;
  AnInt : IntArray;
  MaxHealth : INTEGER;
  FreeSlot : INTEGER := 0;
  Count : INTEGER := 0;
BEGIN
  PutToken := FALSE;
  IF GetRoom(NewLoc, Here, FALSE, TRUE) AND getroomdesc(NewLoc, heredesc) then
  BEGIN
    IF check_bit(HereDesc.SpcRoom, rm$b_lair) THEN
    BEGIN
      FOR I := 1 TO MAXPEOPLE DO
        IF Here.People[I].Kind <> 0 THEN Count := Count + 1;
      IF (Count = 0) THEN
        PutRandomMonsterToken(NewLoc, HereDesc.Mag[rm$b_lair]);
    END;
    FOR I := 1 TO MAXPEOPLE-1 DO
    BEGIN
      IF Here.People[I].Kind = AllStats.Stats.Log THEN
        Here.People[I].Kind := 0;
      IF (Here.People[I].Kind = 0) AND (FreeSlot = 0) then
        FreeSlot := I;
    END;
    IF FreeSlot <> 0 THEN
    BEGIN
      AllStats.Stats.Slot := FreeSlot;
      Here.People[FreeSlot].Kind := AllStats.Stats.Log; {sticks me in room}
      Here.People[FreeSlot].Name := AllStats.Stats.Name;
      Here.People[FreeSlot].Health := AllStats.Stats.Health;

      IF NOT(AllStats.Stats.Privd) AND (HideLev > 0) THEN
      BEGIN
        IF check_bit(HereDesc.SpcRoom, rm$b_nohide) THEN
        BEGIN
          HideLev := 0;
          Writeln('You are no longer hiding.');
        END
        ELSE
        IF (Rnd(100) > (AllStats.Stats.MoveSilent*2)) THEN
        BEGIN
          HideLev := 0;
          Writeln('You are no longer hiding.');
        END;
      END;
      Here.People[FreeSlot].Hiding := HideLev;

      IF SaveRoom(NewLoc, Here) THEN
      BEGIN
        PutToken := TRUE;
        AllStats.Stats.Location := NewLoc;
        SetEvent(AllStats);
        IF GetInt(N_LOCATION, AnInt) THEN 
        BEGIN
          Anint[AllStats.Stats.Log] := NewLoc;
          IF SaveInt(N_Location, AnInt) THEN;
        END;
        FOR J := 1 TO MaxExit DO
        BEGIN
          AllStats.Exit.FoundExits[J] := FALSE;
(*
          Temp := HereDesc.Exits[J].DoorEffect;
          EffectDecompress(Mag, Dir, Temp);
          IF  HereDesc.Exits[Dir].Kind = EK_GUARDED THEN
            AllStats.Exit.KilledGuardian[J] := FALSE
          ELSE
*)
            AllStats.Exit.KilledGuardian[J] := TRUE;
        END;
      END;
    END;  (* Could we find me a slot *)
  END;    (* Did we read in the room and roomdesc *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE XPoof(Loc : INTEGER; VAR AllStats : AllMyStats;
                PoofType : INTEGER := 0);

{ Pooftype of 0 : Norm }
{             1 : Don't log }

VAR
  OldSlot, TmpLoc : INTEGER;
  oldHidLev, HidLev : INTEGER;

BEGIN
  OldSlot := AllStats.Stats.Slot;
  TmpLoc := AllStats.Stats.Location;
  OldHidLev := Here.People[OldSlot].Hiding;
  TakeToken(TmpLoc, AllStats.Stats.Log);
  HidLev := OldHidLev;
  IF PutToken(Loc, HidLev, AllStats) THEN
  BEGIN
    LogEvent(OldSlot, AllStats.Stats.Log, E_POOFOUT, 0,0,
             0,0, AllStats.Stats.Name, TmpLoc, , OldHidLev, PoofType);
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_POOFIN, 0,0,
             0,0, AllStats.Stats.Name, Loc, , HidLev, AllStats.Stats.Health,
             0, PoofType);
    DoLook( ,AllStats);
  END
  ELSE
     Writeln('There is a crackle of electricity, but the poof fails.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DefaultFail(DescNum : INTEGER);

BEGIN
  IF IsDescription(DescNum) THEN
    PrintDesc(DescNum)
  ELSE
    Inform_noGo;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ExitFail(Dir : INTEGER; VAR AllStats : AllMyStats);

VAR
  Tmp : String;

BEGIN
  CASE HereDesc.Exits[Dir].Fail OF
    DEFAULT_DESC : BEGIN
		     IF (Here.ExitBlocked[Dir] > 0) THEN
                     BEGIN
			StartHighLight;
			Writeln('That exit is blocked.');
			StopHighLight;
		     END
		     ELSE
                     CASE HereDesc.Exits[Dir].Kind OF
                       5 : Writeln('There isn''t an exit there yet.');
                       6 : Writeln('You don''t have the power to go there.');
                       OTHERWISE DefaultFail(HereDesc.Exits[Dir].Fail);
                     END;
                   END;
    0 : ;
    OTHERWISE BlockSubs(HereDesc.Exits[Dir].Fail, AllStats.Stats.Name);
  END;
  IF Dir <> 0 THEN
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILGO, 0,0,
             Dir, HereDesc.OFail, AllStats.Stats.Name, AllStats.Stats.Location);
  Freeze(allstats.stats.movespeed/400, AllStats);
  IF DEBUG[DEBUG_ROOM] THEN
    IF AllStats.Stats.Privd THEN
      Writeln('Exit to: ', HereDesc.Exits[Dir].ToLoc:0, ' ',
              'Kind: ', HereDesc.Exits[Dir].Kind:0, ' ',
              'Effect: ', HereDesc.Exits[Dir].DoorEffect:0, ' ',
              'Hidden: ', HereDesc.Exits[Dir].Hidden:0, ' ',
              'ObjReq: ', HereDesc.Exits[Dir].ObjReq:0, ' ',
              'Alias: ', HereDesc.Exits[Dir].Alias, ' ',
              'ReqAlias: ', HereDesc.Exits[Dir].ReqAlias);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION DoExit(ExitSlot : INTEGER; VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Temp, Mag, Dir, DoorEffect : INTEGER;

  OrigSlot, TargSlot,
  OrigRoom, EnterSlot,
  TargRoom : INTEGER;

  DoaLook : BYTE_BOOL;
  S : String;
  WaitTime : REAL := 0.0;
  AnInt : IntArray;

  OldHide, HideLev : INTEGER;

  Log : INTEGER;
  Going : BYTE_BOOL := TRUE;

BEGIN
  DoExit := FALSE;
  IF AllStats.Stats.MoveSpeed > 0 THEN
    WaitTime := (AllStats.Stats.MoveSpeed/100);

  Temp := HereDesc.Exits[ExitSlot].DoorEffect;
  EffectDecompress(Mag, Dir, Temp);

  IF NOT AllStats.Exit.KilledGuardian[ExitSlot] THEN
  BEGIN
    Writeln ('Your way is blocked!');
    going := FALSE;
  END
  ELSE
  BEGIN
    BlockSubs(HereDesc.Exits[ExitSlot].Success, AllStats.Stats.Name);

    OrigSlot := AllStats.Stats.Slot;
    HideLev := Here.People[OrigSlot].Hiding;
    OldHide := HideLev;

    OrigRoom := AllStats.Stats.Location;
    TargRoom := HereDesc.Exits[ExitSlot].ToLoc;

    EnterSlot := HereDesc.Exits[ExitSlot].Slot;
    DoaLook := HereDesc.Exits[ExitSlot].AutoLook;

(* Start door effects *)
    CASE Dir OF
      EX_HEALTHLESS : BEGIN
        IF (AllStats.Stats.Health >= Mag) THEN
        BEGIN
          ExitFail(ExitSlot, AllStats);
          Writeln('You are too healthy to enter.');
          Going := FALSE;
        END;
      END;
      EX_WEALTH : BEGIN
        IF (AllStats.Stats.Wealth < -Mag) THEN
        BEGIN
          ExitFail(ExitSlot, AllStats);
          Writeln('Not enough money!');
          Going := FALSE;
        END
        ELSE
        BEGIN
          AllStats.Stats.Wealth := AllStats.Stats.Wealth + Mag;
          IF Mag > 0 THEN
            Writeln('You now have ',AllStats.Stats.Wealth:0,' wealth')
          ELSE
            Writeln('You just paid ',mag:0);
        END;
      END;
      EX_MANA : BEGIN
        AllStats.Stats.Mana := AllStats.Stats.Mana + Mag;
        Rectify(AllStats);
        IF Mag > 0 THEN
          Writeln('You now have ',AllStats.Stats.Mana:0,' mana');
        IF AllStats.Stats.Mana < 0 THEN
          AllStats.Stats.Mana := 0;
      END;
      EX_ALARMED : BEGIN
        S := AllStats.Stats.Name + ' set off an alarm ';
        CASE HereDesc.NamePrint OF
          1 : s := s + 'in';
          2 : s := s + 'at';
          3 : s := s + 'in the';
          4 : s := s + 'at the';
        END;
        S := S + ' ' + HereDesc.NiceName;
        LogEvent(0, AllStats.Stats.Log, E_ANNOUNCE, 0,0,0,0,
                 S, R_ALLROOMS);
      END;
      EX_CLASSRESET,
      EX_CLASSSET : BEGIN
        Write('You are now a ');
        PrintClass(Mag);
        AllStats.Stats.Class := Mag;
        AttribAssignValue(AllStats.Stats.Log, att_class, Mag);
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_CHANGE, 0, 
		AllStats.Stats.Log, 
		Att_class, 0, AllStats.Stats.name, R_ALLROOMS);

        IF NOT IsRandom(AllStats.Stats.Log) THEN
        BEGIN
          IF GetInt(N_CLASS, AnInt) THEN
          BEGIN
            AnInt[AllStats.Stats.Log] := Mag;
            IF SaveInt(N_CLASS, AnInt) THEN;
          END;
          ClassStats(AllStats);
          ForgetSpells(AllStats);
        END;
        IF Dir = EX_CLASSRESET THEN
          IF NOT IsRandom(AllStats.Stats.Log) THEN
          BEGIN
            ChangeExp(-AllStats.Stats.Experience,
                      AllStats.Stats.Log, AllStats.Stats.Experience);
            EquipmentStats(AllStats);
          END
          ELSE
              AllStats.Stats.Experience := 0;
      END;
      EX_EXP,EX_EXPSET,
      EX_EXPMODIFIED : BEGIN
        CASE Dir OF
          EX_EXP :
            IF NOT IsRandom(AllStats.Stats.Log) THEN
              ChangeExp(Mag, AllStats.Stats.Log, AllStats.Stats.Experience)
            ELSE
              AllStats.Stats.Experience := AllStats.Stats.Experience + Mag;
          EX_EXPSET :
            IF NOT IsRandom(AllStats.Stats.Log) THEN
              ChangeExp(Mag - AllStats.Stats.Experience,
                        AllStats.Stats.Log, AllStats.Stats.Experience)
            ELSE
              AllStats.Stats.Experience := Mag;
          EX_EXPMODIFIED :
            IF NOT IsRandom(AllStats.Stats.Log) THEN
              ChangeExp(Mag, AllStats.Stats.log, AllStats.Stats.Experience)
            ELSE
              AllStats.Stats.Experience := AllStats.Stats.Experience + Mag;
        END;
        IF NOT IsRandom(AllStats.Stats.Log) THEN
        BEGIN
          Rectify(AllStats);
          EquipmentStats(AllStats);
        END;
      END;
      EX_HEALTH : BEGIN
        AllStats.Stats.LastHit := 0;
        AllStats.Stats.LastHitString := 'a twist of fate';
        PoorHealth(-Mag, FALSE, FALSE, ,AllStats);
        IF NOT IsRandom(AllStats.Stats.Log) THEN
          Rectify(AllStats);
        IF AllStats.Stats.Health = AllStats.MyHold.MaxHealth THEN
          Writeln('You are fully healed.');
      END;
    END;  (* Case Statement *)
  END; (* guardian / else *)

  DoExit := going;
  IF going THEN
  BEGIN
(* end door effects *)

(* Are we going to the same room that we are in? *)
    IF (OrigRoom = TargRoom) THEN
    BEGIN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_ENTER, 0, 0,
               EnterSlot, Hidelev, AllStats.Stats.Name, TargRoom,,
               AllStats.Stats.Health, 0);
      LogEvent(OrigSlot, AllStats.Stats.Log, E_EXIT, 0,0,
               ExitSlot, HideLev, AllStats.Stats.Name, OrigRoom);
      IF (HideLev <> 0) THEN Writeln('You moved silently through the shadows.');
      IF DoaLook THEN DoLook(, AllStats);
    END
    ELSE
    BEGIN

(* Wait before we take ourself out of the old room *)
      Freeze(WaitTime, AllStats);

(* Did we move during the freeze? *)
      IF OrigRoom = AllStats.Stats.Location THEN
      BEGIN
        IF PutToken(TargRoom, HideLev, AllStats) THEN
        BEGIN
          FollowMe(Allstats, ExitSlot);
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_ENTER, 0, 0,
                   EnterSlot, Hidelev, AllStats.Stats.Name,
                   AllStats.Stats.Location, , AllStats.Stats.Health, 0);
          LogEvent(OrigSlot, AllStats.Stats.Log, E_EXIT, 0, 0, ExitSlot,
                   OldHide, AllStats.Stats.Name, OrigRoom);
          TakeToken(OrigRoom, AllStats.Stats.Log);
          IF (HideLev <> 0) THEN
            Writeln('You moved silently through the shadows.');
          IF DoALook THEN DoLook(, AllStats);
        END; {Token Made}
      END  (* IF False, we must have been moved out during the wait *)
    END;     (* We actually moved to a new room *)
  END;       (* were we able to move ''going = TRUE'' *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION CycleOpen : BYTE_BOOL;

VAR
  S : String;

BEGIN
  S := SysTime;
  CycleOpen := S[5] IN ['1','3','5','7','9'];
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ExitCase(Dir : INTEGER; VAR AllStats : AllMyStats) : BYTE_BOOL;

(* If dir is negative, we will assume that they did not go through the door *)
(* voluntarily.. i.e.  Pushed through by a spell *)

VAR
  Ty, Po : INTEGER;
  S : String;
  Ok : BYTE_BOOL := TRUE;

BEGIN
  ExitCase := FALSE;
  IF (Dir < 0) THEN
  BEGIN
    Dir := -Dir;
    IF (HereDesc.EXits[-Dir].ReqAlias) THEN
      Ok := FALSE;              (* Pushed through an alias exit *)
  END;
  CASE HereDesc.Exits[Dir].Kind OF
    EK_NoExit     : OK := FALSE;
    EK_Open       : ;
    EK_NeedKey    : IF NOT ObjHold(HereDesc.Exits[Dir].ObjReq, AllStats.MyHold) THEN
                      Ok := FALSE;
    EK_NeedNoKey  : IF ObjHold(HereDesc.Exits[Dir].ObjReq, AllStats.MyHold) THEN
                      Ok := FALSE;
    EK_RandomFail : IF NOT(RND(100) < 34) THEN
                      Ok := FALSE;  
    EK_Acceptor   : Ok := FALSE;
    EK_NeedObject : IF NOT ObjHold(HereDesc.Exits[Dir].ObjReq, AllStats.MyHold) THEN
                      Ok := FALSE;
    EK_OpenClose  : IF NOT CycleOpen THEN
                      Ok := FALSE;
    EK_Password   : BEGIN
                      GrabLine('Enter password: ', S, AllStats, FALSE);
                      IF NOT(S = HereDesc.Exits[Dir].Alias) THEN
                        Ok := FALSE;
                    END;
    OTHERWISE OK := FALSE;
  END;
  IF Ok THEN
    ExitCase := DoExit(Dir, AllStats)
  ELSE
    ExitFail(Dir, AllStats);
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoBlock(S : String ; VAR AllStats : AllMyStats);

VAR
  Dir, Slot, BlockLoc : INTEGER;

BEGIN
  Slot := AllStats.Stats.Slot;

  IF LookupDir(Dir, S) THEN
  BEGIN
    IF (HereDesc.Exits[Dir].ToLoc <> 0) AND (HereDesc.Exits[Dir].Kind <> 0) THEN
    BEGIN
      IF (TestBit(Here.ExitBlocked[Dir],Slot) = 1 ) THEN
      BEGIN
        Writeln('%EXIT-BLKTWC: Slot bit already set. Clearing...');
        ClearBit(Here.ExitBlocked[Dir], Slot);
        SaveRoom(AllStats.Stats.Location, Here);
      END
      ELSE
      BEGIN
        IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
          Writeln('You can''t be hidden while blocking!')
        ELSE
        BEGIN
          SetBit(Here.ExitBlocked[Dir], Slot);
          SaveRoom(AllStats.Stats.Location, Here);
          Writeln('You block the exit with your mighty body.');
          LogEvent(Slot,AllStats.Stats.Log,E_BLOCKEXIT,0,0,Dir,
                   Here.ExitBlocked[Dir],'blocks',
                   AllStats.Stats.Location);
          AllStats.Exit.Blocking := Dir;

          (* We save the location incase you are killed while in *)
          (* the GrabLine routine.. that way you dont miff up    *)
          (* the room record that you 'poof' into after dying... *)

          BlockLoc := AllStats.Stats.Location;
          REPEAT
            GrabLine('Type exit to continue: ', S, AllStats);
          UNTIL (lowcase(trim(bite(S))) = 'exit');
          AllStats.Exit.Blocking := 0;

          (* Now we only clean up if you are still in the same room *)
          (* Otherwise DoDie() is expected to do the cleanup work   *)

          IF (AllStats.Stats.Location = BlockLoc) THEN
          BEGIN
            ClearBit(Here.ExitBlocked[Dir], Slot);
            SaveRoom(AllStats.Stats.Location, Here);
            LogEvent(Slot,AllStats.Stats.Log,E_BLOCKEXIT,0,0,Dir,
                     Here.ExitBlocked[Dir],'is no longer blocking',
                     AllStats.Stats.Location);
            IF AllStats.Stats.Privd THEN
              Writeln('++[Delay: ', AllStats.Stats.MoveSpeed:3,
                      ' usecs]++');
            Freeze((AllStats.Stats.MoveSpeed / 100), AllStats);
          END; (* Were we in the same place that we started blocking *)
        END;  (* Hidden??? *)
      END;   (* Testbit set prematurely??? *)
    END
    ELSE
      Writeln('Doesnt exist.')
  END
  ELSE
    Writeln('Invalid direction.');
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoUnBlock(S : String ; VAR AllStats : AllMyStats);

(* this is a priv'd command that will mark an exit as totally unblocked *)
(* the people who are in the blocking routine will remain in it.. hehe  *)
VAR
  Dir, Slot : INTEGER;
  Loop, Block : INTEGER;

BEGIN
  Slot := AllStats.Stats.Slot;

  IF LookupDir(Dir, S) THEN
  BEGIN
    Block := Here.ExitBlocked[Dir];
    FOR Loop := 1 TO MaxExit DO
    BEGIN
      IF Here.People[Loop].Kind = 0 THEN
        ClearBit(Block, Loop);
    END;
    IF AllStats.Stats.Privd THEN Block := 0;
    IF Here.ExitBlocked[Dir] <> Block THEN
    BEGIN
      Here.ExitBlocked[Dir] := Block;
      Writeln('Fixing exit.');
      SaveRoom(AllStats.Stats.Location, Here);
    END;
  END
  ELSE
    Writeln('Invalid direction.');
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION DoGo(S : string; Verb : BYTE_BOOL := TRUE;
              VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Dir : INTEGER;
  Good : BYTE_BOOL;
  Rand : INTEGER;

BEGIN
  Good := TRUE;
  Rand := RND(100);
  DoGo := FALSE;
  IF WhichDir(Dir, S) THEN
  BEGIN
    IF (Rand >= (Allstats.Stats.MoveSilent*2)) THEN
      Good := CheckHide(AllStats.Stats);
    IF Good THEN
      IF (HereDesc.Exits[Dir].ToLoc <> 0) AND 
	(Here.ExitBlocked[Dir] = 0) THEN
        DoGo := ExitCase(Dir, AllStats)
      ELSE
        ExitFail(Dir, AllStats)
    ELSE
      ExitFail(Dir, AllStats);
  END
  ELSE
    ExitFail(Dir, AllStats);
END;

(* -------------------------------------------------------------------------- *)

END.
