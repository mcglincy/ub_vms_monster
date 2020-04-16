[INHERIT ('MONCONST', 'MONTYPE', 'MONGLOBL')]

MODULE MonSpell(OUTPUT);

%include 'headers.txt'

[GLOBAL]
PROCEDURE ReadInAllSpells;

VAR
  Indx : IndexRec;
  Loop : INTEGER;

BEGIN
  IF GetIndex(I_Spell, Indx) THEN
  BEGIN
    FOR Loop := 1 TO Indx.Top DO
    IF NOT(Indx.Free[Loop]) THEN
      IF NOT(GetSpell(Loop, GlobalSpells[Loop])) THEN
        GlobalSpells[Loop] := Zero;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoUnHide(Slot : INTEGER; RoomNum : INTEGER);

BEGIN
  IF Here.People[Slot].Hiding > 0 THEN
  BEGIN
    LogEvent(Slot, Here.People[Slot].Kind, E_UNHIDE, 0,0, 0,0,
             Here.People[Slot].Name,RoomNum);
    Here.People[Slot].Hiding := 0;
    IF SaveRoom(RoomNum, Here) THEN
      Writeln('You are no longer hiding.');
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION MakeSavingThrow(S : String; MyExperience : INTEGER;
                         MySlot : INTEGER; Location : INTEGER) : BYTE_BOOL;

VAR
  ChanceToSave : INTEGER;

BEGIN
  ChanceToSave := MyExperience DIV 1000;
  IF ChanceToSave > 80 THEN ChanceToSave := 80;
  IF ChanceToSave >= Rnd(100) THEN
  BEGIN
    MakeSavingThrow := TRUE;
    Writeln('You resisted the ',s,'.');
    LogEvent(MySlot, 0, E_MADE_SAVE, 0, 0, 0, 0, S, Location);
  END
  ELSE MakeSavingThrow := false;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoAnnounce(S : String; Log : INTEGER; Spell : BYTE_BOOL := FALSE;
                     Privd : BYTE_BOOL := FALSE);

BEGIN
  IF (Privd OR Spell) THEN
  BEGIN
    IF S <> '' THEN
      LogEvent(0, Log, E_MSG, 0, 0, 0, 0, S, R_ALLROOMS)
    ELSE Writeln('Usage: announce <message>')
  END
  ELSE inform_badcmd;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION EffectDist(Base, Randd, MaxRange, Behavior, CasterDesc,
                     VictimDesc : INTEGER; All : BYTE_BOOL;
                     Missile : String; VAR AllStats : AllMyStats) : INTEGER;

{     0 - Normal
      1 - Bounces off walls
      2 - Returns to thrower
      3 - Hits all in path	}

VAR
  Dir : INTEGER;

  OldLoc : INTEGER := 0;
  NewLoc : INTEGER := 0;

  CurrRange : INTEGER := 0;
  HitLoc : INTEGER := 0;

  Target : String;
  TargSlot : INTEGER;
  TargLog : INTEGER := 0;

  S : String;
  Going : BYTE_BOOL := TRUE;
  HereDesc : RoomDesc;

  Sock : INTEGER;

