[INHERIT ('MONCONST', 'MONTYPE', 'MONGLOBL','CUSTROOM')]

MODULE MonMain(INPUT, OUTPUT);

%include 'parser.pas'
%include 'headers.txt'
%include 'equip.inc'

(* -------------------------------------------------------------------------- *)
[EXTERNAL] FUNCTION ObjPrice(ObjNum : INTEGER) : INTEGER; extern;
[EXTERNAL] FUNCTION IsProg(S : String) : BYTE_BOOL; extern;
[EXTERNAL] PROCEDURE ReadGlobalNames; EXTERN;
(* -------------------------------------------------------------------------- *)

TYPE
  $DEFTYP = [UNSAFE] INTEGER;
  $DEFPTR = [UNSAFE] ^$DEFTYP;

[ASYNCHRONOUS]
FUNCTION Lib$Init_Timer (
	VAR context : [VOLATILE] UNSIGNED := %IMMED 0) : INTEGER; EXTERNAL;
 
[ASYNCHRONOUS]
FUNCTION lib$show_timer (Handle_address : $DEFPTR := %IMMED 0;
 code : INTEGER := %IMMED 0;
 %IMMED [UNBOUND, ASYNCHRONOUS] PROCEDURE user_action_procedure := %IMMED 0;
 %IMMED user_argument_value : [UNSAFE] INTEGER := %IMMED 0) : INTEGER; EXTERNAL;

(* -------------------------------------------------------------------------- *)

function numcansee(log : integer) : integer; forward;

[GLOBAL]
FUNCTION SetPersName(N : INTEGER; Name : ShortString) : BYTE_BOOL;
VAR
  Nam : ShortNameRec;
BEGIN
  SetPersName := FALSE;
  IF GetShortName(s_na_pers, nam) THEN
  BEGIN
    Nam.Idents[N] := Name;
    IF SaveShortName(s_na_pers, Nam) THEN
    BEGIN
      LogEvent(-1, -1, e_setname, 0, 0, nt_short, s_na_pers, '', r_allrooms,
               name, n);
      SetPersName := TRUE;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE SaveKiller(C1, C2 : INTEGER);

{ c1 - his group, c2 - my group }
VAR
  Kill : KillRec;

BEGIN
  IF GetKill(C2, Kill) THEN  { increment our death count for that group }
  BEGIN
    Kill.WeKilled[C1] := Kill.WeKilled[C1] + 1;
    IF SaveKill(C2, Kill) THEN;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE PrintScore;

{ c1 - his group, c2 - my group }
VAR
  Kill : KillRec;
  Nam : RealShortNameRec;
  Indx : IndexRec;
  Loop, Loop2 : INTEGER;

BEGIN
  IF GetRealShortName(RSNR_GroupName, Nam) AND GetIndex(I_GroupName, Indx) THEN
  BEGIN
    FOR Loop := 1 TO MaxGroup DO
    BEGIN
      IF NOT Indx.Free[Loop] THEN
      BEGIN
        Writeln('Kills for group: ', Nam.Idents[Loop]);
        IF GetKill(Loop, Kill) THEN
        BEGIN
          FOR Loop2 := 1 TO MaxGroup DO
            IF NOT Indx.Free[Loop2] THEN
            BEGIN
              WriteNice(Nam.Idents[Loop2], 20);
              Writeln(': ',Kill.WeKilled[Loop2]);
            END;
        END;
      END;
    END;
  END;
END;

(*-----------------------------------------------------------------------*)

[EXTERNAL] PROCEDURE UpdateClassName; EXTERN;

PROCEDURE DoUpdate;
BEGIN
  UpdateClassName;
  Writeln('everything should be correct now');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION SaveHold(Log : INTEGER; Hold : HoldObj) : BYTE_BOOL;

VAR
  Charac : CharRec;
  Loop : INTEGER;

BEGIN
  SaveHold := FALSE;
  IF GetChar(log, charac) then
  begin
    FOR Loop := 1 TO MaxHold DO
    BEGIN
      Charac.Item[Loop] := Hold.Holding[Loop];
      Charac.Condition[Loop] := Hold.Condition[Loop];
      Charac.Charges[Loop] := Hold.Charges[Loop];
      Charac.Equip[Loop] := (Hold.Slot[Loop] <> 0);
    END;
    SaveHold :=  SaveChar(Log, Charac);
  end;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSell(S : String; VAR AllStats : AllMyStats);

VAR
  Slot, NW, N : INTEGER;
  Obj : ObjectRec;

BEGIN
  IF (check_bit(HereDesc.SpcRoom, rm$b_store)) THEN
  BEGIN
    IF LookUpName(nt_short, s_na_objnam, N, S, FALSE, FALSE) THEN
    BEGIN
      Obj := GlobalObjects[N];
      IF ObjHere(N) THEN
      BEGIN
        Slot := FindHold(N, AllStats.MyHold);
        IF Slot > 0 THEN
        BEGIN
          IF Here.ObjHide[Slot] <> -1 THEN
            Here.ObjHide[Slot] := Here.ObjHide[Slot] + 1;
          IF SaveRoom(AllStats.Stats.Location, Here) THEN
          BEGIN
            IF AllStats.Stats.Privd THEN
              Writeln('There are ',here.objhide[slot]:0,' of them here now.');
            NW := Obj.Worth;  
            CASE Obj.Kind OF
              O_EQUIP: BEGIN
                NW := (NW * AllStats.MyHold.Condition[Slot]) DIV 100;
  	        NW := (NW * AllStats.MyHold.Charges[Slot]) DIV 10;
              END;
              O_MISSILE: NW := (NW * AllStats.MyHold.Charges[Slot]) DIV 100;
            END;
	    (* MWG, let the new worth be half *)
            NW := NW DIV 2;
            AllStats.Stats.Wealth := AllStats.Stats.Wealth + NW;
            AttribAssignValue(AllStats.Stats.Log, ATT_Wealth,
                              AllStats.Stats.Wealth);
            LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_SELL, 0, 0, 0,
                     0, AllStats.Stats.Name + ' has sold ' +ObjPart(N)+ '.',
                     AllStats.Stats.Location, , Slot, Here.Objs[Slot],
                     Here.ObjHide[Slot]);
            DropObj(Slot, AllStats);
            SaveHold(AllStats.Stats.Log, AllStats.MyHold);
            Writeln('Sold for ', NW:0,'!');
          END;  (* IF SaveRoom *)
        END ELSE Writeln('You''re not holding that item.  To see what you''re holding, type INV.')
      END ELSE Writeln('You cannot sell that here.')
    END;
  END ELSE Writeln('You cannot sell that here.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoDrop(S : String; VAR AllStats : AllMyStats);

VAR
  Slot, N : INTEGER;
  G : String;
  RoomNum : INTEGER;
  Obj : ObjectRec;
  Temp : String;

BEGIN
  WAIT(0.50); (* MWG to stop duping objects, give time to update *)
  Temp := S;
  G := Trim(Bite(Temp));
  IF G = '' THEN
  BEGIN
    Writeln('To drop an object, type DROP <object name>.');
    Writeln('To see what you are carrying, type INV (inventory).');
  END
  ELSE
  IF G = 'gold' THEN
  BEGIN
    Writeln('You have ', AllStats.Stats.Wealth:0, ' gold.');
    IF NOT IsNum(Temp) THEN
      Grab_Num('How much do you want to drop? ',N, 0, AllStats.Stats.Wealth,
               0, AllStats)
    ELSE N := Number(Temp);

    IF N > AllStats.Stats.Wealth THEN 
        N := AllStats.Stats.Wealth;  (* MWG fixed stuff up here *)

    IF N > 0 THEN
    BEGIN
      AllStats.Stats.Wealth := AllStats.Stats.Wealth - N;
      AttribAssignValue(AllStats.Stats.Log, Att_WEALTH, AllStats.Stats.Wealth);
      IF HereDesc.ObjDrop <> 0 THEN
        RoomNum := HereDesc.ObjDrop
      ELSE
        RoomNum := AllStats.Stats.Location;
      IF GetRoom(RoomNum, Here) THEN
      BEGIN       
        Here.GoldHere := Here.GoldHere + N;
        IF SaveRoom(RoomNum, Here) THEN
        BEGIN
          WriteV (G, AllStats.Stats.Name,' has dropped ', N:1,' gold here.');
          Writeln('You drop ',N:0,' gold.');
      	  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_DROP, 0, 0, 1,
                   0, G, AllStats.Stats.Location, , N);
        END;
      END;
    END;
  END
  ELSE
  IF (check_bit(HereDesc.SpcRoom, rm$b_store)) THEN
    Writeln('Maybe you want to *sell* it?')
  ELSE
  BEGIN
    IF GetRoom(AllStats.Stats.Location, Here) THEN
    BEGIN
      IF ParseObj(N, S, AllStats.MyHold) THEN
      BEGIN
        Slot := FindHold(N, AllStats.MyHold);
        IF Slot <> 0 THEN
        BEGIN
          Obj := GlobalObjects[N];
          IF Obj.Sticky THEN
            INFORM_Sticky(Obj.ObjName)
          ELSE
          IF LookupEffect(Obj, EF_CURSED) > 0 THEN
            Writeln('The ', Obj.ObjName,' is cursed.')
          ELSE
          IF PlaceObj(N, AllStats.Stats.Location, AllStats.MyHold.Condition[slot],
                      AllStats.MyHold.Charges[Slot], , , ,AllStats) THEN
	    DropObj(Slot, AllStats);
        END
        ELSE inform_notholding;
      END
      ELSE inform_notholding;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION IsBomb(Obj : ObjectRec) : BYTE_BOOL;

BEGIN
  IsBomb :=  ((LookupEffect(Obj, EF_BOMBBASE) > 0) OR
     (LookupEffect(Obj, EF_BOMBRANDOM) > 0));
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoThrow(S : String := ''; ObjNum : INTEGER; 
				VAR AllStats : AllMyStats);
VAR
   Slot, DropLoc : INTEGER;
   Good : BYTE_BOOL := FALSE;
BEGIN
   IF ObjNum<>0 then Good := TRUE
   ELSE Good := LookUpname(nt_short,s_na_objnam,ObjNum,S);
   IF Good THEN
   BEGIN 
     Slot := FindHold(ObjNum, AllStats.MyHold);
     IF(Slot = 0)THEN
	Inform_NotHolding
     ELSE
     BEGIN
       DropLoc := EffectDist( 
		  LookupEffect(GlobalObjects[ObjNum], EF_THROWBASE),
		  LookupEffect(GlobalObjects[ObjNum], EF_THROWRANDOM),
		  LookupEffect(GlobalObjects[ObjNum], EF_THROWRANGE),
		  LookupEffect(GlobalObjects[ObjNum], EF_THROWBEHAVIOR),
		  0, 0, FALSE, GlobalObjects[ObjNum].ObjName,
		  AllStats);
       IF DropLoc < 0 then DropLoc := -DropLoc;
       PlaceObj(ObjNum, DropLoc, AllStats.MyHold.Condition[slot],
                AllStats.MyHold.Charges[Slot], TRUE, FALSE, TRUE,
                AllStats);
       DropObj(Slot, AllStats);
       Freeze(AllStats.Stats.AttackSpeed/100, AllStats);
     END;
   END
   ELSE
      Inform_NotHolding
END;

(* ------------------------------------------------------------------------- *)

