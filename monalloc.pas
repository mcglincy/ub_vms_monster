[inherit('monconst','montype','monglobl')]

MODULE MonAlloc(Input, Output);

%include 'headers.txt'

[GLOBAL]
FUNCTION CountRooms(S:ShortString; VAR NumRooms : INTEGER) : BYTE_BOOL;
var
  RoomOwners : LongNameRec;
  RoomIndex : IndexRec;
  Loop : integer;
  Status : BYTE_BOOL;

BEGIN
  NumRooms := 0;
  Status := GetLongName(L_NA_RoomOwn, RoomOwners);
  IF Status THEN
  BEGIN
    Status := GetIndex(I_Room, RoomIndex);
    IF Status THEN
    BEGIN
      FOR Loop := 1 to RoomIndex.Top DO
        IF NOT(RoomIndex.Free[Loop]) THEN
          IF (RoomOwners.Idents[Loop] = S) THEN
            NumRooms := NumRooms + 1;
    END;
  END;
  CountRooms := Status;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION CountObjects(S:ShortString; VAR NumObjects : INTEGER) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Status : BYTE_BOOL;
  ObjectOwners : ShortNameRec;
  ObjectIndex : IndexRec;

BEGIN
  Status := GetShortName(S_NA_ObjOwn, ObjectOwners);
  IF Status THEN
  BEGIN
    Status := GetIndex(I_Object, ObjectIndex);
    IF Status THEN
    BEGIN
      NumObjects := 0;
      FOR Loop := 1 to ObjectIndex.Top DO
      BEGIN
        IF NOT(ObjectIndex.Free[Loop]) THEN
          IF (ObjectOwners.Idents[Loop] = S) THEN
            NumObjects := NumObjects + 1;
      END;
    END;
  END;
  CountObjects := Status;
end;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION AllowRoomOwnership(MyLog : INTEGER;
                            Userid : VeryShortString) : BYTE_BOOL;

VAR
  Character : CharRec;
  NumbRooms : INTEGER;

BEGIN
  IF GetChar(MyLog, Character) THEN
     IF CountRooms(UserId,NumbRooms) THEN
        AllowRoomOwnership := (Character.maxrooms > NumbRooms)
     ELSE
     BEGIN
        AllowRoomOwnership := FALSE;
        Writeln('Error counting number of rooms - AllowRoomOwnership.');
     END
  ELSE
  BEGIN
    Writeln('Error reading character record - AllowRoomOwnership');
    AllowRoomOwnership := FALSE;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION AllowObjectOwnership(MyLog : INTEGER;
                              Userid : VeryShortString) : BYTE_BOOL;

VAR
  Character : CharRec;
  NumbObjects : INTEGER;

BEGIN
  IF GetChar(MyLog, Character) THEN
     IF CountObjects(UserId,NumbObjects) THEN
        AllowObjectOwnership := (Character.MaxObjs > NumbObjects)
     ELSE
     BEGIN
        AllowObjectOwnership := FALSE;
        Writeln('Error counting number of rooms - AllowObjectOwnership.');
     END
  ELSE
  BEGIN
    Writeln('Error reading character record - AllowObjectOwnership');
    AllowObjectOwnership := FALSE;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION AllocDetail(VAR Index : INTEGER; S : String;
                     ThisRoom : INTEGER): BYTE_BOOL;

VAR
  Found : BYTE_BOOL;
  Status : BYTE_BOOL;
  Here : RoomDesc;

BEGIN
  Index := 1;
  Found := FALSE;
  Status := GetRoomDesc(ThisRoom, Here);
  IF Status THEN
  BEGIN 
    WHILE (Index <= MaxDetail) AND (NOT Found) DO
    BEGIN
      IF (Here.DetailDesc[Index] = 0) OR
         (Here.DetailDesc[Index] = DEFAULT_DESC) THEN
         Found := TRUE
      ELSE
        Index := Index + 1;
    END;
    IF Found THEN
    BEGIN
      Status := GetRoomDesc(ThisRoom, Here);
      IF Status THEN
      BEGIN
        Here.Detail[Index] := LowCase(S);
        Status := SaveRoomDesc(ThisRoom, Here);
        IF Status THEN
          LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', ThisRoom);
      END
      ELSE
        Writeln('Error reading in from room file - AllocDetail.');
    END
    ELSE
      Writeln('Could not find a blank slot.');
  END
  ELSE
    Writeln('Error reading in from room file - AllocDetail.');
  AllocDetail := Status AND Found
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Allocate(IndexNum : INTEGER; VAR Slot : INTEGER) : BYTE_BOOL;

VAR
  Index : IndexRec;
  Found : BYTE_BOOL;
  Status : BYTE_BOOL;

BEGIN
  IF FindFreeIndexSlot(IndexNum, Slot) THEN
  BEGIN
    IF GetIndex(IndexNum, Index) THEN
    BEGIN
      Index.Free[Slot] := FALSE;
      Index.InUse := Index.InUse + 1;
      Status := SaveIndex(IndexNum, Index);
    END
    ELSE
      Status := FALSE;
    Allocate := Status;
    IF Status THEN
      Writeln('Space allocated.')
    ELSE
      Writeln('Space not allocated.');
  END
  ELSE
  BEGIN
    Writeln('There is no more space available.');
    Allocate := FALSE;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION DeAllocate(Indexnum : INTEGER; Slot : INTEGER) : BYTE_BOOL;

VAR
  Index : IndexRec;
  Status : BYTE_BOOL := TRUE;

BEGIN
  IF GetIndex(IndexNum, Index) THEN
  BEGIN
    Index.InUse := Index.InUse - 1;
    Index.Free[Slot] := TRUE;
    Status := SaveIndex(IndexNum, Index);
  END
  ELSE
    Status := FALSE;
  DeAllocate := Status;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION DeAllocateDesc(Slot : INTEGER) : BYTE_BOOL;

VAR
  Index : IndexRec;
  Status : BYTE_BOOL := TRUE;
  IndexNum : INTEGER := 0;

BEGIN
  IF Slot < 0 THEN
  BEGIN
    IndexNum := I_LINE;
    Slot := -Slot;
  END
  ELSE
  IF (Slot > 0) THEN
    IF (Slot <> DEFAULT_DESC) THEN
      IndexNum := I_BLOCK;

  IF (IndexNum <> 0) THEN
  BEGIN
    IF (Slot <> DEFAULT_DESC) THEN
    BEGIN
      IF GetIndex(IndexNum, Index) THEN
      BEGIN
        Index.InUse := Index.InUse - 1;
        Index.Free[Slot] := TRUE;
        Status := SaveIndex(IndexNum, Index);
      END
      ELSE
        Status := FALSE;
    END;
  END;
  DeAllocateDesc := Status;
END;

END.