BEGIN
  Sock := Base + RND(Randd);

  NewLoc := AllStats.Stats.Location;

  GrabLine('Direction: ',S, AllStats);
  IF (NOT GetDir(S, Dir)) OR
     (NOT GetRoomDesc(AllStats.Stats.Location, HereDesc)) THEN
    Writeln('Invalid direction.')
  ELSE
  BEGIN
    IF (Behavior <> 3) AND NOT(ALL) THEN
      GrabLine('Person to target? ', Target, AllStats);
    WHILE Going DO
    BEGIN
      IF CurrRange = 0 THEN
        S := AllStats.Stats.Name + ' fires a ' + missile + ' heading '
      ELSE
        S := 'You a see a '+missile+' from '+ALlStats.Stats.Name+' heading ';
      S := S + Direct[Dir] + '.';
      IF NewLoc = Allstats.Stats.Location THEN
      BEGIN
        Writeln('The ',missile,' is in your room.');
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MissileWhiz,
                 0, 0, 0, 0, S, NewLoc);
      END
      ELSE
      BEGIN
        Writeln('The ',missile,' travels into ',HereDesc.Nicename,'.');
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_Missilewhiz,
                 0, 0, 0, 0, S, NewLoc);
      END;

      IF Behavior = 3 THEN
      BEGIN
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_S_DIST, 0, 0, 
                 Sock, 0, Missile, NewLoc);
        IF IsDescription(VictimDesc) THEN
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0,
                   VictimDesc, 0, 'everyone', NewLoc);
      END
      ELSE
      BEGIN
        IF All THEN
        BEGIN
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_S_DIST, 0, 0,
                   Sock, 0, Missile, NewLoc);
          IF IsDescription(VictimDesc) THEN
            LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0,
                     VictimDesc, 0, 'everyone', NewLoc);
          CurrRange := MaxRange;
          HitLoc := NewLoc;
          IF Behavior < 2 THEN
            Going := FALSE;
        END
        ELSE
        BEGIN
          IF GetRoom(NewLoc, Here) THEN
          BEGIN
            IF ParsePers(TargSlot, TargLog, Target, FALSE) THEN
            BEGIN
              LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_S_DIST, 0,TargLog,
                      Sock, 0, Missile, NewLoc);
              IF IsDescription(VictimDesc) THEN
                LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, TargSlot,
                         0, VictimDesc, 0, Here.People[TargSlot].Name, NewLoc);
              CurrRange := MaxRange;
              HitLoc := NewLoc;
              IF Behavior < 2 THEN
                Going := FALSE;
            END;
          END;
        END;
      END;

(* calculate if we can still keep on going *)

      IF ((CurrRange = MaxRange) OR (HereDesc.Exits[Dir].ToLoc=0))
        AND (Behavior IN [1..2]) THEN
      BEGIN
        S := 'You see a '+missile+' from '+ AllStats.Stats.Name+' bounce ';
        IF (Dir MOD 2) = 1 THEN
          Dir := Dir +1
        ELSE
          Dir := Dir -1;
        S := S + Direct[Dir]+'.';
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_Missilewhiz, 0, 0,
                 0, 0, S, Newloc);
        IF (Behavior = 2) THEN  (* Return to caster... *)
        BEGIN
          MaxRange := CurrRange;   (* How many rooms it took to get here *)
          CurrRange := 0;          (* Starting all over again *)
        END;
        Behavior := 0;             (* Don't want it to keep bouncing.. *)
      END;
      OldLoc := NewLoc;
      CurrRange := CurrRange + 1;
      IF Going THEN
        NewLoc := HereDesc.Exits[Dir].ToLoc;
      IF (NewLoc = 0) OR (MaxRange < CurrRange) THEN
      BEGIN
        Going  := FALSE;
        IF HitLoc <> 0 THEN
          NewLoc := HitLoc
        ELSE
          NewLoc := OldLoc;
      END;
      IF NewLoc <> 0 THEN
      BEGIN
        IF NOT GetRoomDesc(NewLoc, HereDesc) THEN
          Going := FALSE;
      END;
    END;
    IF HitLoc <> 0 THEN
      Writeln('Your ',missile,' does ',Sock:0,' points of damage.')
  END;
  IF GetRoom(AllStats.Stats.Location, Here) then;
  IF HitLoc <> 0 THEN
     EffectDist := NewLoc
  ELSE
     EffectDist := -NewLoc;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectWhatIs(VAR AllStats : AllMyStats);

VAR
  Item : INTEGER;
  S : String;
  Obj : ObjectRec;

BEGIN
  GrabLine('What object would you like to know about?',s,AllStats);
  IF LookUpName(nt_short, s_na_objnam,item,s) then
  BEGIN
    Obj := GlobalObjects[Item];
    Write('You know it is a ');
    ShowKind(Obj.Kind);
    CASE Obj.Kind OF
      O_EQUIP  : ProgObjEquipView(Obj);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE EffectLocate(AllStats : AllMyStats);

BEGIN
  DoWho(TRUE, AllStats);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE EffectCure(VAR AllStats : AllMyStats; Value : INTEGER);

BEGIN
  Write('Your blood ');
  CASE Value OF
   0 : BEGIN
         Writeln('runs clean.');
         AllStats.Stats.Poisoned := FALSE;
       END;
   1 : BEGIN
         Writeln('begins to boil!');
         AllStats.Stats.Poisoned := TRUE;
       END;
  END;  (* Case *)
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectStrength(Mag, Time : INTEGER; VAR AllStats : AllMyStats);

VAR
  S : String;

BEGIN
  Write('You feel so ');
  IF Mag < 0 THEN
    Write('weak you couldn''t ')
  ELSE
    Write('strong you could ');
  Writeln('take on an ogre.');
  S := AllStats.Stats.Name+' suddenly bulges with muscles!';
  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
           S, AllStats.Stats.Location);
  IF AllStats.Tick.TkStrength <= GetTicks THEN
  BEGIN
    AllStats.Tick.Strength := Mag;
    AllStats.Stats.WeaponUse := AllStats.Stats.WeaponUse + Mag;
  END
  ELSE
    Time := Time DIV 2;
  AllStats.Tick.TkStrength := GetTicks + ROUND(Time/10);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectSpeed(Mag, Time : INTEGER; VAR AllStats : AllMyStats);

