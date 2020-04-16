[INHERIT   ('monconst','montype','monglobl')]

MODULE MonOther(OUTPUT);

%include 'equip.inc'
%include 'headers.txt'

[GLOBAL]
FUNCTION IsRandom(Log : INTEGER) : BYTE_BOOL;
BEGIN
  IsRandom := (Log < 0);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION StartsVowel(S : String) : BYTE_BOOL;

BEGIN
  StartsVowel := FALSE;
  IF (Length(S) > 0) THEN
    IF (S[1] IN ['a','A','e','E','i','I','o','O','u','U']) THEN
      StartsVowel := TRUE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION A_An(S : String) : String;

BEGIN
  IF StartsVowel(S) THEN
     A_An := 'an ' + s
  ELSE
     A_An := 'a ' + s;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ObjName(ObjNum : INTEGER) : String;

BEGIN
  IF ObjNum = 0 THEN
    ObjName := 'Unknown'
  ELSE
    ObjName := GlobalObjects[ObjNum].ObjName
END;

(* -------------------------------------------------------------------------- *)

{ returns the slot # of object if it's wear value is same as passed in }
[GLOBAL]
FUNCTION SlotEquipped(EquipSlot : INTEGER; VAR MyHold : HoldObj):INTEGER;

VAR
  Loop : INTEGER;

BEGIN
  SlotEquipped := 0;
  FOR Loop := 1 TO MaxHold DO
    IF (MyHold.Slot[Loop] = EquipSlot) THEN
       SlotEquipped := Loop;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION DoWeaponName(MyHold : HoldObj): String;
(* Change this to only put the names, if the damage is greater than 0 *)

VAR
  Weapon : String;

BEGIN
  IF SlotEquipped(OW_SWORDHAND,MyHold) > 0 THEN  
  BEGIN
    Weapon := ObjName(MyHold.Holding[SlotEquipped(OW_SWORDHAND,MyHold)]);
    IF SlotEquipped(OW_SHIELDHAND,MyHold) > 0 THEN   
      Weapon := Weapon +' and '+ ObjName(
		MyHold.Holding[SlotEquipped(OW_SHIELDHAND,MyHold)]);
  END
  ELSE
  BEGIN
    IF (SlotEquipped(OW_SHIELDHAND,MyHold) > 0) THEN
       Weapon := ObjName(MyHold.Holding[SlotEquipped(OW_SHIELDHAND,MyHold)])
    ELSE
    BEGIN
      IF SlotEquipped(OW_TWOHAND,MyHold) > 0 THEN
         Weapon := ObjName(MyHold.Holding[SlotEquipped(OW_TWOHAND,MyHold)])
      ELSE
         Weapon := 'claws';
    END;  (* Not wielding in the second slot *)
  END;  (* Not wielding in the first slot *)  
  DoWeaponName := Weapon;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ClearMyHold(VAR MyHold : HoldObj);

VAR
  Loop : INTEGER;

BEGIN
  WITH MyHold DO
  BEGIN
    FOR Loop := 1 TO MaxHold DO
    BEGIN
      Holding[Loop] := 0;
      Slot[Loop] := 0;
      Charges[Loop] := 0;
      Condition[Loop] := 0;
    END;
    Weapon := 'claws';
    BaseArmor := 0;
    DeflectArmor := 0;
    SpellArmor := 0;
    SpellDeflectArmor :=0; (* MWG added this in for fix *)
    Basedamage := 0;
    RandomDamage := 0;
    BreakChanceLeft := 0;
    BreakChanceRight := 0;
    BreakMagnitudeLeft:= 0;
    BreakMagnitudeRight := 0;
    MaxMana := 0;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION EquipObj(VAR AllStats : AllMyStats; Obj : ObjectRec;
                  OSlot : INTEGER) : BYTE_BOOL;

(* We assume that the equiptment has just been wielded, and we are calculating
   what effect it will have on us *)

VAR
  Cl : ClassRec;   (* Class stats *)
  Status : BYTE_BOOL;
  AllClass : IntArray;
  Base : INTEGER;
  Random : INTEGER;
  HaveSpace : BYTE_BOOL := TRUE;
  SlotClear : BYTE_BOOL := TRUE;
  Level : INTEGER;

BEGIN
  IF Obj.Kind = O_EQUIP THEN
  BEGIN
    Status := GetInt(N_Class, AllClass);
    IF Status THEN
      Status := GetClass(AllClass[AllStats.Stats.Log], Cl);
    Level := AllStats.Stats.Experience DIV 1000;

    WITH AllStats.Stats DO
    BEGIN
      Steal := Steal + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
               ( LookupEffect(Obj, EF_BaseSteal) +
               ( LookupEffect(Obj, EF_LevelSteal)) * Level));
      MoveSilent := MoveSilent + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                    ( LookupEffect(Obj, EF_MoveSilent) +
                    ( LookupEffect(Obj, EF_LevelMoveSilent)) * Level));
      MoveSpeed := MoveSpeed + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                   ( LookupEffect(Obj, EF_MoveSpeed)));
      HealSpeed := HealSpeed + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                   ( LookupEffect(Obj, EF_HealSpeed)));
      AttackSpeed := AttackSpeed + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                     ( LookupEffect(Obj, EF_AttackSpeed)));
      WeaponUse := WeaponUse + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                   ( LookupEffect(Obj, EF_WeaponUsage) +
                   ( LookupEffect(Obj, EF_LevelWeaponUsage)) * Level));
      Size := Size + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
              ( LookupEffect(Obj, EF_Size)));
      Control := Control + ROUND(AllStats.MyHold.Condition[OSlot] / 100 *
                ( LookupEffect(Obj, EF_Control)));
      PoisonChance := PoisonChance + ROUND(AllStats.MyHold.Condition[OSlot] /100 *
                      ( LookupEffect(Obj, EF_Poison)));
    END;

    IF (LookupEffect(Obj, EF_Invisible)) = 1 THEN
    BEGIN
      AllStats.Tick.Invisible := TRUE;
      AllStats.Tick.TkInvisible := -1;
    END;
  
    IF (LookupEffect(Obj, EF_SeeInvisible)) = 1 THEN
    BEGIN
      AllStats.Tick.SeeInvisible := TRUE;
      AllStats.Tick.TkSee := -1;
    END;

    WITH AllStats.MyHold DO
    BEGIN
      Maxhealth := MaxHealth + ROUND(Condition[OSlot] / 100 *
                   ( LookupEffect(Obj, EF_BaseHealth) +
                   ( LookupEffect(Obj, EF_LevelHealth)) * Level));
      Maxmana := MaxMana + ROUND(Condition[OSlot] / 100 *
                 ( LookupEffect(Obj, EF_Basemana) +
                 ( LookupEffect(Obj, EF_LevelMana)) * Level));
      Base := ROUND(Condition[OSlot] /100 *
              ( LookupEffect(Obj, EF_WeaponBaseDamage)));
      Random := ROUND(Condition[OSlot] / 100 *
              ( LookupEffect(Obj, EF_WeaponRandomDamage)));
      IF (Base <> 0) OR (Random <> 0) THEN
      BEGIN
        IF Weapon = 'claws' THEN
        BEGIN
          BaseDamage := 0;
          RandomDamage := 0;
        END;
        BaseDamage := BaseDamage + Base;
        RandomDamage := RandomDamage + Random;
      END;

      BaseArmor := BaseArmor + ROUND(Condition[OSlot] / 100 *
                   ( LookupEffect(Obj, EF_BaseArmor)));
      DeflectArmor := DeflectArmor + ROUND(Condition[OSlot] / 100 *
                      ( LookupEffect(Obj, EF_DeflectArmor)));
      SpellArmor := SpellArmor + ROUND(Condition[OSlot] / 100 *
                    ( LookupEffect(Obj, EF_SpellArmor)));
      SpellDeflectArmor := SpellDeflectArmor + ROUND(Condition[OSlot] / 100 *
                           ( LookupEffect(Obj, EF_SpellDestroy)));
      (* MWG this [spelldeflectarmor] was a quick and easy fix *)

      IF Obj.Wear = OW_ShieldHand THEN 
      BEGIN
        BreakChanceLeft := BreakChanceLeft + LookupEffect(Obj, EF_BreakChance);
        BreakMagnitudeLeft := BreakMagnitudeLeft + LookupEffect(Obj, EF_BreakMagnitude);
      END;
      IF (Obj.Wear = OW_SwordHand) OR (Obj.Wear = OW_TwoHand) THEN
      BEGIN
        BreakChanceRight := BreakChanceRight + LookupEffect(Obj, EF_BreakChance);
        BreakMagnitudeRight := BreakMagnitudeRight + LookupEffect(Obj, EF_BreakMagnitude);
      END;
      Weapon := DoWeaponName(AllStats.MyHold);
      IF Weapon = 'claws' THEN
      BEGIN
        IF Cl.BaseDamage + Cl.RndDamage +
            Cl.LevelDamage*TRUNC(AllStats.Stats.Experience/1000) > 0 THEN
        BEGIN
          BaseDamage := Cl.BaseDamage + ROUND(Condition[OSlot] / 100 *
                        ( LookupEffect(Obj, EF_BaseDamage)));
          RandomDamage := Cl.RndDamage +
                          Cl.LevelDamage*TRUNC(AllStats.Stats.Experience/1000) +
                          ROUND(Condition[OSlot] / 100 *
                          ( LookupEffect(Obj, EF_RandomDamage) +
                          ( LookupEffect(Obj, EF_LevelDamage)) * Level));
        END;
      END;
      EquipObj := Status;
    END;  (* WITH Statement *)
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION EquipmentStats(VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Obj : ObjectRec;
  Charac : CharRec;

BEGIN
  EquipmentStats := TRUE;
  IF GetChar(AllStats.Stats.Log, Charac) THEN
  BEGIN
    ClearMyHold(AllStats.MyHold);
    ClassStats(AllStats);
    FOR Loop := 1 to MaxHold DO
    BEGIN
      IF Charac.Item[Loop] <> 0 THEN
      BEGIN
        Obj := GlobalObjects[Charac.Item[Loop]];
        AllStats.MyHold.Holding[Loop] := Charac.Item[Loop];
        AllStats.MyHold.Charges[Loop] := Charac.Charges[Loop];
        AllStats.MyHold.Condition[Loop] := Charac.Condition[Loop];
        IF Charac.Equip[Loop] THEN
        BEGIN
          IF EquipIt(Loop, TRUE, AllStats.MyHold, AllStats.Stats) THEN
            EquipObj(AllStats, Obj, Loop);
        END;
        AllStats.Stats.MoveSpeed := AllStats.Stats.MoveSpeed + Obj.Weight;
      END;
    END;  (* FOR LOOP *)
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION IsDescription(Slot : INTEGER) : BYTE_BOOL;

BEGIN
  IF (Slot = 0) OR (ABS(Slot) = DEFAULT_DESC) THEN
     IsDescription := FALSE
  ELSE
     IsDescription := TRUE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE WriteNice(S : String; L : INTEGER);

VAR
  I : INTEGER;

BEGIN
  Write(S);
  IF L >= LENGTH(S) + 1 THEN
    FOR I := LENGTH(S) + 1 TO L DO
      Write(' ');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION GetGroupName(Group : INTEGER) : String;

VAR
  RealShortName : RealShortNameRec;

BEGIN
  IF GetRealShortName(RSNR_GroupName, RealShortName) THEN
    IF Group <> 0 THEN
      GetGroupname := RealShortName.Idents[Group]
    ELSE
      GetGroupName := 'All'
  ELSE
    GetGroupName := 'All';
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ListGroups;

VAR
  Loop : INTEGER := 1;
  RealShortName : RealShortNameRec;
  Indx : IndexRec;

BEGIN
  Writeln('---- Groups ----');
  IF GetRealShortName(RSNR_GroupName, RealShortName) AND
     GetIndex(I_GroupName, Indx) THEN
  BEGIN
    FOR Loop := 1 TO Indx.Top DO
      IF NOT Indx.Free[Loop] THEN
        Writeln(Loop:2,'> ',RealShortName.Idents[Loop]);
  END;
  Writeln('----------------');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE StartHighLight;
BEGIN
  Write(CHR(27),'[1m');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE StopHighLight;
BEGIN
  Write(CHR(27),'[0m');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE FixHealth(VAR Health : INTEGER; MaxHealth : INTEGER);

BEGIN
  IF Health < 0 THEN Health := 0
  ELSE
  IF Health > MaxHealth THEN Health := MaxHealth;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DescMyHealth(MaxHealth, CurrentHealth : INTEGER);

BEGIN
  Write('You ');
  CASE CurrentHealth OF
    1700..MAXINT : Writeln('are in ultimate health.');
    1400..1699   : Writeln('are in incredible health.');
    1200..1399   : Writeln('are in extraordinary health.');
    1000..1199   : Writeln('are in tremendous condition.');
    850..999     : Writeln('are in superior condition.');
    700..849     : Writeln('are in exceptional health.');
    500..699     : Writeln('are in good health.');
    350..499     : Writeln('are a little bit dazed.');
    200..349     : Writeln('have some minor wounds.');
    100..199     : Writeln('are suffering from some serious wounds.');
    50..99       : Writeln('are in critical condition.');
    1..49        : Writeln('are knocking on death''s door.');
    0            : Writeln('are dead.');
    OTHERWISE      Writeln('has a fucked up health.');
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PoorHealth(Damage : INTEGER; Armor : BYTE_BOOL:=TRUE;
                     Spell : BYTE_BOOL := FALSE; CanDie : BYTE_BOOL := TRUE;
                     VAR AllStats : AllMyStats);

VAR
  Some : BYTE_BOOL;
  S : String;
  ObjStats : HoldObj;

BEGIN
  ObjStats := AllStats.MyHold;
  IF AllStats.Stats.Privd THEN
    Writeln('---Sock--- [',Damage:0,']');
  IF ObjStats.BaseArmor + ObjStats.DeflectArmor + ObjStats.SpellArmor > 0 THEN
  BEGIN
    IF Armor THEN
    BEGIN
      IF Rnd(100) < ObjStats.DeflectArmor THEN
      BEGIN
        Writeln('The attack is deflected by your armor.');
        Damage := Damage DIV 2;
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_TRYATTACK,
                 0, AllStats.Stats.LastHit, 100, 0,
                 AllStats.Stats.LastHitString, AllStats.Stats.Location);
      END
      ELSE
      IF ObjStats.BaseArmor > 0 THEN
      BEGIN
        Writeln('The attack was partially blocked by your armor.');
        Damage := (Damage * (100-ObjStats.BaseArmor)) DIV 100;
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_TRYATTACK,
                 0, AllStats.Stats.Lasthit, ObjStats.BaseArmor, 0,
                 AllStats.Stats.LastHitString, AllStats.Stats.Location);
      END;
    END
  ELSE IF Spell THEN
    BEGIN
      IF ObjStats.SpellArmor> 0 THEN
      BEGIN
	Damage := (Damage * (100-ObjStats.SpellArmor) DIV 100);
	LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_TRYSPELL,
                 0, AllStats.Stats.LastHit, ObjStats.SpellArmor, 0,
                 AllStats.Stats.LastHitString, AllStats.Stats.Location); 
      END;
    END;
  END;
  IF NOT Spell THEN
    Damage := (Damage * (100-ObjStats.BaseArmor)) DIV 100;
  AllStats.Stats.Health := AllStats.Stats.Health - Damage;
  FixHealth(AllStats.Stats.Health, AllStats.MyHold.MaxHealth);
  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log,  E_WEAKER,
           0, 0, AllStats.Stats.Health, 0,
           AllStats.Stats.Name, AllStats.Stats.Location);
  DescMyHealth(AllStats.MyHold.MaxHealth, AllStats.Stats.Health);
  IF (AllStats.Stats.Health <= 0) THEN DoDie(AllStats);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE EffectDecompress(VAR Mag, Kind : INTEGER; Crypt : INTEGER);

