[INHERIT ('MONCONST','MONGLOBL','MONTYPE')]

MODULE MonLookup(OUTPUT);

%include 'headers.txt'

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupDetail(VAR N : INTEGER; S : String) : BYTE_BOOL;

VAR
  I, Poss, Maybe, Num : INTEGER;
  P : String;

BEGIN
  N := 0;
  S := Lowcase(Trim(S));
  I := 1;
  Maybe := 0;
  Num := 0;
  FOR I := 1 TO MaxDetail DO
  BEGIN
    P := Lowcase(Trim(HereDesc.Detail[I]));
    IF S = P THEN
      Num := I
    ELSE
    IF Index(P, S) = 1 THEN
    BEGIN
      Maybe := Maybe + 1;
      Poss := I;
    END;
  END;
  IF Num <> 0 THEN
  BEGIN
    N := Num;
    LookupDetail := TRUE;
  END
  ELSE
  IF Maybe = 1 THEN
  BEGIN
    N := Poss;
    LookupDetail := TRUE;
  END
  ELSE
  IF Maybe > 1 THEN
    LookupDetail := FALSE
  ELSE
    LookupDetail := FALSE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupAlias(VAR N : INTEGER; S : String) : BYTE_BOOL;

VAR
  I : INTEGER;

BEGIN
  N := 0;
  FOR I := 1 TO MaxExit DO
    IF HereDesc.Exits[I].Kind <> EK_PASSWORD THEN
      IF Lowcase(Trim(S)) = Lowcase(Trim(HereDesc.Exits[I].Alias)) THEN
        N := I;
  IF N = 0 THEN
    LookupAlias := FALSE
  ELSE
    LookupAlias := TRUE;
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupDir(VAR Dir : INTEGER; S : String) : BYTE_BOOL;

VAR
  I, Poss, Maybe, Num : INTEGER;

BEGIN
  S := LowCase(S);
  I := 1;
  Maybe := 0;
  Num := 0;
  FOR I := 1 TO MaxExit DO
  BEGIN
    IF S = Direct[I] THEN Num := i
    ELSE
    IF Index(Direct[I], S) = 1 THEN
    BEGIN
      Maybe := Maybe + 1;
      poss := i;
    END;
  END;
  IF Num <> 0 THEN
  BEGIN
    Dir := Num;
    LookupDir := TRUE;
  END
  ELSE
  IF Maybe = 1 THEN
  BEGIN
    Dir := Poss;
    LookupDir := TRUE;
  END
  ELSE
  IF Maybe > 1 THEN
    LookupDir := FALSE
  ELSE
    LookupDir := FALSE;
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupCmd(S : String; Cmds : ARRAY[$l1..$l2:integer] of shortstring;
                   maxcmds : INTEGER) : INTEGER;

VAR
  Loop, Poss, Maybe, Num : INTEGER;

BEGIN
  S := LowCase(S);
  Loop := 1;
  Maybe := 0;
  Num := 0;
  FOR Loop := 1 TO MaxCmds DO
  BEGIN
    IF S = Cmds[Loop] THEN
       Num := Loop
    ELSE IF Index(Cmds[Loop],S) = 1 THEN
    BEGIN
      Maybe := Maybe + 1;
      Poss := Loop;
    END;
  END;
  IF Num <> 0 then LookupCmd := Num
  ELSE IF Maybe = 1 then LookupCmd := Poss
  ELSE IF Maybe > 1 then LookupCmd := C_Error
  ELSE LookupCmd := C_Error;
END;