VAR
  S : String;

BEGIN
  Write('Your feel ');
  IF Mag < 0 THEN
    write('faster ')
  ELSE
    Write('slower ');
  Writeln('than a speeding turtle.');
  S := AllStats.Stats.Name+' ';
  IF Mag >= 0 THEN
    S := S + 'speeds up.'
  ELSE
    S := S + 'slows down.';
  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
           S, AllStats.Stats.Location);
  IF AllStats.Tick.TkSpeed <= GetTicks THEN
  BEGIN
    AllStats.Tick.MvSpeed := Mag;
    AllStats.Tick.AttSpeed := Mag;
    AllStats.Stats.MoveSpeed := AllStats.Stats.MoveSpeed + Mag;
    AllStats.Stats.AttackSpeed := AllStats.Stats.AttackSpeed + Mag;
  END
  ELSE
    Time := Time DIV 2;
  AllStats.Tick.TkSpeed := GetTicks + ROUND(Time / 10);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectInvisible(Time : INTEGER; VAR AllStats : AllMyStats);

VAR
  S : String;

BEGIN
  S := 'You feel a light gust of wind.';
  IF AllStats.Tick.TkInvisible > GetTicks THEN
  BEGIN
    S := AllStats.Stats.Name+' shimmers and vanishes from sight!';  
    Writeln('You become MORE invisible!')
  END
  ELSE
    Writeln ('You vanish from view!');
  AllStats.Tick.Invisible := TRUE;
  AllStats.Tick.TkInvisible := Getticks + Time * 10;
  Here.people[AllStats.Stats.Slot].Hiding := -1;
  IF SaveRoom(AllStats.Stats.Location, Here) THEN;
  IF S <> '' THEN
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0,
             0, S, AllStats.Stats.Location);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectSeeInvisible(Time : INTEGER; VAR AllStats : AllMyStats);

VAR
  S : String;
  Stat : StatType;
  Tick : TkTimeType;

