[INHERIT('MONCONST','MONTYPE','MONGLOBL','sys$library:Starlet',
         'sys$library:pascal$lib_routines')]
         
MODULE Randoms(OUTPUT);

%include 'headers.txt'

(* -------------------------------------------------------------------------- *)

TYPE
  RoomListPtr = ^RoomList;
  RoomList = RECORD        (* A listing of rooms a certain distance from *)
    DirFrom : INTEGER;     (* How did I get here (i.e. What direction) *)
    RoomNumber : INTEGER;  (* our origination room *)
    Next : RoomListPtr;    (* Joined in a linked list *)
    Parent : RoomListPtr;  (* This Nodes parent in the tree *)
    Children : ARRAY[1..MaxExit] OF RoomListPtr;
  END;

  ExitType = RECORD
    Where : INTEGER;
    Kind : INTEGER;
    Alias : String;
  END;

  RoomType = RECORD     (* A listing of all of the rooms *)
    Used : BYTE_BOOL;
    Exits : ARRAY [1..MaxExit] of ExitType;
  END;
  AllRoomType = ARRAY[1..MaxRoom] of RoomType;

(* -------------------------------------------------------------------------- *)

VAR
  HaveRooms : BYTE_BOOL := FALSE;
  AllRooms : AllRoomType;

(* ======================================================================== *)
(* Section header: Read in all rooms and fill the database.                 *)
(* ======================================================================== *)

FUNCTION ReadRooms(VAR Rooms : AllRoomType) : BYTE_BOOL;

VAR
  Index : IndexRec;
  SomeRoom : RoomDesc;
  ExitNum : INTEGER;
  Status : BYTE_BOOL;
  Loop : INTEGER;

BEGIN
  if (NOT(HaveRooms)) THEN
  BEGIN
    Writeln('Reading in rooms...');
    Status := GetIndex(I_ROOM, Index);
    IF Status THEN
    BEGIN
      FOR Loop := 1 TO Index.Top DO
        IF NOT Index.Free[Loop] THEN
        BEGIN
          Rooms[Loop].Used := FALSE;
          IF GetRoomDesc(Loop, SomeRoom) THEN
            FOR ExitNum := 1 TO MaxExit DO
            BEGIN
              Rooms[Loop].Exits[ExitNum].Where := SomeRoom.Exits[ExitNum].ToLoc;
              Rooms[Loop].Exits[ExitNum].Alias := SomeRoom.Exits[ExitNum].Alias;
              Rooms[Loop].Exits[ExitNum].Kind := SomeRoom.Exits[ExitNum].Kind;
            END
          ELSE
            Rooms[Loop].Used := TRUE;
        END
        ELSE
           Rooms[Loop].Used := TRUE;
      Writeln('All rooms read in.');
      HaveRooms := TRUE;
    END
    ELSE
      Writeln('Error reading in from room file.');
  END;
  ReadRooms := HaveRooms;
END;

(* ======================================================================== *)

PROCEDURE AddToNewList(VAR NewList : RoomListPtr; VAR OldList : RoomListPtr;
                       ThisRoom : INTEGER; DirFrom : INTEGER; Dest : INTEGER);

VAR
  Dummy : RoomListPtr;
  Loop : INTEGER;

BEGIN
  NEW(Dummy);
  Dummy^.RoomNumber := Dest;
  Dummy^.DirFrom := DirFrom;
  Dummy^.Parent := OldList;
  Dummy^.Next := NewList;
  FOR Loop := 1 TO MaxExit DO
    Dummy^.Children[Loop] := NIL;
  IF OldList = NIL THEN
    OldList := Dummy;
  IF DirFrom <> 0 THEN
    OldList^.Children[DirFrom] := Dummy;
  NewList := Dummy;
END;

(* ======================================================================== *)

FUNCTION CanPass(ExitKind : INTEGER; Privd : BYTE_BOOL := FALSE) : BYTE_BOOL;

BEGIN
  CASE ExitKind OF
    EK_NoExit : CanPass := FALSE;
    EK_Open : CanPass := TRUE;
    EK_NeedKey : CanPass := FALSE;
    EK_NeedNoKey : CanPass := TRUE;
    EK_RandomFail : CanPass := TRUE;
    EK_Acceptor : CanPass := FALSE;
    EK_NeedObject : CanPass := FALSE;
    EK_OpenClose : CanPass := FALSE;
    EK_Password : CanPass := FALSE;
    Otherwise CanPass := FALSE;
  END;
END;

(* ======================================================================== *)

PROCEDURE KillTree(VAR List : RoomListPtr);
VAR
  Loop : INTEGER;
BEGIN
  IF List <> NIL THEN
  BEGIN
    FOR Loop := 1 TO MaxExit DO
      KillTree(List^.Children[Loop]);
    DISPOSE(List);
  END;
END;

(* ======================================================================== *)

FUNCTION GetNextMove(Start : INTEGER; VAR List : RoomListPtr) : INTEGER;
BEGIN
  IF List = NIL THEN
    GetNextMove := -1
  ELSE
  BEGIN
    IF (List^.Parent^.RoomNumber = Start) THEN
      GetNextMove := List^.DirFrom
    ELSE
      GetNextMove := GetNextMove(Start, List^.Parent);
  END;
END;

(* ======================================================================== *)

[GLOBAL]
FUNCTION FindShortestPath(Start, Finish : INTEGER;
                          VAR Next : INTEGER) : INTEGER;

VAR
  Top, OldList, NewList : RoomListPtr;
  Rooms : AllRoomType;
  Found : BYTE_BOOL;
  Loop : INTEGER;
  Dest : INTEGER;
  S : String;
  Count : INTEGER;
BEGIN
  ReadRooms(AllRooms);
  Next := -1;
  FindShortestPath := -1;
  Count := 0;
  NewList := NIL;
  OldList := NIL;
  Rooms := AllRooms;
  For loop := 1 to MaxRoom DO
    Rooms[loop].Used := FALSE;
  Rooms[Start].Used := TRUE;
  AddToNewList(NewList,OldList,Start,0,Start);
  Top := NewList;
  Found := Start = Finish;
  WHILE ((OldList <> NIL) AND (NOT FOUND)) DO
  BEGIN
    NewList := NIL;
    WHILE ((OldList <> NIL) AND (NOT Found)) DO
    BEGIN
      Loop := 1;
      WHILE ((Loop <= MaxExit) AND (NOT Found)) DO
      BEGIN
        Dest := Rooms[OldList^.RoomNumber].Exits[Loop].Where;
        IF (Dest <> 0) THEN
        BEGIN
          IF (NOT Rooms[Dest].Used) THEN
          BEGIN
            IF CanPass(Rooms[Oldlist^.RoomNumber].Exits[Loop].Kind) THEN
            BEGIN
              IF (Dest = Finish) THEN
                Found := TRUE;
              AddToNewList(Newlist, Oldlist, Dest, Loop, Dest);
              Rooms[Dest].Used := TRUE;
            END;
          END;
        END;
        IF NOT Found THEN Loop := Loop + 1;
      END;   (* While there is still an exit left *)
      IF NOT Found THEN
        OldList := OldList^.Next;
    END;   (* While there is something left in the list and we are not done *)
    Count := Count + 1;

    IF NOT Found THEN OldList := NewList
    ELSE OldList := OldList^.Children[Loop];
  END;
  IF Found THEN
  BEGIN
    IF Count > 0 THEN Next := GetNextMove(Start, OldList)
    ELSE Next := -2;
    FindShortestPath := Count;
  END;
  KillTree(Top);
END;

END.
