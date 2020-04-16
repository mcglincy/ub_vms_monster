[inherit('monconst','montype','monglobl','monrand','SYS$LIBRARY:STARLET')]

MODULE MonFilio(INPUT, OUTPUT);

(* --------------------- SYSTEM RMS Routines --------------------------- *)

[EXTERNAL, HIDDEN]
FUNCTION Pas$Fab(VAR F : Unsafe_File) : FabPtr; EXTERN;

[EXTERNAL, HIDDEN]
FUNCTION Pas$Rab(VAR F : Unsafe_File) : RabPtr; EXTERN;

(* ------------------- END System RMS Routines ------------------------ *)

(* -------------------- SYSTEM Lib Routines ---------------------------  *)

PROCEDURE LIB$SIGNAL(
	%IMMED Condition_Value : UNSIGNED;
	%IMMED Number_Of_Arguments : INTEGER := %IMMED 0;
	%IMMED FAO_Argument : [LIST,UNSAFE] INTEGER); EXTERNAL;

(* -------------------- END System LIB Routines ----------------------- *)

(* -----------------------  System STR Routines ----------------------- *)

[ASYNCHRONOUS, HIDDEN]
FUNCTION STR$CASE_BLIND_COMPARE(
  First_Source_String : [CLASS_S] PACKED ARRAY [$l1..$u1:INTEGER] OF CHAR;
  Second_Source_String : [CLASS_S] PACKED ARRAY [$l2..$u2:INTEGER] OF CHAR) :
     INTEGER; EXTERNAL;

(* -------------------- END System STR Routines ----------------------- *)

FUNCTION CloseFile(VAR Fab : FabPtr) : BYTE_BOOL;

BEGIN
  CloseFile := ODD($CLOSE(Fab^));
END;

VAR
 OPEN_STATUS : UNSIGNED;

FUNCTION Do_Open(VAR Fab: Fab$Type ; VAR Rab : Rab$Type;
                 VAR SomeFile : Unsafe_File) : unsigned;

(* PRE : This procedure was called from an open statement in pascal *)
(* POST : This actually opens the file so that it can be used later on. *)

CONST
  Wait = 5; (* how many seconds do we wait before we timeout *)

VAR
  Status : unsigned;  (* Status returned from RMS$OPEN and RMS$CONNECT *)

BEGIN
  Status := $OPEN(Fab);
  IF ODD(Status) THEN
  BEGIN
    Status := $CONNECT(Rab);
    IF ODD(Status) THEN  
    BEGIN
      Rab.RAB$L_FAB := IAddress(Fab);
      Rab.RAB$B_RAC := RAB$C_KEY;
      Rab.RAB$B_KRF := 0;
      Rab.RAB$B_TMO := Wait;
    END;
  END;
  Open_Status := Status;
  Do_Open := Status;
END;

PROCEDURE CreateFile(VAR SomeFile : Unsafe_File; FileName : String);

BEGIN
  OPEN(SomeFile,FileName, ACCESS_METHOD := DIRECT, HISTORY := NEW,
       SHARING := ReadWrite);
  Close(SomeFile);
  OPEN(SomeFile,FileName,ACCESS_METHOD := DIRECT, HISTORY := UNKNOWN,
       SHARING := ReadWrite, User_Action := Do_Open, ERROR := CONTINUE);
END;

[GLOBAL]
FUNCTION OpenSomeFile(VAR SomeFile : Unsafe_File; FileName : String;
 		  VAR Fab : FabPtr; VAR Rab : RabPtr;
                   TypeSize : $UWORD) : BYTE_BOOL;

VAR
  Stat : INTEGER;
  Answer : String;
BEGIN
  OPEN(SomeFile, FileName, ACCESS_METHOD := DIRECT, HISTORY := UNKNOWN,
       SHARING := ReadWrite, User_Action := Do_Open,
       Record_Length := TypeSize,  ERROR := CONTINUE);
  IF (Status(SomeFile) <> 0) THEN Writeln('Invalid status: ', OPEN_STATUS:0);