BEGIN
  Stat := AllStats.Stats;
  Tick := AllStats.Tick;
  S := Stat.Name+'''s eyes begin to glow.';
  IF NOT Tick.Invisible THEN
    LogEvent(Stat.Slot, Stat.Log, E_MSG, 0, 0, 0, 0, S, Stat.Location);
  Writeln('Your sight sharpens.');
  Tick.SeeInvisible := TRUE;
  Tick.TkSee := GetTicks + Time*10;
  AllStats.Tick := Tick;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectSleep(Time : INTEGER; S : String; VAR AllStats : AllMyStats);

VAR
  MyExp : INTEGER;
  MySlot : INTEGER;
  MyName : String;

BEGIN
  MyExp := AllStats.Stats.Experience;
  MySlot := AllStats.Stats.Slot;
  MyName := AllStats.Stats.Name;

  IF NOT MakeSavingThrow(S + ' spell', MyExp, MySlot,
                         AllStats.Stats.Location) THEN
  BEGIN
    Writeln('You cannot move!');
    LogEvent(MySlot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0, MyName + 
             ' is frozen.', AllStats.Stats.Location);
    Freeze(Time/100, AllStats);
    Writeln('You can move again.');
    LogEvent(MySlot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0, MyName + 
             ' is moving again.', AllStats.Stats.Location);
  END
  ELSE Writeln('You were not affected by the spell.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectPush(Dir : INTEGER; RoomNum : INTEGER; VAR AllStats : AllMyStats);

VAR
  Here : Room;

BEGIN
  IF (Dir >= 1) AND (Dir <= MaxExit) THEN
  BEGIN
    IF HereDesc.Exits[Dir].ToLoc <> 0 THEN
    BEGIN
      Writeln('You leave the room.');
      IF GetRoom(RoomNum, Here) THEN
        ExitCase(-Dir, AllStats);
    END
    ELSE
    BEGIN
      Writeln('You are thrown into a wall!');
      PoorHealth(10, FALSE, FALSE, TRUE, AllStats);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectAnnounce(Ty, Dgrp : INTEGER:=0; VAR AllStats : AllMyStats); 
{types 0:all 1:group 2:person 3:announce 4:message}
VAR
  Agrp, Alog, Loop : INTEGER;
  S, Mess : String;
  MyGroup : INTEGER;
  MyName : String;
  MyLog : INTEGER;

BEGIN
  MyName := AllStats.Stats.Name;
  MyLog := AllStats.Stats.Log;
  MyGroup := AllStats.Stats.Group;
  Alog := 0;
  Agrp := 0;
  CASE Ty OF
    1 : BEGIN
          IF Dgrp > 0 THEN
            Agrp := Dgrp
          ELSE
            Agrp := MyGroup;
          Writeln('Casting to group - ',GetGroupName(Agrp));
        END;
    2 : BEGIN
          GrabLine('Cast at who? ',S,AllStats);
          IF NOT LookUpName(nt_short, s_na_pers, ALog, s) THEN
            Alog := MyLog;
        END;
  END;

  GrabLine('What is your message? ',s,AllStats);

  CASE Ty OF
    0 : Writev(Mess,'You hear a message from ',myname,': ',s,error:=continue);
    1 : Writev(Mess,'Group talk from ',myname,': ',s,error:=continue);
    2 : Writev(Mess,'Person-To-Person from ',myname,': ',s,error:=continue);
    3 : Mess := S;
    4 : Mess := S;
  END;

  IF Ty < 4 THEN
    LogEvent(0, 0, E_ANNOUNCE, 0, ALog, AGrp, 0, Mess, R_ALLROOMS)
  ELSE
    LogEvent(0, 0, E_MSG, 0, 0, 0, 0, Mess, AllStats.Stats.Location);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EffectFindPerson(VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  S : String;
  RoomNam : ShortString;
  AnInt : IntArray;
  MyLog : INTEGER;

BEGIN
  MyLog := AllStats.Stats.Log;
  GrabLine('Find who? ',S,AllStats);
  IF LookUpName(nt_short, s_na_pers, n, S) THEN
    IF N = MyLog THEN
      Writeln('Your right here! in this very room.')
    ELSE
    BEGIN
      IF GetInt(N_Location, AnInt) THEN
      BEGIN
        GetRoomName(AnInt[N], RoomNam);
        Writeln(s,' is at ', RoomNam);
      END;
    END
  ELSE
    Writeln('The spell fizzels out.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoLearn(S : String; VAR AllStats : AllMyStats);

VAR
  N, Item, Page : INTEGER;
  CanLearn : BYTE_BOOL;
  Spell : SpellRec;
  Obj : ObjectRec;
  Charac : CharRec;
  Lev : INTEGER;
  Stat : StatType;

BEGIN
  Stat := AllStats.Stats;
  Lev := Stat.Experience DIV 1000;
  IF (S='') OR (S='?') THEN
    ListSpells(Stat.Class, Stat.Group, Stat.Experience, Stat.Privd)
  ELSE
  BEGIN
    IF LookUpName(nt_short, s_na_spell, n, s, FALSE, FALSE) THEN
    BEGIN
      Spell := GlobalSpells[N];
      CanLearn := NOT Spell.Memorize;
      IF CanLearn THEN
        Writeln('You do not need to memorize that spell.')
      ELSE
      BEGIN
        FOR Item := 1 TO MaxObjs DO
  	  IF Here.Objs[Item] <> 0 THEN
  	  BEGIN
            Obj := GlobalObjects[Here.Objs[Item] MOD 1000];
            IF Obj.Kind = O_SBOOK THEN
              IF (Obj.Parms[1] = 0) OR (Obj.Parms[1] = Stat.Group) THEN
    	        FOR Page := 2 TO 20 DO
 	          IF Obj.Parms[Page] = N THEN
                    CanLearn := TRUE;
          END;
        FOR Item := 1 TO MaxHold DO
        BEGIN
          IF AllStats.MyHold.Holding[Item] <> 0 THEN
          BEGIN
            Obj := GlobalObjects[AllStats.MyHold.Holding[Item]];
            IF Obj.Kind = O_SBOOK THEN
              IF (Obj.Parms[1] = 0) OR (Obj.Parms[1] = Stat.Group) THEN
    	        FOR Page := 2 TO 20 DO
 	          IF Obj.Parms[Page] = N THEN
                    CanLearn := TRUE;
          END;
        END;
        IF (CanLearn AND
          (Stat.Mana >= (Spell.Mana + Spell.LevelMana * Lev)) AND
          ((Stat.Experience DIV 1000) >= Spell.MinLevel) AND
          ((Spell.Class = 0) OR (Spell.Class = Stat.Class)) AND
          ((Spell.Group = 0) OR (Spell.Group = Stat.Group)))
          OR Stat.Privd THEN
        BEGIN
	  Stat.Mana := Stat.Mana-(Spell.Mana + Spell.LevelMana * Lev);
	  IF Stat.Mana < 0 THEN Stat.Mana := 0;
          IF GetChar(Stat.Log, Charac) THEN
          BEGIN
            Charac.Mana := Stat.Mana;
	    Charac.Spell[N] := Charac.Spell[N] + 1;
            IF SaveChar(Stat.Log, Charac) THEN
            BEGIN
              Writeln(spell.name,' learned.');
              LogEvent(Stat.Slot, Stat.Log, E_S_SPELL, 0, 0, 3, 0,
                       Spell.Name, Stat.Location);
            END;
          END;
        END
     	ELSE
	BEGIN
	  LogEvent(Stat.Slot, Stat.Log, E_S_SPELL, 0, 0, 4, 0,
                   Spell.Name, Stat.Location);
	  IF Stat.Mana < N THEN
            Writeln('You do not have enough mana.')
	  ELSE
            IF Spell.MinLevel > Lev THEN
              Writeln('Your level is too low.')
	    ELSE
              IF NOT CanLearn THEN
                Writeln('You need a spellbook for that spell.')
              ELSE
                Writeln('You are the wrong class to cast that spell.');
	END;
      END;  (* If can learn else *)
    END;      (* If lookup name *)
  END;        (* If s='' else *)
  AllStats.Stats := Stat;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION CanCast(VAR AllStats : AllMyStats;  Spellnum, Direct : INTEGER) : BYTE_BOOL;

VAR
  Ok : BYTE_BOOL;
  Spell : SpellRec;
  Charac : CharRec;
  Obj : ObjectRec;
  Loop : INTEGER;
  Lev : INTEGER;

BEGIN
  Lev := AllStats.StatS.Experience DIV 1000;
  Ok := TRUE;
  Spell := GlobalSpells[SpellNum];
  IF NOT (Direct IN [1..MaxSpells]) THEN
  BEGIN
    IF GetChar(AllStats.Stats.Log, Charac) THEN
    BEGIN
      IF Charac.Spell[SpellNum] > 0 THEN
      BEGIN
        Ok := TRUE;
        Charac.Spell[SpellNum] := Charac.Spell[SpellNum] - 1;
        IF SaveChar(AllStats.Stats.Log, Charac) THEN;
      END
      ELSE
        OK := FALSE
    END;
    IF NOT Ok THEN
      IF NOT Spell.Memorize THEN
        IF AllStats.Stats.Mana >= (Spell.Mana + Spell.LevelMana * Lev) THEN
    	  IF Lev >= Spell.MinLevel THEN
            IF ((AllStats.Stats.Class = Spell.class) OR (Spell.Class=0)) AND
               ((AllStats.Stats.Group = Spell.group) OR (Spell.Group=0)) THEN
	      IF ObjHold(Spell.ObjRequired, AllStats.MyHold) OR
                 (Spell.ObjRequired=0) THEN
              BEGIN
  	        IF (Spell.ObjRequired <> 0) AND Spell.ObjConsumed THEN
	        BEGIN
                  IF DropObj(FindHold(Spell.ObjRequired, AllStats.MyHold), AllStats) THEN;
		  Writeln('The ',GlobalObjects[Spell.ObjRequired].Objname,' was destroyed.');
		END;
                Ok := TRUE;
                IF GetChar(AllStats.Stats.Log, Charac) THEN
                BEGIN
	          Charac.Mana := Charac.Mana - (Spell.Mana +
                                                Spell.LevelMana * Lev);
                  IF SaveChar(AllStats.Stats.Log, Charac) THEN;
	  	  AllStats.Stats.Mana :=Charac.Mana;
	        END;
              END
	      ELSE Writeln('You need something first.')
	    ELSE Writeln('You are not the correct class to cast that spell.')
	  ELSE Writeln('You aren''t high enough level.')
        ELSE Writeln('You don''t have enough mana to cast that spell.')
      ELSE Writeln('You need to learn that spell.')
  END;
  IF Spell.Room <> 0 THEN
    IF AllStats.Stats.Location <> Spell.Room THEN
    BEGIN
      Ok := FALSE;
      Writeln('This isn''t the right place.')
    END;
  CanCast := ok;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE Effect(EffectType ,J : INTEGER; S : String; VAR AllStats : AllMyStats);

VAR
  P1, P2:integer;
  Stat : StatType;
  ObjStats : HoldObj;
  R : String;

BEGIN
  IF RND(100) < AllStats.MyHold.SpellDeflectArmor THEN
  BEGIN
    R := 'The spell was deflected by '+AllStats.Stats.Name+'''s armor.';
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
             R, AllStats.Stats.Location);
    Writeln('The spell has been deflected by your armor!');
  END
  ELSE
  BEGIN
    ObjStats := AllStats.MyHold;
    Stat := AllStats.Stats;
    P1 := J MOD 10000;
    P2 := J DIV 10000; 
    CASE EffectType OF
      sp_cure     : EffectCure(AllStats, P1);
      sp_strength : EffectStrength(P1, P2, AllStats);
      sp_weak     : EffectStrength(-P1, P2, AllStats);
      sp_speed    : EffectSpeed(-P1,P2, AllStats);
      sp_slow     : EffectSpeed(P1,P2,AllStats);
      sp_seeinvisible: EffectSeeInvisible(P2, AllStats);
      sp_invisible: EffectInvisible(P2, AllStats);
      sp_heal	: PoorHealth(-(P1+P2), FALSE, TRUE, TRUE, AllStats);
      sp_hurt	: PoorHealth(P1+P2, FALSE, TRUE, TRUE, AllStats);
      sp_sleep	: EffectSleep(P1+P2,S, AllStats);
      sp_push	: EffectPush(P1, Stat.Location, AllStats);
      sp_announce	: EffectAnnounce(P1, P2, AllStats);
      sp_find_person: EffectFindPerson(AllStats);
      sp_whatis	: EffectWhatis(AllStats);
      sp_locate	: EffectLocate(AllStats);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoCast(Slot, CastLevel : INTEGER; Line : String; Sn: INTEGER:=0;
                 VAR AllStats : AllMyStats);