BEGIN
  Mag := Crypt DIV 100;
  Kind := Crypt MOD 100;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE EffectCompress(Mag, Kind : INTEGER; VAR Crypt: INTEGER);

BEGIN
  Crypt := Mag * 100 + Kind;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION SpellMana(LogNum : INTEGER) : INTEGER;

VAR
  Loop ,SM : INTEGER;
  Charac : CharRec;

BEGIN
  SM := 0;
  IF GetChar(LogNum, Charac) THEN
  FOR Loop:= 1 TO MaxSpells DO
  BEGIN
    IF Charac.Spell[Loop] > 0 THEN
      SM := SM + (Charac.Spell[Loop] * GlobalSpells[Loop].Mana);
  END;
  SpellMana := SM;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE FixMana(VAR Stats : StatType; MM : INTEGER);

VAR
  SM : INTEGER;   (* Mana used in spells. *)

BEGIN
  SM := Spellmana(Stats.Log);
  IF (Stats.Mana + SM) > MM THEN
     Stats.Mana := MM-SM
  ELSE
    IF Stats.Mana < 0 THEN
      Stats.Mana := 0;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE Rectify(VAR AllStats : AllMyStats);

VAR
  Lev, N : INTEGER;

BEGIN
  FixHealth(AllStats.Stats.Health, AllStats.MyHold.MaxHealth);
  FixMana(AllStats.Stats, AllStats.MyHold.MaxMana);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ForgetSpells(VAR AllStats : AllMyStats);

