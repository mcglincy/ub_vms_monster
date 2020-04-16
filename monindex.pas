[INHERIT ('monconst','montype')]
MODULE MonIndex(OUTPUT);

%include 'headers.txt'

[GLOBAL]
FUNCTION ChangeTopIndex(Number : INTEGER; FileSlot : INTEGER;
                        MaxValue :INTEGER) : BYTE_BOOL;

(* Number is the number of allocated slots taht should be put it *)
(* FileSlot should have the form I_xxxxx; where I_xxxxx is one of the defined
   constants in monconst.pas *)
(* MaxValue, should be a constant, such as MaxRoom or MaxIndex or MaxSpell.. *)

VAR
  Index : IndexRec;

BEGIN
  IF GetIndex(FileSlot, Index) THEN
  BEGIN
    IF Index.Top + Number <= MaxValue THEN
       Index.Top := Index.Top + Number
    ELSE
    BEGIN
      Writeln('Insufficient space.  Adding ',MaxValue-Index.Top:3,' slots.');
      Index.Top := MaxValue;
    END;
    ChangeTopIndex := SaveIndex(FileSlot, Index);
  END
  ELSE
    ChangeTopIndex := FALSE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION FindFreeIndexSlot(IndexNum : INTEGER; VAR Slot : INTEGER) : BYTE_BOOL;

VAR
  Indx : IndexRec;
  Found : BYTE_BOOL;

BEGIN
  Found := FALSE;
  Slot := 0;
  IF GetIndex(IndexNum, Indx) THEN
    WHILE Not(Found) AND (Slot < Indx.Top) DO
    BEGIN
      Slot := Slot + 1;
      Found := Indx.Free[Slot];
    END;
  FindFreeIndexSlot := Found;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ResetIndex(IndexNum : INTEGER; MaxValue : INTEGER);

VAR
  Indx : IndexRec;
  Loop : INTEGER;

BEGIN
  Indx := ZERO;
  FOR Loop := 1 TO MaxValue DO
    Indx.Free[Loop] := TRUE;
  Indx.InUse := 0;
  Indx.Top := MaxValue;
  IF SaveIndex(IndexNum, Indx) THEN
END;

[GLOBAL]
PROCEDURE FixIndex;
VAR
  Loop2, Loop : INTEGER;
  Ind : IndexRec;
  lnam1, lnam2 : longnamerec;
  snam1 : shortnamerec;
  rsnm1 : realshortnamerec;
  HDesc : RoomDesc;
  Obj : ObjectRec;
  Class : ClassRec;
  Spell : SpellRec;

BEGIN
  For Loop := 1 TO I_MAX DO
  BEGIN
    IF GetIndex(Loop, Ind) THEN
    BEGIN
      CASE Loop OF
        I_ROOM : BEGIN
          GetLongName(l_na_roomnam, lnam1);
          GetLongName(l_na_roomown, lnam2);
        END;
        I_OBJECT : GetShortName(s_na_objnam, snam1);
        I_CLASS : GetRealShortName(rsnr_class, rsnm1);
        I_SPELL : GetShortName(s_na_spell, snam1);
      END;
      FOR Loop2 := 1 TO Ind.top DO
      BEGIN
        IF not Ind.free[loop2] THEN
        BEGIN
          CASE Loop OF
            I_ROOM : BEGIN
              IF GetRoomDesc(Loop2, HDesc) THEN
              BEGIN
                lnam1.Idents[Loop2] := HDesc.NiceName;
                lnam2.Idents[Loop2] := HDesc.Owner;
              END;
            END;
           I_OBJECT : BEGIN
              IF GetObj(Loop2, Obj) THEN
                snam1.idents[Loop2] := Obj.ObjName
              ELSE
                ind.free[loop] := true;
            END;
            I_CLASS : 
               IF GetClass(Loop2, Class) THEN
                 rsnm1.idents[loop2] := class.name
               ELSE
                 Ind.free[loop] := true;
            I_SPELL :
               IF GetSpell(Loop2, Spell) THEN
                 snam1.idents[loop2] := spell.name
               ELSE
                 Ind.free[loop] := true;
          END;
        END; (* if inuse *)
      END;   (* for loop2 *)
      SaveIndex(Loop, Ind);
      CASE Loop OF
        I_ROOM : BEGIN
          SaveLongName(l_na_roomnam, lnam1);
          SaveLongName(l_na_roomown, lnam2);
        END;
        I_OBJECT : SaveShortName(s_na_objnam, snam1);
        I_CLASS : SaveRealShortName(rsnr_class, rsnm1);
        I_SPELL : SaveShortName(s_na_spell, snam1);
      END;
    END;     (* get index *)
  END;
END;

END.