(* sys$library:pastatus.pas *)
  CASE Status(SomeFile) OF
     2 : Writeln(FileName,' : file is locked (error during open).');
     3 : BEGIN
           Write('File ',Filename,' does not exists. Create it? ');
           Readln(Answer);
           IF (Answer[1] ='y') OR (Answer[1] = 'Y') THEN
             CreateFile(SomeFile, FileName);
         END;
     6 : Writeln(FileName, ' : Record length is inconsistent with filetype');
     0 : ;
     OTHERWISE
     BEGIN
       Writeln('Unknown status in open file --> ',Status(SomeFile):0);
       Writeln('Filename is ',FileName);
     END;
  END;
  Stat := Status(SomeFile);
  IF Stat = 0 THEN
  BEGIN
    Fab := Pas$Fab(SomeFile);
    Rab := Pas$Rab(SomeFile);
    Rab^.Rab$W_USZ := TypeSize;
  END;
  OpenSomeFile := Stat = 0;
END;

[GLOBAL]
FUNCTION OpenFile(VAR SomeFile : Unsafe_File;
                  Index : INTEGER; TypeSize : $UWORD) : BYTE_BOOL;
BEGIN
  OpenFile := OpenSomeFile(SomeFile, Root+F_Names[Index],
                           AF[Index], AR[Index], TypeSize);
END;