VAR
  Loop : INTEGER;
  Character : CharRec;

BEGIN
  IF GetChar(AllStats.Stats.Log, Character) THEN
  BEGIN
    FOR Loop := 1 to MaxSpells DO
       Character.Spell[Loop] := 0;
    IF SaveChar(AllStats.Stats.Log, Character) THEN
       Rectify(AllStats);
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PrintDesc(Dsc : INTEGER; Default : String := '<no default supplied>');

VAR
  Loop : INTEGER;
  Block : DescRec;
  Line : LineRec;

BEGIN
  IF Dsc = DEFAULT_DESC THEN
     Writeln(Default)
  ELSE
  IF Dsc > 0 THEN
  BEGIN
    IF GetDesc(Dsc, Block) THEN
      FOR Loop := 1 TO Block.DescLen DO
        Writeln(Block.Lines[Loop])
    ELSE
      Writeln('Bad description.. perhaps you should zero it.');
  END
  ELSE
  IF Dsc < 0 THEN
  BEGIN
    IF GetLine(-Dsc, Line) THEN
      Writeln(Line.Line)
    ELSE
      Writeln('Bad description.. perhaps you should zero it.');
  END;
END;

(* -------------------------------------------------------------------*)

[GLOBAL]
FUNCTION ObjPrice(ObjNum : INTEGER) : INTEGER;