{ Slot : Either my slot, or the slot of the person that I am "controlling" }
{        that is casting the spell.  If the slot is not me, assume they are }
{        casting the spell at me. }
{ Line : Command line used to invoke the spell.  For example if "cast death" }
{        then line = "death" }
{ Sn   : If the spell number was used to cast the spell then ignore line }

VAR
  peo, N, I, Sock, Sock1, Sock2, Targ, Estart, Eend : INTEGER;
  TargLog : INTEGER;
  All, Hit : BYTE_BOOL := TRUE;
  Spell : SpellRec;
  Tick : TkTimeType;
  Stat : StatType;
  RoomNum : INTEGER;
  S : String;
  ICast : BYTE_BOOL;
  S1, S2, S3, S4 : INTEGER;
  spellnum : integer;
  good : BYTE_BOOL := false;
  OldPriv : BYTE_BOOL := FALSE;

  PROCEDURE PrintCasterDesc(Victim : ShortString; DescNum : INTEGER;
                            Slot, MySlot : INTEGER);
  BEGIN
    IF IsDescription(DescNum) AND ICast THEN
      BlockSubs(DescNum, Victim);
  END;

  FUNCTION CheckFix(Slot, MySlot : INTEGER): BYTE_BOOL;
  BEGIN
    CheckFix := NOT(ICast);
  END;

