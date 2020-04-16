[INHERIT ('monconst','montype','monglobl')]

MODULE MonClass(INPUT, OUTPUT);

%include 'headers.txt'

CONST
  NumOptions = 33;
  NumClasses = 9;

VAR
  Options : ARRAY [1..NumOptions] OF String := 
     ('Group number','Name','Who name','Base health','Level health',
      'Base mana','Level mana','Base steal','Level steal','Move silent',
      'Level move silent','Move speed','Attack speed','Heal speed',
      'Base damage','Random damage','Level damage','Armor','Experience',
      'Weapon usage','Level weapon usage','Size','Hear noise','Poison',
      'Control','Void room','Spell armor', 'Monster Type', 'Alignment',
      'Hide delay modifier', 'Shadow damage addition (x + ??x/100)',
      'Save changes', 'Quit');
  Classes : ARRAY [1..NumClasses] OF String :=
  ('Lethal', 'Spell Caster', 'Pinger', 'Duper', 'Gatherer', 'Guardian',
   'Seeker', 'Healer', 'Chaotic');

FUNCTION GetClassType(x : INTEGER) : String;
BEGIN
  IF (x>0) and (x<NumClasses) THEN
    GetClassType := Classes[x]
  ELSE
    GetClassType := 'Unknown';
END;

PROCEDURE PrintClassType;
VAR
  Loop : INTEGER;
BEGIN
  Writeln('0) Unknown');
  FOR Loop := 1 TO NumClasses DO
    Writeln(Loop:0, ') ', Classes[loop]);
END;

[GLOBAL]
PROCEDURE ReadInAllClasses;

VAR
  Indx : IndexRec;
  Loop : INTEGER;

BEGIN
  IF GetIndex(I_Class, Indx) THEN
  BEGIN
    FOR Loop := 1 TO Indx.Top DO
    BEGIN
      GlobalClasses[Loop] := Zero;
      IF NOT(Indx.Free[Loop]) THEN
        IF NOT(GetClass(Loop, GlobalClasses[Loop])) THEN;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE InitClass(VAR Class : ClassRec);

BEGIN
  Class := Zero;
  WITH Class DO
  BEGIN
    Group := 1;
    BaseHealth := 1000;
    LevelHealth := 100;
    MoveSpeed := 100;
    AttackSpeed := 200;
    HealSpeed := 200;
    WeaponUse := 100;
    Size := 6;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION CreateClass(S : String) : INTEGER;

VAR
  Class : ClassRec;
  Slot : INTEGER;
  Nam : RealShortNameRec;

BEGIN
  CreateClass := 0;
  IF Allocate(I_Class, Slot) THEN
  BEGIN
    InitClass(Class);
    Class.Name := S;
    Class.WhoName := S;
    IF SaveClass(Slot, Class) THEN
    BEGIN
      IF GetRealShortName(RSNR_Class, Nam) THEN
      BEGIN
        Nam.Idents[Slot] := S;
        IF SaveRealShortName(RSNR_Class, Nam) THEN
        BEGIN
          CreateClass := Slot;
          Writeln('New class saved.');
        END
        ELSE
        BEGIN
          IF Deallocate(I_Class, Slot) THEN;
          IF DeleteClass(Slot, Class) THEN;
        END;
      END
      ELSE
      BEGIN
        IF Deallocate(I_Class, Slot) THEN;
          IF DeleteClass(Slot, Class) THEN;
      END;
    END
    ELSE
      IF Deallocate(I_Class, Slot) THEN;    
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE PrintClassMenu;

VAR
  Loop : INTEGER;

BEGIN
  Writeln;
  Loop := 0;
  REPEAT
    Loop := Loop + 1;
    Write(Loop:2,'> ');
    WriteNice(Options[Loop],20);
    IF (Loop MOD 3) = 0 THEN
      Writeln;
  UNTIL (Options[Loop] = 'Quit');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION GetClassValue(Class : ClassRec; Num : INTEGER) : INTEGER;

VAR
  N : INTEGER;

BEGIN
  CASE Num OF
    1 : N := Class.Group;
    4 : N := Class.BaseHealth;
    5 : N := Class.LevelHealth;
    6 : N := Class.BaseMana;
    7 : N := Class.LevelMana;
    8 : N := Class.BaseSteal;
    9 : N := Class.LevelSteal;
   10 : N := Class.MoveSilent;
   11 : N := Class.MoveSilentLevel;
   12 : N := Class.MoveSpeed;
   13 : N := Class.AttackSpeed;
   14 : N := Class.HealSpeed;
   15 : N := Class.BaseDamage;
   16 : N := Class.RndDamage;
   17 : N := Class.LevelDamage;
   18 : N := Class.Armor;
   19 : N := Class.ExpAdd;
   20 : N := Class.WeaponUse;
   21 : N := Class.LevelWeaponUse;
   22 : N := Class.Size;
   23 : N := Class.HearNoise;
   24 : N := Class.PoisonChance;
   25 : N := Class.Control;
   26 : N := Class.MyVoid;
   27 : N := Class.SpellArmor;
   29 : N := Class.Alignment;
   30 : N := Class.HideDelay;
   31 : N := Class.ShadowDamagePercent;
 END; (* CASE *)
  GetClassValue := N;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ViewClass(Class : ClassRec);

VAR
  Loop,tmp : INTEGER;
  S : String;