(* MWG, returns the price of the object *)

VAR

  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[ObjNum];
  ObjPrice := Obj.Worth;
END;

(* -------------------------------------------------------------------------- *)


(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ObjPart(ObjNum : INTEGER) : String;

VAR
  S : String;
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[ObjNum];
  S := Obj.ObjName;
  CASE Obj.Particle OF
    1: S := 'a ' + S;
    2: S := 'an ' + S;
    3: S := 'some ' + S;
    4: S := 'the ' + S;
  END;
  ObjPart := S;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ShowCondition(Cond : INTEGER) : String;

BEGIN
  CASE Cond OF
  -MAXINT..0	:ShowCondition := 'Useless';
   1..25 	:ShowCondition := 'Nearly useless';
  26..50 	:ShowCondition := 'Terrible';
  51..70 	:ShowCondition := 'Very bad';
  71..80 	:ShowCondition := 'Poor';
  81..90 	:ShowCondition := 'Fair';
  91..95	:ShowCondition := 'Good';
  96..100	:ShowCondition := 'Excellent';
  101..115	:ShowCondition := 'Exceptional';
  116..125	:ShowCondition := 'Hoopy';
  126..200    	:ShowCondition := 'Tremendous';
  201..MAXINT 	:ShowCondition := 'Ludicrous';
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LeftHalf(S : String; Icon : CHAR := '#') : String;

VAR
  I : INTEGER;

BEGIN
  I := Index(S, Icon);
  IF I > 0 THEN
    LeftHalf := SubStr(S,1,I-1)
  ELSE
    LeftHalf := '';
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION RightHalf(S : String; Icon : CHAR := '#') : String;

VAR
  I : INTEGER;

BEGIN
  I := Index(S, Icon);
  IF I > 0 THEN
     RightHalf := SubStr(S,I+1,LENGTH(S)-I)
  ELSE
     RightHalf := S;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION SubsParm(S, Parm : String; Icon : CHAR := '#') : String;

BEGIN
  SubsParm := S;
  IF (Index(S, Icon) > 0) THEN
    IF ((LENGTH(S) + LENGTH(Parm)) <= 80) THEN
     SubsParm := LeftHalf(S, Icon) + Parm + RightHalf(S, Icon);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoToggle(VAR Param : BYTE_BOOL; S : String);

VAR
  Repl : String := 'not ';

BEGIN
  Param := NOT Param;
  IF Param THEN
    Repl := '';
  Writeln(SubsParm(S, Repl, '#'));  
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PrintSubs(Slot : INTEGER; S : String);

VAR
  Line : LineRec;
  Status : BYTE_BOOL;

BEGIN
  IF IsDescription(Slot) THEN
  BEGIN
    Slot := ABS(Slot);
    Status := GetLine(Slot, Line);
    IF Slot = DEFAULT_DESC THEN
       Writeln('%<default line> in print_subs')
    ELSE
       Writeln(SubsParm(Line.Line,S));
  END
  ELSE IF Slot = DEFAULT_DESC THEN
          Writeln('%<default line> in print_subs');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION MakeLine(VAR Slot : INTEGER; Prompt : String := '';
                  VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  S : String;
  OK : BYTE_BOOL;
  ALine : LineRec;

BEGIN
  MakeLine := FALSE;
  Writeln('Editing the ',prompt,' description line.');
  Writeln('Type *** for deafult, ** to leave line unchanged, * to make [no line]');
  Writeln('Use # for special substitutions.');
  PrintSubs(Slot,'#');
  GrabLine('Desc> ',S,AllStats);
  IF S = '**' THEN
  BEGIN
    Writeln('No changes to ',prompt,'.');
    MakeLine := TRUE;
  END
  ELSE IF S = '***' THEN
  BEGIN
    DeAllocateDesc(Slot);
    Slot := DEFAULT_DESC;
    MakeLine := TRUE;
  END
  ELSE IF (S = '*') THEN
  BEGIN
    DeAllocateDesc(Slot);
    Slot := 0;
    MakeLine := TRUE;
  END
  ELSE
  IF (S <> '') THEN
  BEGIN
    DeAllocateDesc(Slot);
    IF Allocate(I_Line,Slot) THEN
    BEGIN
      ALine.Line := S;
      MakeLine := SaveLine(Slot, Aline);
      Slot := -Slot;
    END;
  END
  ELSE
    MakeLine := TRUE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION PlaceObj(ObjNum, Location, Cond, Charges : INTEGER;
	          Silent, Shop : BYTE_BOOL:=FALSE; CanDestroy : BYTE_BOOL := TRUE;
                  VAR AllStats : AllMyStats) : BYTE_BOOL;

CONST
  MaxLevel = 10;
VAR
  DropDest, DropRoom : INTEGER;   (* The room number that the object drops to *)
  LocDesc : RoomDesc;
  DRoom : room;
  Level, Slot : INTEGER;
  Found : BYTE_BOOL := FALSE;
  Obj : ObjectRec;
  Destroy : BYTE_BOOL := FALSE;
  P2 : INTEGER;
BEGIN
  Obj := GlobalObjects[ObjNum];
  PlaceObj := FALSE;
  DropDest := Location;
  Level := 0;
  REPEAT
    DropRoom := DropDest;
    GetRoomDesc(DropDest, LocDesc);
    DropDest := LocDesc.ObjDrop;
    Level := Level + 1;
  UNTIL ((DropDest = 0) OR (DropDest = DropRoom) OR (Level > MAXLEVEL));

  IF ((DropDest = 0) OR (DropDest = DropRoom)) THEN
  BEGIN
    GetRoom(DropRoom, DRoom);
    IF (check_bit(LocDesc.SpcRoom, rm$b_store) AND (NOT Shop)) THEN
      Writeln('You can not drop things in a shop.')
    ELSE
    IF (((Obj.Kind = O_EQUIP) AND (LookupEffect(Obj, EF_DROPDESTROY) = 1)) OR
        check_bit(LocDesc.SpcRoom, rm$b_objdestroy)) THEN
    BEGIN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0, 0,
               0, ObjPart(ObjNum) + ' was detroyed when ' +
               AllStats.Stats.Name + ' dropped it.', AllStats.Stats.Location);
      IF NOT Silent THEN Inform_Destroy(Obj.ObjName);
      PlaceObj := TRUE;
    END
    ELSE
    BEGIN
      Slot := 1;
      IF GlobalObjects[ObjNum].Kind = O_MISSILE THEN
      BEGIN
        WHILE (NOT(FOUND) AND (Slot<=MaxObjs)) DO
        BEGIN
          IF ((Droom.Objs[Slot] MOD 1000) = ObjNum) THEN
          BEGIN
            Found := TRUE;
            Charges := Charges + Droom.ObjHide[Slot] DIV 1000;
          END ELSE Slot := Slot + 1;
        END;
      END; (* Was it a missile *)
      IF Not(Found) THEN Slot := 1;
      WHILE ((Slot<MaxObjs) AND NOT(FOUND)) DO
        IF ((Droom.Objs[Slot] MOD 1000) = 0) THEN Found := TRUE
        ELSE Slot := Slot + 1;
      IF Found THEN
      BEGIN
        Droom.Objs[Slot] := ObjNum + Cond*1000;
        Droom.Objhide[Slot] := Charges * 1000;
        IF (DropRoom = AllStats.Stats.Location) THEN
        BEGIN
          Here.Objs[Slot] := ObjNum + Cond*1000;
          Here.Objhide[Slot] := Charges * 1000;
        END;
        SaveRoom(DropRoom, Droom);
        IF Location <> DropRoom THEN
           LogEvent(0, 0, E_BOUNCEDIN, 0, 0, ObjNum, HereDesc.ObjDest, '',
                    HereDesc.ObjDrop);
        P2 := 0;
        IF Silent THEN P2 := 1;
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_DROP, 0, 0, 0,
                 P2, AllStats.Stats.Name+' has dropped '+ ObjPart(ObjNum)+'.',
                 Location, , Slot, Droom.Objs[Slot], Droom.ObjHide[Slot]);
        IF NOT(Silent) THEN
	  IF HereDesc.ObjDesc <> 0 THEN PrintSubs(HereDesc.ObjDesc, ObjPart(ObjNum))
	  ELSE Writeln('Dropped.');
        PlaceObj := TRUE;
      END;
    END;
  END
  ELSE
  BEGIN
    Writeln('The object vaporizes itself in a brilliant flash of light.');
    PlaceObj := TRUE;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION GetName(NameLength : INTEGER; NameType : INTEGER; Text : String;
                 VAR SlotNum : INTEGER; Default : INTEGER := 0;
                 VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  G : String;
  N : INTEGER;

BEGIN
  GetName := TRUE;
  Writeln('Enter * for default.');
  GrabLine(Text, G, AllStats);
  IF G = '*' THEN
    SlotNum := Default
  ELSE
    IF NOT LookUpName(NameLength, NameType, SlotNum, G, FALSE, FALSE) THEN
    BEGIN
      Writeln('No changes.');
      GetName := FALSE;
    END;
END;

END.