BEGIN
  ICast := Slot = AllStats.Stats.Slot;
  Tick := AllStats.Tick;
  Stat := AllStats.Stats;
  RoomNum := AllStats.Stats.Location;
  Line := Trim(Line);
  IF check_bit(HereDesc.SpcRoom, rm$b_nofight) THEN
  begin
    Inform_NoFight;
    good := false;
  end
  ELSE
  BEGIN
    IF Sn = 0 THEN
    BEGIN
      IF Line = '' THEN
        GrabLine('Which spell? ', Line, AllStats);
      IF NOT LookUpName(nt_short, s_na_spell, SpellNum, Line) THEN
        Writeln('Invalid spell.')
      else
        good := true;
    END
    ELSE
    begin
      SpellNum := Sn;
      good := true;
    end;
  end;
  if good and (sn = 0) then
  begin
    IF (SpellNum > 0) AND (SpellNum <= MaxSpells) THEN
      IF not CanCast(AllStats, SpellNum, 0) THEN good := false;
  end;
  if good then
  BEGIN
    Spell := GlobalSpells[SpellNum];
    IF (Here.People[Slot].Hiding > 0) AND Spell.Reveals THEN
      DoUnHide(Slot, RoomNum);
    IF ICast THEN
      Freeze(Spell.CastingTime / 200, AllStats);
    IF (Rnd(100) < Spell.ChanceOfFailure) AND ICast THEN
    BEGIN   
      PrintSubs(Spell.FailureDesc,'');
      Estart := 0;
      Eend := 0;
    END
    ELSE
    BEGIN
      Estart := 1;
      Eend := MaxSpellEffect;
      Freeze(Spell.CastingTime / 200, AllStats);
    END;