BEGIN
  Writeln;
  Loop := 0;
  REPEAT
    Loop := Loop + 1;
    Write(Loop:2,'> ');
    WriteNice(Options[Loop],20);
    CASE Loop OF
      2       : WriteNice(': ' + Class.Name, 15);
      3       : WriteNice(': ' + Class.WhoName, 15);
      28      : WriteNice(': ' + GetClassType(Class.MonsterType), 15);
      29      : WriteNice(': ' + 
			  ReturnAlignment(GetClassValue(Class, Loop),tmp)
						,15);
      1,4..27,
      30, 31  : BEGIN
                   Writev(S, GetClassValue(Class, Loop):0);
                   WriteNice(': ' + S, 15);
                END;
    END;
    IF (Loop MOD 2) = 0 THEN
      Writeln;
  UNTIL (Options[Loop] = 'Quit');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ZapClass(ClassNum : INTEGER);

BEGIN
  IF Deallocate(I_Class, ClassNum) THEN
    Writeln('Class deleted.')
  ELSE
    Writeln('Ooops. Class not deleted.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CustomClass(MonNum : INTEGER; VAR AllStats : AllMyStats);

VAR
  Nam : RealShortNameRec;
  Num : INTEGER;
  Class : ClassRec;
  Done : BYTE_BOOL := FALSE;
  dummy_s, S : String;
  Dummy : ShortString;
  IntDummy, N : INTEGER;

BEGIN
  IF GetClass(MonNum, Class) THEN
  BEGIN
    REPEAT
      GrabLine('Option to change(v to view)? ', S, AllStats);
      S := Trim(LowCase(S));
      IF Length(S) = 0 THEN
        S := '30';
      IF (NOT IsNum(S)) AND (S <> '?') AND (S <> 'v') THEN
        Writeln('Bad command.  Type ? for help.')
      ELSE
      IF S = '?' THEN
        PrintClassMenu
      ELSE
      IF S = 'v' THEN
        ViewClass(Class)
      ELSE
      BEGIN
        Num := Number(S);
        CASE Num OF
        2,3 : BEGIN
                Case Num OF
                  2 : Writeln('Old name was : ',Class.Name);
                  3 : Writeln('Old who name was : ',Class.WhoName);
                END;
                GrabLine('New name? ', Dummy_s, AllStats, , ShortLen);
                dummy := substr(dummy_s, 1, dummy_s.length);
                CASE Num OF
                  2 : Class.Name := Dummy;
                  3 : Class.WhoName := Dummy;
                END;
              END;
      28 : BEGIN
           PrintClassType;
           Grab_Num('Type of Class? ', Class.MonsterType, 0, NumClasses,
                 Class.MonsterType, AllStats);
           END;
      29 : BEGIN
	   Write('Old ', Options[Num],': ');
	   PrintAlignment(GetClassValue(Class, Num));
	   GrabLine('New alignment? ',S, AllStats,,10);
           IntDummy := LookUpAlign(S);
	      IF IntDummy > 0 THEN
                 Class.Alignment := IntDummy * align_thres;
           END;
	
      1,4..27,
      30,31 : BEGIN
                Write('Old ',Options[Num],': ');
                N := GetClassValue(Class, Num);
                Writeln(N:0);
                Grab_Num('New value? ', N, , , N, AllStats);
                CASE Num OF
                   1 : Class.Group := N;
                   4 : Class.BaseHealth := N;
                   5 : Class.LevelHealth := N;
                   6 : Class.BaseMana := N;
                   7 : Class.LevelMana := N;
                   8 : Class.BaseSteal := N;
                   9 : Class.LevelSteal := N;
                  10 : Class.MoveSilent := N;
                  11 : Class.MoveSilentLevel := N;
                  12 : Class.MoveSpeed := N;
                  13 : Class.AttackSpeed := N;
                  14 : Class.HealSpeed := N;
                  15 : Class.BaseDamage := N;
                  16 : Class.RndDamage := N;
                  17 : Class.LevelDamage := N;
                  18 : Class.Armor := N;
                  19 : Class.ExpAdd := N;
                  20 : Class.WeaponUse := N;
                  21 : Class.LevelWeaponUse := N;
                  22 : Class.Size := N;
                  23 : Class.HearNoise := N;
                  24 : Class.PoisonChance := N;
                  25 : Class.Control := N;
                  26 : Class.MyVoid := N;
                  27 : Class.SpellArmor := N;
                  29 : Class.Alignment := N;
                  30 : Class.HideDelay := N;
                  31 : Class.ShadowDamagePercent := N;
                END; (* CASE *)
              END;
         32 : IF GrabYes('Save Class and exit? ', AllStats) THEN
              BEGIN
                IF SaveClass(MonNum, Class) THEN
                BEGIN
                  IF GetRealShortName(RSNR_Class, Nam) THEN
                  BEGIN
                    Nam.Idents[MonNum] := Class.Name;
                    (* MWG *)
                    IF SaveRealShortName(RSNR_Class, Nam) THEN
                      Writeln('Changes saved.');
                  END;
                  Done := TRUE;
                END
              END
              ELSE
                Writeln('Aborting save...');
         33 : IF GrabYes('Really throw away changes? ',AllStats) THEN
               BEGIN
                Done := TRUE;
                Writeln('Changes scrapped.');
              END;
          OTHERWISE Writeln('Bad option.  Type ? for help.');
        END;  (* CASE *)
      END;    (* If s='?' then else *)
    UNTIL Done;
  END       (* If getmonster *)
  ELSE
    Writeln('Error reading in monster.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE UpdateClassName;
VAR
  Loop : INTEGER;
  Cls : ClassRec;

BEGIN
  FOR Loop := 1 TO MaxGroup DO 
  BEGIN
    GetClass(Loop, Cls);
    RSN[RSNR_Class].Idents[Loop] := Cls.Name;
    RSN[RSNR_WhoName].Idents[loop] := Cls.WhoName;
  END;
  SaveRealShortName(RSNR_Class, RSN[RSNR_Class]);
  SaveRealShortName(RSNR_WhoName, RSN[RSNR_WhoName]);
END;

(* -------------------------------------------------------------------------- *)

END.