(* ------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupAlign(S : String) : INTEGER;

VAR
  Loop, Poss, Maybe, Num : INTEGER;

BEGIN
  S := LowCase(S);
  
  Loop := 1;
  Maybe := 0;
  Num := 0;
  FOR Loop := 1 TO MaxAlign DO
  BEGIN
    IF S = Alignments[Loop] THEN
       Num := Loop
    ELSE IF Index(Alignments[Loop],S) = 1 THEN
    BEGIN
      Maybe := Maybe + 1;
      Poss := Loop;
    END;
  END;
  IF Num <> 0 then LookupAlign := Num
  ELSE IF Maybe = 1 then LookupAlign := Poss
  ELSE IF Maybe > 1 then LookupAlign := C_Error
  ELSE LookupAlign := C_Error;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupAtmosphere(S : String) : INTEGER;

VAR
  Loop, Poss, Maybe, Num : INTEGER;

BEGIN
  S := LowCase(S);
  Maybe := 0;
  Num := 0;
  FOR Loop := 1 TO MaxAtmospheres DO
  BEGIN
    IF S = Atmosphere[Loop].Trigger THEN 
       Num := Loop
    ELSE IF Index(Atmosphere[Loop].Trigger, S) = 1 THEN
    BEGIN
      Maybe := Maybe + 1;
      Poss := Loop;
    END;
  END;
  IF Num <> 0 THEN LookupAtmosphere := Num
  ELSE IF Maybe = 1 THEN LookupAtmosphere := Poss
  ELSE IF Maybe > 1 THEN LookupAtmosphere := C_Error
  ELSE LookupAtmosphere := C_Error;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupNameRaw(List : ARRAY [$l0..$l1:integer] of ShortString;
	Ind : IndexRec; VAR Pnum : INTEGER; S : String;
        Exact : byte_bool) : BYTE_BOOL;
VAR
  Off, Top, Poss, Maybe, Loop : INTEGER;
  Found : BYTE_BOOL;
  Name : ShortString;

BEGIN
  S := lowcase(S);
  Maybe := 0;
  Loop := $l0;
  Off := 1 - loop;
  Top := Loop - 1 + Ind.Top;
  Found := FALSE;
  While (Loop <= Top) AND Not(Found) DO
  BEGIN
    IF (NOT Ind.Free[Off+Loop]) THEN
    BEGIN
      Name := LowCase(list[loop]);
      IF S = Name THEN 
        Found := TRUE
      ELSE
      IF Index(Trim(Name),S) = 1 THEN
      BEGIN
        Maybe := Maybe + 1;
        Poss := Loop;
      END;
    END;
    IF not(found) THEN Loop := Loop + 1;
  END;
  IF Found THEN
  BEGIN
    Pnum := Loop;
  END ELSE IF (Maybe = 1) AND NOT Exact THEN
  BEGIN
    Pnum := Poss;
    Found := TRUE;
  END;
  LookupNameRaw := found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION LookupName(NameType : INTEGER; NameNum : INTEGER; VAR Pnum : INTEGER;
                    S : String; Exact : BYTE_BOOL := FALSE;
                    Silent : BYTE_BOOL := TRUE) : BYTE_BOOL;

VAR
  IndexNum : INTEGER;
  Found : BYTE_BOOL := FALSE;
  Status : BYTE_BOOL;
  RealShortName : RealShortNameRec;
  Shortname : ShortNameRec;
  SomeIndex : IndexRec;
  Name : String;

BEGIN
  CASE NameType OF
	nt_RealShort : BEGIN
       		Case NameNum OF
       			RSNR_GroupName : IndexNum := I_GroupName;
       			RSNR_Class : IndexNum := I_Class;
       		END;
       		Status := GetRealShortName(NameNum, RealShortName);
       		IF Status THEN Status := GetIndex(IndexNum, SomeIndex);
       		Found := LookupNameRaw(RealShortName.idents, SomeIndex, Pnum,
                                       S, exact);
	 END;
	 nt_Short : BEGIN
		CASE NameNum OF
			s_na_pers : IndexNum := I_Player;
			s_na_user : IndexNum := I_Player;
       			s_na_objnam : IndexNum := I_Object;
       			s_na_rannam : IndexNum := I_Rand;
       			s_na_spell : IndexNum := I_Spell;
		END;
       		Status := GetShortName(NameNum, ShortName);
       		IF Status THEN Status := GetIndex(IndexNum, SomeIndex);
      		Found := LookupNameRaw(ShortName.Idents, SomeIndex, Pnum, S,
					exact);
 	END;
	nt_long: halt;
  END;
  LookupName := Found;
  IF (NOT Found) AND (NOT Silent) THEN
  BEGIN
    Write('I could not find that ');
    CASE NameType OF
      nt_realshort : CASE NameNum OF
		       RSNR_GroupName : Write('group');
                       RSNR_Class : Write('class');
                     END;
      nt_short : CASE NameNum OF
    		   s_na_pers : write('person');
		   s_na_user : write('user');
		   s_na_objnam : write('object');
		   s_na_rannam : write('random');
		   s_na_spell : write('spell');
                 END;
    END;
    Writeln(' ',S,'.');
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ParseObjHere(VAR Objname : String) : INTEGER;
VAR
  ObjNam : ShortNameRec;
  Poss, ObjNum, Loop : INTEGER;
  Done : BYTE_BOOL;

BEGIN
  Poss := 0;
  ParseObjHere := 0;
  Loop := 1;
  Done := FALSE;
  While ((Loop<=MaxObjs) AND NOT(Done)) DO
  BEGIN
    ObjNum := Here.Objs[Loop] MOD 1000;
    IF (ObjNum <> 0) THEN
    BEGIN
      IF (GlobalObjects[ObjNum].ObjName = ObjName) THEN
      BEGIN
        Poss := Loop;
        Done := TRUE;
      END
      ELSE
      BEGIN
        IF (Index(GlobalObjects[ObjNum].ObjName, ObjName) = 1) THEN 
          IF Poss = 0 THEN Poss := Loop
          ELSE
          BEGIN
            Done := TRUE;
            Poss := -1;
          END;
        Loop := Loop + 1;
      END;
    END ELSE Loop := Loop + 1;
  END;
  IF Poss > 0 THEN
    ObjName := GlobalObjects[Here.Objs[Poss] MOD 1000].ObjName;
  ParseObjHere := Poss;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ObjHere(ObjNum : INTEGER) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Found : BYTE_BOOL;

BEGIN
  Loop := 1;
  Found := FALSE;
  WHILE (Loop <= MaxObjs) AND (NOT FOUND) DO
    IF Here.Objs[Loop] MOD 1000 = ObjNum THEN
      Found := TRUE
    ELSE 
      Loop := Loop + 1;
  ObjHere := Found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ObjHold(ObjNum : INTEGER; MyHold : HoldObj) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Found : BYTE_BOOL;

BEGIN
  IF ObjNum = 0 THEN
     Found := FALSE
  ELSE
  BEGIN
    Loop := 1;
    Found := FALSE;
    WHILE (Loop <= MaxHold) AND (NOT Found) DO
    BEGIN
      IF MyHold.Holding[Loop] = ObjNum THEN
        Found := TRUE
      ELSE
        Loop := Loop + 1;
    END;
  END;
  ObjHold := Found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION FindObj(ObjNum: INTEGER; RoomNum : INTEGER) : INTEGER;

VAR
  Loop : INTEGER;
  Status : BYTE_BOOL;

BEGIN
  Loop := 1;
  FindObj := 0;
  IF GetRoom(RoomNum, Here) THEN
    WHILE (Loop <= MaxObjs) DO
    BEGIN
      IF Here.objs[Loop] MOD 1000 = ObjNum THEN
        FindObj := Loop;
      Loop := Loop + 1;
    END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ParseObj(VAR ObjNum : INTEGER; S : String;
                 MyHold : HoldObj) : BYTE_BOOL;

VAR
  Slot: INTEGER;

BEGIN
  IF LookUpname(nt_short, s_na_objnam,ObjNum,S) THEN
    ParseObj := ObjHere(ObjNum) OR ObjHold(ObjNum, MyHold);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION ParsePers(VAR Pnum : INTEGER; VAR Log : INTEGER; S : String;
                   Echo : BYTE_BOOL := FALSE) : BYTE_BOOL;

VAR
  Persnum, Loop, Poss : INTEGER;
  Maybe : INTEGER := 0;
  Num : INTEGER := 0;
  Found : BYTE_BOOL := FALSE;
  Status : BYTE_BOOL;

BEGIN
  S := Lowcase(S);
  Pnum := 0;
  Log := 0;
  IF Length(S) = 0 THEN
    Loop := MaxPeople
  ELSE
    Loop := 0;

  WHILE (Loop < MaxPeople ) AND NOT Found DO
  BEGIN
    Loop := Loop + 1;
    IF ((Here.People[Loop].Hiding = 0) AND (Here.People[Loop].Kind <> 0)) THEN
    BEGIN
      IF S = LowCase(Here.People[Loop].Name) THEN
         Found := TRUE
      ELSE
      IF Index(Lowcase(Here.People[Loop].Name), S) = 1 THEN
      BEGIN
	Maybe := Maybe + 1;
	Poss := Loop;
      END;
    END;
  END;
  IF Found THEN
  BEGIN
    PNum := Loop;
    Log := Here.People[Loop].Kind;
  END
  ELSE
  IF Maybe = 1 THEN
  BEGIN
    PNum := Poss;
    Found := TRUE;
    Log := Here.People[PNum].Kind;
  END
  ELSE
  BEGIN
    Found := FALSE;
    Log := 0;
  END;

  IF Echo AND (NOT Found) THEN
     Writeln('That person cannot be seen in this room.');
  ParsePers := Found;
END;

(* -------------------------------------------------------------------------- *)

END.   (* Module monlookup *)