(* --------------------------- do effects ----------------------------------- *)

    FOR I := Estart TO Eend DO
    BEGIN
      IF Spell.Effect[I].Name = '' THEN
        Spell.Effect[I].Name := Spell.Name;
       
      IF Spell.Effect[I].Effect <> 0 THEN
      BEGIN
        All := Spell.Effect[I].All;
        S1 := Spell.Effect[I].M1;
        S2 := Spell.Effect[I].M2;
        S3 := Spell.Effect[I].M3;
        S4 := Spell.Effect[I].M4;
     
     	Sock1 := S1 + S2 * CastLevel;
     	Sock2 := RND(S3 + CastLevel * S4);
        Sock := Sock1 + Sock2;
        Sock1 := Sock1 + Sock2*10000;
     
        CASE Spell.Effect[I].Effect OF
          SP_Command : BEGIN
	    OldPriv := AllStats.Stats.Privd;
	    AllStats.Stats.Privd := Spell.CommandPriv;
	    Parser(Spell.Command, AllStats);
	    AllStats.Stats.Privd := OldPriv;
	    END;
          SP_Push : BEGIN
            IF ICast THEN
            BEGIN
              IF S1 = 0 THEN
              BEGIN
                S := TRIM(Bite(Line));
                IF Length(S) = 0 THEN
                  GrabLine('Which direction?',S,AllStats);
                WhichDir(S1, S);
              END
              ELSE IF S1 = -1 THEN
              begin
                S1 := RND(MaxExit);
              end
              ELSE
                S1 := Spell.Effect[I].M1;
              IF NOT (Sock1 IN [1..MaxExit]) THEN
                S1 := RND(MaxExit);
            END
            ELSE
              S1 := RND(MaxExit);
            Sock1 := S1;
          END;
          SP_Cure : Sock1 := S1;
          SP_Weak,
          SP_Slow,
          SP_Strength,
          SP_Speed : BEGIN
            Sock1 := S1 + S2 * CastLevel;
            Sock2 := S3 + RND(S4);
            Sock := Sock1 + Sock2;
            Sock1 := Sock1 + Sock2*10000;
          END;
          SP_Invisible : ;
          SP_SeeInvisible : ;
          SP_Heal : ;
          SP_Hurt :  ;
          SP_Sleep : ;   
          SP_Announce : BEGIN
            Spell.Effect[I].Caster := TRUE;
            All := FALSE;
            Sock1 := S1 + S2 * 10000;
          END;
          SP_Dist :  ;
          SP_WhatIs : BEGIN
            Spell.Effect[I].Caster := TRUE;
            All := FALSE;
          END;
          SP_Locate,
          SP_Find_Person : BEGIN
            Spell.Effect[I].Caster := TRUE;
            All := FALSE;
          END;
        END;  (* Case statement *)
        Targ := Spell.Effect[I].Effect;
     