(* ------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoLob(S : String := ''; VAR AllStats : AllMyStats);

VAR
  Slot,
  N,
  Lobbed,
  Dir,
  Damage : INTEGER;
  Obj : ObjectRec;
  MyName : String;
  MyLoc : INTEGER;
  MySlot : INTEGER;

BEGIN
  MyName := AllStats.Stats.Name;
  MyLoc := AllStats.Stats.Location;
  MySlot := AllStats.Stats.Slot;
  IF (check_bit(HereDesc.Spcroom, rm$b_nofight)) THEN
    Writeln('You cannot fight here.')
  ELSE
  BEGIN
    IF S = '' THEN
      Writeln('To lob a bomb or magic monster, type LOB <object name>.')
    ELSE
    IF LookupName(nt_short, s_na_objnam, N, S, FALSE, FALSE) THEN
    BEGIN
      IF ObjHold(N, AllStats.MyHold) THEN
      BEGIN
        Obj := GlobalObjects[N];
        IF IsBomb(Obj) THEN
        BEGIN
          GrabLine('Direction? ',S, AllStats);
      	  IF NOT (GetDir(S, Dir)) THEN
              Writeln('Invalid direction.')
          ELSE
          BEGIN
            Lobbed := HereDesc.Exits[Dir].ToLoc;
	    IF Lobbed = 0 THEN
              Lobbed := MyLoc;
            Damage := LookupEffect(Obj, EF_BOMBBASE) +
	                           RND(LookupEffect(Obj, EF_BOMBRANDOM));
	    LogEvent(MySlot, AllStats.Stats.Log, E_MSG, 0,0,0,0, MyName+
                     ' has lobbed ' + ObjPart(N) + ' somewhere.', MyLoc);
	    LogEvent(MySlot, 0, E_LOB, LookupEffect(Obj, EF_BOMBTIME)*10, 0,
                     Damage, 0, MyName+'''s ' + Obj.ObjName, Lobbed);
 	    Writeln('Lobbing...');
            N := FindHold(N, AllStats.MyHold);
	    DropObj(N, AllStats);
            Freeze(AllStats.Stats.AttackSpeed/100, AllStats);
          END;
        END 
        ELSE
          Writeln('You can only lob bombs or magic monsters.');
      END
      ELSE
        Inform_NotHolding
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoOperators;

BEGIN
  Writeln('CURRENT MONSTER MANAGERS:');
  Writeln('-------------------------');
  Writeln(MM_USERID,' ',MVM_USERID,' ',MPGR_USERID);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ListGet(ShowHidden : BYTE_BOOL);

VAR
  First : BYTE_BOOL := TRUE;
  I : INTEGER;

BEGIN
  FOR I := 1 TO MaxObjs DO
  BEGIN
    IF (Here.Objs[I] MOD 1000 <> 0) THEN
      IF (Here.ObjHide[I] MOD 1000 = 0) OR ShowHidden THEN
      BEGIN
        IF First THEN
        BEGIN
(* MWG attempt to show price in stores, seems to work *)
          IF ShowHidden THEN
            WriteLn('Objects that you can buy here:         Price:')
          ELSE
  	    Writeln('Objects that you see here:');
	  First := FALSE;
        END;
(* MWG attempt to show price in stores *)
        IF ShowHidden THEN
          WriteLn('   ',ObjPart(Here.Objs[I] MOD 1000):20,'               ',
		  ObjPrice(Here.Objs[I] MOD 1000):5) 
        ELSE
          Writeln(ObjPart(Here.Objs[I] MOD 1000):20)
      END;
  END;
  IF First THEN
    writeln('There is nothing you see here that you can get.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE GetOriginalStats(ObjNum : INTEGER; VAR Condition : INTEGER;
                           VAR Charges : INTEGER);

VAR
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[ObjNum];
  Condition := LookupEffect(Obj, ef_condition);
  IF Condition = 0 THEN
    Condition := 100;

  Charges := LookupEffect(Obj, ef_charges);
  IF Charges = 0 THEN
    Charges := 10;
  CASE Obj.Kind OF
    O_SCROLL: Charges := Obj.Parms[2];
    O_WAND: Charges := Obj.Parms[2];
    O_MISSILE: Charges := Obj.Parms[3];
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION CanHold(VAR MyHold : HoldObj) : BYTE_BOOL;

VAR
  Slot : INTEGER := 0;
  Loop : INTEGER;

BEGIN
  FOR Loop := 1 TO MaxHold DO
    IF MyHold.Holding[Loop] = 0 THEN
      Slot := Loop;
  CanHold :=  Slot <> 0;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION GetMissileHold(ObjNum: INTEGER; VAR NumGet : INTEGER;
                        MyHold : HoldObj) : INTEGER;

VAR
  I : INTEGER;
  First : BYTE_BOOL;

BEGIN
  GetMissileHold := 0;
  First := TRUE;
  NumGet := 0;
  FOR I := 1 TO MaxHold DO
    IF (MyHold.Holding[I] = ObjNum) AND First THEN
    BEGIN
      NumGet := MyHold.Charges[I];
      First := FALSE;
      GetMissileHold := I;
    END;
END;

{ put object number n into the player's inventory; returns false if
  he's holding too many things to carry another }

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Put_Obj_In_Hold(N, Cond, C : INTEGER; VAR MyHold : HoldObj;
                 VAR Speed : INTEGER; Log : INTEGER) : BYTE_BOOL;

VAR
  Found, FoundMissile : BYTE_BOOL;
  I : INTEGER;
  Obj : ObjectRec;
  OldCharges : INTEGER;

BEGIN
  Obj := GlobalObjects[N];
  I := 0;
  Found := FALSE;
  FoundMissile := FALSE;
  IF Obj.Kind = O_MISSILE THEN
    I := GetMissileHold(N, OldCharges, MyHold);
  IF I <> 0 THEN
    Found := TRUE
  ELSE
  BEGIN
    OldCharges := 0;
    I := 1;
    WHILE (I <= MaxHold) AND (NOT Found) DO
      IF MyHold.Holding[I] = 0 THEN
        Found := TRUE
      ELSE
        I := I + 1;
  END;
  Put_Obj_In_Hold := Found;
  IF Found THEN
  BEGIN
    Speed := Speed + Obj.Weight;
    MyHold.Holding[I] := N;
    MyHold.Condition[I] := Cond;
    MyHold.Charges[I] := OldCharges + C;
    SaveHold(Log, MyHold);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoBuy(S : String; VAR AllStats : AllMyStats);

VAR
  Slot, N, Cond, C : INTEGER;
  Obj : ObjectRec;

BEGIN
  Cond := 0;
  C := 0;
  IF ParseObj(N, S, AllStats.MyHold) THEN
  BEGIN
    Obj := GlobalObjects[N];
    IF ObjHere(N) THEN
    BEGIN
      IF AllStats.Stats.Wealth >= Obj.Worth THEN
      BEGIN
        GetOriginalStats(N, Cond, C);
	Slot := FindObj(N, AllStats.Stats.Location);
        IF (Here.ObjHide[Slot] > 0) OR (Here.ObjHide[Slot] = -1) THEN
        BEGIN
          IF Put_Obj_In_Hold(N,Cond,C,AllStats.MyHold, AllStats.Stats.MoveSpeed,
                    AllStats.Stats.Log) THEN
          BEGIN
            AllStats.Stats.Wealth := AllStats.Stats.Wealth - Obj.Worth;
            AttribAssignValue(AllStats.Stats.Log, ATT_Wealth,
                              AllStats.Stats.Wealth);
            IF Here.ObjHide[Slot] <> - 1 THEN
            BEGIN
              Here.ObjHide[Slot] := Here.ObjHide[Slot] - 1;
              IF SaveRoom(AllStats.Stats.Location, Here) THEN;
            END;
            IF AllStats.Stats.Privd THEN
              Writeln('There are ', Here.ObjHide[Slot],' of them now.');
	    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0, 0,
                     0,0, AllStats.Stats.Name + ' has bought ' +
                     ObjPart(N) + '.', AllStats.Stats.Location);
    	    Writeln('All yours for ', Obj.Worth:0,' gold.')
          END
          ELSE
            writeln('Your hands are full.  You''ll have to drop something you''re carrying first.')
   	END
        ELSE
          Writeln('We are out of them now.')
      END
      ELSE
        Writeln('You don''t have enough gold!')
    END
    ELSE
      Writeln('You cannot buy that here.');
  END
  ELSE
    Writeln('What are you talking about?');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE P_GetSucc(N : INTEGER; Obj : ObjectRec);

BEGIN
  IF IsDescription(Obj.GetSuccess) THEN
    PrintDesc(Obj.GetSuccess)
  ELSE
    Writeln('You have taken ', ObjPart(N) ,'.');
END;

(* -------------------------------------------------------------------------- *)

FUNCTION TakeObj(ObjNum, Slot : INTEGER; VAR Q : INTEGER;
                 VAR C : INTEGER; RoomNum : INTEGER) : BYTE_BOOL;

BEGIN
  IF GetRoom(RoomNum, Here) THEN
  BEGIN
    IF Here.Objs[Slot] MOD 1000 = ObjNum THEN
    BEGIN
      Q := Here.Objs[Slot] DIV 1000;
      C := Here.ObjHide[Slot] DIV 1000;
      Here.Objs[Slot] := 0;
      Here.ObjHide[Slot] := 0;
      TakeObj := TRUE;
      IF NOT SaveRoom(RoomNum, Here) THEN
        TakeObj := FALSE;
    END
    ELSE
      TakeObj := FALSE;
  END
  ELSE
    TakeObj := FALSE;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoMetaGet(N : INTEGER; Silent : BYTE_BOOL := FALSE;
                    VAR AllStats : AllMyStats; VAR Obj : ObjectRec);

VAR
  Slot, Q, C : INTEGER;

BEGIN
  Q := 0;
  if ObjHere(N) THEN
  BEGIN
    IF CanHold(AllStats.MyHold) THEN
    BEGIN
      Slot := FindObj(N, AllStats.Stats.Location);
      IF Slot > 0 THEN
      IF TakeObj(N, Slot, Q, C,AllStats.Stats.Location) THEN
      BEGIN
        Put_Obj_In_Hold(N, Q, C, AllStats.MyHold, AllStats.Stats.MoveSpeed,
                 AllStats.Stats.Log);
        IF NOT Silent THEN
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_TAKE, 0,0,0,0,
                   ObjPart(N), AllStats.Stats.Location);
        P_GetSucc(N, Obj);
      END 
      ELSE
        Writeln('Someone got to it before you did.');
    END 
    ELSE
      Writeln(
'Your hands are full.  You''ll have to drop something you''re carrying first.');
  END
  ELSE
  IF ObjHold(N, AllStats.MyHold) THEN
    Writeln('You''re already holding that item.')
  ELSE
    Writeln('That item isn''t in an obvious place.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoGet(S : String; VAR AllStats : AllMyStats);

VAR
  G, Ext : String;
  N : INTEGER;
  Ok : BYTE_BOOL := TRUE;
  Obj : ObjectRec;

BEGIN
  WAIT(0.50);  (* MWG to stop gold and object duping *)   
  IF GetRoom(AllStats.Stats.Location, Here) THEN
  BEGIN
    Ext := S;
    IF S = '' THEN
      ListGet(check_bit(HereDesc.SpcRoom, rm$b_store))
    ELSE
    IF Bite(Ext) = 'gold' THEN
    BEGIN
      IF IsNum(Ext) THEN
        N := Number(ext)
      ELSE
        N := 0;
      IF N = 0 THEN
        N := Here.GoldHere;
      IF (N <= Here.GoldHere) AND (N > 0) THEN 
      BEGIN
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_GETGOLD,
                 0, 0, N, Here.GoldHere, AllStats.Stats.Name,
                 AllStats.Stats.Location);
      END
      ELSE
      BEGIN
        Writeln('There is ',here.goldhere:1,' gold here.');
      END;
    END 
    ELSE
    IF check_bit(HereDesc.SpcRoom, rm$b_store) THEN
      DoBuy(S, AllStats)
    ELSE
    IF ParseObj(N, S, AllStats.MyHold) THEN 
    BEGIN
      Obj := GlobalObjects[N];
      OK := TRUE;
      IF Obj.Sticky THEN
      BEGIN
        OK := FALSE;
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILGET, 0,0,
                N,0, AllStats.Stats.Name, AllStats.Stats.Location);
        IF NOT IsDescription(Obj.GetFail) THEN
	  Writeln('You can''t take ',ObjPart(N),'.')
        ELSE
          PrintDesc(Obj.GetFail);
      END 
      ELSE
      IF Obj.GetObjReq > 0 THEN
      BEGIN
       IF NOT(ObjHold(Obj.GetObjReq, AllStats.MyHold)) THEN
       BEGIN
         OK := FALSE;
         LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILGET, 0,0, N,0,
                  AllStats.Stats.Name, AllStats.Stats.Location);
  	  IF NOT IsDescription(Obj.GetFail) THEN
	    Writeln('You''ll need something first to get the ',
                    ObjPart(N),'.')
 	  ELSE
            PrintDesc(Obj.GetFail);
  	END;
      END
      ELSE
      IF Obj.Holdability > RND(100) THEN
      BEGIN
        OK := FALSE;
    	LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILGET, 0,0, N,0,
                 AllStats.Stats.Name, AllStats.Stats.Location);
	IF NOT IsDescription(Obj.GetFail) THEN
          Writeln(ObjPart(N),' slipped from your grasp.')
	ELSE
          PrintDesc(Obj.GetFail);
      END;
      IF OK THEN
        DoMetaGet(N, , AllStats, Obj);
    END
    ELSE
      Writeln('There is no object here by that name.');
  END
  ELSE
  IF LookupDetail(N, S) THEN
  BEGIN
    writeln('That detail of this room is here for the enjoyment of all Monster players,');
    writeln('and may not be taken.');
  END
  ELSE
    Writeln('There is no object here by that name.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoDuplicate(S : String; VAR AllStats : AllMyStats);

VAR
  ObjNum, Cond, C : INTEGER;

BEGIN
  Cond := 0;
  C := 0;
  IF Length(s) > 0 THEN
  BEGIN
    IF Not IsRoomOwner(AllStats.Stats.Location, AllStats.Stats.Privd, FALSE) THEN
      Writeln('You may only create objects when fyou are in one of your own rooms.')
    ELSE
    BEGIN
      IF LookupName(nt_short, s_na_objnam, ObjNum, S) THEN
      BEGIN
        IF IsOwner(nt_short, s_na_objown, ObjNum,AllStats.Stats.Privd, FALSE) THEN
        BEGIN
	  GetOriginalStats(ObjNum, Cond, C);
      	  IF NOT PlaceObj(Objnum, AllStats.Stats.Location, Cond, C, TRUE,
                          TRUE, AllStats.Stats.Privd, AllStats) THEN
	    Writeln('There isn''t enough room here to make that.')
	  ELSE
	    Writeln('Object created.');
        END
        ELSE
          writeln('You don''t own that object.');
      END
      ELSE
        writeln('There is no object by that name.');
    END;
  END
  ELSE
    writeln('To duplicate an object, type DUPLICATE <object name>.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE SpecialEffectSubs(Text, S : String; VAR AllStats : AllMyStats);

BEGIN
  Text := SubsParm(Text, S, '#');
  Text := SubsParm(Text, AllStats.Stats.Name, '&');
  Parser(Text, AllStats);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoSpecialEffect(S : String := ''; VAR AllStats : AllMyStats);

VAR
  I : INTEGER;
  G : String;
  OldPrivs : BYTE_BOOL;
  Line : LineRec;
  Desc : DescRec;

BEGIN
  OldPrivs := AllStats.Stats.Privd;
  AllStats.Stats.Privd := TRUE;
  IF HereDesc.Special_Effect < 0 THEN
  BEGIN
    IF GetLine(-HereDesc.Special_Effect, Line) THEN
      SpecialEffectSubs(Line.Line, S, AllStats);
  END
  ELSE
  IF HereDesc.Special_Effect > 0 THEN
  BEGIN
    IF GetDesc(HereDesc.Special_Effect, Desc) THEN
      FOR I := 1 TO Desc.DescLen DO
        SpecialEffectSubs(Desc.Lines[I], S, AllStats);
  END;
  AllStats.Stats.Privd := OldPrivs;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ReadAtmosphere;

VAR
  Loop : INTEGER;
  Atmos : AtmosphereRec;

BEGIN
  Atmosphere := Zero;
  FOR Loop := 1 TO MaxAtmospheres DO
  BEGIN
    IF GetAtmosphere(Loop, Atmos, TRUE) THEN
      Atmosphere[Loop] := Atmos
    ELSE
      Atmosphere[Loop].Trigger.Length := 0;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoAtmosphere(S : String; At_Type : INTEGER;
                       Slot, Log, Location : INTEGER);

VAR
  N : INTEGER;
  Victim : ShortString;
  TargLog : INTEGER;

BEGIN
  IF (S = '') OR ParsePers(N, Targlog, S) THEN
  BEGIN
    IF S = '' THEN
    BEGIN
      Victim := 'yourself';
      N := 0;
    END
    ELSE
      Victim := Here.People[N].Name;
    LogEvent(Slot, Log,  E_ATMOSPHERE, N, 0, At_Type,0, '', Location);
    IF N = 0 then
      Writeln(Atmosphere[At_Type].Isee)
    ELSE
      Writeln(SubsParm(Atmosphere[At_Type].ISeeExtra, Victim));
  END
  ELSE
    Writeln(S, ' can not be seen in this room.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE EventAtmosphere(Targ : INTEGER; Sendname : String; P : INTEGER;
                          VAR AllStats : AllMyStats);

VAR
  Victim, S : String;

BEGIN
  IF Targ = 0 THEN
    Writeln(SubsParm(Atmosphere[P].EventSee, SendName, '&'))
  ELSE
  BEGIN
    IF Targ = AllStats.Stats.Slot THEN
      Victim := 'you'
    ELSE
      Victim := Here.People[Targ].Name;
    S := SubsParm(Atmosphere[P].EventSeeExtra, Victim);
    S := SubsParm(S, SendName, '&');
    Writeln(s);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSelf(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  Charac : CharRec;
  User : INTEGER;

BEGIN
  User := AllStats.Stats.Log;
  IF (Length(S) <> 0) AND AllStats.Stats.Privd THEN
    IF LookupName(nt_short, s_na_pers, N, S, FALSE, FALSE) THEN
      User := N;
  Writeln('[ Editing self description ]');
  IF GetChar(User, Charac) THEN
    IF EditDesc(Charac.Self, ,AllStats) THEN
      IF SaveChar(User, Charac) THEN
        Writeln('Self description modified.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoPlayers(Loc : INTEGER; Slot : INTEGER);

VAR
  I, J : INTEGER;
  Location : IntArray;
  RoomName : LongNameRec;
  User : ShortNameRec;
  Pers : ShortNameRec;
  ASleep : IndexRec;
  Date : ShortNameRec;
  Ok : BYTE_BOOL := TRUE;
  Indx : IndexRec;

BEGIN
  Ok := GetIndex(I_ASLEEP, ASleep) AND
        GetIndex(I_PLAYER, Indx) AND
        GetInt(N_LOCATION, Location) AND
        GetShortName(s_NA_USER, user) AND
        GetShortName(s_NA_PERS, pers) AND
        GetShortName(s_NA_DATE, date) AND
        GetLongName(l_NA_ROOMNAM, RoomName);
  IF Ok THEN
  BEGIN
    Writeln;
    Writeln('Userid    Personal Name             Last Play');
    FOR I := 1 TO Indx.Top DO
    BEGIN
      IF NOT(Indx.Free[I]) THEN
      BEGIN
        WriteNice(User.Idents[I], 10);
        WriteNice(Pers.Idents[I], 21);
        IF Asleep.Free[I] THEN
          WriteNice(Date.Idents[I], 18)
        ELSE
          Write('   -playing now-   ');
        Writeln('  ',RoomName.Idents[Location[I]]);
      END;
    END;
    Writeln;
  END;
END;                                                                           

(* -------------------------------------------------------------------------- *)

PROCEDURE DoWhoIs(S : String; Check : INTEGER := 3);

(*  IF Check =
      1 : then check against game names
      2 : then check against user names
      3 : then check against both *)

VAR
  Len : INTEGER;
  Pers : ShortNameRec;
  User : ShortNameRec;
  Indx : IndexRec;
  Loop : INTEGER;
  Found : BYTE_BOOL;
  S_Pers : ShortString;
  S_User : ShortString;

BEGIN
  Len := Length(S);
  IF Len <> 0 THEN
  BEGIN
    S := LowCase(s);
    IF GetShortName(s_na_pers, Pers) AND GetShortName(s_na_user, User) AND
       GetIndex(I_Player, Indx) THEN
    BEGIN
      FOR Loop := 1 TO Indx.Top DO
      BEGIN
        IF NOT(Indx.Free[Loop]) THEN
        BEGIN
          Found := FALSE;
          S_Pers := LowCase(Pers.Idents[Loop]);
          S_Pers.Length := Len;
          S_User := LowCase(User.Idents[Loop]);
          S_User.Length := Len;
          CASE Check OF
            1 : Found := (S_Pers = S);
            2 : Found := (S_User = S);
            3 : Found := (S_Pers = S) OR (S_User = S);
          END;
          IF Found THEN
            Writeln(Pers.Idents[Loop],' is ', User.Idents[Loop],'.')
        END;
      END;
    END;
  END
  ELSE
    Writeln('Usage whois <name>');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RevealPeople(VAR Found : BYTE_BOOL;
                       VAR AllStats : AllMyStats);

VAR
  Retry, I : INTEGER;

BEGIN
  Found := FALSE;
  Retry := 1;
  REPEAT
    Retry := Retry + 1;
    I := RND(maxpeople);
    IF (Here.People[I].Hiding > 0) AND
	(I <> AllStats.Stats.Slot) AND (Here.People[I].Kind <> 0) AND
	((RND(MaxHide) >= Here.People[I].Hiding) OR
	AllStats.Stats.Privd) THEN
    BEGIN
      Here.People[I].Hiding := 0;
      IF SaveRoom(AllStats.Stats.Location, Here) THEN;
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FOUNDYOU, I,0,
               0,0, AllStats.Stats.Name, AllStats.Stats.Location);
      Found := TRUE;
      writeln('You''ve found ',Here.People[I].Name,' hiding in the shadows!');
    END;
  UNTIL (Retry > 7) OR Found;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RevealObjects(VAR Two : BYTE_BOOL;
                        VAR Location : INTEGER);

VAR
  Tmp : String;
  I : INTEGER;

BEGIN
  Two := FALSE;
  FOR I := 1 TO MaxObjs DO
  BEGIN
    IF Here.objs[I] MOD 1000 <> 0 THEN	{ if there is an object here }
      IF (Here.ObjHide[I] MOD 1000 <> 0) THEN
      BEGIN
        Two := TRUE;
        Here.ObjHide[I] := Here.ObjHide[I] - 1;
        IF Here.ObjHide[I] MOD 1000 = 0 THEN
        BEGIN
	  Writeln('You''ve found ',ObjPart(Here.Objs[i] MOD 1000),'.');
	  Here.Objhide[I] := 1000*(Here.ObjHide[I] DIV 1000);
        END;
        IF SaveRoom(Location, Here) THEN;
      END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RevealExits(VAR One : BYTE_BOOL; VAR AllStats : AllMyStats);

VAR
  Retry, I : INTEGER;

BEGIN
  One := FALSE;
  Retry := 1;
  REPEAT
    Retry := Retry + 1;
    I := RND(maxexit);
    IF (HereDesc.Exits[I].Hidden <> 0) AND (NOT AllStats.Exit.FoundExits[I]) THEN
    BEGIN
      One := TRUE;
      AllStats.Exit.FoundExits[I] := TRUE;	{ mark exit as found }
      IF HereDesc.Exits[I].Hidden = DEFAULT_DESC THEN
      BEGIN
	IF HereDesc.Exits[I].Alias = '' THEN
          Writeln('You''ve found a hidden exit: ', Direct[i],'.')
	ELSE
          Writeln('You''ve found a hidden exit: ', HereDesc.Exits[I].Alias,'.');
      END
      ELSE
        PrintDesc(HereDesc.Exits[I].Hidden);
    END;
  UNTIL (Retry > 4) OR (One);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSearch(S : String; VAR AllStats : AllMyStats);

VAR
  Chance : INTEGER;
  Found,
  Dummy : BYTE_BOOL;

BEGIN
  IF CheckHide(AllStats.Stats) THEN
  BEGIN
    Chance := Rnd(100);
    Found := FALSE;
    Dummy := FALSE;
    IF Chance IN [1..20] THEN
      RevealObjects(Found, AllStats.Stats.Location)
    ELSE
    IF Chance IN [21..40] THEN
      RevealExits(Found, AllStats)
    ELSE
    IF (Chance IN [41..100]) OR AllStats.Stats.Privd THEN
      RevealPeople(Dummy, AllStats);
    IF Found THEN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FOUND, 0,0, 0,0,
               AllStats.Stats.Name, AllStats.Stats.Location)
    ELSE
    IF NOT(Dummy) THEN
    BEGIN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_SEARCH, 0,0, 0,0,
               AllStats.Stats.Name, AllStats.Stats.Location);
      Writeln('You haven''t found anything.');
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoHide(S : String; VAR AllStats : AllMyStats);

VAR
  Slot, N : INTEGER;
  FoundDsc : INTEGER;
  Tmp : String;

BEGIN
  Freeze(0.5+AllStats.Stats.HideDelay, AllStats);
  IF GetRoom(AllStats.Stats.Location, Here) THEN
  BEGIN
    IF S = '' THEN	{ hide yourself }
    BEGIN
      IF check_bit(HereDesc.Spcroom , rm$b_nohide) THEN
        Writeln('There is no place to hide here.')
      ELSE
      IF ((check_bit(HereDesc.Spcroom, rm$b_hardhide)) AND
          (RND(100) > 20)) THEN
        writeln('You couldn''t find a place to hide.')
      ELSE
      BEGIN
        IF (NOT(AllStats.Stats.Privd) AND
            (NumCanSee(AllStats.Stats.Log) > 0)) THEN
        BEGIN
          IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
            Writeln('You can''t hide any better with people in the room.')
          ELSE
            Writeln('You can''t hide when people are watching you.');
        END
        ELSE
        IF (RND(100) > 25) THEN
        BEGIN
          IF ((Here.People[AllStats.Stats.Slot].Hiding >
              (AllStats.Stats.Experience DIV 1000)) AND
             (NOT AllStats.Stats.Privd)) THEN
            Writeln('You''re pretty well hidden now.  I don''t think you could be any less visible.')
          ELSE
          BEGIN
    	    Here.People[AllStats.Stats.Slot].Hiding :=
                                   Here.People[AllStats.Stats.Slot].Hiding + 1;
            IF SaveRoom(AllStats.Stats.Location, Here) THEN;
  	    IF Here.People[AllStats.Stats.Slot].Hiding > 1 THEN
	      Writeln('You''ve managed to hide yourself a little better.')
            ELSE
            BEGIN
	      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_IHID,0,0,
                       here.people[allstats.stats.slot].hiding, 0,
                       AllStats.Stats.Name, AllStats.Stats.Location);
	      Writeln('You''ve hidden yourself from view.');
 	    END;
          END;  (* If can hide some more *)
        END     (* If we can hide *)
        ELSE
        BEGIN { unsuccessful }
          IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
            Writeln('You could not find a better hiding place.')
          ELSE
            Writeln('You could not find a good hiding place.');
        END;
      END;   (* Hide possible in this room *)
    END
    ELSE
    BEGIN  { Hide an object }
      IF check_bit(HereDesc.SpcRoom, rm$b_store) THEN
        Writeln('You can''t hide the vender of that object.')
      ELSE
      IF ParseObj(N, S, AllStats.MyHold) THEN
      BEGIN
        IF ObjHere(N) THEN
        BEGIN
	  Slot := FindObj(N, AllStats.Stats.Location);
   	  IF Slot = 0 THEN
  	  BEGIN    (* object no longer in room *)
	    Tmp := ObjPart(N);
  	    Writeln('Somebody took ',Tmp,' while you were hiding it!');
  	  END
	  ELSE
	  BEGIN
	    Here.ObjHide[Slot] := Here.ObjHide[Slot] + 1;
            IF SaveRoom(AllStats.Stats.Location, Here) THEN;
	    BEGIN
              Tmp := ObjPart(N);
	      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_HIDOBJ, 0,0,
                       0,0, Tmp, AllStats.Stats.Location);
	      Writeln('You have hidden ',Tmp,'.');
	    END
          END
        END
        ELSE
        IF ObjHold(N, AllStats.MyHold) THEN
          Writeln('You''ll have to put it down before it can be hidden.');
      END
      ELSE
        Writeln('I see no such object here.');
    END;  (* IF s='' then else hideobj *)
  END;    (* Getroom *)
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoClaim(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  OK : BYTE_BOOL;
  Tmp : String;

  Objown : ShortNameRec;
  Own : LongNameRec;
  Obj : ObjectRec;

BEGIN
  IF Length(S) = 0 then 
  BEGIN
    IF GetRoom(AllStats.Stats.Location, Here) THEN
    BEGIN
      IF NOT AllowRoomOwnerShip(AllStats.Stats.Log, AllStats.Stats.Userid) THEN
        Writeln('Your quota for rooms has been consumed.')
      ELSE
      IF (HereDesc.Owner = '*') OR (AllStats.Stats.Privd) THEN
      BEGIN
        HereDesc.Owner := AllStats.Stats.Userid;
        IF SaveRoom(AllStats.Stats.Location, Here) THEN
          IF SetRoomOwner(AllStats.Stats.Location, AllStats.Stats.Userid) THEN
            Writeln('You are now the owner of this room.');
      END
      ELSE 
      BEGIN
        IF HereDesc.Owner = '' THEN
          Writeln('This is a public room.  You may not claim it.')
        ELSE
          Writeln('This room has an owner.');
      END;
    END;
  END
  ELSE
  IF LookupName(nt_short, s_na_objnam, n, s) THEN 
  BEGIN
    IF GetShortName(s_na_objown, ObjOwn) THEN
    BEGIN
      IF NOT AllowObjectOwnerShip(AllStats.Stats.Log, AllStats.Stats.Userid) THEN
        Writeln('Your quota for objects ]`has been consumed.')
      ELSE
      IF (Objown.Idents[N] = '') AND (NOT AllStats.Stats.Privd) THEN
      BEGIN
        Writeln('That is a public object. ') ;
        Writeln('You may DUPLICATE it, but may not CLAIM it.')
      END
      ELSE
      IF (Objown.Idents[N] <> '*') AND (NOT AllStats.Stats.Privd) THEN
        Writeln('That object has an owner.')
      ELSE
      BEGIN
        Obj := GlobalObjects[N];
        IF Obj.NumExist = 0 THEN
          Ok := TRUE
        ELSE
        BEGIN
          IF ObjHold(n, AllStats.MyHold) THEN
            Ok := TRUE
          ELSE
            Ok := FALSE;
        END;
        IF Ok THEN
        BEGIN
          IF SetObjOwner(N, AllStats.Stats.Userid) THEN
	    Writeln('You are now the owner of the ',Obj.ObjName,'.');
        END
        ELSE
          Writeln('You must have one to claim it.');
      END;
    END;
  END
  ELSE
    Writeln('There is nothing here by that name to claim.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoDisown(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  Tmp : String;
  Own : LongNameRec;
  ObjOwn : ShortNameRec;
  Obj : ObjectRec;

BEGIN
  IF Length(S) = 0 then
  BEGIN
    IF GetRoom(AllStats.Stats.Location, Here) THEN
      IF (HereDesc.Owner = AllStats.Stats.Userid) OR (AllStats.Stats.Privd) THEN
      BEGIN
        HereDesc.Owner := '*';
        IF SaveRoom(AllStats.Stats.Location, Here) THEN
          IF SetRoomOwner(AllStats.Stats.Location, '*') THEN
            Writeln('You have disowned this room.');
      END
      ELSE
        Writeln('You are not the owner of this room.');
  END
  ELSE
  BEGIN
    IF LookupName(nt_short, s_na_objnam, N, S) THEN
    BEGIN
      Obj := GlobalObjects[N];
      Tmp := Obj.ObjName;
      IF GetShortName(s_NA_ObjOwn, ObjOwn) THEN
      BEGIN 
        IF Objown.Idents[N] = AllStats.Stats.Userid THEN
        BEGIN
          IF SetObjOwner(N, '*') THEN
  	    Writeln('You are no longer the owner of the ',tmp,'.');
        END
        ELSE
          Writeln('You are not the owner of any such thing.');
      END;
    END
    ELSE
      Writeln('You are not the owner of any such thing.');
  END;  (* If s = '' THEN ELSE *)
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoPublic(S : String; VAR AllStats : AllMyStats);

VAR
  Ok : BYTE_BOOL;
  Tmp : String;
  N : INTEGER;
  Own : LongNameRec;
  Obj : ObjectRec;
  ObjOwn : ShortNameRec;

BEGIN
  IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
  BEGIN
    IF Length(S) = 0 THEN
    BEGIN
      IF GetRoom(AllStats.Stats.Location, Here) THEN
      BEGIN
        IF HereDesc.Owner <> '' THEN
        BEGIN
          HereDesc.Owner := '';
          IF SaveRoom(AllStats.Stats.Location, Here) THEN
          BEGIN
            IF SetRoomOwner(AllStats.Stats.Location, '') THEN
              Writeln('This room is now public.');
          END
        END
        ELSE
          Writeln('This room is already public.');
      END
    END
    ELSE
    IF LookupName(nt_short, s_na_objnam, N, S) THEN
    BEGIN
      IF GetShortName(s_na_objown, ObjOwn) THEN
      BEGIN
        IF Objown.Idents[N] = '' THEN
          Writeln('That is already public.')
        ELSE 
        BEGIN
          Obj := GlobalObjects[N];
  	  IF Obj.NumExist = 0 THEN
            Ok := TRUE
   	  ELSE
	    IF ObjHold(N, AllStats.MyHold) THEN
              Ok := TRUE
	    ELSE
              Ok := FALSE
	END;
	IF Ok THEN
	BEGIN
          IF SetObjOwner(N, '') THEN
	    Writeln('The ',Obj.Objname,' is now public.');
        END
	ELSE
          Writeln('You must have one to claim it.');
      END;
    END
    ELSE
      Writeln('There is nothing here by that name to claim.');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE NiceSay(VAR S : String);

BEGIN
  IF S[1] IN ['a'..'z'] THEN
    S[1] := CHR( Ord('A') + (Ord(S[1]) - Ord('a')) );
  IF S[Length(S)] IN ['a'..'z','A'..'Z'] THEN
    S := S + '.';
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoWhisper(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  G : String;
  Targlog : INTEGER;

BEGIN
  IF Length(S) = 0 THEN
    Writeln('To whisper, type WHISPER <personal name>.')
  ELSE
  BEGIN
    G := Trim(Bite(S));
    IF ParsePers(N, TargLog, S) THEN
    BEGIN
      IF N = AllStats.Stats.Slot THEN
        Writeln('You tell yourself many a dark secret.')
      ELSE
      BEGIN
        IF Length(S) = 0 THEN
          GrabLine('>> ',S, AllStats);
        IF Length(S) > 0 THEN
        BEGIN
	  NiceSay(S);
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_WHISPER,
			0,0,N,TargLog,  S, AllStats.Stats.Location);
        END
        ELSE
          Writeln('Nothing whispered.');
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSay(S : String; VAR AllStats : AllMyStats);

VAR
  Origs : String;

BEGIN
  IF Length(S) > 0 THEN
  BEGIN
    Origs := S;
    NiceSay(S);
    IF (Here.People[AllStats.Stats.Slot].Hiding > 0) THEN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_HIDESAY, 0,0,
               0,0, S, AllStats.Stats.Location)
    ELSE
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_SAY, 0, 0,
               AllStats.Stats.Health, 0,
               S, AllStats.Stats.Location, AllStats.Stats.Name);
  END
  ELSE
    Writeln('To talk to others in the room, type SAY <message>.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ViewSlot(RoomNum : INTEGER; Slot : INTEGER := -1);

VAR
  Loop : INTEGER;
  Here : Room;

  PROCEDURE PrintSlot(SlotNum : INTEGER; Here : Room);
  BEGIN
    WITH Here.People[SlotNum] DO
    BEGIN
      Write('[',SlotNum:4,']');
      Write('[',Kind:4,']');
      Write('[',Targ:4,']');
      Write('[',Name:9,']');
      Write('[',Hiding:4,']');
      Write('[',NextAct:10,']');
      Write('[',Health:6,']');
      Writeln;
    END;
  END;

BEGIN
  IF GetRoom(RoomNum, Here) THEN
  BEGIN
    Writeln;
    Writeln('[Slot][Kind][Targ][Game Name][Hide][Next][Health]');
    IF Slot = -1 THEN
      FOR Loop := 1 TO MaxPeople DO
        PrintSlot(Loop, Here)
    ELSE
      PrintSlot(Slot, Here);
    Writeln;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditSlot(RoomNum : INTEGER; Slot : INTEGER; VAR AllStats : AllMyStats);

VAR
  Here : Room;
  Done : BYTE_BOOL := FALSE;
  dummy_s, S : String;
  Dummy : INTEGER;
  DStr : String;

  PROCEDURE EditMenu;
  BEGIN
    Writeln;
    Writeln('1.  LogNumber.');
    Writeln('2.  Game name.');
    Writeln('3.  Hide level.');
    Writeln('4.  Health.');
    Writeln('? for help.');
    Writeln('q to exit.');
    Writeln;
  END;

BEGIN
  IF GetRoom(RoomNum, Here) THEN
  BEGIN
    REPEAT
      GrabLine('Slot edit> ', S, AllStats, , 1);
      IF Length(S) = 0 THEN S := 'q';
      CASE S[1] OF
        'q' : Done := TRUE;
        '?' : EditMenu;
        '1' : Grab_Num('Log number? ', Here.People[Slot].Kind,,,,AllStats);
        '2' : BEGIN
           GrabLine('Game name? ', dummy_s, AllStats, , ShortLen);
           here.people[slot].name := substr(dummy_s, 1, dummy_s.length);
        end;
        '3' : Grab_Num('Hide level? ', Here.People[Slot].Hiding, 0, MaxHide,
                       0,AllStats);
        '4' : Grab_Num('Health? ', Here.People[Slot].Health, 0, 99999,
                       1000,AllStats);
        OTHERWISE
          Writeln('Bad command.');
      END;
      IF SaveRoom(RoomNum, Here) THEN
        Writeln('Room modified.');
    UNTIL Done;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditPeopleHere(S : String; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL := FALSE;
  Index : INTEGER;  
  RoomNum : INTEGER;
  Choice : String;

  PROCEDURE Menu;
  BEGIN
    Writeln('V.  View all slots.');
    Writeln('E.  Edit a slot.');
    Writeln('Q.  Quit.');
  END;

BEGIN
  IF NOT LookupRoomName(S, RoomNum, false, true) THEN
    RoomNum := AllStats.Stats.Location;
  REPEAT
    GrabLine('Edit room> ', Choice,AllStats, , 1);
    IF Length(Choice) = 0 THEN
      Choice := 'q'
    ELSE
      Choice := Lowcase(Trim(Choice));
    CASE Choice[1] OF
      '?' : Menu;
      'v' : ViewSlot(RoomNum);
      'e' : BEGIN
              Grab_Num('Slot number? ', Index, 1, MaxPeople, 1, AllStats);
              ViewSlot(RoomNum, Index);
              EditSlot(RoomNum, Index, AllStats);
            END;
      'q' : Done := TRUE;
      OTHERWISE
        Writeln('Bad parameter.');
    END;
  UNTIL Done;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditGroupName(S : String; VAR AllStats : AllMyStats);

VAR
  Num : INTEGER;
  Nam : RealShortNameRec;
  Loop : INTEGER;
  Indx : IndexRec;
  dummy_s : string;
BEGIN
  IF (Length(S) = 0) OR (NOT IsNum(S)) THEN
    Grab_Num('Group number(0 to exit)? ',Num, 0, MaxGroup, 0, AllStats)
  ELSE
    Num := Number(S);
  IF (Num > 0) AND (Num <= MaxGroup) THEN
  BEGIN
    IF GetrealShortName(RSNR_GroupName, Nam) THEN
    BEGIN
      GrabLine('Group name? ', dummy_s, AllStats, , ShortLen);
      nam.idents[num] := substr(dummy_s, 1, dummy_s.length);
      IF GetIndex(I_GroupName, Indx) THEN
      BEGIN
        IF Indx.Top < Num THEN
          Indx.Top := Num;
        Indx.Free[Num] := FALSE;
        IF SaveIndex(I_GroupName, Indx) THEN
          IF SaveRealShortName(RSNR_GroupName, Nam) THEN
            Writeln('Group name modified.');
      END;
    END;
  END
  ELSE
    IF Num <> 0 THEN
      Writeln('Inavlid group number.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditAtmosphere(S : String; VAR AllStats : AllMyStats);

VAR
  Good : BYTE_BOOL := FALSE;
  Loop : INTEGER := 1;
  Found : BYTE_BOOL := FALSE;
  CmdNum : INTEGER;
  Atmos : AtmosphereRec;
  dummy_s : string;
  PROCEDURE EditAtmosphere(CmdNum : INTEGER; VAR AllStats : AllMyStats);

  VAR
    Atmos : AtmosphereRec;
    Done : BYTE_BOOL := FALSE;
    S : String;

  PROCEDURE ViewAtmos(Atmos : AtmosphereRec);
  BEGIN
    Writeln('If & appears in the line, the casters name will be substituted');
    Writeln('If # appears in the line, the targets name will be substituted');
    Writeln('If you are the target, and a # is found, the word "you" will be substituted.');
    Writeln('U - Owner            : ',Atmos.Owner);
    Writeln('T - Trigger          : ',Atmos.Trigger);
    Writeln('M - You See          : ',Atmos.ISee);
    Writeln('O - Others see(&)    : ',Atmos.EventSee);
    Writeln('I - You see (#)      : ',Atmos.ISeeExtra);
    Writeln('E - Others see (#,&) : ',Atmos.EventSeeExtra);
    Writeln('Q - Quit.');
    Writeln('S - Save.');
    Writeln('V - View.');
    Writeln('? - Help.');
  END;

BEGIN
  IF GetAtmosphere(CmdNum, Atmos) THEN
  BEGIN
    REPEAT
      GrabLine('Edit atm. command(? for help)? ', S, AllStats);
      S := Lowcase(Trim(S));
      IF Length(S) = 0 THEN
        S := '?';
      CASE S[1] OF
        'u' : IF NOT AllStats.Stats.Privd THEN
                Writeln('You are not allowed to do that.')
              ELSE
              begin
                GrabLine('New Owner? ', dummy_s, AllStats, , ShortLen);
                atmos.owner := substr(dummy_s, 1, dummy_s.length);
              end;
        't' : begin
           GrabLine('New trigger? ', dummy_s, AllStats, , ShortLen);
           atmos.trigger := substr(dummy_s, 1, dummy_s.length);
        end;
        'm' : GrabLine('Message for user? ', Atmos.ISee, AllStats);
        'o' : GrabLine('Message for others(&)? ', Atmos.EventSee, AllStats);
        'i' : GrabLine('Message for user(#)? ', Atmos.ISeeExtra, AllStats);
        'e' : GrabLine('New message for others(#,&)? ', Atmos.EventSeeExtra,
                       AllStats);
        'q' : Done := TRUE;
        's' : IF SaveAtmosphere(CmdNum, Atmos) THEN
              BEGIN
                LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log,
                         E_ReadAtmosphere, 0,0,0,0, '', R_ALLROOMS);
                Done := TRUE
              END
              ELSE
                Writeln('Unable to save atmosophere.');
        'v','?' : ViewAtmos(Atmos);
        OTHERWISE
        BEGIN
          Writeln('Bad command.');
        END;
      END;
    UNTIL Done;
  END;
END;

BEGIN
  IF Length(S) > ShortLen THEN S.Length := ShortLen
  ELSE IF Length(S) = 0 THEN
    GrabLine('Atmosphere command to edit? ', S, AllStats, , ShortLen);
  S := Lowcase(S);
  CmdNum := LookupAtmosphere(S);
  Found := FALSE;
  IF (CmdNum = 0) THEN
  BEGIN
    CmdNum := 1;
    IF GrabYes('Atmosphere command not exist,  create it? ', AllStats) THEN
    BEGIN
      WHILE (CmdNum <= MaxAtmospheres) AND (NOT Found) DO
      BEGIN
        Found := Length(Atmosphere[CmdNum].Trigger) = 0;
        IF NOT(Found) THEN CmdNum := CmdNum + 1;
      END;
      IF Not(Found) THEN
          Writeln('We could not find an empty slot.')
      ELSE
      BEGIN
        Atmos := Zero;
        Atmos.Owner := AllStats.Stats.Userid;
        Atmos.Trigger := SubStr(S, 1, S.Length);
        IF SaveAtmosphere(CmdNum, Atmos) THEN
          Good := TRUE;
      END;
    END;
  END
  ELSE
    IF (GetAtmosphere(CmdNum, Atmos)) THEN
      IF ((Atmos.Owner = AllStats.Stats.Userid) OR (AllStats.Stats.Privd)) THEN
        Good := TRUE
      ELSE
        Writeln('That atmosphere command already exists.');
  IF Good THEN
    EditAtmosphere(CmdNum, AllStats);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoEdit(S : String; VAR AllStats : AllMyStats);

VAR
  Done : BYTE_BOOL := FALSE;
  Option : String;

PROCEDURE DoEditMenu(P : BYTE_BOOL := FALSE);
BEGIN
  IF (P) THEN
  BEGIN
    Writeln('R - Edit the player slots in a room.');
    Writeln('G - Edit group names.');
  END;
  Writeln('A - Edit atmosphere commands.');
  Writeln('Q - Exit.');
  Writeln('? - Help Menu.');
  Writeln;
END;

BEGIN
  IF Length(S) = 0 THEN
    DoEditMenu(AllStats.Stats.Privd)
  ELSE
  BEGIN
    Option := Lowcase(Trim(Bite(S)));
    S := Trim(S);
    CASE Option[1] OF
      'r' : IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
              EditPeopleHere(S, AllStats);
      'q' : ;
      'g' : IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
              EditGroupName(S, AllStats);
      'a' : EditAtmosphere(S, AllStats);
      OTHERWISE
         DoEditMenu(AllStats.Stats.Privd);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE HelpAtmosphere;

VAR
  I : INTEGER;
  Count : INTEGER;

BEGIN
  Writeln;
  Writeln('Atmosphere commands:');
  Count := 1;
  FOR I := 1 TO MaxAtmospheres DO
  BEGIN
    IF Atmosphere[I].Trigger <> '' THEN
    BEGIN
      WriteNice(Atmosphere[I].Trigger,20);
      IF Count MOD 4 = 0 THEN
        Writeln;
      Count := Count + 1;
    END;
  END;
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE HelpNormal(VAR AllStats : AllMyStats);

VAR
  S : String;

BEGIN
  Writeln;
  Writeln('=============> Primary Commands <==============');
  Writeln('N,S,E,W,U,D      Move n/north s/south e/east w/west u/up d/down)');
  Writeln('Who              List of people playing monster now.');
  Writeln('Sheet            View your stats.');
  Writeln('I,inventory #    See what you are carrying.');
  Writeln('Att #            Attack person # with weapon or claws.');
  Writeln('. (period)       Repeat last command.');
  Writeln('Cast #           Cast spell #.');
  Writeln('Hide [#]         Hide yourself or hide object (#).');
  Writeln('Look,l [#]       Look here | look at something or someone (#) closely');
  Writeln('Search           Look around the room for anything hidden.');
  Writeln('Say or '' (quote)  Say line of text following command to others in the room');
  Writeln('Get or drop #       Get/drop an object.');
  Writeln('Wear #           Wear the object # (same as equip).'); 
  Writeln('Wield #          Wield the weapon # (you must be holding int first).');
  Writeln('Use #            Use object #.');
  Writeln('Block #          Block an exit.'); 
  Writeln;
  GrabLine('-more-', S, AllStats);
  Writeln;
  Writeln('==========> Less Important Commands <==========');
  Writeln('Brief            Toggle printing of room descriptions.');
  Writeln('Equip #          Equip yourself with object #.');
  Writeln('Ping #           Make sure a player is alive.');
  Writeln('Punch #          Punch person #.');
  Writeln('Quit             Leave the game.');
  Writeln('Lob #            Lob a bomb in a direction.');
(*  Writeln('Health           Show how healthy you are.');
    Writeln('Highlight        Highlight people attacking you.'); *)
  WriteLn('Alias # command  Alias a shorter name to a command, ex: alias 4 attack fred');
  Writeln('Self (#)         Edit a description yourself.');
  Writeln('Throw #          Throws object #');
  Writeln('?,Help           This list.');
  Writeln('Express #        Express youself with message #.'); 
  Writeln('Learn [#]        Learn a spell # or see all spells.'); 
  Writeln('Make #           Attempt to make an object named #.'); 
(*  Writeln('Name #           Set your game name to #.');
  Writeln('Whois #          What is a player''s username.');
  Writeln('Return           Pray to the vax so that it may return you to the great hall.');
*)  
  Writeln('Show details     Look in a room for special clues.');
(*  Writeln('Steal #          Attempt to steal an item from another player.');
*)
(*  Writeln('Whisper #        Whisper something (prompted for) to person #.');
*)
(*  Writeln('Pickpocket       Attempt to steal gold from another player.');  
*)
(*  Writeln('Players          List people who have played monster.'); *)

  Writeln;
END;

(* -------------------------------------------------------------------------- *)
PROCEDURE HelpPrintFile(Filename : String);
VAR
  AFile : TEXT;
  line : string;
  good : boolean := TRUE;
BEGIN
  open(afile, filename, sharing:=readonly, history:=old, error := continue);
  if (status(afile) = 0) then reset(afile);
  WHILE (not(eof(afile)) and (status(afile) = 0)) DO
  BEGIN
    readln(afile, line, error := continue);
    writeln(line);
  END;
  close(afile,error:=continue);
END;
(* -------------------------------------------------------------------------- *)

PROCEDURE HelpCustom;

BEGIN
  Writeln;
  Writeln('Accept #         Allow others to link an exit here.');
  Writeln('Alink            Creates a one way link.');
  Writeln('Create #         Create a new structure named #');
  Writeln('Customize [#]    Customize a room, object #, or exit #.');
  Writeln('Describe #       Describe a room feature (#) in detail');
  Writeln('Destroy #        Destroy an instance of object #.');
  Writeln('Duplicate #      Make a duplicate of an already-created object.');
  Writeln('Link #           Link exit # to another room.');
  Writeln('Nuke #           Destroy all instances of object #.'); 
  Writeln('Objects          List objects that you own.');
  Writeln('Refuse #         Refuse any links in a direction.');
  Writeln('Rooms            List rooms that you own.');
  Writeln('Unlink #         Unlink exit #.');
  Writeln('Zap #            Zap a structure named #.');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE HelpPrivd(SysMaint : BYTE_BOOL := FALSE);

BEGIN
  Writeln;
  Writeln('These are priviledged user commands only.');
  Writeln('-----------------------------------------');
  Writeln('Announce #       Announce text # to all occupied rooms.');
  Writeln('Change #|?       Change attribute.');
  Writeln('Cia              Enters cia mode.');
  Writeln('Class [#]        Lists player classes by group');
  Writeln('Find #           Lists locations of objects, exits, or gold.');
  Writeln('Mess #           Display text # in current room.');
  Writeln('Objects #|*      List objects by owner or all objects.');
  Writeln('Poof #           Move to room # or move player #.');
  Writeln('Repeat           Repeats previous events logged.');
  Writeln('Rooms #|*        List rooms by owner or all rooms.');
  IF SysMaint THEN
  BEGIN
    Writeln('System           Enter system maintenance mode.');
    Writeln('Universe         Enters universe maintenance for univ.mon.');
  END
  ELSE
    Writeln('System           View system maintenance stats.');
  Writeln('Unblock #        Mark an exit as totally unblocked.');
  Writeln('Unmake #         Remove all instances of an object.');
  Writeln('Unwho #          Remove/add player # from/to who list.');
  Writeln('Claim #          Claim ownership of stuff, rooms.');
  Writeln('Public #         Make a room, or object public.');
  Writeln('Togop #          Toggle that op thing to trick players.');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowAllCommands;

VAR
  I : INTEGER;
  Posit : INTEGER := 0;

BEGIN
  FOR I := 1 TO MaxCmds DO
  BEGIN
    IF Posit = 3 THEN
    BEGIN
      Posit := 0;
      Writeln;
    END
    ELSE
      Posit := Posit + 1;
    WriteNice(Get_command_by_number(I), 20);
  END;
  IF Posit <> 3 THEN
    Writeln;
END;

(* -------------------------------------------------------------------------- *)

(* -------------------------------------------------------------------------- *)

PROCEDURE PrintScrollPattern;
CONST
  MIN = 32;
  MAX = 126;
VAR
 Curr : INTEGER;
 Start, Loop, Num : INTEGER;
BEGIN
  Num := 1;
  Curr := MIN;
  Start := MIN;
  WHILE TRUE DO
  BEGIN
    Curr := Start;
    FOR Loop := 1 TO 80 DO
    BEGIN
      Write(CHR(Curr));
      Curr := Curr + 1;
      IF Curr > MAX THEN Curr := MIN;
    END;
    Writeln;
    Start := Start + 1;
    IF Start > MAX THEN Start := MIN;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowHelp(VAR AllStats : AllMyStats);

VAR
  Prompt, S : String;

BEGIN
  Prompt := '';
  IF AllStats.Stats.SysMaint THEN
    Prompt := '(F)ile ';
  IF AllStats.Stats.Privd THEN
    Prompt := prompt + '(P)rivd, (X)tra, (C)ustomization ';
  Prompt := Prompt + '(M)ap, (N)ormal, or (A)tmosphere help? ';
  GrabLine(Prompt, S,  AllStats);
  S := LowCase(S);
  IF (S = 'f') AND AllStats.Stats.SysMaint THEN
  BEGIN
    GrabLine('Filename? ', S, AllStats);
    helpprintfile(S);
  END ELSE IF (S = 'a') THEN
    HelpAtmosphere
  ELSE IF (S = 'm') THEN
    HelpPrintFile('mon_disk:monster.map')
  ELSE IF (S = 'c') THEN
    HelpCustom
  ELSE IF (S = 'p') AND AllStats.Stats.Privd THEN
    HelpPrivd(AllStats.Stats.Privd)
  ELSE IF (S = 'x') AND AllStats.Stats.Privd THEN
    ShowAllCommands
  ELSE IF (S = 'n') THEN
    HelpNormal(AllStats);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE MainHelp;
BEGIN
  Writeln('O - Object');
  Writeln('E - Exit');
  Writeln('S - Spell');
  Writeln('R - Room');
  Writeln('C - Class');
  Writeln('M - Random');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CreateHelp;

BEGIN
Writeln('Usage CREATE (O,S,R,C,M) (name)');
  MainHelp;
END;

PROCEDURE CustomHelp;

BEGIN
  Writeln('Usage CUSTOM (O,E,S,R,C,M) (name)');
  MainHelp;
END;

PROCEDURE ZapHelp;

BEGIN
  Writeln('Usage ZAP (O,S,R,C,M) (name)');
  MainHelp;
END;

(* -------------------------------------------------------------------------- *)

[EXTERNAL] PROCEDURE ZapRandom(Num : INTEGER); extern;

PROCEDURE DoZap(TheName : String; VAR AllStats : AllMyStats);

VAR
  S : String;
  N : INTEGER;

BEGIN
  N := 0;
  S := LowCase(Trim(Bite(TheName)));
  IF Length(S) > 0 THEN
  BEGIN
    CASE S[1] OF
      'o' : IF LookupName(nt_short, s_na_objnam, N, TheName, FALSE) THEN
              ZapObject(N, AllStats.Stats.Slot, AllStats.Stats.Log,
                        AllStats.Stats.Location);
      's' : IF LookupName(nt_short, s_na_spell, N, TheName, FALSE) THEN
              ZapSpell(N);
      'r' : IF LookupRoomName(TheName, N, FALSE, FALSE) THEN
              ZapRoom(N, AllStats);
      'c' : IF LookupName(nt_realshort, rsnr_class, N, TheName, FALSE) THEN
              ZapClass(N);
      'm' : IF AllStats.Stats.SysMaint THEN
              IF LookupName(nt_short, s_na_rannam, N, TheName, FALSE, FALSE) THEN
                ZapRandom(N);
      OTHERWISE ZapHelp;
    END;
  END
  ELSE ZapHelp;
END;

(* -------------------------------------------------------------------------- *)

[EXTERNAL] PROCEDURE CustomRandom(RandomNum : INTEGER;
                                  VAR AllStats : AllMyStats); EXTERN;

PROCEDURE DoCustom(TheName : String; VAR AllStats : AllMyStats);

VAR 
  S : String;
  N : INTEGER;
  Stat : StatType;

BEGIN
  Stat := AllStats.Stats;
  N := 0;
  IF Length(TheName) > 0 THEN
  BEGIN
    S := LowCase(Bite(TheName));
    CASE S[1] OF
      'o' : IF LookupName(nt_short, s_na_objnam, N, TheName, FALSE, FALSE) THEN
              CustomObject(N, AllStats);
      'e' : IF LookupDir(N, TheName) THEN
              CustomExit(N, AllStats);
      's' : IF AllStats.Stats.Privd THEN
              IF LookupName(nt_short, s_na_spell, N, TheName, FALSE, FALSE) THEN
                CustomSpell(N,AllStats);
      'r' : IF Length(TheName) = 0 THEN
              CustomRoom(AllStats.Stats.Location, AllStats)
            ELSE
            IF LookupRoomName(TheName, N, FALSE, FALSE) THEN
              CustomRoom(N, AllStats);
      'c' : IF AllStats.Stats.Privd THEN
              IF LookupName(nt_realshort, RSNR_class, N, TheName, FALSE, FALSE) THEN
                CustomClass(N, AllStats);
      'm' : IF AllStats.Stats.SysMaint THEN
              IF LookupName(nt_short, s_na_rannam, N, TheName, FALSE, FALSE) THEN
                CustomRandom(N, AllStats);
      OTHERWISE CustomHelp;
    END;
  END
  ELSE CustomHelp;
END;

(* -------------------------------------------------------------------------- *)

[EXTERNAL] PROCEDURE CreateRandom(S : string;
                                  VAR AllStats : AllMyStats); extern;

PROCEDURE DoCreate(TheName : String; VAR AllStats : AllMyStats);

VAR
  S : String;
  N : INTEGER;

BEGIN
  N := 0;
  IF Length(TheName) > 0 THEN
  BEGIN
    S := Lowcase(Bite(TheName));
    CASE S[1] OF
      'o' : CreateObject(TheName, AllStats.Stats);
      'r' : DoCreateRoom(TheName, AllStats);
      's' : CreateSpell(TheName, AllStats.Stats);
      'c' : IF NOT LookupName(nt_realshort, RSNR_class, N, TheName, TRUE) THEN
              IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
                CreateClass(TheName);
      'm' : IF AllStats.Stats.SysMaint THEN
              IF NOT LookupName(nt_short, s_na_rannam, N, TheName, TRUE) THEN
                CreateRandom(TheName, AllStats);
       OTHERWISE CreateHelp;
    END  (* CASE *)
  END
  ELSE CreateHelp;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSheet(Player : INTEGER := 0; AllStats : AllMyStats);

VAR
  NumRooms, tmp, NumObjects, I, J, Lev, AverageDamage : INTEGER;
  First : BYTE_BOOL := TRUE;
  S : String;
  Class : ClassRec;
  Stat : StatType;
  Tick : TkTimeType;
  MyHold : HoldObj;
  Charac : CharRec;
  SpellNam : ShortNameRec;
  Indx : IndexRec;
 
BEGIN
  IF Player <> 0 THEN
    LoadStats(Player, AllStats)
  ELSE
    Player := AllStats.Stats.Log;
  IF GetClass(AllStats.Stats.Class, Class) THEN
  BEGIN
    Stat := AllStats.Stats;
    Tick := AllStats.Tick;
    MyHold := AllStats.MyHold;
  END;
  Lev := Stat.Experience DIV 1000;
  Writeln('--------------- Character Sheet ------------------');
  Writeln('Name        : ',Stat.Name,'          Class : ',Class.Name);
  Write('Size        : ',Stat.Size:0,'''','            Alignment : ');
    PrintAlignment(Stat.Alignment);
  Writeln('Exp/level   : ',Stat.Experience:0,'/',Lev:0);
  Writeln('Health/Max  : ',Stat.Health:0,'/',MyHold.MaxHealth:0);
  IF AllStats.MyHold.MaxMana > 0 THEN
    Writeln('Mana/max    : ',Stat.Mana:0,'/',AllStats.MyHold.MaxMana:0);
  
  IF Stat.Poisoned THEN Writeln('Status      :Poisoned');

  Writeln('Move delay  : ',Stat.MoveSpeed:0,'/100 sec.');
(*IF (Stat.Steal>0) THEN  
    Writeln('Steal       : ',Stat.Steal:0,'%'); *)

  IF (Stat.MoveSilent>0) THEN
    Writeln('Move silent : ',Stat.MoveSilent:0,'%');

  IF Stat.PoisonChance > 0 THEN
    Writeln('Poison chnc : ',Stat.PoisonChance:0,'%');

  Writeln('Attack delay: ',Stat.AttackSpeed:0,'/100 sec.');
  Writeln('Weapon use  : ',Stat.WeaponUse:0,'%');

  IF Player = 0 THEN
  BEGIN
    IF Tick.Invisible AND (Tick.TkInvisible <> -1) THEN
      Writeln('Invisible time left: ',(Tick.TkInvisible-GetTicks) DIV 10);
    IF Tick.TkSpeed > GetTicks THEN
      Writeln('Speed time left    : ',(Tick.TkSpeed-GetTicks) DIV 10);
    IF Tick.TkStrength > GetTicks THEN
      Writeln('Strength change/time: ', Tick.Strength:0, '/',
             ((Tick.TkStrength-Getticks) DIV 10):0);
    IF Tick.SeeInvisible AND (Tick.TkSee <> -1) THEN
      Writeln('See invisible time : ',(Tick.TkSee-GetTicks) DIV 10);
  END;

  IF (Stat.MaxRooms >  0) THEN
    IF CountRooms(AllStats.Stats.Userid, NumRooms) THEN
      Writeln('Max. Rooms  : ',Stat.MaxRooms:7,' (Remaining: ',Stat.MaxRooms-NumRooms:0,')');
  IF (Stat.MaxObj > 0) THEN
    IF CountObjects(AllStats.Stats.Userid, NumObjects) THEN
      Writeln('Max. Objs   : ',Stat.MaxObj:7,' (Remaining: ',Stat.MaxObj-NumObjects:0,')');

(*  Writeln('Kills       : ',Stat.Kills:7);
    Writeln('Deaths      : ',Stat.Deaths:7);
    Writeln('K/D Rating  : ', ((Stat.Kills+1)/(Stat.Deaths+1)):7:1); *)

  IF Stat.Wealth > 0 THEN
    Writeln('Money       :',Stat.Wealth:7);
  IF Stat.Bank > 0 THEN
    Writeln('    Money in Bank: ',Stat.Bank:7);
  (* MWG *)
  IF (MyHold.Weapon = 'claws') THEN
    AverageDamage := MyHold.BaseDamage + (Myhold.RandomDamage DIV 2)
  ELSE
    AverageDamage := Round((0.01 * Stat.WeaponUse) * 
                           (MyHold.BaseDamage + (Myhold.RandomDamage DIV 2))); 
  IF (AverageDamage <> 0 ) THEN
  BEGIN
    Writeln('Weapon      : ',Myhold.Weapon);
    Writeln('Avg Dmg     : ',AverageDamage:0);  
(*  Writeln(' ', MyHold.BaseDamage:0,'/',MyHold.RandomDamage:0); *)
  END;

  Writeln('Worn Armor  : ',MyHold.BaseArmor:0,'%','   Weapon Deflect : ' 
          ,MyHold.DeflectArmor:0,'%');
  Writeln('Spell Armor : ',MyHold.SpellArmor:0,'%','    Spell Deflect : '
          ,MyHold.SpellDeflectArmor:0,'%'); 
  
  IF GetChar(Player, Charac) AND GetIndex(I_Spell, Indx) AND
     GetShortName(s_na_spell, SpellNam) THEN
  BEGIN
    FOR I := 1 TO Indx.Top DO
    BEGIN
      IF NOT(Indx.Free[I]) then
        if (Charac.Spell[I] <> 0) THEN
        BEGIN
          IF First THEN
          BEGIN
            Writeln('Spells: ');
            First := FALSE;
          END;
          Writeln('(',Charac.Spell[I]:0,') ',SpellNam.Idents[I]);
        END;
    END;
  END;
  Writeln('--------------------------------------------------');
END;

(* -------------------------------------------------------------------------- *)

FUNCTION DoSetName(S : String; VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Notice, Sprime : String;
  Ok : BYTE_BOOL := TRUE;
  Dummy : INTEGER;
  DumNam : String;
  Pers : ShortNameRec;

BEGIN
    DoSetName := FALSE;
    IF (S <> '') THEN
    BEGIN
      IF (Length(s) <= ShortLen) AND (Length(s) > 2) THEN
      BEGIN 
        Sprime := Lowcase(s);
     	IF LookupName(nt_short, s_na_pers, Dummy, Sprime) THEN
        BEGIN
          Ok := FALSE;
        END;
        DumNam := Sprime;
        DumNam.Length := 3;
        IF LookupName(nt_short, s_na_pers, Dummy, Dumnam) THEN
        BEGIN
          Ok := FALSE;
          Writeln('Please choose a more unique name.');
	  IF AllStats.Stats.Privd THEN
             DoWhois(DumNam, 1);
        END;
        IF Ok THEN
        BEGIN
          AllStats.Stats.Name := S;
	  Notice := Here.People[AllStats.Stats.Slot].Name;
	  Here.People[AllStats.Stats.Slot].Name := S;
          IF SaveRoom(AllStats.Stats.Location, Here) THEN;
	  Notice := Notice + ' is now known as ' + S;
          LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_SETPSLOT,
                   0, 0, AllStats.Stats.Health, 0,
                   S, AllStats.Stats.Location, ,
                   Here.People[AllStats.Stats.Slot].Hiding);
	  IF NOT(Here.People[AllStats.Stats.Slot].Hiding > 0) THEN
            LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG,
                     0,0,0,0, Notice, AllStats.Stats.Location);
          IF SetPersName(Allstats.stats.Log, S) THEN
            Writeln('You are now known as ',AllStats.Stats.Name,'.');
	END;
      END
      ELSE
        Writeln('Please limit your name to between 3 and ',
			 ShortLen:0, ' characters.');
    END
    ELSE
    BEGIN 
        Writeln('You are known to others as ',AllStats.Stats.Name);
        Ok := TRUE;
    END;
    DoSetName := Ok;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION GetDir(S : String; VAR Dir : INTEGER) : BYTE_BOOL;

BEGIN
  S := Trim(s);
  S := LowCase (s);
  CASE S.Body[1] OF
     'n','N' : Dir := North;
     's','S' : Dir := South;
     'e','E' : Dir := East;
     'w','W' : Dir := West;
     'u','U' : Dir := Up;
     'd','D' : Dir := Down;
     OTHERWISE Dir := 0;
  END;
  GetDir := Dir <> 0;
END;

(* -------------------------------------------------------------------------- *)

[global]
FUNCTION LookupEffect(Obj : ObjectRec; EffectNum : INTEGER) : INTEGER;

VAR
  I : INTEGER;

BEGIN
  LookupEffect := 0;
  FOR I := 1 TO MaxParm DO
    IF Obj.Parms[I] MOD 100 = EffectNum THEN
      LookupEffect := Obj.Parms[I] DIV 100;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Equipit(Slot : INTEGER; Silent : BYTE_BOOL := FALSE;
                 VAR MyHold : HoldObj; VAR Stat : StatType) : BYTE_BOOL;

VAR
  N, I : INTEGER;
  Obj : ObjectRec;

BEGIN
  EquipIt := FALSE;
  Obj := GlobalObjects[MyHold.Holding[Slot]];
  IF Obj.Wear = 0 THEN
    Writeln('That object is not equippable.')
  ELSE
  BEGIN
    IF Obj.Kind = O_EQUIP THEN
    BEGIN
      IF LookupEffect(Obj, EF_SFIT) > Stat.Size THEN
   	Writeln('The ',Obj.ObjName,' is too large.')
      ELSE
      IF LookupEffect(Obj, EF_LFIT) < Stat.Size THEN
    	Writeln('The ', Obj.ObjName,' is too small.')
      ELSE
      IF (Stat.Class <> LookupEffect(Obj, EF_CLASS)) AND
         (LookupEffect(Obj, EF_CLASS) <> 0) THEN
        Writeln('You are not the correct class to equip that.')
      ELSE
      IF (Stat.Group <> LookupEffect(Obj, EF_GROUP)) AND
         (LookupEffect(Obj, EF_GROUP) <>0) THEN
    	Writeln('You are not the correct group to equip that.')
      ELSE
      BEGIN
     	MyHold.Slot[Slot] := Obj.Wear;
        EquipIt := TRUE;
      END;
    END
    ELSE
    BEGIN   (* Not equipment, but can still wear *)
      EquipIt := TRUE;
      MyHold.Slot[Slot] := Obj.Wear;
    END;
  END;
  IF (NOT Silent) AND (MyHold.Slot[Slot] <> 0) THEN
  BEGIN
    Writeln('The ',Obj.ObjName,' is now equipped.');
    LogEvent(Stat.Slot, Stat.Log, E_MSG, 0,0, 0,0, Stat.Name +
             ' has equipped ' +  Obj.ObjName + '.', Stat.Location);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE UnEquip(Slot : INTEGER; Silent : BYTE_BOOL := FALSE;
                  VAR AllStats : AllMyStats);

VAR
  N, I : INTEGER;
  Obj : ObjectRec;
  ObjNum : INTEGER;

BEGIN
  ObjNum := AllStats.MyHold.Holding[Slot];
  Obj := GlobalObjects[ObjNum];
  IF AllStats.MyHold.Slot[Slot] <> 0 THEN
  BEGIN
    IF NOT Silent THEN
    BEGIN
      Writeln('The ', Obj.ObjName,' is no longer equipped.');
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, 0,0, 0,0,
               AllStats.Stats.Name + ' has unequipped '+ ObjPart(ObjNum) + '.',
               AllStats.Stats.Location);
    END;
    AllStats.MyHold.Slot[Slot] := 0;
    SaveHold(AllStats.Stats.Log, AllStats.MyHold);
    IF Obj.Kind = 1 THEN
      EquipmentStats(AllStats);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DeEquip(Wear : INTEGER; VAR Curse : BYTE_BOOL;
                  VAR AllStats : AllMyStats);