(* ----------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION RMS_LockGet(AddVar : [LONG, UNSAFE] UNSIGNED; RecNum : INTEGER;
		 VAR RAB : RabPtr) : BYTE_BOOL;

VAR
  Status : INTEGER;
  Loop : INTEGER;
  Found : INTEGER := 1;
  Lock : UNSIGNED := RAB$M_ULK;

BEGIN
  IF Debug[DEBUG_Files] THEN
  BEGIN
    FOR Loop := 1 TO NumberFiles DO
      IF AR[Loop] = RAB THEN
        Found := Loop;
      Writeln('read (lock): ',F_Names[Found]);
  END;
  RAB^.RAB$L_ROP := Lock + RAB$M_WAT + RAB$M_TMO;
  RAB^.RAB$L_UBF := AddVar;
  RAB^.RAB$L_KBF := IADDRESS(RecNum);
  Rab^.Rab$W_RSZ := Rab^.Rab$W_USZ;
  Status := $GET(RAB^);
  IF NOT ODD(Status) THEN
    IF Debug[DEBUG_Files] THEN
      LIB$SIGNAL(Status);
  RMS_LockGet := ODD(Status);
END;

(* ----------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION RMS_Get(AddVar : [LONG, UNSAFE] UNSIGNED; RecNum : INTEGER;
		 VAR RAB : RabPtr) : BYTE_BOOL;

VAR
  Status : INTEGER;
  Loop : INTEGER;
  Found : INTEGER := 1;
  Lock : UNSIGNED := RAB$M_NLK;

BEGIN
  IF Debug[DEBUG_Files] THEN
  BEGIN
    FOR Loop := 1 TO NumberFiles DO
      IF AR[Loop] = RAB THEN
        Found := Loop;
      Writeln('read: ',F_Names[Found]);
  END;
  RAB^.RAB$L_ROP := Lock + RAB$M_WAT + RAB$M_TMO;
  RAB^.RAB$L_UBF := AddVar;
  RAB^.RAB$L_KBF := IADDRESS(RecNum);
  Rab^.Rab$W_RSZ := Rab^.Rab$W_USZ;
  Status := $GET(RAB^);
  IF NOT ODD(Status) THEN
    IF Debug[DEBUG_Files] THEN
      LIB$SIGNAL(Status);
  RMS_Get := ODD(Status);
END;

[GLOBAL]
FUNCTION RMS_Put(AddVar : [LONG, UNSAFE] UNSIGNED; RecNum : INTEGER;
		 RAB : RabPtr): BYTE_BOOL;

VAR
  Status : INTEGER;
  Found : INTEGER;
  Loop : INTEGER;

BEGIN
  IF Debug[DEBUG_Files] THEN
  BEGIN
    FOR Loop := 1 TO NumberFiles DO
      IF AR[Loop] = RAB THEN
        Found := Loop;
      Writeln('WRITE: ',F_Names[Found]);
  END;
  RMS_Put := TRUE;
  RAB^.RAB$L_ROP := RAB$M_RLK + RAB$M_WAT + RAB$M_TMO + RAB$M_UIF;
  RAB^.RAB$L_RBF := AddVar;
  RAB^.RAB$L_KBF := IADDRESS(RecNum);
  Rab^.Rab$W_RSZ := Rab^.Rab$W_USZ;
  Status := $PUT(RAB^);
  IF NOT ODD(Status) THEN
    IF Debug[DEBUG_Files] THEN
      LIB$SIGNAL(Status);
  RMS_Put := ODD(Status);
END;

FUNCTION RMS_Delete(AddVar : [LONG,UNSAFE] UNSIGNED;
             RecordNumber : INTEGER; VAR RAB : RabPtr) : BYTE_BOOL;

VAR
  Status : INTEGER;

BEGIN
(*
  $DELETE Is only allowed on relative or indexed files.  It is not allowed
  on sequential files - which we are currently using. *)

(*
  RAB^.RAB$L_ROP := RAB$M_WAT + RAB$M_TMO;
  RAB^.RAB$L_UBF := AddVar;
  RAB^.RAB$L_KBF := IADDRESS(RecordNumber);
  Rab^.Rab$W_RSZ := Rab^.Rab$W_USZ;
  Status := $FIND(RAB^);
  IF ODD(Status) THEN
    Status := $DELETE(RAB^);
  IF NOT ODD(Status) AND Debug[DEBUG_Files] THEN
    LIB$SIGNAL(Status);
  RMS_Delete := ODD(Status);
*)
  RMS_Delete := TRUE;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetKill(KillNum : INTEGER; VAR Kill : KillRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Kill), KillNum, AR[F_Kill]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in Kill #', KillNum:0);
  GetKill := Status;
END;

[GLOBAL]
FUNCTION SaveKill(KillNum : INTEGER; VAR Kill : KillRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Kill), KillNum, AR[F_Kill]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving kill #', KillNum:0);
  SaveKill := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetAtmosphere(AtmosNum : INTEGER; VAR Atmos : AtmosphereRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Atmos), AtmosNum, AR[F_Atmosphere]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in Atmosphere #', AtmosNum:0);
  GetAtmosphere := Status;
END;

[GLOBAL]
FUNCTION SaveAtmosphere(AtmosNum : INTEGER; VAR Atmos : AtmosphereRec;
                        Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Atmos), AtmosNum, AR[F_Atmosphere]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving atmosphere #', AtmosNum:0);
  SaveAtmosphere := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetObj(ObjNum : INTEGER; VAR Obj : ObjectRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Obj), ObjNum, AR[F_Object]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in object #', ObjNum:0);
  GetObj := Status;
END;

[GLOBAL]
FUNCTION DeleteObj(ObjNum : INTEGER; VAR Obj : ObjectRec;
                   Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Obj), ObjNum, AR[F_Object]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleteing object #', ObjNum:0);
  DeleteObj := Status;
END;

[GLOBAL]
FUNCTION SaveObj(ObjNum : INTEGER; VAR Obj : ObjectRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Obj), ObjNum, AR[F_Object]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving object #',ObjNum:0);
  SaveObj := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetChar(CharNum : INTEGER; VAR Charac : CharRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Charac), CharNum, AR[F_Character]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in character #', CharNum:0);
  GetChar := Status;
END;

[GLOBAL]
FUNCTION SaveChar(CharNum : INTEGER; VAR Charac : CharRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Charac), CharNum, AR[F_Character]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving character #',CharNum:0);
  SaveChar := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetRoomDesc(RoomNum : INTEGER; VAR Here : RoomDesc;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Here), RoomNum, AR[F_RoomDesc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in room #', RoomNum:0);
  GetRoomDesc := Status;
END;

[GLOBAL]
FUNCTION DeleteRoomDesc(RoomNum : INTEGER; VAR Here : RoomDesc;
                        Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Here), RoomNum, AR[F_RoomDesc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleteing room #', RoomNum:0);
  DeleteRoomDesc := Status;
END;

[GLOBAL]
FUNCTION SaveRoomDesc(RoomNum : INTEGER; VAR Here : RoomDesc;
                      Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Here), RoomNum, AR[F_RoomDesc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving room #',RoomNum:0);
  SaveRoomDesc := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetRand(RandNum : INTEGER; VAR Rand : RandRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Rand), RandNum, AR[F_Rand]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in random #', RandNum:0);
  GetRand := Status;
END;

[GLOBAL]
FUNCTION SaveRand(RandNum : INTEGER; VAR Rand : RandRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Put(IADDRESS(Rand), RandNum, AR[F_Rand]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saveing random #', RandNum:0);
  SaveRand := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetLongName(SlotNum : INTEGER; VAR Name : LongNameRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  IF Long_name_loaded THEN BEGIN
    Name := LN[slotnum];
    GetLongName := TRUE;
  END ELSE BEGIN
    Status := RMS_Get(IADDRESS(Name), SlotNum, AR[F_LongName]);
    IF NOT Status AND NOT Silent THEN
      Writeln('Error reading in Long name #', SlotNum:0);
    GetLongName := Status;
  END;
END;

[GLOBAL]
FUNCTION SaveLongName(SlotNum : INTEGER; VAR Name : LongNameRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Name), SlotNum, AR[F_LongName]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving long name #',SlotNum:0);
  SaveLongName := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetShortName(SlotNum : INTEGER; VAR Name : ShortNameRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  IF Short_name_loaded THEN BEGIN
    GetShortName := TRUE;
    Name := SN[SlotNum];
  END ELSE BEGIN
    Status := RMS_Get(IADDRESS(Name), SlotNum, AR[F_ShortName]);
    IF NOT Status AND NOT Silent THEN
      Writeln('Error reading in short name #', SlotNum:0);
    GetShortName := Status;
  END;
END;

[GLOBAL]
FUNCTION SaveShortName(SlotNum : INTEGER; VAR Name : ShortNameRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Name), SlotNum, AR[F_ShortName]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving short name #',SlotNum:0);
  SaveShortName := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetRealShortName(SlotNum : INTEGER; VAR Name : RealShortNameRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  IF RealShort_name_loaded THEN BEGIN
    Name := RSN[SlotNum];
    GetRealShortName := TRUE;
  END ELSE BEGIN
    Status := RMS_Get(IADDRESS(Name), SlotNum, AR[F_RealShortName]);
    IF NOT Status AND NOT Silent THEN
      Writeln('Error reading in real short name #', SlotNum:0);
    GetRealShortName := Status;
  END;
END;

[GLOBAL]
FUNCTION SaveRealShortName(SlotNum : INTEGER; VAR Name : RealShortNameRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Name), SlotNum, AR[F_RealShortName]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving real short name #',SlotNum:0);
  SaveRealShortName := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetDesc(DescNum : INTEGER; VAR Block : DescRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Block), DescNum, AR[F_Desc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in description block #', DescNum:0);
  GetDesc := Status;
END;

[GLOBAL]
FUNCTION DeleteDesc(DescNum : INTEGER; VAR Block : DescRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Block), DescNum, AR[F_Desc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleting in description block #', DescNum:0);
  DeleteDesc := Status;
END;

[GLOBAL]
FUNCTION SaveDesc(DescNum : INTEGER; VAR Block : DescRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(block), DescNum, AR[F_Desc]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving description block #',DescNum:0);
  SaveDesc := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetInt(IntNum : INTEGER; VAR Int : IntArray;
                Silent : BYTE_BOOL := FALSE;
                Lock : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Int), IntNum, AR[F_Int]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in int #', IntNum:0);
  GetInt := Status;
END;

[GLOBAL]
FUNCTION SaveInt(IntNum : INTEGER; VAR Int : IntArray;
                  Silent : BYTE_BOOL := FALSE;
                 Locked : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Int), IntNum, AR[F_Int]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving int #',IntNum:0);
  SaveInt := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetClass(ClassNum : INTEGER; VAR Monst : ClassRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Monst), ClassNum, AR[F_Monster]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in class #', ClassNum:0);
  GetClass := Status;
END;

[GLOBAL]
FUNCTION DeleteClass(ClassNum : INTEGER; VAR Monst : ClassRec;
                       Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Monst), ClassNum, AR[F_Monster]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleteing class #', ClassNum:0);
  DeleteClass := Status;
END;

[GLOBAL]
FUNCTION SaveClass(ClassNum : INTEGER; VAR Monst : ClassRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Monst), ClassNum, AR[F_Monster]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving class #', ClassNum:0);
  SaveClass := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetSpell(SpellNum : INTEGER; VAR Spell : SpellRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Spell), SpellNum, AR[F_Spell]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in spell #', SpellNum:0);
  GetSpell := Status;
END;

[GLOBAL]
FUNCTION DeleteSpell(SpellNum : INTEGER; VAR Spell : SpellRec;
                     Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Spell), SpellNum, AR[F_Spell]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleteing spell #', SpellNum:0);
  DeleteSpell := Status;
END;

[GLOBAL]
FUNCTION SaveSpell(SpellNum : INTEGER; VAR Spell : SpellRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Spell), SpellNum, AR[F_Spell]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving spell #',SpellNum:0);
  SaveSpell := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetIndex(IndexNum : INTEGER; VAR Indx : IndexRec;
                  Silent : BYTE_BOOL := FALSE;
                  Lock : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Indx), IndexNum, AR[F_Index]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in index #', IndexNum:0);
  GetIndex := Status;
END;

[GLOBAL]
FUNCTION SaveIndex(IndexNum : INTEGER; VAR Indx : IndexRec;
                   Silent : BYTE_BOOL := FALSE;
                   Locked : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Indx), IndexNum, AR[F_Index]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving index #',IndexNum:0);
  SaveIndex := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetLine(LineNum : INTEGER; VAR Line : LineRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Line), LineNum, AR[F_Line]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in line #', LineNum:0);
  GetLine := Status;
END;

[GLOBAL]
FUNCTION DeleteLine(LineNum : INTEGER; VAR Line : LineRec;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Line), LineNum, AR[F_Line]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleting in line #', LineNum:0);
  DeleteLine := Status;
END;

[GLOBAL]
FUNCTION SaveLine(LineNum : INTEGER; VAR Line : LineRec;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Line), LineNum, AR[F_Line]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving line #',LineNum:0);
  SaveLine := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetUniv(UnivNum : INTEGER; VAR Univ : Universe;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Get(IADDRESS(Univ), UnivNum, AR[F_Universe]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in universe #', UnivNum:0);
  GetUniv := Status;
END;

[GLOBAL]
FUNCTION SaveUniv(UnivNum : INTEGER; VAR Univ : Universe;
                  Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Univ), UnivNum, AR[F_Universe]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving universe #',UnivNum:0);
  SaveUniv := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetRoom(RoomNum : INTEGER; VAR Stuff : Room;
                 Silent : BYTE_BOOL := FALSE;
                 Lock : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  IF Lock THEN
    Status := RMS_LockGet(IADDRESS(Stuff), RoomNum, AR[F_Room])
  ELSE
    Status := RMS_Get(IADDRESS(Stuff), RoomNum, AR[F_Room]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in room #', RoomNum:0);
  GetRoom := Status;
END;

[GLOBAL]
FUNCTION DeleteRoom(RoomNum : INTEGER; VAR Stuff : Room;
                 Silent : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status := RMS_Delete(IADDRESS(Stuff), RoomNum, AR[F_Room]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error deleting room #', RoomNum:0);
  DeleteRoom := Status;
END;

[GLOBAL]
FUNCTION SaveRoom(RoomNum : INTEGER; VAR Stuff : Room;
                  Silent : BYTE_BOOL := FALSE;
                  Locked : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  Status :=  RMS_Put(IADDRESS(Stuff), RoomNum, AR[F_Room]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving room #',RoomNum:0);
  SaveRoom := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

[GLOBAL]
FUNCTION GetEvent(EventNum : INTEGER; VAR Stuff : EventArray;
                  Silent : BYTE_BOOL := FALSE;
                  Lock : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
BEGIN
  IF Lock THEN
    Status := RMS_LockGet(IADDRESS(Stuff), EventNum, AR[F_Event])
  ELSE
    Status := RMS_Get(IADDRESS(Stuff), EventNum, AR[F_Event]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error reading in event #', EventNum:0);
  GetEvent := Status;
END;

[GLOBAL]
FUNCTION SaveEvent(EventNum : INTEGER; VAR Stuff : EventArray;
                   Silent : BYTE_BOOL := FALSE;
                   Locked : BYTE_BOOL := FALSE) : BYTE_BOOL;
VAR
  Status : BYTE_BOOL;
  UStatus : UNSIGNED;
BEGIN
  Status :=  RMS_Put(IADDRESS(Stuff), EventNum, AR[F_Event]);
  IF NOT Status AND NOT Silent THEN
    Writeln('Error saving event #', EventNum:0);
(*
  IF Locked THEN
  BEGIN
    UStatus := $RELEASE(AR[F_Event]);
    writeln('Error ', UStatus:0);
    IF NOT(Odd(UStatus)) THEN lib$signal(UStatus);
  END;
*)
  SaveEvent := Status;
END;

(* ---------------------- Get and put routines ---------------------- *)

END.
