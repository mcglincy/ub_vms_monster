[INHERIT ('MONCONST','MONTYPE','MONGLOBL')]

MODULE MonTime(OUTPUT);

%include 'headers.txt'

[GLOBAL]
PROCEDURE TimeHealth(VAR AllStats : AllMyStats);

VAR
  Stat : StatType;
  Tick : TkTimeType;
  MaxHealth : INTEGER;
  Change : INTEGER := 0;
  S : String;

BEGIN
  Stat := AllStats.Stats;
  Tick := AllStats.Tick;
  MaxHealth := AllStats.MyHold.MaxHealth;
  IF NOT (Stat.Poisoned) AND (Stat.Health < MaxHealth) THEN
  BEGIN
    Change := ROUND((MaxHealth-Stat.Health) * (Stat.HealSpeed/1000));
    Stat.Health := Stat.Health + Change;
  END
  ELSE
    IF Stat.Poisoned THEN
      Stat.Health := Stat.Health - ROUND((MaxHealth-Stat.Health) * 
                     (Stat.HealSpeed/1000));
  FixHealth(Stat.Health, MaxHealth);
  IF Change <> 0 THEN
  BEGIN
    Here.People[Stat.Slot].Health := Stat.Health;
    IF SaveRoom(Stat.Location, Here) THEN
    BEGIN
      AttribAssignValue(Stat.Log, ATT_Health, Stat.Health); 
      DescMyHealth(MaxHealth, Stat.Health);
      Stat.Printed := TRUE;
    END;
  END;
  Tick.TkHealth := GetTicks + 300;
  AllStats.Stats := Stat;
  AllStats.Tick := Tick;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE DoRest(VAR AllStats : AllMyStats);

VAR
  S : String;

BEGIN
  IF check_bit(HereDesc.SpcRoom, rm$b_heal) THEN
  BEGIN
    Allstats.Stats.HealSpeed := 2 * AllStats.Stats.HealSpeed;
    REPEAT
      GrabLine('Type exit to continue: ', S, AllStats);
    UNTIL (lowcase(trim(bite(S))) = 'exit');
    AllStats.Stats.HealSpeed := ROUND(AllStats.Stats.HealSpeed/2);
    Freeze(AllStats.Stats.MoveSpeed * HereDesc.Mag[rm$b_heal] / 100, AllStats);
  END
  ELSE
    Writeln('You can not rest here.');
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeMana(VAR AllStats : AllMyStats);

VAR
  S : String;
  OldMana : INTEGER;

BEGIN
  OldMana := AllStats.Stats.Mana;
  IF AllStats.Stats.Mana < AllStats.MyHold.MaxMana THEN
  BEGIN
    AllStats.Stats.Mana := AllStats.Stats.Mana + (AllStats.MyHold.MaxMana) DIV 2;
    Rectify(AllStats);
    AttribAssignValue(AllStats.Stats.Log, ATT_Mana, AllStats.Stats.Mana); 
    IF AllStats.Stats.Mana <> OldMana THEN
    BEGIN
      Writeln('You feel magically energized.');
      AllStats.Stats.Printed := TRUE;
    END;
  END;
  AllStats.Tick.TkMana := GetTicks + 350;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeNoises(Slot, Log, Location : INTEGER);

VAR
  N : INTEGER;

BEGIN
  N := RND(100);
  IF (Here.People[Slot].Hiding > 0) AND (N < 11) THEN
    LogEvent(Slot, Log, E_REALNOISE, 0, 0, N, 0, '', Location);
  IF Rnd(100) <= 2 THEN
  BEGIN
    N := Rnd(100);
    IF N IN [1..40] THEN
      LogEvent(0, 0, E_NOISES, 0, 0, Rnd(100), HereDesc.RndMsg,
               '', Location)
    ELSE
      IF N IN [41..60] THEN
        LogEvent(0, 0, E_ALTNOISE, 0, 0, Rnd(100), HereDesc.XMsg2,
                 '',Location);
  END;
END;

(* ------------------------------------------------------------------------- *) 

PROCEDURE TimeTrapdoor(VAR AllStats : AllMyStats; LoggedAct : BYTE_BOOL := FALSE);

VAR
  Fall : BYTE_BOOL := TRUE;

BEGIN
  IF (Rnd(100) < HereDesc.TrapChance) THEN
  BEGIN
    IF (AllStats.Exit.ExitHandled) THEN
    BEGIN { trapdoor fires! }
      IF HereDesc.TrapTo > 0 THEN
      BEGIN
        IF (LoggedAct) THEN
          Fall := FALSE
        ELSE
        IF ObjHold(HereDesc.MagicObj, AllStats.MyHold) THEN
          Fall := FALSE;
      END
      ELSE
        Fall := FALSE;
  
      IF Fall THEN
      BEGIN
        IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
          Here.People[AllStats.Stats.Slot].Hiding := 0;
        IF SaveRoom(AllStats.Stats.Location, Here) THEN;
        DoExit(HereDesc.TrapTo, AllStats);
        AllStats.Stats.Printed := TRUE;
      END;
    END;
  END;
