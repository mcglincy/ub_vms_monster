[INHERIT('MONCONST','MONTYPE','MONGLOBL','MONRAND')]
         
MODULE MonRand(OUTPUT);

%include 'headers.txt'
%include 'monrand.inc'

[external] function seconds_time : INTEGER; extern;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ReadInAllRandoms;

VAR
  Indx : IndexRec;
  Loop, Count : INTEGER;

BEGIN
  Count := 0;
  IF GetIndex(I_Rand, Indx) THEN
  BEGIN
    FOR Loop := 1 TO Indx.Top DO
      IF NOT(Indx.Free[Loop]) THEN
        IF NOT(GetRand(Loop, GlobalRandoms[Loop])) THEN
          GlobalRandoms[Loop] := Zero
        ELSE
          Count := Count + 1;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION PutRandomMonsterToken(Loc : INTEGER; RandType : INTEGER) : BYTE_BOOL;

VAR
  Loop : INTEGER := 1;
  Found : BYTE_BOOL := FALSE;
  Random : RandRec;

BEGIN
  PutRandomMonsterToken := FALSE;
  IF GetRand(RandType, Random) THEN
BEGIN
    While (Loop <= MaxPeople) AND NOT (FOUND) DO
      IF Here.People[Loop].Kind = 0 THEN
        Found := TRUE
      ELSE
        Loop := Loop + 1;
  END;
  IF Found THEN
  BEGIN
    Here.People[Loop].Kind := -RandType;
    Here.People[Loop].Name := Random.Name;
    Here.People[Loop].Health := Random.BaseHealth + rnd(Random.RandomHealth);
    Here.People[Loop].NextAct := seconds_time * 100;
    Here.People[Loop].Targ := 0;
    Here.People[Loop].Hiding := 0;
    SaveRoom(Loc, Here);
    LogEvent(Loop, -RandType, E_ENTER, 0, 0, Rnd(6), 0, Random.Name,
             Loc, , Here.People[Loop].health, 0);
    PutRandomMonsterToken := TRUE;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PutRandom(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  TempS : String;

BEGIN
  IF LookupName(nt_short, s_na_rannam, N, S, FALSE, FALSE) THEN
  BEGIN
    writev(temps, a_an(globalrandoms[n].name), GlobalRandoms[N].name,
           ' has just entered the room.');
    PutRandomMonsterToken(AllStats.Stats.Location, N);
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION IsRandomMonster(People : PeopleRec) : BYTE_BOOL;

BEGIN
  IsRandomMonster := People.Kind < 0;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION GetMonsterKind(N : INTEGER) : String;
BEGIN
  CASE N OF
    1 : GetMonsterKind := 'Fighter';
(*
    2 : GetMonsterKind := 'NPC';
    3 : GetMonsterKind := 'Spell caster';
    4 : GetMonsterKind := 'Fighter spell caster';
    5 : GetMonsterKind := 'Thief';
    6 : GetMonsterKind := 'Cut throat';
    7 : GetMonsterKind := 'Undead';
    8 : GetMonsterKind := 'Multiplier';
   10 : GetMonsterKind := 'Mana charger';
*)
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomRandHelp(Rand : RandRec);

VAR
  S : String;
  SpellNam : ShortNameRec;
  N : INTEGER;

BEGIN
  IF GetShortName(s_na_spell, SpellNam) THEN
  BEGIN
    writeln;
    writeln('N)ame          = ', Rand.Name);
    writeln('K)ind          = ', GetMonsterKind(Rand.Kind));
    writeln('G)roup         = ', GetGroupname(Rand.Group));
    writeln('B)asehealth    = ', Rand.BaseHealth);
    writeln('C)Randomhealth = ', Rand.Randomhealth);
    writeln('D)aseDamage    = ', Rand.BaseDamage);
    writeln('R)andomDamage  = ', Rand.RandomDamage);
    writeln('4)Level damage = ', Rand.LevelDamage);
    writeln('A)rmor         = ', Rand.Armor);
    writeln('S)pell armor   = ', Rand.SpellArmor);
    writeln('Y)Move speed   = ', Rand.MoveSpeed);
    writeln('U)Attack speed = ', Rand.AttackSpeed);
    writeln('X)Experience   = ', Rand.Experience);
    writeln('M)Gold         = ', Rand.Gold);
    writeln('L)evel attract = ', Rand.MinLevel);
    writeln('H)eal speed    = ', Rand.HealSpeed);
    writeln('P)ursuitChance = ', Rand.PursuitChance);
    writeln('T)Weapon Usage = ', Rand.WeaponUse);
    writeln('J)Lvl weapon   = ', Rand.LevelWeaponUse);
    writeln('W)eapon (name) = ', Rand.Weapon);
(*    writeln('O)bject drop   = ', ObjName(Rand.Object));*)
    writeln('I)Base mana    = ', Rand.BaseMana);
    writeln('F)Level mana   = ', Rand.LevelMana);
    writeln('Z)Size         = ', Rand.Size);
    writeln('1)Set sayings');
    writeln('Keyword: Saying');
    FOR N := 1 TO 10 DO
      IF Rand.Sayings[n].Keyword <> '' THEN
        Writeln(Rand.Sayings[N].Keyword,': ', Rand.Sayings[N].Saying);
    writeln('2)Add spell');
    writeln('3)Remove spell');
    FOR N := 1 TO MaxRandomSpells DO
      IF Rand.Spell[N] > 0 THEN
        Writeln(SpellNam.Idents[Rand.Spell[N]]);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ListmonsterKinds;

VAR
  Loop : INTEGER;

BEGIN
  FOR Loop := 1 TO RM_MAX DO
    Writeln(Loop:2,') ',GetMonsterKind(Loop));
END;

(* -------------------------------------------------------------------------- *)

FUNCTION CanAddSpell(Rand : RandRec) : INTEGER;

VAR
  Loop : INTEGER := 1;
  Found : INTEGER := 0;

BEGIN
  WHILE (Found = 0) AND (Loop <= MaxRandomSpells) DO
    Found := Loop;
  CanAddSpell := Found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CustomRandom(RandomNum : INTEGER; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  Done : BYTE_BOOL;
  S : String;
  Rand : RandRec;
  Nam : ShortNameRec;
  Loop : INTEGER;
  Dummy : INTEGER;
  TempString : String;

BEGIN
  IF AllStats.Stats.Privd AND GetRand(RandomNum, Rand) THEN
  BEGIN
    Done := FALSE;
    REPEAT
      Writev(tempstring,  Rand.Name, '[', RandomNum:0, ']> ');
      GrabLine(tempstring, S, AllStats);
      S := Lowcase(Trim(S));
      IF Length(S) = 0 THEN
        S := 'e';
      CASE S[1] OF
        'n' : BEGIN
   	        GrabLine('Name ', S, AllStats);
                IF NOT LookupName(nt_short, s_na_RanNam, Dummy, S, TRUE) THEN
                  Rand.Name := S;
              END;
        'b' : Grab_Num('Base health? ', Rand.Basehealth, 0, , Rand.BaseHealth,
                          AllStats);
        'c' : Grab_Num('Level Health? ',Rand.RandomHealth, , ,
                       Rand.RandomHealth, AllStats);
        'd' : Grab_Num('Base Damage? ', Rand.BaseDamage, , , Rand.BaseDamage,
                          AllStats);
        'r' : Grab_Num('Random Damage? ', Rand.RandomDamage, , ,
                          Rand.RandomDamage, AllStats);
        '4' : Grab_Num('Level Damage? ', Rand.LevelDamage, , , Rand.LevelDamage,
                          AllStats);
        'a' : Grab_Num('Armor? ', Rand.Armor, 0, 100, Rand.Armor,
                          AllStats);
        's' : Grab_Num('Spell armor? ', Rand.SpellArmor, 0, 100, Rand.SpellArmor,
                          AllStats);
        'y' : Grab_Num('Move speed? ', Rand.MoveSpeed, 0, , Rand.MoveSpeed,
                          AllStats);
        'u' : Grab_Num('Attack speed? ', Rand.AttackSpeed, 0, , Rand.AttackSpeed,
                          AllStats);
        'k' : BEGIN
		ListMonsterKinds;
		Grab_Num('Kind? ', rand.Kind, 0, RM_MAX, Rand.Kind, AllStats);
	      END;
        'x' : Grab_Num('Experience? ', Rand.Experience, , , Rand.Experience,
                          AllStats);
        'm' : Grab_Num('Money? ', Rand.Gold, 0, , Rand.Gold, AllStats);
        'l' : Grab_Num('Level attract? ', Rand.MinLevel, -1, , Rand.MinLevel,
                          AllStats);
        'h' : Grab_Num('Heal speed? ', Rand.HealSpeed, 0, 1000, Rand.HealSpeed,
                          AllStats);
        '2' : IF (CanAddSpell(Rand) > 0) THEN
              BEGIN
		IF GetName(nt_short, s_na_spell, 'Spell to add? ',
                            Rand.Spell[CanAddSpell(Rand)], 0, AllStats) THEN;
              END
              ELSE
                Writeln('You need to remove a spell first.');
        'g' : BEGIN
		Listgroups;
		Grab_Num('Group? ', Rand.Group, 0, , 0, AllStats);
              END;
        'p' : Grab_Num('PursuitChance? ', Rand.PursuitChance, 0, 100,
                          Rand.PursuitChance, AllStats);
        't' : Grab_Num('Weapon usage? ', Rand.WeaponUse, 0, , Rand.WeaponUse,
                         AllStats);
        'j' : Grab_Num('Level weapon usage? ', Rand.LevelWeaponUse, 0, ,
                         Rand.LevelWeaponUse, AllStats);
        'w' : IF GetName(nt_short, s_na_objnam, 'Weapon? ', Rand.Weapon,
                          Rand.Weapon, AllStats) THEN;
        'o' : IF NOT GetName(nt_short, s_na_objnam, 'Object monster will drop? ',
                              Rand.Object, 0, AllStats) THEN;
	'1' : BEGIN
                Grab_Num('Saying number: ',N ,1 ,10 , 0, AllStats);
                IF N <> 0 THEN
                BEGIN
                  GrabLine('Keyword? ', Rand.Sayings[N].Keyword, AllStats);
		  Rand.Sayings[N].Keyword := LowCase(Rand.Sayings[N].Keyword);
		  GrabLine('Saying? ',Rand.Sayings[N].Saying, AllStats);
                END;
              END;
        'i' : Grab_Num('Base mana? ', Rand.BaseMana, 0, , Rand.BaseMana,
                         AllStats);
        'f' : Grab_Num('Level mana? ', Rand.LevelMana, 0, , Rand.LevelMana,
                         AllStats);
        'z' : Grab_Num('Size? ', Rand.Size, 0, , Rand.Size, AllStats);
        '3' : IF GetName(nt_short, s_na_spell, 'Spell to remove? ', N, 0,
                          AllStats) THEN
              BEGIN
                FOR Loop := 1 TO MaxRandomSpells DO
                  IF (Rand.Spell[Loop] = N) THEN
                    Rand.Spell[Loop] := 0;
              END;
        'q' : Done := TRUE;
        'e' : BEGIN
                Done := TRUE;
                IF SaveRand(RandomNum, Rand) THEN
                BEGIN
                  IF GetShortName(s_NA_RanNam, Nam) THEN
                  BEGIN
                    Nam.Idents[RandomNum] := Rand.Name;
                    IF SaveShortName(s_NA_RanNam, Nam) THEN
                      LogEvent(-1, -1, E_SETNAME, 0, 0, nt_short, s_NA_RANNAM, 
                               '', R_ALLROOMS, Rand.Name, RandomNum);
                  END;
                END
              END;
       	'?',
        'v' : CustomRandHelp(rand);
      END;
    UNTIL Done;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ZeroRandom(VAR Rand : Randrec);

VAR
  I : INTEGER;
  Loop : INTEGER;

BEGIN
  WITH Rand DO
  BEGIN
    BaseHealth := 500;
    RandomHealth := 0;
    BaseDamage := 0;
    Leveldamage := 0;
    RandomDamage := 0;
    Armor := 0;
    SpellArmor := 0;
    MoveSpeed := 0;
    AttackSpeed := 0;
    Kind := 1;
    Experience := 0;
    Gold := 0;
    MinLevel := 0;
    HealSpeed := 0;
    FOR Loop := 1 TO maxRandomSpells DO
      Spell[Loop] := 0;
    Group := 0;
    PursuitChance :=0;
    WeaponUse := 0;
    LevelWeaponUse := 0;
    Weapon :=0;
    Object := 0;
    FOR Loop := 1 TO 10 DO
    BEGIN
      Sayings[Loop].KeyWord := '';
      Sayings[Loop].Saying := '';
    END;
    BaseMana := 0;
    Levelmana := 0;
    Size := 0;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CreateRandom(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  RandName : ShortNameRec;
  Rand : RandRec;

BEGIN
  IF Allocate(I_RAND, N) AND GetShortName(s_NA_RANNAM, RandName) THEN
  BEGIN
    RandName.Idents[N] := LowCase(S);
    IF SaveShortName(s_NA_RANNAM, RandName) THEN
    BEGIN
      Rand.Name := Lowcase(S);
      ZeroRandom(Rand);
      IF SaveRand(N, Rand) THEN
      Writeln('Done');
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ZapRandom(Num : INTEGER);

BEGIN
  IF Deallocate(I_RAND, Num) THEN
    Writeln('Done.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActSearch(MonSlot : INTEGER; VAR AllStats : AllMyStats);

BEGIN
  IF (Here.People[MonSlot].Hiding = 0) THEN
    IF (Rnd(MaxHide) >= Here.People[AllStats.Stats.Slot].Hiding) THEN
    BEGIN
      Here.People[AllStats.Stats.Slot].Hiding := 0;
      LogEvent(MonSlot, 0, E_FOUNDYOU, AllStats.Stats.Slot, AllStats.Stats.Log,
               0,0, Here.People[MonSlot].Name, AllStats.Stats.Location);
    END
    ELSE
      LogEvent(MonSlot, 0, E_SEARCH, 0,0, 0,0, '', AllStats.Stats.Location);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActAttack(MonSlot : INTEGER; VAR AllStats : AllMyStats;
                    VAR TheRand : RandRec);

VAR
  Damage : INTEGER;
  Weapon : String := 'claws'; 
  Log : INTEGER;
BEGIN
  Log := -Here.People[MonSlot].Kind;
  IF not check_bit(HereDesc.SpcRoom, rm$b_nofight) THEN
  BEGIN
    IF Here.People[MonSlot].Hiding > 0 THEN
    BEGIN
      Here.People[MonSlot].Hiding := 0;
      LogEvent(MonSlot, 0, E_MSG, 0,0, 0,0, 'Surprise!',
               AllStats.Stats.Location);
      Damage := TheRand.BaseDamage + TheRand.RandomDamage;
    END ELSE
      Damage := TheRand.BaseDamage + RND(TheRand.RandomDamage);
    Here.People[MonSlot].NextAct := seconds_time * 100 + 
                                    GlobalRandoms[Log].AttackSpeed;
    LogEvent(MonSlot, Here.People[MonSlot].Kind, E_ATTACK,
             AllStats.Stats.Slot, 0,
             Damage, Here.People[MonSlot].NextAct, Weapon,
             AllStats.Stats.Location);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ActFighter(MonSlot : INTEGER; VAR AllStats : AllMyStats;
                     MonNum : INTEGER);

BEGIN
  IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
    ActSearch(MonSlot, AllStats)
  ELSE
    ActAttack(MonSlot, AllStats, GlobalRandoms[MonNum]);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ActWander(VAR AllStats : AllMyStats);
VAR
  Loop, OldOne, One, Chance : INTEGER;
  
BEGIN
  AllStats.Tick.TkRandMove := AllStats.Tick.TkRandMove + 100;
  One := Rnd(MAXRANDOMS);
  OldOne := One;
  IF check_bit(HereDesc.SpcRoom, rm$b_random) then
    chance := HereDesc.mag[rm$b_random]
  else Chance := 1;
  IF check_bit(HereDesc.SpcRoom, rm$b_nofight) THEN Chance := 0;
  IF (RND(100)<=Chance) THEN
  BEGIN
    Loop := 1;
    REPEAT
      if ((length(GlobalRandoms[loop].Name) > 0) and
       (allstats.stats.experience >= (GlobalRandoms[Loop].Minlevel*1000))) then
        one := one - 1;
      if one <> 0 THEN
        loop := loop + 1;
      if loop > maxrandoms then loop := 1;
      if (loop = 1) and (one = oldone) then one := -1;
    UNTIL (One <= 0);
    if one = 0 then
      PutRandomMonsterToken(AllStats.Stats.Location, loop);
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE FollowMe(VAR AllStats : AllMyStats; Dir : INTEGER);
BEGIN
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ActMonster(VAR AllStats : AllMyStats);

VAR
  Loop : INTEGER;
  MonNum : INTEGER := 0;
  Ticks : INTEGER;
  Changed : BYTE_BOOL := FALSE;

BEGIN
  Ticks := GetTicks;
  AllStats.Tick.TkRandAct := AllStats.Tick.TkRandAct + 10;
  GetRoom(AllStats.Stats.Location, here, FALSE, TRUE);
  FOR Loop := 1 TO MaxPeople DO
    IF IsRandomMonster(Here.People[Loop]) THEN
    BEGIN
      IF NOT(Here.People[Loop].Targ IN [1..MaxPeople]) THEN
      BEGIN
        Changed := TRUE;
        Here.People[Loop].Targ := AllStats.Stats.Slot;
      END
      ELSE IF (Here.People[Here.People[Loop].Targ].Kind <= 0) THEN
      BEGIN
        Changed := TRUE;
        Here.People[Loop].Targ := AllStats.Stats.Slot;
      END;
      IF (Here.People[Loop].Targ = AllStats.Stats.Slot) AND
         ((seconds_time*100) >= Here.People[Loop].NextAct) THEN
      BEGIN
        Changed := TRUE;
        MonNum := -Here.People[Loop].Kind;
        CASE MonNum OF
          RM_FIGHTER : ActFighter(Loop, AllStats, MonNum);
          OTHERWISE    ActFighter(Loop, AllStats, MonNum);
        END;
      END;
    END; (* Is a random? *)
  SaveRoom(AllStats.Stats.Location, Here);
END;

(* -------------------------------------------------------------------------- *)

END.