VAR
  I, J : INTEGER;
  ObjNum : INTEGER;
  Obj : ObjectRec;

BEGIN
  Curse := FALSE;
  J := SlotEquipped(Wear, AllStats.MyHold);
  IF J > 0 THEN
  BEGIN
    ObjNum := AllStats.MyHold.Holding[J];
    Obj := GlobalObjects[ObjNum];
    IF (LookupEffect(Obj, EF_CURSED)) > 0 THEN
    BEGIN
      Curse := TRUE;
      Writeln('The ', Obj.ObjName,' is cursed.');
    END
    ELSE
      UnEquip(J, , AllStats);
  END;
END;
  
(* -------------------------------------------------------------------------- *)

PROCEDURE DoEquip(S : String; VAR AllStats : AllMyStats);

VAR
  N, Slot, Wear, I, OldSlot : INTEGER;
  Curse : BYTE_BOOL;
  Obj : ObjectRec;

BEGIN
  Curse := FALSE;
  IF S = '' THEN
    Writeln('Type EQUIP <Equipment name> to equip something.')
  ELSE
  BEGIN
    IF NOT LookupName(nt_short, s_na_objnam,n,s) THEN
      Writeln('Unknown object.')
    ELSE
    IF FindHold(N, AllStats.MyHold) = 0 THEN
      INFORM_NotHolding
    ELSE
    BEGIN
      Slot := FindHold(N, AllStats.MyHold);
      Obj := GlobalObjects[N];
      Wear := Obj.Wear;
      OldSlot := SlotEquipped(Wear, AllStats.MyHold);
      IF Wear = OW_TWOHAND THEN
      BEGIN
        DeEquip(OW_SWORDHAND, Curse, AllStats);
        IF NOT Curse THEN
     	  DeEquip(OW_SHIELDHAND, Curse, AllStats);
      END;
      IF (Wear = OW_SWORDHAND) OR (Wear = OW_SHIELDHAND) THEN
	DeEquip(OW_TWOHAND, Curse, AllStats);
      IF NOT(Curse) AND (Wear <> 0) THEN
  	DeEquip(Wear, Curse, AllStats);
      IF (OldSlot <> Slot) AND (NOT Curse) THEN
      BEGIN
        EquipIt(Slot, , AllStats.MyHold, AllStats.Stats);
      END;
    END;
    SaveHold(AllStats.Stats.Log, AllStats.MyHold);
    EquipmentStats(AllStats);
    IF (Obj.Kind = 8) THEN (* Missile Launcher *)
    BEGIN
      AllStats.MyHold.BaseDamage := Obj.Parms[3];
      AllStats.MyHold.RandomDamage := Obj.Parms[4];
      AllStats.MyHold.Weapon := Obj.ObjName;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION WhichDir(VAR Dir : INTEGER; S : String) : BYTE_BOOL;