(* Does it affect me? *)
     
        IF ICast AND Spell.Effect[I].Caster THEN
          Effect(Spell.Effect[I].Effect, Sock1, Spell.Effect[I].Name, AllStats);
     
(* Does it affect everyone (and not distance spell)? *)
     
        IF Spell.Effect[I].Effect <> SP_DIST THEN
        BEGIN
          IF All THEN
          BEGIN
     	    PrintCasterDesc('everyone', Spell.CasterDesc, Slot,
                            AllStats.Stats.Slot);
            IF IsDescription(Spell.VictimDesc) THEN
              LogEvent(Slot, AllStats.Stats.Log, E_MSG, 0, 0, Spell.VictimDesc,
                       0, Here.People[Slot].Name, AllStats.Stats.Location);
            LogEvent(Slot, AllStats.Stats.Log, E_S_EFFECT, 0, 0,
                     Spell.Effect[I].Effect, Sock1,
                     Spell.Effect[I].Name, AllStats.Stats.Location);
	    (* If this is area-effect.. you will hit all people.. including
               those who are hiding.. so we must REVEAL those people *)
	    FOR peo := 1 TO maxpeople DO
	    BEGIN
	       IF Here.People[peo].Hiding > 0 THEN
	       BEGIN
                  Here.People[peo].Hiding := 0;
                  IF SaveRoom(AllStats.Stats.Location, Here) THEN;
                  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, 
			E_FOUNDYOU, peo,0,
               		0,0, AllStats.Stats.Name, AllStats.Stats.Location);
	       END;
	    END;
          END
          ELSE
          BEGIN
            IF ICast AND NOT(Spell.Effect[I].Caster) THEN 
            BEGIN
              GrabLine('At who? ', S, AllStats);
              IF (ParsePers(N, TargLog, S)) THEN
              BEGIN
                PrintCasterdesc(Here.People[N].Name, Spell.CasterDesc,
                                Slot, AllStats.Stats.Slot);
                IF NOT(N = AllStats.Stats.Slot) OR NOT(ICast) THEN
                BEGIN
                  IF IsDescription(Spell.VictimDesc) THEN
                    LogEvent(Slot, AllStats.Stats.Log, E_MSG, N, 0,
                             Spell.VictimDesc, 0,
                             Here.People[Slot].Name, AllStats.Stats.Location);
                  LogEvent(Slot, AllStats.Stats.Log, E_S_EFFECT, N,
                           TargLog, Spell.Effect[I].Effect, Sock1,
                           Spell.Effect[I].Name, AllStats.Stats.Location);
                END
                ELSE
                BEGIN
                  Effect(Spell.Effect[I].Effect, Sock1,
                         Spell.Effect[I].Name, AllStats);
                END;
                IF (Spell.Effect[I].Effect = SP_HURT) AND ICast THEN
                  Writeln('Your ', Spell.Name, ' spell does ',
                          Sock:0,' damage.');
              END
              ELSE
              BEGIN
                Hit := FALSE;
                IF ICast THEN
                  Writeln('The ',spell.name,' spell fizzels out.');
                  LogEvent(Slot, AllStats.Stats.Log, E_S_SPELL, 0, 0, 2,
                           0, Spell.Name, Allstats.Stats.Location);
              END;
            END;
          END;   (* Not all people affected *)
        END      (* Not a distance spell *)
        ELSE
        BEGIN
          IF ICast THEN
            WITH Spell DO
            BEGIN
              EffectDist(S1, S2, S3, S4, CasterDesc, VictimDesc, All,
                         Effect[I].Name, AllStats);
            END
          ELSE
            Writeln('Distance spell not cast by me.');
        END;
      END;  (* Was the effect number 0 *)
    END;    (* for loop := minspelleffect to maxspelleffect *)
  END;      (* Is good *)
END;

END.