END;

(* ------------------------------------------------------------------------- *) 

FUNCTION TimeMidnight : BYTE_BOOL;
BEGIN
  TimeMidnight := FALSE;
  IF ((SysTime = '12:00am') and (not(midnightnotyet))) THEN
  BEGIN
    Writeln('It is now midnight.');
    TimeMidnight := TRUE;
    MidNightNotYet := TRUE;
  END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeUnwho(Log : INTEGER; Loc : INTEGER; Privd : BYTE_BOOL := FALSE);

VAR
  Indx : IndexRec;
  inta : IntArray;
BEGIN
  IF GetIndex(I_Asleep, Indx) THEN
    IF (NOT Privd) AND Indx.Free[Log] THEN
    BEGIN
      Indx.Free[Log] := FALSE;
      IF SaveIndex(I_Asleep, Indx) THEN;
    END;
  IF GetInt(n_location, inta) THEN
    IF Inta[Log] <> Loc THEN
    BEGIN
     Inta[log] := Loc;
     SaveInt(n_location, inta);
    END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeInvisible(VAR Tick : TkTimeType;
                        RoomNum : INTEGER; Slot : INTEGER; Log : INTEGER);

VAR
  S : String;

BEGIN
  Writeln('Your invisibility has expired.');
  Tick.Invisible := FALSE;
  Here.People[Slot].Hiding := 0;
  IF SaveRoom(RoomNum, Here) THEN
  BEGIN
    S := Here.People[Slot].Name+ ' suddenly appears before your eyes!';
    LogEvent(Slot, Log, E_MSG, 0, 0, 0, 0, S, RoomNum);
  END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeStrength(VAR AllStats : AllMyStats; Quiet : BYTE_BOOL := FALSE);

VAR
  S : String;

BEGIN
  AllStats.Stats.WeaponUse := AllStats.Stats.WeaponUse - AllStats.Tick.Strength;
  AllStats.Tick.TkStrength := 0;
  AllStats.Tick.Strength := 0;
  IF NOT Quiet THEN
  BEGIN
    writeln('Your muscles return to their normal size.');
    S := AllStats.Stats.Name + '''s muscles revert back to normal.';
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.log, E_MSG, 0, 0, 0, 0,
             S, AllStats.Stats.Location);
  END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeSpeed(VAR AllStats : AllMyStats; Quiet : BYTE_BOOL := FALSE);

VAR
  S : String;

BEGIN
  AllStats.Stats.MoveSpeed := AllStats.Stats.MoveSpeed - AllStats.Tick.MvSpeed;
  AllStats.Stats.AttackSpeed := AllStats.Stats.AttackSpeed - AllStats.Tick.AttSpeed;
  AllStats.Tick.TkSpeed := 0;
  AllStats.Tick.MvSpeed := 0;
  AllStats.Tick.AttSpeed := 0;
  IF NOT Quiet THEN
  BEGIN
    Writeln('Your metabolism returns to normal.');
    S := AllStats.Stats.Name + ' is disoriented.';
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
             S, AllStats.Stats.Location);
  END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE TimeSee(VAR Tick : TkTimeType; Name : String; Slot : INTEGER;
                  Log : INTEGER; Location : INTEGER; Quiet : BYTE_BOOL := FALSE);

VAR
  S : String;

BEGIN
  Tick.SeeInvisible := FALSE;
  IF NOT Quiet THEN
  BEGIN
    Writeln('Your vision returns to normal.');
    S := Name + '''s eyes cease to glow.';
    LogEvent(Slot, Log, E_MSG, 0, 0, 0, 0, S, Location);
  END;
END;

(* ------------------------------------------------------------------------- *) 

PROCEDURE RndAttack(Control : INTEGER := 0; VAR AllStats : AllMyStats);

VAR
  I : INTEGER;
  Attacked : BYTE_BOOL := FALSE;
  MySlot : INTEGER;

BEGIN
  MySlot := AllStats.Stats.Slot;
  I := Rnd(MaxPeople);
  IF ((Rnd(100) < Control) AND (Here.People[I].Name <> '') AND
      (I <> MySlot) AND (Here.People[I].Hiding = 0)) THEN
  BEGIN
    Writeln('A madness overcomes your mind!');
    LogEvent(MySlot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
             AllStats.Stats.Name + ' spasms as a madness overcomes his body.',
             AllStats.Stats.Location);
    DoAttack(Here.People[I].Name, AllStats);
  END;
END;

(* ------------------------------------------------------------------------- *) 

[GLOBAL]
PROCEDURE RndEvent(VAR Allstats : AllMyStats);

VAR
  N : INTEGER;

BEGIN
  TimeNoises(AllStats.Stats.Slot, AllStats.Stats.Log, AllStats.Stats.Location);
  TimeTrapdoor(AllStats);
  RndAttack(AllStats.Stats.Control, AllStats);
  AllStats.Stats.Printed := AllStats.Stats.Printed or TimeMidnight;
END;

END.