VAR
  AliasDir, ExitDir : INTEGER;
  AliasMatch, ExitMatch,
  AliasExact, ExitExact,
  ExitReq : BYTE_BOOL;

BEGIN
  S := LowCase(S);
  AliasMatch := LookupAlias(AliasDir, S);
  ExitMatch := LookupDir(ExitDir, S);
  IF AliasMatch THEN
    AliasExact := S = HereDesc.Exits[AliasDir].Alias
  ELSE
    AliasExact := FALSE;
  IF ExitMatch THEN
  BEGIN
    IF (S = Direct[ExitDir]) OR (S = SubStr(Direct[ExitDir],1,1)) THEN
      ExitExact := TRUE
    ELSE
      ExitExact := FALSE;
  END
  ELSE
    ExitExact := FALSE;
  IF ExitMatch THEN
    ExitReq := HereDesc.Exits[ExitDir].ReqAlias
  ELSE
    ExitReq := FALSE;
  Dir := 0;
  WhichDir := TRUE;
  IF AliasExact AND ExitExact THEN
    Dir := AliasDir
  ELSE
  IF AliasExact THEN
    Dir := AliasDir
  ELSE
  IF ExitExact AND NOT ExitReq THEN
    Dir := ExitDir
  ELSE
  IF AliasMatch THEN
    Dir := AliasDir
  ELSE
  IF ExitMatch AND NOT ExitReq THEN
    Dir := ExitDir
  ELSE
  IF ExitMatch AND ExitReq THEN
  BEGIN
    Dir := ExitDir;
    WhichDir := FALSE;
  END
  ELSE
    WhichDir := FALSE;
END;

[global]
FUNCTION FindHold(ObjNum : INTEGER; MyHold : HoldObj) : INTEGER;

VAR
  I, Found : INTEGER;

BEGIN
  Found := 0;
  I := 1;
  WHILE I <= MaxHold DO
  BEGIN
    IF (MyHold.Holding[I] = ObjNum) THEN
      Found := I;
    I := I + 1;
  END;
  FindHold := Found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ClassStats(VAR AllStats : AllMyStats);

VAR
  AClass : ClassRec;
  Level : INTEGER;
  Indx : IndexRec;
  Good : BYTE_BOOL := FALSE;

BEGIN
  Level := AllStats.Stats.Experience DIV 1000;
  IF GetIndex(I_Class, Indx) THEN
  BEGIN
    IF NOT(Indx.Free[AllStats.Stats.Class]) THEN
    BEGIN
      IF GetClass(AllStats.Stats.Class, AClass) THEN
      BEGIN
        WITH AllStats.Stats DO
        BEGIN
          HealSpeed := AClass.HealSpeed;
          Control := AClass.Control;
          Group := AClass.Group;
          Steal := AClass.BaseSteal + AClass.LevelSteal * Level;
          MoveSilent := AClass.MoveSilent + AClass.MoveSilentLevel * Level;
          MoveSpeed := AClass.MoveSpeed;
          AttackSpeed := AClass.AttackSpeed;
          WeaponUse := AClass.WeaponUse + AClass.LevelWeaponUse * Level;
          PoisonChance := AClass.PoisonChance;
	  Alignment := AClass.Alignment;
          Size := AClass.Size;
          HideDelay := AClass.HideDelay;
          ShadowDamagePercent := AClass.ShadowDamagePercent;
        END;
        WITH AllStats.MyHold DO
        BEGIN
          MaxHealth := AClass.BaseHealth + AClass.LevelHealth * Level;
          MaxMana := AClass.BaseMana + AClass.LevelMana * Level;
          BaseDamage := AClass.BaseDamage;
          Randomdamage := AClass.RndDamage + AClass.LevelDamage * Level;
          BaseArmor := AClass.Armor;
          SpellArmor := AClass.SpellArmor;
        END;
        Good := TRUE;
      END;
    END;
  END;
  IF NOT Good THEN
  BEGIN
    WITH AllStats.Stats DO
    BEGIN
      HealSpeed := 0;
      Control := 0;
      Group := 1;
      Steal := 0;
      MoveSilent := 0;
      MoveSpeed := 100;
      AttackSpeed := 0;
      WeaponUse := 0;
      PoisonChance := 0;
      Size := 0;
      HideDelay := 0;
      ShadowDamagePercent := 0;
    END;
    WITH AllStats.MyHold DO
    BEGIN
      MaxHealth := 0;
      MaxMana := 0;
      BaseDamage := 0;
      Randomdamage := 0;
      BaseArmor := 0;
      SpellArmor := 0;
      SpellDeflectArmor := 0;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION FindNumObjs : INTEGER;

VAR
  Sum, I : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxObjs DO
    IF Here.Objs[I] MOD 1000 <> 0 THEN
      Sum := Sum + 1;
  FindNumObjs := Sum;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION FindNumPeople : INTEGER;

VAR
  Sum, I : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxPeople DO
    IF (Here.People[I].Kind <> 0) THEN
      Sum := Sum + 1;
  FindNumPeople := Sum;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION NumPlayersHere : INTEGER;

VAR
  I, Sum : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxPeople DO
    IF (Here.People[I].Kind > 0) THEN
      Sum := Sum + 1;
  NumPlayersHere := Sum;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION FindNumHold(MyHold : HoldObj) : INTEGER;

VAR
  Sum, I : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxHold DO
  IF MyHold.Holding[I] <> 0 THEN
    Sum := Sum + 1;
  FindNumHold := Sum;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE NoiseHide(Percent : INTEGER := 25; Stat : StatType);

BEGIN
  IF ((Here.People[Stat.Slot].Hiding > 0) AND (NumPlayershere > 1)) AND
    NOT(Stat.Privd) THEN
    LogEvent(Stat.Slot, Stat.Log, E_REALNOISE, 0, 0, RND(100) + Percent,
             0, '', Stat.Location);
END;

(* -------------------------------------------------------------------------- *)

[global]
FUNCTION CheckHide(Stat : StatType) : BYTE_BOOL;
BEGIN
  IF (Here.People[Stat.Slot].Hiding > 0) AND NOT(Stat.Privd) THEN
  BEGIN
    CheckHide := FALSE;
    NoiseHide(40, Stat);
    Writeln('You can''t do that while you''re hiding.');
  END
  ELSE
    CheckHide := TRUE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ShowNoises(N : INTEGER);

BEGIN
  IF N < 40 THEN Writeln('There are strange noises coming from behind you.')
  ELSE IF N < 70 THEN Writeln('You hear strange rustling noises behind you.')
  ELSE IF N < 100 THEN Writeln('There are faint noises coming from behind you.')
  ELSE IF N < 140 THEN Writeln('There are faint noises coming from the shadows here.')
  ELSE Writeln('You hear somebody hiding in this room!');
END;

[GLOBAL]
PROCEDURE ShowAltNoise(N : INTEGER);

