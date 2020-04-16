[INHERIT ('MONCONST','MONTYPE','MONGLOBL')]

MODULE MonObj(OUTPUT);

%include 'headers.txt'
%include 'equip.inc'

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION LookupObjName(VAR N : INTEGER; S : String;
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
  if (good) then found := lookupnameraw(nam.idents, ind, N, S, exact);
  LookupObjName := found;
  if not(found) and not(silent) then
    writeln('I could not find object ', S, '.');
END;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION GetObjOwner(N : INTEGER; VAR Owner : ShortString) : BYTE_BOOL;
VAR
  Own : ShortNameRec;
BEGIN
  GetObjOwner := FALSE;
  IF GetShortName(s_na_objown, own) THEN
  BEGIN
    Owner := Own.Idents[N];
    GetObjOwner := TRUE;
  END;
END;

[GLOBAL]
FUNCTION SetObjOwner(N : INTEGER; Owner : ShortString) : BYTE_BOOL;
VAR
  Own : ShortNameRec;
BEGIN
  SetObjOwner := FALSE;
  IF GetShortName(s_na_objown, own) THEN
  BEGIN
    Own.Idents[N] := Owner;
    IF SaveShortName(s_na_objown, own) THEN
    BEGIN
      LogEvent(-1, -1, e_setname, 0, 0, nt_short, s_na_objown, '', r_allrooms,
               owner, n);
      SetObjOwner := TRUE;
    END;
  END;
END;

[GLOBAL]
FUNCTION IsObjOwner(ObjNo : INTEGER; Privd : BYTE_BOOL;
                    CheckPub : Byte_Bool) : BYTE_BOOL;
VAR
  MyId, Own : ShortString;
BEGIN
  MyId := LowCase(UserId);
  IF GetObjOwner(ObjNo, Own) THEN
    IsObjOwner := (CheckPub AND (Own = '')) OR (LowCase(Own) = MyId) OR Privd
  ELSE IsObjOwner := Privd;
END;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION GetObjName(N : INTEGER; VAR Name : ShortString) : BYTE_BOOL;
VAR
  Nam : ShortNameRec;
BEGIN
  GetObjName := FALSE;
  Name := 'ERROR';
  IF GetShortName(s_na_objnam, Nam) THEN
  BEGIN
    Name := Nam.Idents[N];
    GetObjName := TRUE;
  END;
END;

[GLOBAL]
FUNCTION SetObjName(N : INTEGER; Name : ShortString) : BYTE_BOOL;
VAR
  Nam : ShortNameRec;
BEGIN
  SetObjName := FALSE;
  IF GetShortName(s_na_objnam, nam) THEN
  BEGIN
    Nam.Idents[N] := Name;
    IF SaveShortName(s_na_objnam, Nam) THEN
    BEGIN
      LogEvent(-1, -1, e_setname, 0, 0, nt_short, s_na_objnam, '', r_allrooms,
               name, n);
      LogEvent(0, 0, E_READOBJECT, 0, 0, N, 0, '', R_ALLROOMS);
      SetObjName := TRUE;
    END;
  END;
END;

[GLOBAL]
PROCEDURE ReadinAllObjects;

VAR
  Indx : IndexRec;
  Loop : INTEGER;

BEGIN
  IF GetIndex(I_Object, Indx) THEN
    FOR Loop := 1 TO Indx.Top DO
    BEGIN
      GlobalObjects[Loop] := Zero;
      IF NOT Indx.Free[Loop] THEN
        IF NOT GetObj(Loop, GlobalObjects[Loop]) THEN;
    END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE GrabParm(Prompt : String; Parm : INTEGER; VAR Obj : ObjectRec;
                   ObjEffect : INTEGER; Max : INTEGER := MAXINT;
                   Min : INTEGER := 0; Default : INTEGER := 0;
                   VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  S : String;
  Privd : BYTE_BOOL;

BEGIN
  Privd := AllStats.Stats.Privd;
  GrabLine(Prompt, S,AllStats);
  IF IsNum(S) THEN
  BEGIN
    N := Number(S);
    IF ((Max >= Min) AND ((N > Max) OR (N < Min) )) AND (NOT PRIVD) THEN
      IF Max < N THEN
         Writeln(N, ' is to high.')
      ELSE
         WRITELN(N, ' is to low.')
    ELSE
    BEGIN
      IF N = 0 THEN    
        ObjEffect := default;
      IF ObjEffect <> 0 THEN
        IF N < 0 THEN
          N := ObjEffect + 100*(N-1)
        ELSE
          N := ObjEffect + 100*N;
      Obj.Parms[Parm] := N;
    END;
  END
  ELSE
    Writeln('Non-integer ignored');
END;

FUNCTION LookUpStat(S : String) : INTEGER;

VAR
  I, Poss, Maybe, Num : INTEGER;

BEGIN
  S := LowCase(S);
  I := 1;
  Maybe := 0;
  Num := 0;
  FOR I := 1 TO MaxStat DO
  BEGIN
    IF S = Stat[I] THEN
      Num := i
    ELSE
      IF Index(Stat[I],S) = 1 THEN
      BEGIN
        Maybe := Maybe + 1;
        Poss := i;
      END;
  END;
  IF Num <> 0 THEN
    LookUpStat := Num
  ELSE
    IF Maybe = 1 THEN
      LookUpStat := Poss
    ELSE
      LookUpStat := C_ERROR;
END;

PROCEDURE ShowEffects;

VAR
  I : INTEGER;

BEGIN
  I := 1;
  WHILE I <= MaxStat DO
  BEGIN
    Write(Stat[I]:20);
    IF I+1 <= MaxStat THEN
      Write('   ',stat[I+1]:20);
    IF I+2 <= MaxStat THEN
      Writeln('   ',stat[I+2]:20);
    I := I + 3;
  END;
  Writeln;
END;

FUNCTION FindASlot(LookingFor : INTEGER; Obj : ObjectRec) : INTEGER;

VAR
  I : INTEGER;
  First : BYTE_BOOL;

BEGIN
  First := TRUE;
  FindASlot := 0;
  FOR I := 1 TO MaxParm DO
    IF (Obj.Parms[I] MOD 100 = LookingFor) AND First THEN
    BEGIN
      FindASlot := I;
      First := FALSE;
    END;
END;

[GLOBAL]
PROCEDURE ListSpells(MyClass : INTEGER; MyGroup : INTEGER; MyExp : INTEGER;
                     Privd : BYTE_BOOL := FALSE);

VAR
  N : INTEGER;
  Right : BYTE_BOOL := FALSE;
  Indx : IndexRec;
  Spell : SpellRec;

BEGIN
  IF GetIndex(I_Spell, Indx) THEN
  BEGIN
    Writeln('Spell name          Mana/Lvl Lvl Time  |  Spell name          Mana/Lvl Lvl Time');
    Writeln('---------------------------------------+---------------------------------------');
    FOR N := 1 TO Indx.Top DO
      IF NOT Indx.Free[N] THEN
      BEGIN
        Spell := GlobalSpells[N];
        IF Privd OR ((Spell.Class = 0) OR (Spell.Class = MyClass))
          AND ((Spell.Group = MyGroup) OR (Spell.Group = 0)) THEN
        BEGIN
          IF ((MyExp DIV 1000) >= Spell.MinLevel) THEN
          BEGIN
            WITH Spell DO
            BEGIN
              WriteNice(Name,20);
              Write(Mana:4,'/',LevelMana:2,' ',MinLevel:4, CastingTime/100:5:1);
            END;
            IF Right THEN Writeln
            ELSE Write('  |  ');
            Right := NOT Right;
           END;
        END;
      END;
  END;
  Writeln;
END;

PROCEDURE AddEffect(VAR Obj : ObjectRec; S : String:= '';
                    VAR AllStats : AllMyStats);

VAR
  I, J, Slot : INTEGER;
  MyExp : INTEGER;

BEGIN
  MyExp := AllStats.Stats.Experience;
  IF Length(S) > 0 THEN
    IF S[1] = '?' THEN
      ShowEffects;
  I := LookupStat(s);
  IF I > 0 THEN
  BEGIN
    Slot := FindASlot(I, Obj);   (* Are we using that option *)
    IF Slot = 0 THEN
      Slot := FindASlot(0, Obj);  (* If not already an option, use blank *)
    IF Slot <> 0 THEN
    BEGIN
      CASE I OF
   	EF_INVISIBLE,
        EF_SEEINVISIBLE,
        EF_CURSED,
        EF_TRAP,
        EF_DROPDESTROY,
        EF_NOTHROW : BEGIN
                       Writeln('Choose 0(False) or 1(True).');
                       GrabParm(Stat[I] + ': ', Slot, Obj, I,,, 0, AllStats)
                     END;
	EF_SPELL : BEGIN
                     ListSpells(0,0, MyExp);
                     GrabParm(Stat[I] + ': ', Slot, Obj, I,,,0, AllStats)
                   END;
	EF_TELEPORT  : BEGIN
                         REPEAT
                           GrabLine('Enter teleport destination : ',S,AllStats);
                         UNTIL (S='') OR LookUpRoomName(S, j, false, false);
                         IF S <> '' THEN
                           Obj.Parms[Slot] := I + J*100;
		       END;
        OTHERWISE GrabParm(Stat[I] + ': ', Slot, Obj, I,,,0,AllStats)
      END;
    END
    ELSE
      Writeln('You must first remove an effect.')
  END
  ELSE
    Writeln('%Error-Parse-Field, Unknown attribute ',I:0); 
END;

[GLOBAL]
PROCEDURE ProgObjEquipView(Obj : ObjectRec);

VAR
  I : INTEGER;

BEGIN
  FOR I := 1 TO MaxParm DO
    IF Obj.Parms[I] MOD 100 IN [1..MaxStat] THEN
     Writeln(Stat[Obj.Parms[I] MOD 100]:20, Obj.Parms[I] DIV 100);
END;

PROCEDURE ProgObjEquipHelp;

BEGIN
  Writeln('Type the name of the attribute to be added/removed.');
  Writeln('S) Show effects');
  Writeln('V) View object');
  Writeln('E) Exit');
END;

PROCEDURE ProgObjEquip(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL := FALSE;
  S : String;
  MyExp : INTEGER;

BEGIN
  MyExp := AllStats.Stats.Experience;
  REPEAT
    GrabLine('Program equipment>',s,AllStats);
    S := Lowcase(Trim(S));
    IF Length(S) = 1 THEN
    CASE S[1] OF
        '?': ProgObjEquipHelp;
	's': ShowEffects;
    'q','e': Done := TRUE;
	'v': ProgObjEquipView(Obj);
    END
    ELSE
      IF Length(S) = 0 THEN
        Done := TRUE
      ELSE
        AddEffect(Obj, S, AllStats);
  UNTIL Done;
END;

PROCEDURE SpellBookMenu;

BEGIN
  writeln('A - Add spell');
  writeln('G - Group usable by');
  writeln('L - List all spells');
  writeln('R - Remove spell');
  writeln('V - View spells in spellbook');
  writeln('Q - Quit');
END;

PROCEDURE ProgObjSbook(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL := FALSE;
  S : String;
  N, Page : INTEGER;
  SpellNam : ShortNameRec;
  MyExp : INTEGER;

BEGIN
  MyExp := AllStats.Stats.Experience;
  IF GetShortName(s_NA_Spell, SpellNam) THEN
  REPEAT
    GrabLine('Program spell book>',s,AllStats);
    S := LowCase(Trim(s));
    IF Length(S) = 1 THEN
      CASE S[1] OF
        '?'    : SpellBookMenu;
        'q','e': Done := TRUE;
        'l'    : ListSpells(0,0,MyExp);
        'u'    : BEGIN
	           ListGroups;
	           GrabParm('Group number? ',1,Obj,0,,,0,AllStats);
	         END;
        'a'    : BEGIN
       	           Grab_num('Page number [2..20]', Page, 2, 20, 2, AllStats);
                   IF GetName(nt_short, s_na_spell, 'Spell? ',N,,AllStats) THEN
	             Obj.Parms[Page] := N;
           	 END;
        'r'    : BEGIN
	           Grab_Num('Remove spell from page[2..20]',page,2,20,2,AllStats);
    	           Obj.Parms[Page] := 0;
                 END;
        'v'    : BEGIN
	           WRITELN;
	           Writeln('Spells for group: ',getgroupname(obj.parms[1]));
	           Writeln('Spells: ');
	           FOR Page := 2 TO 20 DO
	             IF Obj.Parms[Page] > 0 THEN
	               Writeln(page:2,'-',SpellNam.idents[obj.parms[page]]);
	           Writeln;
	         END;
        OTHERWISE Inform_BadCmd;
    END
    ELSE
      IF Length(S) = 0 THEN
        Done := TRUE
      ELSE
         Writeln('%ERROR-Parse-Option, Error parsing command.');
  UNTIL Done
  ELSE
    Writeln('Error readin in spell names.');
END;

PROCEDURE ProgObjMissile(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL;
  S : String;

  PROCEDURE PrintMenu;

  BEGIN
    writeln('1) Base amount of damage done.');
    writeln('2) Random amount of damage.');
    writeln('3) Number of missiles');
    writeln('4) View settings.');
    writeln('5) Quit.');
    writeln('? - For Help.');
  END;

  PROCEDURE ViewSettings(Obj : ObjectRec);

  BEGIN
    Writeln('Damage = ', Obj.Parms[1]:1,' + 1..',Obj.Parms[2]:1,'.');
    Writeln('Number of missiles ',Obj.Parms[3]:1,'.');
  END;

BEGIN
  PrintMenu;
  Done := FALSE;
  REPEAT
    S := ' ';
    GrabLine ('Missile> ',S,AllStats);
    S := Lowcase(Trim(S));
    CASE S.Body[1] OF
      '1','b' : GrabParm('Base Damage? ',1, Obj, 0,30,0,0,AllStats);
      '2','r' : GrabParm('Random Damage? ', 2, Obj, 0,30,0,0,AllStats);
      '3','n' : GrabParm('Number of missiles? ',3, Obj, 0,10,0,0,AllStats);
      '4','v' : ViewSettings(Obj);
      '5','q','e' : Done := TRUE;
      '?','6' : PrintMenu;   
    END; 
  UNTIL Done;
END;

PROCEDURE ProgObjMissileLauncher (VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL;
  S : String;

  PROCEDURE PrintMenu;

  BEGIN
    Writeln('1) Missile for launcher.');
    Writeln('2) Range of launcher.');
    Writeln('3) Set Firing Time Delay (in milliseconds)');
    Writeln('4) Set Base Damage.');
    Writeln('5) Set Random Damage.');
    Writeln('6) View current settings.');
    Writeln('7) Quit.');
    Writeln('? - Help.');
  END;

  PROCEDURE ViewSettings(Obj : ObjectRec);

  BEGIN
    IF Obj.Parms[1] = 0 THEN
      Writeln('No missile for weapon.')
    ELSE
      Writeln('Missile  :',GlobalObjects[Obj.Parms[1]].ObjName,'.');   
    Writeln  ('Range    :',Obj.Parms[2],'.');
    Writeln  ('Base D   :',Obj.Parms[3]);
    Writeln  ('Rand D   :',Obj.Parms[4]);
    Writeln  ('Fire Time:',Obj.Parms[5], 'ms');
  END;

  PROCEDURE ChangeMissile(VAR Obj :ObjectRec; VAR AllStats : AllMyStats);

  VAR
    S : String;
    N : INTEGER;

  BEGIN
    GrabLine ('New missile? ',S,AllStats);
    S := Trim(S);
    IF NOT LookUpName(nt_short, s_na_objnam,n, s) THEN
      Writeln('Unknown object.')
    ELSE
      Obj.Parms[1] := N;
  END;

BEGIN
  PrintMenu;
  Done := FALSE;
  REPEAT
    S := ' ';
    GrabLine ('Missile Launcher> ', S,AllStats);
    S := LowCase(Trim(S));
    IF Length(S) = 1 THEN
      CASE S.Body[1] OF
       '1','m' : ChangeMissile(Obj, AllStats);
       '2','r' : GrabParm('Range? ',2,Obj, 0, 5, 1, 0, AllStats);
       '3','f' : GrabParm('Firing Time (1000 = 1 second)? ',
			  	5,Obj,0,,0,0,AllStats);
       '4','b' : GrabParm('Base Damage? ',3, Obj, 0,,0,0,AllStats);
       '5','a' : GrabParm('Random Damage? ', 4, Obj, 0,,0,0,AllStats);
       '6','v' : ViewSettings(Obj);
       '7','q','e' : Done := TRUE;
       '8','?','h' : PrintMenu;
      END
    ELSE
      Done := TRUE;
  UNTIL Done;
END;

PROCEDURE ZapObj(VAR Obj : ObjectRec; ObjNum : INTEGER);

VAR
  I : INTEGER;
  Indx : IndexRec;

BEGIN
  DeallocateDesc(obj.linedesc);
  DeallocateDesc(obj.examine);
  DeallocateDesc(obj.getfail);
  DeallocateDesc(obj.getsuccess);
  DeallocateDesc(obj.usefail);
  DeallocateDesc(obj.usesuccess);
  DeallocateDesc(obj.d1);
  DeallocateDesc(obj.d2);
  IF GetIndex(I_Object, Indx) THEN
  BEGIN
    Indx.Free[ObjNum] := TRUE;
    IF SaveIndex(I_Object, Indx) THEN
      IF DeleteObj(ObjNum, Obj) THEN
        Writeln('Object deleted.')
      ELSE
        Writeln('Unable to delete object.');
  END
  ELSE
    Writeln('Unable to read in index for objects.');
END;

PROCEDURE DoObjRename(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  NewName, S: String;
  Dummy : INTEGER;   (* Used for call to lookupname *)

BEGIN
  Writeln('This object is named ',obj.ObjName);
  writeln;
  GrabLine('New name: ',newname,AllStats, , ShortLen);
  newname := Trim(NewName);
  IF (NewName = '') OR (NewName = '**') THEN 
    Writeln('No changes.')
  ELSE
    IF LookUpName(nt_short, s_na_objnam, Dummy, NewName, TRUE) THEN
      Writeln(newname,' is not a unique object name.')
    ELSE
      Obj.ObjName := NewName;
END;

PROCEDURE ProgKind(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  N, Lcv : INTEGER;
  S : String;
  Privd : BYTE_BOOL;

BEGIN
  Privd := AllStats.Stats.Privd;
  Writeln('Select the type of your object:');
  Writeln;
  Writeln('0      Ordinary object (good for door keys)');
  Writeln('1      Equipment(weapon/armor/ring/etc)');
  Writeln('2      Scroll');
  Writeln('3      Wand');
  Writeln('7      Missile');
  Writeln('8      Missile Launcher');
  IF Privd THEN
  BEGIN
    Writeln('104    Spell Book');
    Writeln('106    Banking Machine');
  END;
  Writeln;
  Grab_Num('Which kind? ',n,0,106,1,AllStats);
  IF (N >= 100) AND (NOT Privd) THEN Writeln('Out of range.')
  ELSE IF N IN [0..3,7,8,104,106] THEN
  BEGIN
    Obj.Kind := N;
    FOR Lcv := 1 TO MaxParm DO
      Obj.Parms[Lcv] := 0;
  END
  ELSE Writeln('Out of range.');
END;

(* ------------------------------------------------------------------------- *)

PROCEDURE ProgObjScrollhelp;
BEGIN
  writeln('1 - Pick a spell for scroll/wand to cast.');
  writeln('2 - Set the number of charges.');
  writeln('v - view settings.');
  writeln('? - This list.');
  writeln('q - quit without saving.');
  writeln('s - save and exit.');
END;


PROCEDURE ProgObjScroll(var Obj : ObjectRec; VAR AllStats : AllMyStats);
VAR
  backup : objectrec;
  done : BYTE_BOOL;
  prompt, opt : string;
  num, temp : integer;
BEGIN
  done := false;
  backup := obj;
  ProgObjScrollHelp;
  repeat
    grabline('Option? ', opt, allstats);
    if (opt.length>0) then
      case opt.body[1] of
        '1' : begin
           num := Obj.Parms[1];
           if num = 0 then
             writev(prompt, 'Spell to cast? ')
           else
             writev(prompt, 'Spell to cast? [', GlobalSpells[num].name, ']');
           grabline(prompt, opt, allstats);           
           if lookupname(nt_short, s_na_spell, temp, opt) then
             num := temp;
           Obj.Parms[1] := num;
        end;
        '2' : begin
                num := obj.Parms[2];
                writev(prompt, 'Number of charges? [', num:0, ']');
                Grab_num(prompt, Obj.Parms[2], 0, , num, allstats);
              end;
        'v' : begin
           if obj.parms[1] = 0 then
             writeln('Spell   : none.')
           else
             writeln('Spell   : ', GlobalSpells[obj.parms[1]].name);
           writeln  ('Charges : ', obj.parms[2]:0);
         end;
        '?' : ProgObjScrollHelp;
        's' : done := true;
        'q' : begin
           done := true;
           obj := backup;
        end;
      end;
  until done;
END;

(* ------------------------------------------------------------------------- *)

PROCEDURE ProgObj(VAR Obj : ObjectRec; VAR AllStats : AllMyStats);

VAR
  S : String;
  MyName : String;
  Privd : BYTE_BOOL;

BEGIN
  MyName := AllStats.Stats.Name;
  Privd := AllStats.Stats.Privd;
  CASE Obj.Kind OF
    O_EQUIP	         : ProgObjEquip (Obj, AllStats);
    O_SCROLL             : ProgObjScroll(obj, allstats);
    O_WAND               : ProgObjScroll(obj, allstats);
    O_MISSILE	         : ProgObjMissile (Obj, AllStats);
    O_MISSILELAUNCHER    : ProgObjMissileLauncher (Obj, AllStats);
    O_SBOOK	         : IF Checkprivs(Privd, Myname) THEN
                             ProgObjSbook (Obj, AllStats);
    OTHERWISE Writeln(' This cannot be programmed.');
  END;
END;

[GLOBAL]
PROCEDURE ShowKind(P : INTEGER);

BEGIN
  CASE P OF
    O_BLAND            : writeln('Ordinary object');
    O_EQUIP            : writeln('Equipment');
    O_SCROLL           : writeln('Scroll');
    O_WAND             : writeln('Wand');
    O_MISSILE          : writeln('Missile');
    O_MISSILELAUNCHER  : writeln('Missile Launcher');
    O_SBOOK            : writeln('Spell Book');
    O_BANKING_MACHINE  : writeln('Banking Machine');
    OTHERWISE Writeln('Bad object type');
  END;
END;

PROCEDURE ObjView(Obj : ObjectRec; ObjNum : INTEGER);

VAR
  I : INTEGER;
  Component : ARRAY [1..MaxComponent] OF INTEGER;
  Owner : ShortString;

BEGIN
  Writeln;
  Component := Obj.Component;
  Writeln('Object name:    ',obj.Objname);
  GetObjOwner(ObjNum, Owner);
  Writeln('Owner:          ',owner);
  Write('Type: ');
  ShowKind(obj.kind);
  Writeln('Equipment slot: ',Equipment[Obj.Wear]);
  Writeln('Move speed add: ',obj.weight);
  IF obj.linedesc = 0 THEN
    Writeln('There is a(n) # here')
  ELSE
    PrintDesc(obj.linedesc);
  IF Obj.Examine = 0 THEN
    Writeln('No inspection description set')
  ELSE
    PrintDesc(Obj.Examine);
  IF NOT IsDescription(Obj.UseSuccess) THEN
    Writeln('No use success description set')
  ELSE PrintDesc(Obj.UseSuccess);
  IF NOT IsDescription(Obj.UseFail) THEN
    Writeln('No use fail description set')
  ELSE PrintDesc(Obj.UseFail);
  Writeln('Worth of this object: ',obj.worth:1);
  Writeln('Number in existence: ',obj.numexist:1);
  Writeln('Components:');
  FOR I := 1 TO MaxComponent DO
  IF Component[I] > 0 THEN
  BEGIN
    Write(i:2,' ',ObjPart(Component[I]):25);
    Write(' will ');
    IF Component[I] < 0 THEN
      Write('not ');
    Writeln('be destroyed.');
  END;
  Writeln;
END;

PROCEDURE ProgramHelp;

BEGIN
  writeln;
  writeln('A    "a", "an", "some", etc.');
  writeln('C    Set the components to make the object');
  writeln('D    Edit a Description of the object');
  writeln('F    Edit the GET failure message');
  writeln('G    Set the object required to pick up this object');
  writeln('1    Set the get success message');
  writeln('K    Set the Kind of object this is');
  writeln('L    Edit the label description ("There is a ... here.")');
  writeln('W    Set the worth of the object');
  writeln('P	Program the object based on the kind it is');
  writeln('R	Rename the object');
  writeln('S	Toggle the sticky bit');
  writeln('M    Move speed addition (weight)');
  writeln('6    Equipment slot');
  writeln;
  writeln('U    Set the object required for use');
  writeln('2    Set the place required for use');
  writeln('3    Edit the use failure description');
  writeln('4    Edit the use success description');
  writeln('V    View attributes of this object');
  writeln;
  writeln('X    Edit the extra description');
  writeln('5    Edit extra desc #2');
  writeln('Z    Zero (reset) the object');
  writeln('E    Exit (same as Quit)');
  writeln('Q    Quit (same as Exit)');
  writeln('?    This list');
  writeln;
END;

[GLOBAL]
PROCEDURE CustomObject(ObjNum : INTEGER; VAR AllStats : AllMyStats);

VAR
  S : String;
  Done : BYTE_BOOL;
  N, NewDsc : INTEGER;
  Obj : ObjectRec;
  Slot : INTEGER;
  MyName : String;
  MyExp : INTEGER;
  RoomNum : INTEGER;
  Here : Room;
  ObjNam : ShortNameRec;

BEGIN
  IF IsObjOwner(ObjNum, AllStats.Stats.Privd, FALSE) THEN
  BEGIN
    IF GetObj(ObjNum, Obj) THEN
    BEGIN
      Writeln;
      Writeln('Customizing object');
      Done := FALSE;
      REPEAT
     	GrabLine('Custom '+Obj.ObjName+'> ',s,AllStats);
	S := LowCase(Trim(S));
        IF Length(S) = 0 THEN
          S := 'q';
  	CASE S[1] OF
          '?'     : ProgramHelp;
          'q'     : Done := GrabYes('Throw away all changes? ', AllStats);
          'e'     : IF SaveObj(ObjNum, Obj) THEN
                      IF SetObjName(ObjNum, LowCase(obj.objname)) THEN
                      BEGIN
                        LogEvent(0, 0, E_READOBJECT, 0,0, ObjNum ,0,
                                 '', R_ALLROOMS);
                        Done := TRUE;
                      END;
          'v'     : ObjView(Obj, ObjNum);
          'r'     : DoObjRename(Obj, AllStats);
          'c'     : BEGIN
	              Grab_Num('Enter component number (1-10)',n,1,maxcomponent,1, AllStats);
                      IF GetName(nt_short, s_na_objnam,'Enter component name ',
                                 Obj.Component[N],, AllStats) THEN
	                IF NOT GrabYes('Will the object be destroyed',AllStats) THEN
	  	          Obj.Component[N] := -Obj.Component[N];
                    END;
          'g'     : IF GetName(nt_short, s_na_objnam,'Object required for GET? ' ,
                               obj.getobjreq,, AllStats) THEN;
	  'u'     : IF GetName(nt_short, s_na_objnam,'Object required for USE?', 
                               obj.useobjreq,, AllStats) THEN;
  	  '2'     : IF GetName(nt_long, l_na_roomnam,'Place required for USE?',
                               Obj.UseLocReq,, AllStats) THEN;
	  'w'     : Grab_Num('Worth of object',obj.worth,0,,obj.worth,AllStats);
	  'h'     : Grab_Num('Holdability ',obj.holdability,0,100,obj.holdability, AllStats);
	  's'     : BEGIN
	              Obj.Sticky := NOT (Obj.Sticky);
   	              IF Obj.Sticky THEN
                        Writeln('The object will not be takeable.')
	              ELSE
                        Writeln('The object will be takeable.');
	            END;
	   'a'    : BEGIN
                      Writeln;
	              Writeln('Select the article for your object:');
	              Writeln;
	              Writeln('0) None   ex: " You have taken Excalibur "');
	              Writeln('1) "a"    ex: " You have taken a small box "');
	              Writeln('2) "an"   ex: " You have taken an empty bottle "');
	              Writeln('3) "some" ex: " You have picked up some jelly beans "');
	              Writeln('4) "the"  ex: " You have picked up the Scepter of Power"');
	              Writeln;
	              Grab_Num('Article',obj.particle,0,4,obj.particle,AllStats);
 	            END;
	   'k'    : ProgKind(Obj, AllStats);
	   'p'    : ProgObj(Obj, AllStats);
	   'd'    : IF EditDesc(obj.examine,'object examine',AllStats) THEN;
	   'x'    : IF EditDesc(obj.d1,'extra #1',AllStats) THEN;
	   '5'    : IF EditDesc(obj.d2,'extra #2',AllStats) THEN ;
	   'f'    : IF EditDesc(obj.getfail,'get failure',AllStats) THEN;
	   '1'    : IF EditDesc(obj.getsuccess,'get success',AllStats) THEN;
	   '3'    : IF EditDesc(obj.usefail,'use failure',AllStats) THEN;
	   '4'    : IF EditDesc(obj.usesuccess,'use success',AllStats) THEN;
	   'm'    : Grab_Num('Weight ',obj.weight,,,obj.weight,AllStats);
	   '6'    : BEGIN
	              writeln('Valid equipment slots:');
	              FOR N := 0 TO MaxEquipment DO
                        Writeln(n:2,' ',equipment[n]);
	              Grab_Num('Equipment slot> ',n,,,,AllStats);
	              Writeln;
	              IF (N >= 0) AND (N <= MaxEquipment) THEN
	  	          Obj.wear := N;
    	            END;
           'z'    : BEGIN
	              ZapObj(Obj, ObjNum);
	              writeln('All object attributes have been reset except for Name and Numexist.');
  	            END;
           'l'    : IF MakeLine(obj.linedesc,'line', AllStats) THEN;
           OTHERWISE Inform_BadCmd;
	END;
      UNTIL Done;
    END;
  END
    ELSE writeln('You are not allowed to program that object.');
END;

PROCEDURE ZeroObj(VAR Obj : ObjectRec);
VAR
  Loop : INTEGER;
BEGIN
  obj.kind := 0; { bland object }
  obj.linedesc := DEFAULT_DESC;
  obj.examine := DEFAULT_DESC;
  obj.worth := 0;
  obj.wear:= 0;
  obj.weight:= 0;
  obj.sticky := false;
  obj.getobjreq := 0;
  obj.getfail := DEFAULT_DESC;
  obj.getsuccess := DEFAULT_DESC;
  obj.useobjreq := 0;
  obj.uselocreq := 0;
  obj.usefail := DEFAULT_DESC;
  obj.usesuccess := DEFAULT_DESC;
  obj.particle := 1;
  for loop := 1 to maxcomponent do
    obj.component[loop] := 0;
  for loop := 1 to maxparm do
    obj.parms[loop] := 0;
  obj.d1 := 0;
  obj.d2 := 0;
  obj.holdability := 0;
  obj.numexist := 0;
END;

[GLOBAL]
PROCEDURE CreateObject(S : String; Stat : StatType);

VAR
  ObjNum : INTEGER;
  Here : Room;
  ObjNam : ShortNameRec;
  ObjOwn : ShortNameRec;
  Charac : CharRec;
  Obj : ObjectRec;
  RoomNum : INTEGER;
  MySlot : INTEGER;
  Privd : BYTE_BOOL;
  MyLog : INTEGER;
  Good : BYTE_BOOL;

BEGIN
  MyLog := Stat.Log;
  RoomNum := Stat.Location;
  MySlot := Stat.Slot;
  Privd := Stat.Privd;
  Good := TRUE;
  IF GetRoom(RoomNum, Here) THEN
  BEGIN 
    IF NOT AllowObjectOwnership(MyLog, Stat.Userid) THEN 
    BEGIN
      IF GetChar(MyLog, Charac) THEN
        Writeln('The maximum number of objects you may own is ',charac.maxobjs:1,'.');
    END
    ELSE
      IF NOT IsRoomOwner(RoomNum, Privd, FALSE) THEN
        Writeln('You may only create objects when you are in one of your own rooms.')
      ELSE
        IF S <> '' THEN 
        BEGIN
          IF Length(s) > ShortLen THEN
            Writeln('Please limit your object names to ',shortlen:1,' characters.')
          ELSE
            IF LooKUpName(nt_short, s_na_objnam, objnum, s, TRUE) THEN
              Writeln('That object already exits.  You may DUPLICATE it.')
            ELSE
              BEGIN
                IF Allocate(i_object,objnum) THEN
                BEGIN
                  Good := FALSE;
                  ZeroObj(Obj);
    	          Obj.ObjName := S;
	          IF StartsVowel(S[1]) THEN
                    Obj.Particle := 2
                  ELSE
                    Obj.Particle := 1;
                  IF SaveObj(ObjNum, Obj) THEN
                  BEGIN
                    IF SetObjOwner(ObjNum, Stat.Userid) AND
                       SetObjName(ObjNum, Lowcase(s)) THEN
                    BEGIN
                      LogEvent(MySlot, MyLog, E_MSG, 0, 0, 0, 0,
                               Stat.Userid+' has created a new object.',
                               RoomNum);
                      Writeln('Object created.');
                      Good := TRUE;
                    END;
                  END;
                END;
              END;
        END
        ELSE writeln('To create an object, type CREATE O <object name>.');
  END;
  IF NOT Good THEN
  BEGIN
    Writeln('Error saving obj name/owner. Deallocating.');
    Deallocate(I_Object, ObjNum);
    IF DeleteObj(ObjNum, Obj) THEN;
  END;
END;

[GLOBAL]
PROCEDURE ZapObject(N : INTEGER; MySlot, MyLog : INTEGER; Location : INTEGER);

VAR
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[N];
  IF Obj.NumExist = 0 THEN
  BEGIN
    ZapObj(Obj, N);
    Deallocate(I_OBJECT,N);
    LogEvent(MySlot, MyLog, E_UNMAKE, 0, 0, 0, 0, Obj.ObjName, Location);
    writeln('Object removed.');
  END
  ELSE Writeln('You must DESTROY all instances of the object first.');
END;

PROCEDURE ListObjects(Id : ShortString);

VAR
  I , Pos : INTEGER;
  First : BYTE_BOOL := TRUE;
  DidPrint : BYTE_BOOL := FALSE;
  Indx : IndexRec;
  ObjOwn : ShortNameRec;
  ObjNam : ShortNameRec;

BEGIN
  IF GetIndex(I_Object, Indx) AND
     GetShortName(s_NA_ObjOwn, ObjOwn) AND
     GetShortName(s_NA_ObjNam, ObjNam) THEN
  BEGIN
    Pos := 0;
    FOR I := 1 TO Indx.Top DO
     IF NOT Indx.Free[i] THEN
       IF ObjOwn.Idents[I] = Id THEN
       BEGIN
         IF First THEN
         BEGIN
           IF Id = '' THEN writeln('<Public>:')
           ELSE IF Id = '*' then writeln('<Disowned>:')
                ELSE Writeln(id,':');
           First := FALSE;
         END;
         DidPrint := TRUE;
         WriteNice(objnam.idents[i],20);
         Pos := Pos + 1;
         IF Pos = 4 THEN
         BEGIN
           Pos := 0;
           Writeln;
         END;
       END;
  END;
  IF DidPrint THEN
  BEGIN
    Writeln;
    IF Pos <> 0 THEN Writeln;
  END;
END;

[GLOBAL]
PROCEDURE DoObjects(S : String; Privd : BYTE_BOOL := FALSE; MyId : VeryShortString);

VAR
  I ,N : INTEGER;
  FreeUser : PACKED ARRAY [1..MaxIndex] OF BYTE_BOOL;
  Indx : IndexRec;
  User : ShortNameRec;

BEGIN
  IF GetIndex(I_Player, Indx) AND GetShortName(s_NA_User, User) THEN
  BEGIN
    Freeuser := Indx.Free;
    IF Privd AND LookUpName(nt_short, s_na_pers, n, s) THEN
      ListObjects(user.idents[n])
    ELSE
      IF Privd AND LookUpName(nt_short, s_na_user,n,s) THEN
        ListObjects(user.idents[n])
      ELSE
        IF Privd AND (S = '*') THEN
        BEGIN
          ListObjects('');
          ListObjects('*');
          FOR I := 1 TO MaxPlayers DO
            IF NOT FreeUser[i] THEN
              ListObjects(user.idents[i]);
        END
        ELSE ListObjects(LowCase(MyId));
  END;
END;

END.