BEGIN
  IF N < 20 THEN Writeln('A Buffalo wind blows, ruffling your clothes and chilling your bones.')
  ELSE IF N < 40 THEN Writeln('Muffled scuffling sounds can be heard behind you.')
  ELSE IF N < 60 THEN Writeln('The roar of thunder echoes across the sky.')
  ELSE IF N < 80 THEN Writeln('A slight breeze whisps through the air.')
  ELSE Writeln('A loud crash can be heard in the distance.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE BlockSubs(N : INTEGER; S : String);

(* IF N is less than zero, then it is a line description, if it is greater *)
(* than zero, than it is a block *)

VAR
  P, I : INTEGER;
  Desc : DescRec;

BEGIN
  IF N < 0 THEN
    PrintSubs(Abs(N),S)
  ELSE
  IF (N > 0) AND (N <> DEFAULT_DESC) THEN
  BEGIN
    IF GetDesc(N, Desc) THEN
    BEGIN
      I := 1;
      WHILE I <= Desc.DescLen DO
      BEGIN
        P := Index(Desc.Lines[I],'#');
        IF (P > 0) THEN
          Writeln(SubsParm(Desc.Lines[I], S))
        ELSE
          Writeln(Desc.Lines[I]);
        I := I + 1;
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE NicePrint(VAR Len : INTEGER; S : String);

BEGIN
  IF Len + Length(s) > 78 THEN
  BEGIN
    Len := 0;
    Writeln;
  END
  ELSE
    Len := Len + Length(S);
  Write(s);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DescObj(ObjNum : INTEGER);

VAR
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[ObjNum];
  PrintDesc(Obj.LineDesc, 'On the ground here is '+ObjPart(ObjNum)+'.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowObj(ObjNum, Quan, Char : INTEGER; Eqp : BYTE_BOOL);

VAR
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[ObjNum];
  Write(ObjPart(ObjNum):20);
  IF Obj.Kind = O_EQUIP THEN
    Write(ShowCondition(Quan):15)
  ELSE
  IF Obj.Kind = O_MISSILE THEN
    Write(Char:15, '(charges)')
  ELSE
    Write('':15);
  IF Eqp THEN
    Writeln(' [',Equipment[Obj.Wear],']')
  ELSE
    Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoInv(S : String; VAR AllStats : AllMyStats);

VAR
  First : BYTE_BOOL;
  I, ObjNum : INTEGER;

BEGIN
  IF S = '' THEN
  BEGIN
    NoiseHide(30, AllStats.Stats);
    First := TRUE;
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_INVENT, 0,0, 0,0,
             AllStats.Stats.Name, AllStats.Stats.Location);
    FOR I := 1 TO MaxHold DO
    BEGIN
      ObjNum := AllStats.MyHold.Holding[I];
      IF ObjNum <> 0 THEN
      BEGIN
        IF First THEN
     	BEGIN
          Writeln('You are holding:');
          First := FALSE;
  	END;
        ShowObj(Objnum, AllStats.MyHold.Condition[i],AllStats.MyHold.Charges[i],
                (AllStats.MyHold.Slot[I] <> 0));
      END;
    END;
    IF First THEN
      Writeln('You are empty handed.');
  END
  ELSE
    Writeln('To see what someone else is carrying, look at them.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowObjects(Stat : StatType);

VAR
  I : INTEGER;
  ObjName : ShortNameRec;

BEGIN
  IF Here.GoldHere > 0 THEN
    Writeln('There is ', Here.GoldHere:0, ' gold here');
  IF not check_bit(HereDesc.SpcRoom, rm$b_store) THEN
  BEGIN
    FOR I := 1 TO MaxObjs DO
    BEGIN
      IF (Here.Objs[I] MOD 1000 <> 0) AND ((Here.ObjHide[I] MOD 1000 = 0)
          OR Stat.Privd) THEN
      BEGIN
        IF Here.ObjHide[I] MOD 1000 <> 0 THEN
          Write('Hidden ');
        DescObj(Here.Objs[I] MOD 1000);
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION LookDetail(S : String; MySlot, MyLog : INTEGER;
                    Location : INTEGER) : BYTE_BOOL;

VAR
  N : INTEGER;

BEGIN
  IF LookupDetail(N, S) THEN
  BEGIN
    IF HereDesc.DetailDesc[N] = 0 THEN
      LookDetail := FALSE
    ELSE
    BEGIN
      PrintDesc(HereDesc.DetailDesc[N]);
      LogEvent(MySlot, MyLog, E_LOOKDETAIL, 0,0, 0,0, HereDesc.Detail[N],
               Location);
      LookDetail := TRUE;
    END;
  END
  ELSE
   LookDetail := FALSE;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION LookPerson(S : String; Stat : StatType) : BYTE_BOOL;

VAR
  Objnum, I, N, LogNum : INTEGER;
  First, InRoom : BYTE_BOOL;
  ObjNam : ShortNameRec;
  Charac : CharRec;
  Pers : ShortNameRec;
  TargLog : INTEGER;

BEGIN
  IF GetShortName(s_na_objnam, ObjNam) THEN
  BEGIN
    InRoom := ParsePers(N, TargLog, S);
    IF InRoom THEN
      S := Here.People[N].Name;
    IF InRoom OR Stat.Privd THEN
    BEGIN
      IF LookupName(nt_short, s_na_pers, LogNum, S) THEN
      BEGIN
        IF GetChar(LogNum, Charac) THEN
          IF LogNum = Stat.Log THEN
          BEGIN
    	    LogEvent(Stat.Slot, Stat.Log, E_LOOKSELF, 0,0, N,0, Stat.Name,
                     Stat.Location);
	    Writeln('You step outside of yourself for a moment to get an objective self-appraisal:');
	    Writeln;
          END
          ELSE
          IF InRoom THEN
            LogEvent(Stat.Slot, Stat.Log, E_LOOKYOU, N,0, 0,0,
                     '', Stat.Location)
          ELSE
            LogEvent(Stat.Slot, Stat.Log, E_MSG, 0,0, 0,0, Stat.Name + 
                     '''s eyes gaze into the distance.', Stat.Location);
          IF Charac.Self <> 0 THEN
          BEGIN
            PrintDesc(Charac.Self);
	    Writeln;
          END;
          IF InRoom THEN
            DescHealth(N);
          First := TRUE;
          FOR I := 1 TO MaxHold DO
            IF Charac.Item[I] <> 0 THEN
            BEGIN
	      ShowObj(Charac.Item[I], Charac.Condition[I], Charac.Charges[I],
                      Charac.Equip[I]);
  	      First := FALSE;
            END;
          IF First THEN
          BEGIN
            IF GetShortName(s_na_pers, Pers) THEN
              Write(Pers.Idents[LogNum]);
            Writeln(' is empty handed.');
          END;
          LookPerson := TRUE;
      END;   (* LookUp name *)
    END   (* Inroom or privd *)
    ELSE
      LookPerson := FALSE;
  END (* getshortname = true *)
  ELSE
    LooKPerson := FALSE;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoExamine(S : String; VAR Three : BYTE_BOOL; Silent : BYTE_BOOL := FALSE;
                    Stat : StatType; MyHold : HoldObj);

VAR
  N : INTEGER;
  Msg : String;
  Obj : ObjectRec;

BEGIN
  Three := FALSE;
  IF ParseObj(N, S, MyHold) THEN
  BEGIN
    IF ObjHere(N) OR ObjHold(N, MyHold) THEN
    BEGIN
      Three := TRUE;
      Obj := GlobalObjects[N];
      Msg := Stat.Name + ' is examining ' + ObjPart(N) + '.';
      LogEvent(Stat.Slot, Stat.Log, E_EXAMINE, 0,0, 0,0, Msg, Stat.Location);
      IF Obj.Examine = 0 THEN
        Writeln('You see nothing special about the ',Obj.ObjName,'.')
      ELSE
         PrintDesc(Obj.Examine);
    END  (* Obj here *)
    ELSE
    IF NOT(Silent) THEN
      Writeln('That object cannot be seen here.');
  END
  ELSE
  IF NOT(Silent) THEN
    Writeln('That object cannot be seen here.');
END;

(* -------------------------------------------------------------------------- *)

FUNCTION NumCanSee{(log : integer) : INTEGER};

VAR
  Sum, I : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxPeople DO
    IF (Here.People[I].Kind <> log) AND (Here.People[I].Hiding = 0)
       AND (Here.People[I].Kind <> 0) THEN
      Sum := Sum + 1;
  NumCanSee := Sum;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION NextCanSee(VAR Point : INTEGER; Stat : StatType) : String;

VAR
  Found : BYTE_BOOL;
  SelfSlot : INTEGER;

BEGIN
  Found := FALSE;
  WHILE (NOT Found) AND (Point <= MaxPeople) DO
  BEGIN
    IF (Point <> Stat.Slot) AND (Length(Here.People[Point].Name) > 0) AND
     (Here.People[Point].Hiding = 0) THEN
      Found := TRUE
    ELSE
      Point := Point + 1;
  END;

  IF Found THEN
  BEGIN
    NextCanSee := Here.People[Point].Name;
    Point := Point + 1;
  END
  ELSE
  BEGIN
    NextCanSee := Stat.Name;	{ error!  error! }
    Writeln('%searching error in next_can_see; notify the Monster Manager');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowPeople(Stat : StatType; Tick : TkTimeType);

VAR
  I  : INTEGER;
  CanSee : BYTE_BOOL;

BEGIN
  FOR I := 1 TO MaxPeople DO
    IF (Here.People[I].Kind <> 0) AND (I <> Stat.Slot) THEN
    BEGIN
      IF Stat.Privd OR ((Here.People[I].Hiding = 0) OR Tick.SeeInvisible) THEN
      BEGIN
        IF (Here.People[I].hiding = -1) THEN
          Write('Invisible ');
        IF (Here.People[I].Hiding > 0) THEN
          Write('Hiding ');
        DescHealth(I);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowWindow(Stat : StatType);

VAR
  I : INTEGER;
  Loop : INTEGER;
  Line : Linerec;
  Here : Room;

BEGIN
  FOR I := 1 TO MaxWindow DO
  BEGIN
    IF (HereDesc.WindowDesc[I] <> 0) AND (HereDesc.Window[I] <> 0) AND
       (HereDesc.Window[I] <> Stat.Location) THEN
    BEGIN
      GetLine(-HereDesc.Windowdesc[I], Line);
      GetRoom(HereDesc.Window[I], Here);
      FOR Loop := 1 TO NumCanSee(Stat.log) DO
        Writeln(SubsParm(Line.Line, Here.People[Loop].Name));
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE PrintRoom(MyHold : HoldObj; AllStats : AllMyStats);

BEGIN
  PrintParticle(HereDesc.namePrint, HereDesc.NiceName, AllStats);
  IF NOT(AllStats.Stats.Brief) THEN
  BEGIN
    CASE HereDesc.Which of
      0 : PrintDesc(HereDesc.Primary);
      1 : PrintDesc(HereDesc.Secondary);
      2 : BEGIN
            PrintDesc(HereDesc.Primary);
            PrintDesc(HereDesc.Secondary);
          END;
      3 : BEGIN
            PrintDesc(HereDesc.Primary);
            IF HereDesc.MagicObj <> 0 THEN
              IF ObjHold(HereDesc.MagicObj, MyHold) THEN
                PrintDesc(HereDesc.Secondary);
	  END;
      4 : BEGIN
            IF HereDesc.MagicObj <> 0 THEN
            BEGIN
              IF ObjHold(HereDesc.MagicObj, MyHold) THEN
                PrintDesc(HereDesc.Secondary)
              ELSE
                PrintDesc(HereDesc.Primary);
            END
            ELSE
              PrintDesc(HereDesc.Primary);
          END;
    END;  (* Case *)
  END;   { IF not(brief) }
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoLook(S : String := ''; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  One, Two, Three : BYTE_BOOL;
  Stat : StatType;
  MyHold : HoldObj;

BEGIN
  IF NOT AllStats.Op.NoText THEN
  BEGIN
    Stat := AllStats.Stats;
    MyHold := AllStats.MyHold;
    IF S = '' THEN
    BEGIN	{ do an ordinary top-level room look }
      IF (Here.People[Stat.Slot].Hiding <> 0) AND NOT(Stat.Privd) THEN
      BEGIN  
        NoiseHide(5, Stat);
        PrintParticle(HereDesc.NamePrint, HereDesc.NiceName, AllStats, TRUE);
        IF NOT Stat.Brief THEN
        BEGIN
          Writeln;
          Writeln('You can''t get a very good view of the details of the room from where');
          Writeln('you are hiding.');
        END;
      END
      ELSE
      BEGIN
        PrintRoom(MyHold, AllStats);
        IF NOT Stat.Brief THEN
        BEGIN
	   Writeln;
           ShowExits(AllStats.Exit.FoundExits, MyHold);
        END;
      END;
      ShowPeople(Stat, AllStats.Tick);
      ShowWindow(Stat);
      ShowObjects(Stat);
    END
    ELSE
    BEGIN
      One := LookDetail(S, Stat.Slot, Stat.Log, Stat.Location);
      Two := LookPerson(S, Stat);
      DoExamine(S, Three, TRUE, Stat, MyHold);
      IF NOT (One OR Two OR Three) THEN
        Writeln('There isn''t anything here by that name to look at.');
    END;
  END;  (* Are we going to print any text? *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ChangeExp(DeltaExp : INTEGER; Log : INTEGER; VAR Exp : INTEGER);

VAR
  Level : INTEGER;
  NewLevel : INTEGER;
  Anint : IntArray;

BEGIN
  IF GetInt(n_experience, AnInt) THEN
  BEGIN
    IF Anint[Log] < Exp THEN
      Exp := AnInt[Log];
    Level := (Exp DIV 1000);
    Exp := Exp + DeltaExp;
    IF Exp < 0 THEN
      Exp := 0;
    NewLevel := (Exp div 1000);
    AnInt[Log] := Exp;
    IF SaveInt(n_experience, AnInt) THEN
      IF Level < NewLevel THEN
        Writeln('You have gained ',(Newlevel-level):0,' level(s)')
      ELSE
      IF Level > NewLevel THEN
        Writeln('You have lost ',(Level-Newlevel):0,' level(s).');
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DieChangeExperience(Th : INTEGER; My : INTEGER; VAR Stat : StatType);

(* MWG The new experience algorithm *)

VAR
  Mylevel, R : INTEGER;

BEGIN

  Th := Th DIV 1000;  (* making it the level, not the exp *)
  Mylevel := My DIV 1000;
  
  IF (Mylevel = 0) OR (Mylevel < Th) THEN
  BEGIN
    IF (((TH/2) + 1.5 - Mylevel) > 0) THEN
      R := Round(1000*((Th/2) + 1.5 - Mylevel))
    ELSE R := Round(1000*(1/(Mylevel+(Mylevel-th))));
  END
  ELSE
  BEGIN
    IF (Mylevel >= Th) AND (Mylevel < 10) AND ((Mylevel - Th) < 3)THEN
      R := Round(1000*(1/(Mylevel+(Mylevel-Th))))
   ELSE
     R := 0;
   END;
   ChangeExp(R, Stat.Log, Stat.Experience);
END;

(* MWG the old exp algorithm 'it sucked' *)

(* PROCEDURE DieChangeExperience(Th : INTEGER; My : INTEGER; VAR Stat : StatType);

CONST
  e = 2.71828182845;

VAR
  R : INTEGER;

BEGIN
  R := Round((5/13*(Th-My)+15000/13) * E**((-My DIV 1000)/3));
  IF R < 0 THEN
    R := 0;
  IF My > 9999 THEN
    R := 0;
  ChangeExp(R, Stat.Log, Stat.Experience);
END; *)

(* -------------------------------------------------------------------------- *)

[global]
FUNCTION DropObj(ObjSlot : INTEGER; VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Obj : ObjectRec;
  Status : BYTE_BOOL;
  Charac : CharRec;

BEGIN
  DropObj := TRUE;
  Obj := GlobalObjects[AllStats.MyHold.Holding[ObjSlot]];
  AllStats.Stats.MoveSpeed := AllStats.Stats.MoveSpeed - Obj.Weight;
  IF AllStats.MyHold.Slot[ObjSlot] <> 0 THEN
    Unequip(ObjSlot, TRUE, AllStats);
  AllStats.MyHold.Holding[ObjSlot] := 0;
  AllStats.MyHold.Slot[ObjSlot] := 0;
  AllStats.MyHold.Charges[ObjSlot] := 0;
  AllStats.MyHold.Condition[ObjSlot] := 0;
  IF GetChar(AllStats.Stats.Log, Charac) THEN
  BEGIN
    Charac.Item[ObjSlot] := 0;
    Charac.Charges[ObjSlot] := 0;
    Charac.Condition[ObjSlot] := 0;
    Charac.Equip[ObjSlot] := FALSE;
    IF NOT SaveChar(AllStats.Stats.Log, Charac) THEN
      DropObj := FALSE;
  END
  ELSE
    DropObj := FALSE;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION DropEverything(VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  I, Slot, TheObj : INTEGER;
  DidOne : BYTE_BOOL;
  Obj : ObjectRec;

BEGIN
  IF GetRoom(AllStats.Stats.Location, Here) THEN
  BEGIN
    DidOne := FALSE;
    FOR I := 1 TO MaxHold DO
    BEGIN
      IF AllStats.MyHold.Holding[I] <> 0 THEN
      BEGIN
        DidOne := TRUE;
        TheObj := AllStats.MyHold.Holding[I];
        IF PlaceObj(TheObj,AllStats.Stats.Location,AllStats.MyHold.Condition[I],
                    AllStats.MyHold.Charges[I], TRUE, , , AllStats) THEN
        BEGIN
          IF DropObj(I, AllStats) THEN
            DidOne := TRUE
        END
        ELSE
        BEGIN
   	  IF DropObj(I, AllStats) THEN
     	    Inform_Destroy(GlobalObjects[TheObj].ObjName);
        END; 
      END;
    END;
    SaveHold(AllStats.Stats.Log, AllStats.MyHold);
    EquipmentStats(AllStats);
    DropEverything := DidOne;
  END; (* GetRoom *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoDie(VAR AllStats : AllMyStats);

VAR
  Some, Dummy : BYTE_BOOL;
  OldExp, I : INTEGER;
  DieRoomName : ShortString;
  S : String;
  Charac : CharRec;
  Exp : IntArray;
  Class : ClassRec;
  MyWealth : INTEGER := 0;
  Stat : StatType;
  Hide : INTEGER := 0;
  MyVoid : INTEGER;

BEGIN
  IF AllStats.Exit.Blocking <> 0 THEN
  BEGIN
    ClearBit(Here.ExitBlocked[AllStats.Exit.Blocking], AllStats.Stats.Slot);
    SaveRoom(AllStats.Stats.Location,Here);
    LogEvent(AllStats.Stats.Slot,AllStats.Stats.Log,E_BLOCKEXIT,0,0,
	  AllStats.Exit.Blocking,
	  Here.ExitBlocked[AllStats.Exit.Blocking],'is no longer blocking',
	  AllStats.Stats.Location);
    AllStats.Exit.Blocking := 0;
  END;
  WITH AllStats.Stats DO
  BEGIN
    Deaths := Deaths + 1;
    MyWealth := Wealth;
    Wealth := 0;
    Mana := 0;
    OldExp := Experience;
(*    Experience := Experience DIV 2;  *)
    Experience := Experience - 1000; (* MWG change per request *)
    IF Experience < 0 THEN
      Experience := 0;
    Poisoned := FALSE;
  END;
  TimeStrength(AllStats, TRUE);
  TimeSpeed(AllStats, TRUE);
  WITH AllStats DO
  BEGIN
    Tick.Invisible := FALSE;
    Tick.SeeInvisible := FALSE;
  END;
  IF GetChar(AllStats.Stats.Log, Charac) THEN
  BEGIN
    WITH Charac DO
    BEGIN
      Wealth := 0;
      Poisoned := FALSE;
      Health := AllStats.Stats.Health;
      Wealth := 0;
      Mana := 0;
      FOR I := 1 TO MaxSpells DO
        Spell[I] := 0;
      FOR I := 1 TO MaxHold DO
      BEGIN
        Equip[I] := FALSE;
        Item[I] := 0;
        Condition[I] := 0;
        Charges[I] := 0;
      END;
    END;
    IF SaveChar(AllStats.Stats.Log, Charac) THEN;
  END;  (* IF GetChar... *)
  IF GetInt(N_Experience, Exp) THEN
  BEGIN
    Exp[AllStats.Stats.Log] := AllStats.Stats.Experience;
    IF SaveInt(N_Experience, Exp) THEN;
  END;
  Some := DropEverything(AllStats);
  Stat := AllStats.Stats;
  IF Stat.LastHit = Stat.Log THEN
    Stat.LastHit := 0;
  LogEvent(Stat.Slot, Stat.Log, E_MSG, 0,0, 0,0, Stat.Name + 
           ' expires and vanishes in a cloud of greasy black smoke.',
           Stat.Location);
(* MWG *)
  IF GetRoomName(Stat.Location,DieRoomName) THEN
    BEGIN
    IF Length(Stat.Name) + 19 +
       Length(DieRoomName) > 80 THEN
      S := Stat.Name + ' has been slain.'
    ELSE
      S := Stat.Name + ' has been slain at '+ DieRoomName + '.';
    END
  ELSE S := 'Someone has just died.';    
(* MWG *)

  IF NOT GetClass(Stat.Class, Class) THEN
  BEGIN
    Class.ExpAdd := 0;
    Stat.Health := 500;
    myvoid := r_void;
  END
  ELSE
  BEGIN
    Stat.Health := (Class.BaseHealth + (Class.LevelHealth *
                   Stat.Experience DIV 1000)) DIV 2;
    MyVoid := Class.myvoid;
  END;
  if myvoid=0 then myvoid := r_void;

  LogEvent(Stat.Slot, Stat.Log, E_DIED, 0, Stat.LastHit,
           Stat.Group, OldExp+Class.ExpAdd,  S, R_ALLROOMS);

  IF MyWealth > 0 THEN
  BEGIN
    IF GetRoom(Stat.Location, Here) THEN
    BEGIN
      Here.GoldHere := Here.GoldHere + MyWealth;
      IF SaveRoom(Stat.Location, Here) THEN
        Writev(S,'When ',Stat.Name,' died, ',MyWealth:0,
               ' gold fell to the ground.', ERROR := CONTINUE);
      LogEvent(Stat.Slot, Stat.Log, E_MSG, 0,0, 0,0, S, Stat.Location);
    END;
  END;
  Writeln;
  Writeln('        *** You have died! ***');
  Writeln;
  AllStats.Stats := Stat;
  Xpoof(MyVoid, AllStats, 1);
  IF AllStats.Stats.Location <> MyVoid THEN
  BEGIN
    Writeln('You drift in limbo...');
    FOR I := 1 TO MaxPeople DO
      Dummy := FALSE (* PingPlayer(I,, Here, AllStats) *) ;
    IF NOT PutToken(R_VOID, Hide, AllStats) THEN
    BEGIN
      AllStats.Stats.Location := R_GREATHALL;
      IF PutToken(R_GREATHALL, Hide, AllStats) THEN
        Writeln('Your mind clears.')
      ELSE
      BEGIN
	Writeln('Sorry about the inconvenience...');
	Halt;
      END
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION HaveComponents(N : INTEGER; MyHold : HoldObj) : BYTE_BOOL;

VAR
  I : INTEGER;
  Empty,
  Ok : BYTE_BOOL := TRUE;
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[N];
  FOR I := 1 TO MaxComponent DO
  IF NOT ((Obj.Component[i] = 0) OR ObjHold(Abs(Obj.Component[I]), MyHold)) THEN
    Ok := FALSE;
  FOR I := 1 TO MaxComponent DO
    IF Obj.Component[I] <> 0 THEN
      Empty := FALSE;
  HaveComponents := Ok AND (NOT Empty);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DestroyComponents(N : INTEGER; VAR AllStats : AllMyStats);

VAR
  I, Slot : INTEGER;
  Component : ARRAY [1..MaxComponent] OF INTEGER;
  Obj : ObjectRec;

BEGIN
  Obj := GlobalObjects[N];
  Component := Obj.Component;
  FOR I := 1 TO MaxComponent DO
  BEGIN
    Slot := FindHold(Abs(Component[I]), AllStats.MyHold);
    IF (Slot <> 0) AND (Component[i] > 0) THEN
    BEGIN
      DropObj(Slot, AllStats);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoMake(S : String; VAR AllStats : AllMyStats);

VAR
  N, Q, C : INTEGER;

BEGIN
  IF LookupName(nt_short, s_na_objnam, N, S, FALSE, FALSE) THEN
  BEGIN
    IF HaveComponents(N, AllStats.MyHold) THEN
    BEGIN
      GetOriginalStats(N, Q, C);
      IF NOT PlaceObj(N, AllStats.Stats.Location, Q, C ,TRUE, , FALSE,
                      AllStats) THEN 
        inform_noroom
      ELSE
      BEGIN
 	Writeln('Object created.');
        DestroyComponents(N, AllStats);
        SaveHold(AllStats.Stats.Log, AllStats.MyHold);
      END;
    END
    ELSE
      Writeln('You don''t have all the components.');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoDestroy(S : String; VAR AllStats : AllMyStats);

VAR
  Slot, N, Q, C : INTEGER;

BEGIN
  Q := 0;
  IF Length(S) = 0 THEN	
    Writeln('To destroy an object you own, type DESTROY <object>.')
  ELSE
  IF ParseObj(N, S, AllStats.MyHold) THEN
  BEGIN
    IF IsOwner(nt_short, s_na_objown, N, AllStats.Stats.Privd, FALSE) OR
       (GlobalObjects[N].Worth = 0) THEN
    BEGIN
      IF ObjHold(N, AllStats.MyHold) THEN
      BEGIN
        Slot := FindHold(N, AllStats.MyHold);
        DropObj(Slot, AllStats);
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_DESTROY, 0,0, 0,0,
                 AllStats.Stats.Name + ' has destroyed ' + ObjPart(N) + '.',
                 AllStats.Stats.Location);
        Inform_Destroy(ObjPart(N));
      END
      ELSE
      IF ObjHere(N) THEN
      BEGIN
        Slot := FindObj(N, AllStats.Stats.Location);
        IF NOT TakeObj(N, Slot, Q, C, AllStats.Stats.Location) THEN
          Writeln('Someone picked it up before you could destroy it.')
        ELSE
        BEGIN
       	  LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_DESTROY, 0,0, 0,0,
                   AllStats.Stats.Name +  ' has destroyed '+ObjPart(N)+'.',
                   AllStats.Stats.Location);
      	  Inform_Destroy(ObjPart(N));
        END;
      END ELSE
        Writeln('Such a thing is not here.');
    END ELSE
      Writeln('You must be the owner of an object to destroy it.')
  END
  ELSE
    Writeln('There is no such object.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE PrintShortClass(ClassNum : INTEGER);

VAR
  Class : ClassRec;

BEGIN
  IF GetClass(ClassNum, Class) THEN
    Write(Class.WhoName:8)
  ELSE
    Write('ERROR':8);
END;

(* -------------------------------------------------------------------------- *)

[global]
PROCEDURE PrintClass(ClassNum : INTEGER);

VAR
  Class : ClassRec;

BEGIN
  IF GetClass(ClassNum, Class) THEN
    Writeln(Class.Name)
  ELSE
    Writeln('ERROR');
END;

(* -------------------------------------------------------------------------- *)

FUNCTION PDoorKey(N : INTEGER) : String;

VAR
  ObjNam : ShortNameRec;

BEGIN
  IF (N = 0) THEN
    PDoorKey := '<none>'
  ELSE
  IF GetShortName(s_NA_ObjNam, ObjNam) THEN
    PDoorKey := ObjNam.Idents[N]
  ELSE
    PDoorKey := '<error>'
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE AnalExit(Dir : INTEGER);

VAR
  RoomNam : LongNameRec;

BEGIN
  IF NOT ((HereDesc.Exits[Dir].ToLoc = 0) AND (HereDesc.Exits[Dir].Kind <> 5)) AND
          GetLongName(l_NA_RoomNam, RoomNam) THEN
  WITH HereDesc.Exits[Dir] DO
  BEGIN
    Write(Direct[Dir]);
    IF Length(Alias) > 0 THEN
    BEGIN
      Write('(', Alias);
      IF ReqAlias THEN
        Write(' required): ')
      ELSE
        Write('): ');
    END
    ELSE
      Write(': ');
    IF (ToLoc = 0) THEN
      Write('accept, no exit yet')
    ELSE
    IF ToLoc > 0 THEN
    BEGIN
      Write('to ', RoomNam.Idents[ToLoc],', ');
      CASE Kind OF
        0 : Write('no exit');
        1 : Write('open passage');
        2 : Write('door, key=', PDoorKey(ObjReq));
        3 : Write('~door, ~key=', PDoorKey(ObjReq));
        4 : Write('exit open randomly');
        5 : Write('potential exit');
        6 : Write('xdoor, key=', PDoorKey(ObjReq));
        7 : BEGIN
              write('timed exit, now ');
              IF CycleOpen THEN
                Write('open')
              ELSE
                Write('closed');
            END;
        8: Write('passworded');
      END;
      IF Hidden <> 0 THEN
        Write(', hidden');
      IF ReqVerb THEN
        Write(', reqverb');
      IF NOT (AutoLook) THEN
        Write(', autolook off');
      IF HereDesc.TrapTo = Dir THEN
        Write(', trapdoor (', HereDesc.TrapChance:1,'%)');
      IF Here.ExitBlocked[Dir] = 0 THEN
	Write(', unblocked')
      ELSE
        Write(', blocked by ', Count1Bits(Here.ExitBlocked[Dir],0,9):2,
			' people');
    END;
    Writeln;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSExits(RoomNum : INTEGER; Privd : BYTE_BOOL);

VAR
  I : INTEGER;
  Accept, One : BYTE_BOOL; { accept is true if the particular exit is
                           an "accept" (other players may link there)
                           one means at least one exit was shown }

BEGIN
  One := FALSE;
  FOR I := 1 TO MaxExit DO
  BEGIN
    IF (HereDesc.Exits[I].ToLoc = 0) AND (HereDesc.Exits[I].Kind = 5) THEN
      Accept := TRUE
    ELSE
      Accept := FALSE;
    IF (CanAlterExit(I, RoomNum, Privd)) OR (Accept) THEN
    BEGIN
      AnalExit(I);
      One := TRUE;
    END;
  END;
  IF NOT (One) THEN
    Writeln('There are no exits here which you may inspect.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSDetails;

VAR
  I : INTEGER;
  One : BYTE_BOOL;

BEGIN
  One := FALSE;
  FOR I := 1 TO MaxDetail DO
    IF (HereDesc.Detail[I] <> '') AND (HereDesc.DetailDesc[I] <> 0) THEN
    BEGIN
      IF NOT (One) THEN
      BEGIN
        One := TRUE;
        Writeln('Details here that you may inspect:');
      END;
      Writeln('    ', HereDesc.Detail[I]);
    END;
  IF NOT (One) THEN
    Writeln('There are no details of this room that you can inspect.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSHelp;

BEGIN
  Writeln;
  Writeln('Exits             Lists exits you can inspect here');
  Writeln('Details           Show details you can look at in this room');
  Writeln('Experience (*)    Check players experience');
  Writeln('Class      (*)    Check players class');
  Writeln('Room              Check room slots');
  Writeln('Hold              Check what I am holding.');
  Writeln('Randoms           Check to see what types of randoms exist.');
  Writeln('* - currently not available');
  Writeln;
END;

VAR
  ShowCommands : ARRAY[1..7] OF ShortString := 
  ('exits', 'details', 'experience', 'class', 'room', 'hold', 'randoms');

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowRoom(S : String; VAR AllStats : AllMyStats);
VAR
  Index : INTEGER;
BEGIN
  IF NOT LookupRoomName(S, Index, false, false) THEN
    Index := AllStats.Stats.Location;
  ViewSlot(Index);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowHold(VAR AllStats : AllMyStats);
VAR
  Loop : INTEGER;
BEGIN
  Writeln('Slot  Obj Num  Slot equ  Cond  Charges');
  Writeln('----  -------  --------  ----  -------');
  FOR Loop := 1 To MaxHold DO
  BEGIN
    Write(Loop:2,'>');
    Write(AllStats.MyHold.Holding[Loop]:7);
    Write(AllStats.MyHold.Slot[Loop]:10);
    Write(AllStats.MyHold.Condition[Loop]:8);
    Writeln(AllStats.MyHold.Charges[Loop]:7);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowRandoms(VAR AllStats : AllMyStats);
VAR
  Loop : INTEGER;
BEGIN
  Writeln('Monsters..');
  FOR Loop := 1 To MaxRandoms DO
  BEGIN
    IF (Length(GlobalRandoms[Loop].Name) <> 0) then
      Writeln(Loop:0, ') ', GlobalRandoms[Loop].Name);
  END;
  Writeln('End of list');
END;
(* -------------------------------------------------------------------------- *)

PROCEDURE DoShow(S : String; VAR AllStats : AllMyStats);

VAR
  Cmd : INTEGER;
  Part : String;
BEGIN
  Part := Lowcase(Trim(S));
  IF Length(Part) = 0 THEN
    S := '?';
  Cmd := LookupCmd(Part, ShowCommands, 7);
  CASE Cmd OF
    1 : DoSExits(AllStats.Stats.Location, AllStats.Stats.Privd);
    2 : DoSDetails;
    5 : if allstats.stats.privd then ShowRoom(S, AllStats);
    6 : if allstats.stats.privd then ShowHold(AllStats);
    7 : if allstats.stats.privd then ShowRandoms(AllStats);
    OTHERWISE DoSHelp;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoCheck(S : String; VAR AllStats : AllMyStats);

VAR
  Oloop : INTEGER;
  Loop : INTEGER;
  Done : BYTE_BOOL;
  Here : Room;
  User,
  Pers : ShortNameRec;
  Indx : IndexRec;
  Class,
  Exp : IntArray;
  First : String;
  Index : INTEGER;
  MinExp : INTEGER;
  ClassNum : INTEGER;

  PROCEDURE checkhelp;
  BEGIN
    Writeln;
    Writeln('A - check alignments (count them up).');
    Writeln('C - check players class.');
    Writeln('E - check players experience.');
    Writeln('K - check the scores');
    Writeln('Q - quit');
    Writeln;
  END;

BEGIN
  Done := FALSE;
  IF Length(S) = 0 THEN
    GrabLine('Check? ',S, AllStats);
  S := Lowcase(S);
  First := Trim(Bite(S));
  S := Trim(S);
  IF Length(First) = 0 THEN 
    First := 'q';
  CASE First[1] OF
    '?' : CheckHelp;
    'k' : PrintScore;
    'a' : TallyAlignments;
    'e' : BEGIN
            IF GetInt(n_experience, Exp) AND
               GetIndex(I_PLAYER, Indx) AND
               GetShortName(s_na_Pers, Pers) AND
               GetShortName(s_na_user, User) THEN
            BEGIN
              IF S = '' THEN
                GrabLine('Exp minimum (0)? ',S, AllStats);
              IF IsNum(S) THEN
                MinExp := Number(S)
              ELSE
                MinExp := 0;
              FOR Loop := 1 TO Indx.Top do
                IF (NOT Indx.Free[Loop]) THEN
                BEGIN
                  IF Exp[Loop] >= MinExp THEN
                  BEGIN
                    WriteNice(User.Idents[Loop],10);
                    WriteNice(Pers.Idents[Loop],21);
                    Writeln(Exp[Loop]:2);
                  END;
                END;
            END;
          END;
    'c' : BEGIN
            IF S = '' THEN
              GrabLine('Class (all to list all classes)? ',S,AllStats);
            S := Lowcase(Trim(S));
            IF LookupName(nt_realshort, RSNR_class, ClassNum, S) OR (S = 'all') THEN
            BEGIN
              IF GetInt(n_class, Class) AND
                 GetIndex(I_Player, Indx) AND
                 GetShortName(s_na_pers, Pers) AND
                 GetShortName(s_na_user, User) THEN
              BEGIN
                FOR Loop := 1 TO Indx.Top DO
                BEGIN
                  IF (NOT Indx.Free[Loop]) AND ((Class[Loop] = ClassNum) OR
                     (S = 'all')) THEN
                  BEGIN
                    WriteNice(User.Idents[Loop],10);
                    WriteNice(Pers.Idents[Loop],21);
                    PrintShortClass(Class[Loop]);
                    Writeln;
                  END;
                END;
              END;
            END;
          END;
    'q' : Done := TRUE;
    OTHERWISE CheckHelp;
  END;              
  S.Length := 0;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoWho(MetaOk : BYTE_BOOL:= FALSE; AllStats : AllMyStats);

VAR
  I, MyLoc : INTEGER;
  Loc, Exp, Class : IntArray;
  Pers : ShortNameRec;
  Indx : IndexRec;
  RName : LongNameRec;
  Stat : StatType;
  Stmp : String;
  junk, Itmp : INTEGER;
  Aligns, IsAnOp : IntArray;
  classname : realshortnamerec;

BEGIN
  Stat := AllStats.Stats;
  IF NOT ((Here.People[Stat.Slot].Hiding > 0) OR (AllStats.Tick.Invisible)) THEN
    LogEvent(Stat.Slot, Stat.Log, E_WHO, 0,0, Rnd(3),0, Stat.Name, Stat.Location)
  ELSE
    NoiseHide(, Stat);
  IF GetIndex(I_ASLEEP, Indx) AND GetShortName(s_NA_Pers, Pers) AND
    GetLongname(l_NA_RoomNam, RName) AND GetInt(N_Experience, Exp) AND
    GetInt(N_Class, Class) AND GetInt(N_Location, Loc) AND 
    GetInt(N_Alignment, Aligns) AND GetInt(N_Privd, IsAnOp) AND
    GetRealShortName(rsnr_whoname, classname) THEN
  BEGIN
    MyLoc := Loc[Stat.Log];
    CenterText('Monster Status');
    CenterText(SysDate + ' ' + SysTime);
    Writeln;
    Writeln('Game Name             Level   Alignment   Class     Where');
    FOR I := 1 TO Indx.Top DO
    BEGIN
      IF NOT(Indx.Free[I]) THEN
      BEGIN
        WriteNice(Pers.Idents[I],21);
        Stmp := ReturnAlignment(Aligns[I], junk);
        Write((Exp[I] DIV 1000):6);
	IF (IsAnOp[I] > 0) THEN
	   Write('*  ')
	ELSE
	   Write('   ');

	WriteNice(Stmp, 10);
        Write('  ');
        WriteNice(ClassName.idents[class[i]], 8);
        Write('  ');
        Writeln(RName.Idents[Loc[I]])
      END; (* IF Not Free *)
    END;   (* for 1 to indx.top *)
  END;     (* if get.. *)
END;       (* DoWho *)

(* -------------------------------------------------------------------------- *)

PROCEDURE DoSteal(Victim : String; VAR AllStats : AllMyStats;
                  StealType : INTEGER := 1);

(* StealType 1 = steal item. *)
(* StealType 2 = steal gold. *)

VAR
  Num, VictimSlot : INTEGER;
  S : String;
  TargLog : INTEGER;

BEGIN
  Freeze(1, AllStats);
  Num := RND(100);
  IF ParsePers(VictimSlot, TargLog, Victim) THEN
  BEGIN
    IF VictimSlot = AllStats.Stats.Slot THEN
      Writeln('You managed to steal everything you had.')
    ELSE 
    IF Num >= AllStats.Stats.Steal THEN
    BEGIN
      Writeln('You failed to steal from ', here.people[victimslot].Name,'.');
      IF Rnd(100) >= AllStats.Stats.Steal THEN
      BEGIN
	WriteLn('You have been noticed by everyone!');
	S := AllStats.Stats.Name+' has been caught trying to steal from '+
	        Here.People[VictimSlot].Name+'.';
	LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_STEALFAIL,
                 0,0,0,0, S, AllStats.Stats.Location);
        Freeze(2, AllStats);
      END
      ELSE
      BEGIN
	Writeln('Your victim has noticed!');
	S := AllStats.Stats.Name + ' has tried to steal from you but failed.';
	LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_STEALFAIL,
                 VictimSlot,0, 0,0, S, AllStats.Stats.Location);
        Freeze(2, AllStats);
      END;       
    END
    ELSE
    BEGIN
      Write('You just may succeed in stealing ');
      CASE StealType OF
        1 : BEGIN
              Writeln('an item from ', Here.People[VictimSlot].Name,'.');
               LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_STEALSUCCEED,
                        VictimSlot,0, 0,0, '', AllStats.Stats.Location);
            END;
        2 : BEGIN
               Writeln('gold from ', Here.People[VictimSlot].Name,'.');
               LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_PICKSUCCEED,
                        VictimSlot,0, Num,0, '', AllStats.Stats.Location);
            END;
      END;
      Freeze(1, AllStats);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoEndPlay(LogNum : INTEGER; Ping : BYTE_BOOL := FALSE);

VAR
  Adate : ShortNameRec;
  Indx : IndexRec;

BEGIN
  IF NOT(Ping) THEN
  BEGIN { Set the "last date & time of play" }
    IF GetShortName(s_na_date, Adate) THEN
    BEGIN
      Adate.Idents[LogNum] := sysdate + ' ' + systime;
      IF SaveShortName(s_na_date, Adate) THEN;
    END;
  END;
  IF GetIndex(I_ASLEEP, Indx) THEN
  BEGIN
    Indx.Free[LogNum] := TRUE;	{ Yes, I'm asleep }
    IF SaveIndex(I_Asleep, Indx) THEN;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION NukePerson(Location : INTEGER; N : INTEGER; Log : INTEGER) : BYTE_BOOL;
VAR
  Dir : INTEGER;
BEGIN
  IF GetRoom(Location, Here) THEN
  BEGIN
    IF (Here.People[N].Kind = Log) THEN
    BEGIN
      (* Make sure to unblock any exits that the ghost is holding *)
      FOR Dir := 1 TO MaxExit DO
         ClearBit(Here.ExitBlocked[Dir], N {The ghosts slot number} );
      Here.People[N] := Zero;
      IF SaveRoom(Location, Here) THEN
      BEGIN
        IF (log > 0) THEN DoEndPlay(Log, TRUE);
        NukePerson := TRUE;
      END
      ELSE
        NukePerson := FALSE;
    END
    ELSE
      NukePerson := FALSE;
  END
  ELSE  
    NukePerson := FALSE;
END;

(* -------------------------------------------------------------------------- *)

[global]
PROCEDURE LoadStats(Player : INTEGER; VAR AllStats : AllMyStats);

VAR
  AnInt : IntArray;
  Charac : CharRec;
  slote, Loop : INTEGER;
  Pers : ShortNameRec;
  AClass : ClassRec;
  Obj : ObjectRec;

BEGIN
  IF GetShortName(s_NA_Pers, Pers) THEN
    AllStats.Stats.Name := Pers.Idents[Player];
  IF GetInt(N_Class, AnInt) THEN
    AllStats.Stats.Class := AnInt[Player];
  IF GetInt(N_Experience, AnInt) THEN
    AllStats.Stats.Experience := AnInt[Player];
  IF GetInt(N_Location, AnInt) THEN
    AllStats.Stats.Location := AnInt[Player];
  IF GetChar(Player, Charac) THEN
  BEGIN
    WITH AllStats.Stats DO
    BEGIN
      MaxRooms := Charac.MaxRooms;
      MaxObj := Charac.MaxObjs;
      Health := Charac.Health;
      Mana := Charac.Mana;
      Wealth := Charac.Wealth;
      Bank := Charac.BankWealth;
      Kills := Charac.Kills;
      Deaths := Charac.Deaths;
      Alignment := Charac.Alignment;
      Memory := Charac.Memory;
      Poisoned := Charac.Poisoned;
      LastHit := 0;
      LastHitString := 'the Grim Reaper';
      Slot := 0;
      IF GetClass(AllStats.Stats.Class, AClass) THEN
      BEGIN
        Group := AClass.Group;
        MoveSpeed := AClass.MoveSpeed;
        AttackSpeed := AClass.AttackSpeed;
        Size := AClass.Size;
        PoisonChance := AClass.PoisonChance;
        WeaponUse := AClass.WeaponUse + AClass.LevelWeaponUse *
                     (Experience DIV 1000);
        MoveSilent := AClass.MoveSilent + AClass.MoveSilentLevel *
                      (Experience DIV 1000);
        Steal := AClass.BaseSteal + AClass.LevelSteal *
                 (Experience DIV 1000);
        WITH AllStats.MyHold DO
        BEGIN
          BaseArmor := AClass.armor;
          SpellArmor := AClass.SpellArmor;
          BaseDamage := AClass.BaseDamage;
          RandomDamage := AClass.RndDamage * AClass.LevelDamage *
                          (AllStats.Stats.Experience DIV 1000);
        END;
      END;   (* IF GetClass) *)
      Done := FALSE;
    END;
    IF EquipmentStats(AllStats) THEN;
  END;
  AllStats.MyHold.Weapon := DoWeaponName(AllStats.MyHold);
  (* If your weapon is a missile launcher we have to set up the *)
  (* base and rand damage.. *)
  slote := SlotEquipped(OW_TWOHAND, AllStats.MyHold);
  IF slote > 0 THEN
  BEGIN
    Obj := GlobalObjects[AllStats.MyHold.Holding[slote]];
    IF Obj.Kind = 8 THEN (* Missile Launcher *)
    BEGIN
      AllStats.MyHold.BaseDamage := Obj.Parms[3];
      AllStats.MyHold.RandomDamage := Obj.Parms[4];
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[global]
PROCEDURE SaveStats(Player : INTEGER; VAR AllStats : AllMyStats);

VAR
  AnInt : IntArray;
  Charac : CharRec;
  Loop : INTEGER;
  Pers : ShortNameRec;

BEGIN
  IF GetInt(N_Class, AnInt) THEN
  BEGIN
    AnInt[Player] := AllStats.Stats.Class;
    IF SaveInt(N_Class, AnInt) THEN;
  END;
  IF GetInt(N_Experience, AnInt) THEN
  BEGIN
    AnInt[Player] := AllStats.Stats.Experience;
    IF SaveInt(N_Experience, AnInt) THEN;
  END;
  IF GetInt(N_Location, AnInt) THEN
  BEGIN
    AnInt[Player] := AllStats.Stats.Location;
    IF SaveInt(N_Location, AnInt) THEN;
  END;
  IF GetChar(Player, Charac) THEN
  BEGIN
    WITH AllStats.Stats DO
    BEGIN
      Charac.Health := Health;
      Charac.Mana := Mana;
      Charac.Wealth := Wealth;
      Charac.BankWealth := Bank;
      Charac.Kills := Kills;
      Charac.Deaths := Deaths;
      Charac.Poisoned := Poisoned;
    END;
    WITH AllStats.MyHold DO
    BEGIN
      FOR Loop := 1 TO MaxHold DO
      BEGIN
        Charac.Item[Loop] := Holding[Loop];
        Charac.Condition[Loop] := Condition[Loop];
        Charac.Charges[Loop] := Charges[Loop];
        Charac.Equip[Loop] := (Slot[Loop] <> 0);
      END;
    END;
    IF SaveChar(Player, Charac) THEN;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoVersion;
BEGIN
  Writeln('             Monster: Buffalo version 3.5');
  Writeln;
  Writeln('A multiplayer adventure game where the players create');
  Writeln('the world and make the rules.');
  Writeln;
  Writeln('Written by Rich Skrenta at Northwestern University, 1988.');
  Writeln('Modified by: Brent LaVelle MASBRENT@UBVMS');
  Writeln('             Rob Rothkopf  MASROB@UBVMS');
  Writeln('             Larry Nadien  V090N38H@UBVMS');
  Writeln('             Mark Cromwell V112PDL5@UBVMS');
  Writeln('             Pete Beaty    V090KH6B@UBVMS (89-90)');
  Writeln('             Douglas Lewis MASDOUGH@UBVMS (90-92)');
  Writeln('             State University of New York at Buffalo');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RebuildSystem(VAR AllStats : AllMyStats);

VAR
  I, J : INTEGER;
  Indx : IndexRec;

  PROCEDURE BuildIndexFile;

  VAR
    Loop : INTEGER;
    Dummy : IndexRec;

  BEGIN
    Writeln('Rebuilding index file.');
    FOR Loop := 1 TO MaxIndex DO
      Dummy.Free[Loop] := TRUE;
    Dummy.Top := 5;
    Dummy.InUse := 0;
    FOR Loop := 1 TO I_Max DO
      SaveIndex(Loop, Dummy);
  END;

  PROCEDURE BuildNameFiles;

    PROCEDURE BuildShortName;

    VAR
      Dummy : ShortNameRec;
      Loop : INTEGER;

    BEGIN
       Writeln('Building short name.');
       Dummy := ZERO;
       FOR Loop := 1 TO s_NA_Max DO
         SaveShortName(Loop, Dummy);
    END;

    PROCEDURE BuildLongName;

    VAR
      Dummy : LongNameRec;
      Loop : INTEGER;

    BEGIN
       Writeln('Building long name.');
       Dummy := ZERO;
       FOR Loop := 1 TO l_NA_Max DO
         SaveLongName(Loop, Dummy);
    END;

    PROCEDURE BuildRealShortName;

    VAR
      Dummy : RealShortNameRec;
      Loop : INTEGER;

    BEGIN
       Writeln('Building real short name.');
       Dummy := ZERO;
       FOR Loop := 1 TO RSNR_Max DO
         SaveRealShortName(Loop, Dummy);
    END;

  BEGIN
    BuildShortName;
    BuildLongName;
    BuildRealShortName;
  END;

  PROCEDURE BuildIntFile;
  
  VAR
    Loop : INTEGER;
    Dummy : IntArray;

  BEGIN
    Writeln('Rebuilding int file.');
    FOR Loop := 1 TO MaxPlayers DO
      Dummy[Loop] := 1;
    FOR Loop := 1 TO Num_Ints DO
      SaveInt(Loop, Dummy);
  END;

  PROCEDURE BuildStartupRooms;
  
  VAR
    Own : LongNameRec;

  BEGIN
    Writeln('Creating the Great Hall.');
    CreateRoom('The Great Hall');
    DoPublic('The Great Hall', AllStats);
    SetRoomOwner(1, '');
    Writeln('Creating the void.');
    CreateRoom('void');
  END;

  PROCEDURE BuildMonsterFile;

  BEGIN
    CreateClass('Student');
  END;

  PROCEDURE BuildKillFile;

  VAR
    Kill : KillRec;
    Loop : INTEGER;

  BEGIN
    Kill := Zero;
    FOR Loop := 1 TO MaxGroup DO
      IF SaveKill(Loop, Kill) THEN;
  END;

  PROCEDURE BuildEventFile;

  VAR
    ea : EventArray;
    Loop : INTEGER;

  BEGIN
    ea := Zero;
    ea.point :=  1;
    FOR Loop := 1 TO NumEventRec DO
      IF SaveEvent(Loop, ea, false) THEN;
  END;

BEGIN
  IF ReadYes('Rebuild event FILE?') THEN
    BuildEventFile;

  IF ReadYes('Rebuild index FILE?') THEN
    BuildIndexFile;

  IF ReadYes('Add namfile? ') THEN
    BuildNameFiles;

  IF ReadYes('Rebuild intfile? ') THEN
    BuildIntFile;

  IF ReadYes('Rebuild killfile? ') THEN
    BuildKillFile;

  IF ReadYes('Rebuild monsterfile? ') THEN
    BuildMonsterFile;

  IF GetIndex(I_PLAYER, Indx) THEN
  BEGIN
    Indx.Top := MaxPlayers;
    IF SaveIndex(I_PLAYER, Indx) THEN;
  END;

  IF GetIndex(I_ASLEEP, Indx) THEN
  BEGIN
    Indx.Top := MaxPlayers;
    IF SaveIndex(I_Asleep, Indx) THEN;
  END;

  IF ReadYes('Make startup rooms?') THEN
    BuildStartupRooms;

  Writeln('Use the SYSTEM command to view and add capacity to the database');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE Special(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  TName : VeryShortString;
  Nam : ShortNameRec;

BEGIN
  IF (S = 'rebuild') AND (AllStats.Stats.SysMaint) THEN
  BEGIN
    IF AllStats.Stats.SysMaint THEN
    BEGIN
      IF ReadYes('Do you really want to destroy the entire universe? ') THEN
        RebuildSystem(AllStats);
    END;
  END
  ELSE IF S = 'help' THEN
  BEGIN
    Writeln('     Force:Creates another user');
    Writeln(' Invisible:Enter game unannounced.');
    Writeln('      User:Play as another user');
    Writeln('   REBUILD:Rebuilds entire Universe');
    Writeln('    update:Updates class who names');Writeln; 
 END
  ELSE IF (S = 'user') AND (AllStats.Stats.Privd) THEN
  BEGIN
    Write('Username? ');
    Readln(tname);
    Writeln;
    IF LookupName(nt_short, s_na_user, n, tname) THEN
    BEGIN
      IF GetShortName(s_na_user, Nam) THEN
        AllStats.Stats.Userid := Nam.Idents[N];
      IF GetShortName(s_na_pers, Nam) THEN
        AllStats.Stats.Name := Nam.Idents[N];
    END
    ELSE Writeln('User not found in players list.');
  END
  ELSE IF (s = 'force') AND (AllStats.Stats.SysMaint) THEN
  BEGIN
    Write('Username? ');
    Readln(AllStats.Stats.Userid);
  END
  ELSE IF (S = 'invisible') AND AllStats.Stats.Privd THEN
       BEGIN
         AllStats.Tick.Invisible := TRUE;
         AllStats.Tick.TkInvisible := -1;
       END
  ELSE IF S = 'quit' THEN
         AllStats.Stats.Done := TRUE
  ELSE IF S = 'update' THEN Doupdate (* MWG *)
  ELSE Writeln('Invalid option.  Type help for more information.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE Grab(RoomNum : INTEGER; NukeShop : BYTE_BOOL := FALSE);

VAR
  I : INTEGER;

BEGIN
  IF GetRoom(RoomNum, Here) THEN
  BEGIN
    IF (not check_bit(HereDesc.SpcRoom, rm$b_store) OR NukeShop) THEN
    BEGIN
      Writeln('Nuking objects at ',HereDesc.nicename);
      FOR I := 1 TO MaxObjs DO
      BEGIN
        Here.Objs[I] := 0;
        Here.Objhide[I] := 0;
      END;
      IF SaveRoom(RoomNum, Here) THEN;
    END;
  END;
END;
  
(* -------------------------------------------------------------------------- *)

PROCEDURE DoGrab(S : String; VAR AllStats : AllMyStats);

VAR
  RoomNum, I : INTEGER;
  NukeShop : BYTE_BOOL := FALSE;
  Indx : IndexRec;

BEGIN
  IF S = '*' THEN
  BEGIN
    IF GrabYes('Destroy objects in shops? ', AllStats) THEN
      NukeShop := TRUE;
    IF GetIndex(I_ROOM, Indx) THEN
    BEGIN
      FOR I := 1 TO Indx.Top DO
        IF NOT Indx.Free[I] THEN
          Grab(I, NukeShop);
    END;
  END
  ELSE
    Grab(AllStats.Stats.Location, FALSE);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE P_UseFail(N : INTEGER);

BEGIN
  PrintDesc(N, 'It doesn''t work for some reason.');
END;

PROCEDURE P_UseSucc(N : INTEGER);

BEGIN
  IF N <> DEFAULT_DESC THEN
    PrintDesc(N, '');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE Use_SpellBook(VAR Obj : ObjectRec);

VAR
  Page : INTEGER;
  Nam : ShortNameRec;

BEGIN
  IF GetShortName(s_na_spell, Nam) THEN
  BEGIN
    Write('Spell for class: ');
    IF Obj.Parms[1]=0 THEN
      Writeln('any')
    ELSE
      Writeln(GetGroupName(Obj.Parms[1]));
    Writeln('Spells  :');
    FOR Page := 2 to 20 DO
      IF Obj.Parms[Page] > 0 THEN
        Writeln(Nam.Idents[Obj.Parms[Page]]);
  END;
END;

(* ------------------------------------------------------------------------- *)

PROCEDURE Use_MissileLauncher(ObjNum : INTEGER; VAR AllStats : AllMyStats);
(* A note on the Parms fields:                                           *)
(* 1 =                                                                   *)
(* 2 = missile                                                           *)
(* 3 = base dam if used as a weapon                                      *)
(* 4 = rand dam if used as a weapon                                      *)
(* 5 = firing time delay                                                 *)
VAR
  ML_FT, ML_Slot, M_Slot, M_ObjNum, DropLoc : INTEGER;
BEGIN
  IF Here.People[AllStats.Stats.Slot].Hiding <> 0 THEN
     Writeln('You can''t do that whilst hiding!')
  ELSE
  BEGIN
    ML_FT    := GlobalObjects[ObjNum].Parms[5];
    ML_Slot  := FindHold(ObjNum, AllStats.MyHold);
    M_ObjNum := GlobalObjects[ObjNum].Parms[1];
    M_Slot   := FindHold( M_ObjNum, AllStats.MyHold);
    IF( (ML_Slot = 0) OR (M_Slot = 0) )THEN
    BEGIN
      IF(ML_Slot = 0)THEN
       Inform_NotHolding
      ELSE IF(M_Slot = 0)THEN
       Writeln('You have no missles for that!');
    END
    ELSE
    BEGIN
     IF AllStats.MyHold.Charges[M_Slot] > 0 THEN
     BEGIN
       Writeln('You hurry to load a missile into the launcher...');
       Freeze( (ML_FT/1000), AllStats);  (* Fire Time Delay *)
       DropLoc := EffectDist( 
                    GlobalObjects[M_ObjNum].Parms[1],
                    GlobalObjects[M_ObjNum].Parms[2],
     		    GlobalObjects[ObjNum].Parms[2],
      		    0, 0, 0, FALSE, GlobalObjects[M_ObjNum].ObjName,
		    AllStats);
       IF DropLoc < 0 THEN
          PlaceObj(M_ObjNum, -DropLoc, AllStats.MyHold.Condition[m_slot], 1,
			TRUE, , , AllStats);
     END;
     AllStats.MyHold.Charges[M_Slot] := AllStats.MyHold.Charges[M_Slot]-1;
     IF AllStats.MyHold.Charges[M_Slot] <= 0 THEN
     BEGIN
       DropObj(m_slot, allstats);
       Writeln('You just shot your last ' + 
		GlobalObjects[M_ObjNum].ObjName + '.');
     END;
  END;
  END;
END;

(* ------------------------------------------------------------------------- *)

PROCEDURE Use_Bank_Machine(VAR AllStats : AllMyStats);

VAR
  S : String;
  N, Gold : INTEGER;

BEGIN
  Writeln;
  Writeln('You are carrying ', AllStats.Stats.Wealth:0,' gold, and have ',
          AllStats.Stats.Bank:0,' gold in the bank.');
  Writeln;
  Writeln(' 0 - End transaction');
  Writeln(' 1 - Deposit gold');
  Writeln(' 2 - Withdraw gold');
  Writeln(' 3 - Zero account');
  Writeln;
  REPEAT
    GrabLine('Option? ',S , AllStats);
  UNTIL Length(S) > 0;
  S := Trim(S);
  IF IsNum(S) THEN
    N := Number(S)
  ELSE
    N := 0;
  CASE N OF
    0 : Writeln('Transactions completed.');
    1 : BEGIN
	  Grab_Num('How much gold would you like to deposit? ', Gold, 0,
                   AllStats.Stats.Wealth, 0, AllStats);
          IF (AllStats.Stats.Wealth < Gold) OR (Gold < 0) THEN
            Gold := 0; 
	  AllStats.Stats.Bank := AllStats.Stats.Bank + Gold;
	  AllStats.Stats.Wealth := AllStats.Stats.Wealth - Gold;
          AttribAssignValue(AllStats.Stats.Log, ATT_BankWealth, AllStats.Stats.Bank);
          AttribAssignValue(AllStats.Stats.Log, ATT_Wealth, AllStats.Stats.Wealth)
        END;
    2 : BEGIN
  	  IF AllStats.Stats.Bank > 0 THEN
          BEGIN
	    Grab_Num('How much gold would you like to withdraw? ', Gold, 0, 
                     AllStats.Stats.Bank, 0, AllStats);
            IF (AllStats.Stats.Bank < Gold) OR (Gold < 0) THEN
              Gold := 0;
	    AllStats.Stats.Bank := AllStats.Stats.Bank - Gold;
	    AllStats.Stats.Wealth := AllStats.Stats.Wealth + Gold;
            AttribAssignValue(AllStats.Stats.Log, ATT_BankWealth, AllStats.Stats.Bank);
            AttribAssignValue(AllStats.Stats.Log, ATT_Wealth, AllStats.Stats.Wealth)
          END
          ELSE writeln('You have no money in the bank to withdraw!');
        END;
    3 : BEGIN
	  IF GrabYes('Are you sure you want to do this? ', AllStats) THEN
	  BEGIN
  	    AllStats.Stats.Bank := 0;
            AttribAssignValue(AllStats.Stats.Log, ATT_BankWealth, 0);
  	  END
	  ELSE
            Writeln('Aborted.');
        END;
  END;
  Writeln('Done.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE UseCrystal(ObjNum : INTEGER; VAR AllStats : AllMyStats);

BEGIN
  Writeln('Sorry, that is not implemented yet.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE UseSpell(ObjNum : INTEGER; VAR AllStats : AllMyStats);
VAR
  Slot  : INTEGER;
  overb  : STRING;
BEGIN
  Slot := FindHold(ObjNum, AllStats.MyHold);
  IF(Slot = 0)THEN
    Writeln('You are not holding that object.')
  ELSE
  BEGIN
    IF( AllStats.MyHold.Charges[Slot] > 0 )THEN
    BEGIN
      AllStats.MyHold.Charges[Slot] := AllStats.MyHold.Charges[Slot]  - 1;
      DoCast(AllStats.Stats.Slot, AllStats.Stats.Experience DIV 1000, '', 
             GlobalObjects[ObjNum].Parms[1], AllStats);
    END;
    IF( AllStats.MyHold.Charges[Slot] < 1 )THEN
    BEGIN
      DropObj(Slot, AllStats);
      CASE GlobalObjects[ObjNum].Kind OF
        O_SCROLL : overb := ' crumbles ';
        O_WAND   : overb := ' shatters ';
      END;
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_DESTROY, 0,0, 0,0,
            'The ' + GlobalObjects[ObjNum].objname + overb + 'as '
             + AllStats.Stats.Name +
             ' drains its remaining power.', AllStats.Stats.Location);
      Writeln('The ' + GlobalObjects[ObjNum].objname + overb +
              'in your hands.');
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE UseEquipment(N : INTEGER; VAR Obj : ObjectRec;
                       VAR AllStats : AllMyStats);

BEGIN
  IF (LookupEffect(Obj, EF_CrystalRadius) > 0) OR
     (LookupEffect(Obj, EF_Teleport) > 0) OR
     (LookupEffect(Obj, EF_SPELL) > 0) THEN
  BEGIN
    IF LookupEffect(Obj, EF_SPELL) > 0 THEN
      UseSpell(N, AllStats)
    ELSE
    IF LookupEffect(Obj, EF_CrystalRadius) > 0 THEN
      UseCrystal(N, AllStats)
    ELSE
    IF LookupEffect(Obj, EF_Teleport) > 0 THEN
      XPoof(LookupEffect(Obj, EF_Teleport), AllStats);
  END
  ELSE
    Writeln('How the heck do you expect to be able to use that?');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoUse(S : String; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;
  Obj : ObjectRec;

BEGIN
  IF Length(S) = 0 THEN
    GrabLine('Object ?',S, AllStats);
  IF ParseObj(N, S, AllStats.MyHold) THEN
  BEGIN
    Obj := GlobalObjects[N];
    S := Bite(S);
    IF (Obj.UseObjReq > 0) AND NOT(ObjHold(Obj.UseObjReq, AllStats.MyHold)) THEN
    BEGIN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILUSE, N,0,
               0,0, AllStats.Stats.Name, AllStats.Stats.Location);
      P_UseFail(Obj.UseFail);
    END
    ELSE
    IF (Obj.UseLocReq > 0) AND (AllStats.Stats.Location <> Obj.UseLocReq) THEN
    BEGIN
      LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_FAILUSE, N,0,
               0,0, AllStats.Stats.Name, AllStats.Stats.Location);
      P_UseFail(Obj.UseFail);
    END
    ELSE
    BEGIN
      P_UseSucc(Obj.UseSuccess);
      CASE Obj.Kind OF
   	O_BLAND	             : ;
        O_EQUIP	             : UseEquipment(N, Obj, AllStats);
        O_SCROLL             : UseSpell(N, AllStats);
	O_WAND               : UseSpell(N, AllStats);
        O_MISSILELAUNCHER    : Use_MissileLauncher(N, AllStats);
	O_BANKING_MACHINE    : Use_Bank_Machine(AllStats);
	O_SBOOK	             : Use_SpellBook(Obj);
        OTHERWISE writeln('That object is of an unknown type.');
      END;
    END;
  END
  ELSE
    Writeln('There is no such object here.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoPossess(S : String; Possessor : BYTE_BOOL := TRUE;
                    VAR AllStats : AllMyStats);

VAR
  N, Log : INTEGER;
  Ok : BYTE_BOOL := TRUE;      (* Ok to do the switch *)
  Switch : BYTE_BOOL := FALSE; (* Are we switching bodies or taking over a dead one *)
  Indx : IndexRec;
  Nam : ShortNameRec;

BEGIN
  Log := 0;
  IF LookupName(nt_short, s_na_pers, N, S) THEN
    Log := N
  ELSE
  IF LookupName(nt_short, s_na_user, N, S) THEN
    Log := N;
  IF Log = 0 THEN
    LookupName(nt_short, s_na_pers, N ,S, FALSE, FALSE)
  ELSE
  BEGIN
    IF Possessor THEN
    BEGIN
      IF GetIndex(i_asleep, Indx) THEN
      BEGIN
        Switch := NOT Indx.Free[Log];
        IF Switch AND AllStats.Stats.Privd THEN
        BEGIN
	  LogEvent(0, 0, E_POSSESS, 0,Log, AllStats.Stats.Log,0,
                   AllStats.Stats.Name, R_ALLROOMS);
  	  Freeze(1, AllStats);
        END
        ELSE
        IF (Switch) THEN
        BEGIN
       	  Writeln('Sorry, that body is in use now.');
          OK := FALSE;
        END;
      END
      ELSE
        Ok := FALSE;
    END;
    IF OK THEN
    BEGIN
      LeaveUniverse(TRUE, AllStats);
      IF Switch THEN
        Freeze(5, AllStats);
      IF GetShortName(s_na_user, Nam) THEN;
      AllStats.Stats.Userid := Nam.Idents[Log];
      IF NOT EnterUniverse(TRUE, AllStats) THEN
      BEGIN
	AllStats.Stats.Userid := LowCase(Userid);
	EnterUniverse(TRUE, AllStats);
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoDebug(S : String);

  PROCEDURE PrintDebugMenu;
  BEGIN
    Writeln('Debugging options (toggle).');
    Writeln('F - files.');
    Writeln('T - timer.');
    Writeln('L - logged events.');
    Writeln('K - ticker events.');
    Writeln('H - handled events.');
  END;

BEGIN
  IF Length(S) = 0 THEN
    S := '1'
  ELSE
    S := Lowcase(Trim(S));
  Write('Debugging for ');
  CASE S[1] OF
    'f' : BEGIN
            Write('files is now ');
            Debug[Debug_Files] := NOT Debug[Debug_Files];
            CASE Debug[DEBUG_Files] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    't' : BEGIN
            Write('the timer is now ');
            Debug[Debug_Timer] := NOT Debug[Debug_Timer];
            CASE Debug[DEBUG_Timer] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    'l' : BEGIN
            Write('logged events is now ');
            Debug[Debug_LogEvent] := NOT Debug[Debug_LogEvent];
            CASE Debug[DEBUG_LogEvent] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    'h' : BEGIN
            Write('handling events is now ');
            Debug[Debug_HandleEvent] := NOT Debug[Debug_HandleEvent];
            CASE Debug[DEBUG_HandleEvent] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    'k' : BEGIN
            Write('the ticker is now ');
            Debug[Debug_Ticker] := NOT Debug[Debug_Ticker];
            CASE Debug[DEBUG_Ticker] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    'r' : BEGIN
            Write('the room is now');
            Debug[Debug_Room] := NOT Debug[Debug_Room];
            CASE Debug[DEBUG_Room] OF
               TRUE : Writeln('on.');
               OTHERWISE Writeln('off.');
            END;
          END;
    '?' : PrintDebugMenu;
    OTHERWISE BEGIN
                Writeln('everything is the same.');
                PrintDebugMenu;
              END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION PingPlayer(N : INTEGER; Silent : BYTE_BOOL := FALSE;
                    VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Retry : INTEGER;
  Idname : String;
  Log : INTEGER;
  TargLog : INTEGER;

BEGIN
  PingPlayer := FALSE;
  Log := Here.People[N].Kind;
  Idname := Here.People[N].Name;
  Retry := 0;
  AllStats.Op.PingAnswered := FALSE;
  REPEAT
    Retry := Retry + 1;
    IF NOT (Silent) THEN
      Writeln('Sending ping # ',retry:1,' to ',idname,'...');
    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_PING, N, Log,
             0,0, AllStats.Stats.Name, AllStats.Stats.Location);
    CheckEvents(FALSE, TRUE, FALSE, AllStats);
    IF NOT(AllStats.Op.PingAnswered) THEN
    BEGIN
      IF ParsePers(N, TargLog, IdName) THEN
      BEGIN
        IF AllStats.Stats.Privd THEN
          Wait(0.1)
        ELSE
          Wait(2.0); (* MWG, change 1 to 2 for non player, c code is fast? *)
        CheckEvents(FALSE, TRUE, FALSE, AllStats);
      END
      ELSE
        AllStats.Op.PingAnswered := TRUE;
    END;
  UNTIL (Retry >= 3) OR AllStats.Op.PingAnswered;
  PingPlayer := NOT AllStats.Op.PingAnswered;
  IF NOT(AllStats.Op.PingAnswered) THEN 
  BEGIN 
    IF NOT(Silent) THEN
      Writeln('That person is not responding to your pings...');
    IF NukePerson(AllStats.Stats.Location, N, Log) THEN 
    BEGIN
      PingPlayer := TRUE;
      IF NOT(Silent) THEN
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_PINGONE, N, 0,
                 0,0, IdName, AllStats.Stats.Location);
    END
  END
  ELSE
  IF NOT(Silent) THEN
    Writeln('That person is alive and well.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoPing(S : String; VAR AllStats : AllMyStats);

VAR
  N, P : INTEGER;
  Dummy : BYTE_BOOL;
  TargLog : INTEGER;

BEGIN
  IF GetRoom(AllStats.Stats.Location, Here) THEN
    IF S <> '' THEN 
    BEGIN
      IF ParsePers(N, TargLog, S, TRUE) THEN
      BEGIN
        IF (TargLog < 0) THEN
        BEGIN
          IF AllStats.Stats.Privd THEN
          BEGIN
            IF NukePerson(AllStats.Stats.Location, N, TargLog) THEN 
              Writeln('The random looks at you with sad eyes and dissappears.')
          END ELSE
            Writeln('Don''t do that!');
        END
	ELSE IF (N = AllStats.Stats.Slot) THEN
	  Writeln('Don''t ping yourself.')
	ELSE
          Dummy := PingPlayer(N, FALSE, AllStats);
      END;
    END
    ELSE
      Writeln('To see if someone is really alive, type PING <personalname>.');
END;

(* ------------------------------------------------------------------------- *)

PROCEDURE DoQuit(VAR AllStats : AllMyStats);
VAR
  Itmp : INTEGER;
BEGIN
  Itmp := GetTicks - AllStats.Stats.LastHitTime;
  IF( Itmp > QuitWait )THEN
    AllStats.Stats.Done := TRUE
  ELSE
  BEGIN
    StartHighLight;
    Writeln('You are being attacked!! You *must* fight or run!!!');
    StopHighLight;
    AllStats.Stats.Done := FALSE;
  END;
END;

(* ------------------------------------------------------------------------- *)

[EXTERNAL] PROCEDURE PutRandom(S : String; VAR AllStats : AllMyStats); extern;

(* ------------------------------------------------------------------------- *)
[external] function findshortestpath(start, finish:integer;
                    var next:integer) : integer; extern;

PROCEDURE DoGoto(S : String; VAR AllStats : AllMyStats);
VAR
  done : BYTE_BOOL := FALSE;
  Cmd : String;
  Finish, Status, Next : INTEGER;
BEGIN
  Cmd := Lowcase(S);
  done := NOT LookupRoomName(Cmd, Finish, FALSE, FALSE);
  while ((not done) and (finish <> allstats.stats.location)) do
  begin
    status := findshortestpath(allstats.stats.location, finish, next);
    if (status <= 0) then
    begin
     done := TRUE;
     writeln('I don''t think I can make it there sir!');
    end
    else
    begin
      writeln('Trying to go ', Direct[next]);
      done := not exitcase(next, allstats);
      if (done) then writeln('Failed to go ', Direct[next], '(', next:0, ').');
    end;
  end;
END;

[global]
PROCEDURE Parser(S : String := ''; VAR AllStats : AllMyStats);

VAR
  prompt, cmd : string;
  n,i,cmdnum,atmosnum : INTEGER;
  DummyBool : BYTE_BOOL;
  Privd : BYTE_BOOL;
  OldCmd : [STATIC] String := '';
  Stat : StatType;
  SpecialAction : BYTE_BOOL := FALSE;

BEGIN
  Stat := AllStats.Stats;
  Privd := Stat.Privd;
  IF (s.length = 0) THEN
  BEGIN
    REPEAT 
      Writev(Prompt,'> ');
      GrabLine(Prompt, S, AllStats, TRUE, size(s.body));
    UNTIL (Length(S) > 0) AND (AllStats.Stats.Privd OR AllStats.Stats.SysMaint
           OR (NOT AllStats.Op.Frozen));
  END;

  Lookup_Alias(S);

  IF Debug[DEBUG_Timer] THEN
    Lib$INIT_TIMER;

  IF S = '.' THEN
    S := OldCmd
  ELSE
    OldCmd := S;

  IF AllStats.Op.OpCheckComm <> 0 THEN
    LogEvent(0, 0, E_ANNOUNCE, 0, AllStats.Op.OpCheckComm, 0,0,
             Stat.Name+'>' + S, R_ALLROOMS);

  IF (S[1]='''') AND (Length(s) > 1) THEN
    S := 'say ' + SubStr(S, 2, Length(S)-1);

  Cmd := Bite(S);
  Cmd := Lowcase(Cmd);

  AtmosNum := LookupAtmosphere(Cmd);
  CmdNum := lookup_command(Cmd);

  IF ((CmdNum = HereDesc.Special_Act) OR (AtmosNum = -HereDesc.Special_Act))
     AND (HereDesc.Special_Act <> 0) THEN
    SpecialAction := TRUE;
  IF SpecialAction THEN
    DoSpecialEffect(S, AllStats)
  ELSE
  CASE CmdNum OF
    -1, c_error :
    begin
      IF LookupAlias(N, Cmd) OR LookupDir(N, Cmd) THEN
        DoGo(Cmd, FALSE, AllStats)
      ELSE
        IF (AtmosNum <> 0) THEN
        BEGIN
          DoAtmosphere(S,Atmosnum, AllStats.Stats.Slot,
          AllStats.Stats.Log, AllStats.Stats.Location)
        END
        ELSE
          Inform_badcmd;
    END;
    c_alias	: user_alias(S);
    c_update	: doupdate;
    c_putmon       : IF CheckPrivs(Privd, AllStats.Stats.Name) THEN
                       PutRandom(s, AllStats);
    c_debug        : DoDebug(S);
    c_setnam	   : IF CheckPrivs(Privd, AllStats.Stats.Name) THEN
			DoSetName(S, AllStats);
    c_help,c_quest : ShowHelp(AllStats);
    c_help2	   : DoHelp(S, AllStats);
    c_quit	   : DoQuit(AllStats);
    c_l,c_look	   :
    BEGIN
      IF Length(S) = 0 THEN
       LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log,
                E_MSG, 0,0, 0,0, AllStats.Stats.Name +
                ' is looking around the room.', AllStats.Stats.Location);
      if getroom(allstats.stats.location, here) then
        DoLook(S, AllStats);
    END;
    c_invisible    : IF AllStats.Stats.Privd THEN
                     BEGIN
                       AllStats.Tick.Invisible := TRUE;
                       AllStats.Tick.TkInvisible := -1;
                       IF GetRoom(AllStats.Stats.Location, Here) THEN;
                       Here.People[AllStats.Stats.Slot].Hiding := -1; 
                       IF SaveRoom(AllStats.Stats.Location, Here) THEN;
                     END;
    c_link         : DoLink(S, FALSE, AllStats);
    c_unlink       : DoUnlink(S, AllStats);
    c_poof         : IF CheckPrivs(Privd, AllStats.Stats.Name) THEN
                       DoPoof(S, AllStats);
    c_remotepoof   : IF CheckPrivs(Privd, AllStats.Stats.Name) THEN
                       DoRemotePoof(S, Stat.name, AllStats);
    c_desc         : DoDescribe(S, AllStats);
    c_say          : DoSay(S, AllStats);
    c_edit         : DoEdit(S, AllStats);
    c_class        : IF CheckPrivs(Privd, AllStats.Stats.Name) THEN
			DoClasses(AllStats);
    c_lob          : DoLob(S, AllStats);
    c_throw        : DoThrow(S, 0, AllStats);
    c_cast         : DoCast(AllStats.Stats.Slot, AllStats.Stats.Experience DIV
                            1000, S, ,AllStats);
    c_block	   : DoBlock(S, AllStats);
    c_unblock	   : DoUnBlock(S, AllStats);
    c_learn        : DoLearn(S, AllStats);
    c_change       : IF CheckPrivs(Privd, Stat.Name) THEN
		       DoChange(S, AllStats);
    c_rooms        : DoRooms(S, AllStats);
    c_claim        : DoClaim(S, AllStats);
    c_disown       : DoDisown(S, AllStats);
    c_public       : DoPublic(S, AllStats);
    c_accept       : DoAccept(S, AllStats);
    c_refuse       : DoRefuse(S, AllStats);
    c_ping         : DoPing(S, AllStats);
    c_north, c_n,
    c_south, c_s,
    c_east, c_e,
    c_west, c_w,
    c_up, c_u,
    c_down,c_d     : DoGo(Cmd, FALSE, AllStats);
    c_who          : DoWho(, AllStats);
    c_custom       : DoCustom(S, AllStats);
    c_search       : DoSearch(S, AllStats);
    c_system       : IF AllStats.Stats.Sysmaint THEN
                       DoSystem(AllStats)
		     ELSE
                     IF CheckPrivs(Privd, Stat.Name) THEN
                       SystemView
		     ELSE
                       Writeln('You do not have the capability to enter SYSTEM.');
    c_hide         : DoHide(S, AllStats);
    c_unhide       : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       DoUnhide(AllStats.Stats.Slot, AllStats.Stats.Location);
    c_punch        : DoPunch(S, AllStats);
    c_create       : DoCreate(S, AllStats);
    c_get          : DoGet(S, AllStats);
    c_goto         : DoGoto(S, AllStats);
    c_sell         : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       DoSell(S, AllStats);
    c_drop         : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       DoDrop(S, AllStats);
    c_i,c_inv      : DoInv(S, AllStats);
    c_whois        : if CheckPrivs(Privd, stat.name) then
		       DoWhois(S);
    c_players      : if CheckPrivs(Privd, stat.name) then
                       DoPlayers(AllStats.Stats.Location, AllStats.Stats.Slot);
    c_attack       : DoAttack(S, AllStats);
    c_duplicate    : DoDuplicate(S, AllStats);
    c_make         : DoMake(S, AllStats);
    c_version      : DoVersion;
    c_objects      : DoObjects(S, AllStats.Stats.Privd, AllStats.Stats.Userid);
    c_self         : DoSelf(S, AllStats);
    c_use          : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       DoUse(S, AllStats);
    c_whisper      : DoWhisper(S, AllStats);
    c_wield        : DoEquip(S, AllStats);
    c_brief        : DoToggle(AllStats.Stats.Brief,
                              'Descriptions will #be in brief format.');
    c_wear         : DoEquip(S, ALlStats);
    c_destroy      : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       DoDestroy(S, AllStats);
    c_alink        : Dolink(S, TRUE, AllStats);
    c_zap          : IF CheckPrivs(Privd, Stat.Name) THEN DoZap(S, AllStats);
    c_show         : DoShow(S, AllStats);
    c_priv         : DoTogglePrivs(AllStats.Stats.Privd);
    c_sheet        : IF AllStats.Stats.Privd AND
                         LookupName(nt_short, s_na_pers,n,s) THEN
                       DoSheet(N, AllStats)
		     ELSE
                       DoSheet(, AllStats);
    c_announce     : DoAnnounce(SubsParm(S, AllStats.Stats.Name),
                                0, FALSE, Privd);
    c_find         : IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
                       DoFind(S);
    c_unwho        : IF CheckPrivs(AllStats.Stats.Privd, AllStats.Stats.Name) THEN
                       DoUnwho(S);
    c_steal        : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       Dosteal(S, AllStats, 1);
    c_operators    : Dooperators;
    c_cia          : IF CheckPrivs(Privd, Stat.Name) THEN DoCia(AllStats);
    c_pickpocket   : IF GetRoom(AllStats.Stats.Location, Here) THEN
                       Dosteal(S, AllStats, 2);
    c_nuke         : IF CheckPrivs(Privd, Stat.Name) THEN DoNukeObj(S);
    c_zero         : IF CheckPrivs(Privd, Stat.Name) THEN DoZero(S, AllStats);
    c_togop        : IF CheckPrivs(Privd, Stat.Name) THEN 
			DoTogOp(S, AllStats);
    c_extend       : IF AllStats.Stats.Sysmaint THEN 
			DoExtend(S, AllStats)
		     ELSE
			Inform_BadCmd;
    c_rest         : DoRest(AllStats);
    c_universe     : IF AllStats.Stats.Sysmaint THEN
                     BEGIN
                       IF Edit_Universe THEN;
                     END
                     ELSE
                       Inform_BadCmd;
    c_grab         : IF CheckPrivs(Privd, Stat.Name) THEN
                       DoGrab(S, AllStats);
    c_equip        : Doequip(S, AllStats);
    c_possess      : IF CheckPrivs(Privd, Stat.Name) THEN
                       DoPossess(S, TRUE, AllStats);
    c_highlight    : DoToggle(AllStats.Stats.HighLight,
                              'When you get hit, text will #be highlighted.');
    c_express      : BEGIN
                       Cmd := 'You see that ' + AllStats.Stats.Name + ' ';
                       IF (Length(Cmd) + Length(S)) > NormLen THEN
                         S.Length := NormLen - Length(Cmd);
                       LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG,
                                0,0, 0,0, Cmd + S, AllStats.Stats.Location);
                     END;
    c_dcl          : IF AllStats.Stats.Sysmaint AND AllStats.Stats.Privd THEN
                       Spawn(S)
                     ELSE
                       Inform_Badcmd;
    c_check        : IF CheckPrivs(Privd, Stat.Name) THEN DoCheck(S, AllStats);
    c_copy        : IF CheckPrivs(Privd, Stat.Name) THEN DoCopy(S, AllStats);

    (* the following are debugging commands to force a re-read of *)
    (* the room records						  *)

    c_readroom          : IF CheckPrivs(Privd, Stat.Name) THEN
			    GetRoom(AllStats.Stats.Location, Here);
    c_readroomdesc      : IF CheckPrivs(Privd, Stat.Name) THEN
			    GetRoomDesc(AllStats.Stats.Location, HereDesc);
    OTHERWISE      Writeln('%Parser error, bad return from lookup');
  END;  (* Case *)
  IF Debug[DEBUG_Timer] THEN
    LIB$Show_Timer;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE Init(VAR AllStats : AllMyStats; Real : BYTE_BOOL := TRUE);

(* real - Is this a real character coming in, or a random. *)

VAR
  I : INTEGER;

BEGIN
  AllStats.Tick.TkEvent := GetTicks;
  AllStats.Tick.TkAllEvent := GetTicks;
  AllStats.Tick.TkRandMove := GetTicks;
  AllStats.Tick.TkRandAct := GetTicks;
  AllStats.Tick.TkRandomEvent := GetTicks;
  AllStats.Tick.TkHealth := GetTicks + 600;
  AllStats.Tick.TkMana := GetTicks + 600;
  AllStats.Tick.TkSpeed := 0;
  AllStats.Tick.TkStrength := 0;
  AllStats.Exit.ExitHandled := TRUE;
  AllStats.Stats.Location := R_GREATHALL;
  AllStats.Stats.Userid := LowCase(Userid);
  AllStats.Stats.Realid := AllStats.Stats.Userid;
  AllStats.Stats.InGame := TRUE;
  WITH AllStats.Stats DO
  BEGIN
    SysMaint := SysUserid(Userid);
    Privd := SysMaint;
  END;
  IF NOT(Real) THEN AllStats.Stats.SysMaint := FALSE;

  IF OpenAllFiles(AllStats.Stats.SysMaint) THEN
  BEGIN
    AllStats.Stats.Privd := AllStats.Stats.SysMaint OR IsUnivSpecificOp(Userid);
    FOR I := 1 TO MaxTimedEvents DO
      AllStats.TimedEvents[I].Action := 0;
    AllStats.Op.OpCheckComm := 0;
    AllStats.Op.NoText := FALSE;
    AllStats.Op.Frozen := FALSE;
    AllStats.Stats.Done := FALSE;
    AllStats.Stats.Done := FALSE;
  END
  ELSE
    AllStats.Stats.Done := TRUE;
  IF NOT(Real) THEN AllStats.Stats.Privd := FALSE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE PreStart(VAR AllStats : AllMyStats);

VAR
  S : String;
  Dummy : String;
  Name : String;

BEGIN
  IF AllStats.Stats.Privd THEN
  BEGIN
    Write('Type Help now for startup commands: ');
    REPEAT
      S.Length := 0;
      Readln(S, ERROR := CONTINUE);
      Reset(INPUT);
      Writeln;
      IF (Length(S) > 0) THEN
      BEGIN
        Special(LowCase(S), AllStats);
        Write('Type Help now for startup commands: ');
      END;
    UNTIL (Length(S)=0) OR (AllStats.Stats.Done);
  END;
  IF Not AllStats.Stats.Done THEN
    ReadAtmosphere;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE WelcomeBack(VAR Stat : StatType; Silent : BYTE_BOOL; Tick : TkTimeType);

VAR
  Tmp : String;
  SDate, STime : ShortString;
  Date : ShortNameRec;

BEGIN
  IF GetShortName(s_na_date, Date) THEN
  BEGIN
    Writeln;
    Write('Welcome back, ',Stat.Name,'.');
    IF Length(Stat.Name) > 18 THEN
      Writeln;
    Write('  Your last play was on');
    IF Length(Date.Idents[Stat.Log]) < 11 THEN
      Writeln('???')
    ELSE
    BEGIN
      SDate := SubStr(Date.Idents[Stat.Log],1,11);
      IF Length(Date.Idents[Stat.Log]) = 19 THEN
        STime := SubStr(Date.Idents[Stat.Log],13,7)
      ELSE
        STime := '???';
      IF SDate[1] = ' ' THEN
        Tmp := SDate
      ELSE
         Tmp := ' ' + SDate;
      IF STime[1] = ' ' THEN
        Tmp := Tmp + ' at' + Stime
      ELSE
        Tmp := Tmp + ' at ' + STime;
      Writeln(Tmp,'.');
    END;
    Writeln;
  END; (* GetShortName *)
END;

(* -------------------------------------------------------------------------- *)
[EXTERNAL] PROCEDURE ReadInAllRandoms; EXTERN;
(* -------------------------------------------------------------------------- *)

FUNCTION NewPlayer(VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  S : String;
  Len : INTEGER;
  User : ShortNameRec;
  Ok : BYTE_BOOL := FALSE;
  I : INTEGER;
  Charac : CharRec;
  AnInt : IntArray;
  Pers : ShortNameRec;
  AClass : ClassRec;

BEGIN
  ReadInAllSpells;
  ReadInAllClasses;
  ReadInAllObjects;
  ReadInAllRandoms;
  ReadGlobalNames;
  Writeln;
(*
  mail_user(allstats.stats.userid, 
            'disk$userdisk1:[mas0.masmonst.datafiles.current]new.user');
*)
  IF GetShortName(s_na_user, User) THEN
  BEGIN
     User.Idents[AllStats.Stats.Log] := LowCase(AllStats.Stats.Userid);
     IF SaveShortName(s_na_user,User) THEN
       LogEvent(-1, -1, E_SETNAME, 0, 0, nt_short, s_na_user, '',
                R_ALLROOMS, lowcase(allstats.stats.userid), Allstats.stats.log);
  END;
  SetPersName(Allstats.Stats.Log, Lowcase(AllStats.Stats.Userid));
  IF GetInt(N_LOCATION, AnInt) THEN
  BEGIN
    Anint[AllStats.Stats.Log] := R_GREATHALL;
    IF SaveInt(N_LOCATION, AnInt) THEN;
  END;
  IF GetInt(N_Class, AnInt) THEN
  BEGIN
    Anint[AllStats.Stats.Log] := 1;
    IF SaveInt(N_Class, AnInt) THEN;
  END;
  WITH AllStats.Stats Do
  BEGIN
    Name := AllStats.Stats.Userid;
    Location := R_GREATHALL;
    Class := 1;
    Experience := 0;
    Mana := 0;
    Health := 1;
    Poisoned := FALSE;
    Wealth := 5;
    Bank := 0;
    Kills := 0;
    Deaths := 0;
    Maxrooms := MAX_ROOM;
    Maxobj := MAX_ROOM;
    IF GetClass(AllStats.Stats.Class, AClass) THEN
    BEGIN
      Alignment := AClass.Alignment;
      IF GetInt(n_alignment, AnInt) THEN
      BEGIN
         AnInt[Log] := Alignment;
         IF NOT SaveInt(n_alignment, AnInt) THEN;
      END
      ELSE
            Writeln('Error reading in data.');
    END;
  END;
  WITH AllStats.MyHold DO
  BEGIN
    FOR Loop := 1 TO MaxHold DO
    BEGIN
      Holding[Loop] := 0;
      Slot[Loop] := 0;
      Charges[Loop] := 0;
      Condition[Loop] := 0;
    END;
  END;
  Charac.MaxRooms := MAX_ROOM;
  Charac.MaxObjs := MAX_ROOM;
  Charac.Self := 0;
  Charac.Alignment := AClass.Alignment;
  FOR I := 1 TO MaxSpells DO
    Charac.Spell[I] := 0;
  IF SaveChar(AllStats.Stats.Log, Charac) THEN
    Ok := TRUE
  ELSE
    Ok := FALSE;
  SaveStats(AllStats.Stats.Log, AllStats);
  Equipmentstats(AllStats);
  NewPlayer := Ok;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION RevivePlayer(Silent : BYTE_BOOL; VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Ok : BYTE_BOOL;
  I, N : INTEGER;
  Indx : IndexRec;
  AnInt : IntArray;
  Charac : CharRec;
  User,
  Pers,
  ADate : ShortNameRec;
  Loop : INTEGER;
  S : String;
  Len : INTEGER;

BEGIN
  IF LookUpName(nt_short, s_na_user, AllStats.Stats.Log,
                AllStats.Stats.Userid, TRUE) THEN
  BEGIN	{ player has played before }
    ReadInAllSpells;
    ReadInAllObjects;
    ReadInAllRandoms;
    ReadGlobalNames;
    LoadStats(AllStats.Stats.Log, AllStats);
    IF GetInt(N_LOCATION, AnInt) THEN
      AllStats.Stats.Location := AnInt[AllStats.Stats.Log]
    ELSE
      AllStats.Stats.Location := 1;
    IF GetIndex(I_ASLEEP, Indx) THEN
      Ok := TRUE
    ELSE
      Ok := FALSE;
    IF Ok THEN
      WelcomeBack(AllStats.Stats, Silent, AllStats.Tick);
  END
  ELSE
  BEGIN	{ must allocate a log block for the player }
    IF Allocate(i_player, AllStats.Stats.Log) THEN
    BEGIN
      IF NewPlayer(AllStats) THEN
        Ok := TRUE;
    END
    ELSE
      Ok := FALSE;
  END; (* If the else lookupname *)
  RevivePlayer := Ok;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE LogEntryInGame(VAR AllStats : AllMyStats; Silent : BYTE_BOOL);

VAR
  Indx : IndexRec;
  Adate : ShortNameRec;

BEGIN
  IF (NOT AllStats.Tick.Invisible) AND (NOT Silent) THEN
  BEGIN
    DoAnnounce('('+ AllStats.Stats.Name + ' once again roams the land.)',
               AllStats.Stats.Log, TRUE);
    IF GetIndex(I_ASLEEP, Indx) THEN
    BEGIN
      Indx.Free[AllStats.Stats.Log] := FALSE;
      IF SaveIndex(I_ASLEEP, Indx) THEN;
    END;
  END;
  IF GetShortName(s_na_date, adate) THEN
  BEGIN
    Adate.Idents[AllStats.Stats.Log] := SysDate + ' ' + SysTime;
    IF SaveShortName(s_na_date, adate) THEN;
  END;
END;

(* -------------------------------------------------------------------------- *)

[global]
FUNCTION EnterUniverse(Silent : BYTE_BOOL := FALSE;
                       VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  OrigNam : String;
  Dummy, I : INTEGER;
  OkV, Ok,OldPriv : BYTE_BOOL;
  Indx : IndexRec;
  Pers : ShortNameRec;
  Hide : INTEGER := 0;
  NewName : String;
     
BEGIN
  EnterUniverse := FALSE;
  OrigNam := AllStats.Stats.Name;
  I := 0;
  REPEAT
    Ok := TRUE;
    IF LookupName(nt_short, s_na_pers, Dummy, AllStats.Stats.Name) THEN
      IF GetShortName(s_na_Pers, Pers) THEN
        IF (Lowcase(Pers.Idents[Dummy]) = LowCase(AllStats.Stats.Name)) THEN
        BEGIN
          Ok := FALSE;
          I := I + 1;
          Writev(AllStats.Stats.Name, OrigNam,'_',I:1);
        END;
  UNTIL Ok;
  IF RevivePlayer(Silent, AllStats) THEN
  BEGIN
    IF PutToken(AllStats.Stats.Location, Hide, AllStats) AND
       GetRoomDesc(AllStats.Stats.Location, HereDesc) THEN
    BEGIN
      SetPersName(Allstats.stats.log, AllStats.Stats.Name);
      IF AllStats.Tick.Invisible THEN
      BEGIN
     	AllStats.Tick.TkInvisible := -1;
    	IF GetRoom(AllStats.Stats.Location, Here) THEN
        BEGIN
          Here.People[AllStats.Stats.Slot].Hiding := -1;
          IF SaveRoom(AllStats.Stats.Location, Here) THEN;
        END;
        Writeln('-=> Successful invisible entrance into Monster <=-');
        Writeln;
      END;
      EnterUniverse := TRUE;
      setevent(allstats);
      setallevent(allstats);

      Ok := FALSE;

      REPEAT
         OkV := FALSE;
	 WHILE NOT OkV DO
         BEGIN
            Write('By what name do you wish to be known? ');
            Readln(NewName);
            Writeln;
	    OkV := IsValid(NewName, vt_alpha);
	    IF NOT OkV THEN
		Writeln('Only alphabetical letters are permitted!');
         END;
	 NewName := TRIM(NewName);
         Ok := DoSetName(NewName,AllStats);
      UNTIL Ok;

      Writeln;
      LogEntryInGame(AllStats, Silent);
      DoLook(,AllStats);
      IF NOT (AllStats.Tick.Invisible OR Silent) THEN
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_BEGIN, 0, 0,
                 AllStats.Stats.Health, 0,
                 AllStats.Stats.Name, AllStats.Stats.Location, ,
                 Here.People[AllStats.Stats.Slot].Hiding);
    END
    ELSE
      EnterUniverse := FALSE;
  END
  ELSE
    EnterUniverse := FALSE;
END;

[global]
PROCEDURE LeaveUniverse(Silent : BYTE_BOOL := FALSE; VAR AllStats : AllMyStats);

VAR
  I : INTEGER;
  Stat : StatType;
  Nam : ShortNameRec;

BEGIN
    SaveStats(AllStats.Stats.Log, AllStats);
    Stat := AllStats.Stats;
    IF NOT (AllStats.Tick.Invisible OR Silent) THEN
      LogEvent(Stat.Slot, Stat.Log, E_MSG, 0,0, 0,0,
             Stat.Name + ' is about to quit.', Stat.Location);
    Writeln('Quitting...');

    IF NOT (AllStats.Tick.Invisible OR Silent) THEN
      LogEvent(Stat.Slot, Stat.Log, E_QUIT, 0,0, 0,0, Stat.Name, 
			Stat.Location);
    TakeToken(Stat.Location, Stat.Log);
    DoEndPlay(Stat.Log, FALSE);
    Writeln('You vanish in a brilliant burst of multicolored light.');
    IF NOT (AllStats.Tick.Invisible OR Silent) THEN
      DoAnnounce('(' + Stat.Name + ' has returned to sleep.)',
               AllStats.Stats.Log, TRUE);
END; (* endnendnend *)

(*-----------------------------------------------------------------------*)

END.
