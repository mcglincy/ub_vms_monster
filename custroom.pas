[INHERIT ('MONCONST','MONTYPE','MONGLOBL'),
 ENVIRONMENT ('CUSTROOM')]

MODULE CustRoom(OUTPUT);

%include 'headers.txt'

VAR
  maxcmds : [EXTERNAL] INTEGER;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION GetRoomOwner(N : INTEGER; VAR Owner : ShortString) : BYTE_BOOL;
VAR
  Own : LongNameRec;
BEGIN
  GetRoomOwner := FALSE;
  IF GetLongName(l_na_roomown, own) THEN
  BEGIN
    Owner := Own.Idents[N];
    GetRoomOwner := TRUE;
END;
END;

[GLOBAL]
FUNCTION SetRoomOwner(N : INTEGER; Owner : ShortString) : BYTE_BOOL;
VAR
  Own : LongNameRec;
BEGIN
  SetRoomOwner := FALSE;
  IF GetLongName(l_na_roomown, own) THEN
  BEGIN
    Own.Idents[N] := Owner;
    IF SaveLongName(l_na_roomown, own) THEN
    BEGIN
      LogEvent(-1, -1, e_setname, 0, 0, nt_long, l_na_roomown, '', r_allrooms,
               owner, n);
      SetRoomOwner := TRUE;
    END;
  END;
END;

[GLOBAL]
FUNCTION IsRoomOwner(RoomNo : INTEGER; Privd : BYTE_BOOL;
                     CheckPub : Byte_Bool) : BYTE_BOOL;
VAR
  MyId, Own : ShortString;
BEGIN
  MyId := LowCase(UserId);
  IF GetRoomOwner(RoomNo, Own) THEN
    IsRoomOwner := (CheckPub AND (Own = '')) OR (LowCase(Own) = MyId) OR Privd
  ELSE IsRoomOwner := Privd;
END;

(* ------------------------------------------------------------------------- *)
[GLOBAL]
FUNCTION GetRoomName(N : INTEGER; VAR Name : ShortString) : BYTE_BOOL;
VAR
  Nam : LongNameRec;
BEGIN
  GetRoomName := FALSE;
  Name := 'ERROR';
  IF GetLongName(l_na_roomnam, Nam) THEN
  BEGIN
    Name := Nam.Idents[N];
    GetRoomName := TRUE;
  END;
END;

[GLOBAL]
FUNCTION SetRoomName(N : INTEGER; Name : ShortString) : BYTE_BOOL;
VAR
  Nam : LongNameRec;
BEGIN
  SetRoomName := FALSE;
  IF GetLongName(l_na_roomnam, nam) THEN
  BEGIN
    Nam.Idents[N] := Name;
    IF SaveLongName(l_na_roomnam, Nam) THEN
    BEGIN
      LogEvent(-1, -1, e_setname, 0, 0, nt_long, l_na_roomnam, '', r_allrooms,
               name, n);
      LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', N);
      SetRoomName := TRUE;
    END;
  END;
END;

(* ------------------------------------------------------------------------- *)

FUNCTION GetExitType(N : INTEGER) : String;
VAR
  S : String;
BEGIN
  CASE N OF
    0: S := '  no exit';
    1: S := '  Open passage';
    2: S := '* Door, object required to pass';
    3: S := '* No passage if holding object';
    4: S := '  Randomly fails';
    5: S := '  Potential exit';
    6: S := '* Only exists while holding the required object';
    7: S := '  Timed exit';
    8: S := '* Passworded exit';
    OTHERWISE S := 'ERROR';
  END;
  GetExitType := S;
END;

PROCEDURE PrintExitTypes;
VAR
  Loop : INTEGER;
BEGIN
  For Loop := 0 TO 8 DO
    Writeln(Loop:0, ') ', GetExitType(Loop));
END;

(* ------------------------------------------------------------------------- *)
FUNCTION GetRoomType(N : INTEGER) : String;

BEGIN
 CASE N OF
    0: getroomtype :='Market or Store';
    1: getroomtype :='No Combat/Spells in this area';
    2: getroomtype :='No hiding in this area';
    3: getroomtype :='Hard to Hide in this area';
    4: getroomtype :='Object destroying area';
    5: getroomtype :='Treasure dropping area';
    6: getroomtype :='Monster generator';
    7: getroomtype :='Generates monsters of a group';
    8: getroomtype :='Lair of a monster';
    9:getroomtype :='Generates monsters of min level';
    10:getroomtype :='Generates monsters of max level';
    11:getroomtype :='Healing room';
    otherwise getroomtype := 'Unknown';
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ListRoomTypes;

VAR
  I : INTEGER;

BEGIN
  FOR I := 0 TO MaxRoomType DO
  Writeln(I:2,' ',GetRoomType(I));
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION CanAlterExit(Dir : INTEGER; RoomNum : INTEGER;
                      Privd : BYTE_BOOL := FALSE) : BYTE_BOOL;

(* Assumes a valid direction "dir", and a valid room number "roomnum" *)
(* RETURNS TRUE if they can alter the exit in room "roomnum" in the *)
(*         direction "dir", else RETURNS FALSE *)

VAR
  HereDesc : RoomDesc;

BEGIN
  CanAlterExit := FALSE;
  IF IsRoomOwner(RoomNum, Privd, FALSE) THEN
    CanAlterExit := TRUE
  ELSE
  BEGIN
    IF GetRoomDesc(RoomNum, HereDesc) THEN
      IF HereDesc.Exits[Dir].ToLoc > 0 THEN
        IF IsRoomOwner(HereDesc.Exits[Dir].ToLoc, Privd, FALSE) THEN
          CanAlterExit := TRUE;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION CanMakeExit(Dir, RoomNum : INTEGER; Alink : BYTE_BOOL;
                     Privd : BYTE_BOOL) : BYTE_BOOL;

(* Assumes that Dir is a valid Direction, and that RoomNum is valid. *)
(* RETURNS TRUE, if they are able to create an exit in Room "RoomNum" *)
(*         in the direction "Dir" *)

VAR
  HereDesc : RoomDesc;

BEGIN
  CanMakeExit := FALSE;
  IF GetRoomDesc(RoomNum, HereDesc) THEN
  BEGIN
    IF (HereDesc.Exits[Dir].ToLoc <> 0) THEN
      IF (Alink) AND (Privd) THEN
        CanMakeExit := TRUE
      ELSE
      IF Privd THEN
        Writeln('There is already an exit there. Use UNLINK to remove it.')
      ELSE
        INFORM_NoAlterExit
    ELSE
    IF IsRoomOwner(RoomNum, Privd, FALSE) OR
              (HereDesc.Exits[Dir].Kind = EK_ACCEPTOR) THEN
      CanMakeExit := TRUE
    ELSE
      INFORM_NoAlterExit
  END
  ELSE
    INFORM_NoAlterExit
END;

(* -------------------------------------------------------------------------- *)

FUNCTION LinksPossible(RoomNum : INTEGER; Privd : BYTE_BOOL := FALSE) : BYTE_BOOL;

VAR
  I : INTEGER;
  HereDesc : RoomDesc;

BEGIN
  LinksPossible := FALSE;
  IF IsRoomOwner(RoomNum, Privd, FALSE) THEN
    LinksPossible := TRUE
  ELSE
    IF GetRoomDesc(RoomNum, HereDesc) THEN
      FOR I := 1 TO MaxExit DO
        IF (HereDesc.Exits[I].ToLoc = 0) AND
           (HereDesc.Exits[I].Kind = EK_ACCEPTOR) THEN
          LinksPossible := TRUE;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE InitExit(Dir : INTEGER; VAR HereDesc : RoomDesc);

BEGIN
  WITH HereDesc.Exits[Dir] DO
  BEGIN
    Kind := 1;
    Exitdesc := DEFAULT_DESC;
    Fail := DEFAULT_DESC;
    Success := DEFAULT_DESC;
    Comeout := DEFAULT_DESC;
    Goin := DEFAULT_DESC;
    DoorEffect := 0;
    ObjReq := 0;
    Hidden := 0;
    ReqAlias := FALSE;
    ReqVerb := FALSE;
    AutoLook := TRUE;
    Alias := '';
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE LinkRoom(Start, Dir, Finish, EndDir : INTEGER; MySlot : INTEGER;
                   Name : String);

VAR
  TargName : String;
  HereDesc : RoomDesc;

BEGIN
  IF GetRoomDesc(Start, HereDesc) THEN
  BEGIN
    WITH HereDesc.Exits[Dir] DO
    BEGIN
      ToLoc := Finish;
      Slot := EndDir;
      InitExit(Dir, HereDesc);
    END;
    IF SaveRoomDesc(Start, HereDesc) THEN
      LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', Start);
  END
  ELSE
    Writeln('Error linking room.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoLink(S : String; Alink :BYTE_BOOL := FALSE;VAR AllStats : AllMyStats);

VAR
  Ok : BYTE_BOOL;
  OrgExitNam, TargNam, TrgExitNam : String;
  TargRoom, TargDir, OrigDir : INTEGER;
  RoomNum : INTEGER;
  TempLoc : INTEGER;

BEGIN
  RoomNum := AllStats.Stats.Location;
  IF LinksPossible(RoomNum, AllStats.Stats.Privd) THEN
  BEGIN
    Writeln('Hit return alone at any prompt to terminate exit creation.');
    Writeln;
  
    IF S = '' THEN
      GrabLine('Direction of exit? ', OrgExitNam,AllStats)
    ELSE
      OrgExitNam := Bite(S);
    WHILE (OrgExitNam <> '')  AND (NOT LookupDir(OrigDir, OrgExitNam)) DO
      GrabLine('Direction of exit? ', OrgExitNam,AllStats);
    OK := LookupDir(OrigDir, OrgExitnam);
   
    IF OK THEN
    BEGIN
      IF S = '' THEN
        GrabLine('Room to link to? ',TargNam,AllStats)
      ELSE
        TargNam := Bite(S);
      WHILE (Targnam <> '') AND
            (NOT LookupRoomName(Targnam, TargRoom, false, false)) DO
        GrabLine('Room to link to? ',TargNam,AllStats);
      OK := LookupRoomName(Targnam, TargRoom, false, true);
    END;
   
    IF OK THEN
    BEGIN
      IF S = '' THEN
      BEGIN
        Writeln('Exit comes out in target room');
        GrabLine('from what direction? ',TrgExitNam,AllStats);
      END
      ELSE
        TrgExitNam := Bite(S);
      WHILE (TrgExitNam <> '') AND (NOT LookupDir(TargDir, TrgExitNam)) DO
        GrabLine('from what direction? ',TrgExitNam,AllStats);
      OK := LookupDir(TargDir, TrgExitNam);
    END;
 
    IF OK THEN
      Ok := CanMakeExit(Targdir, TargRoom, Alink, AllStats.Stats.Privd);

    IF OK THEN
    BEGIN
      LinkRoom(RoomNum, Origdir, TargRoom, TargDir, AllStats.Stats.Slot,
               AllStats.Stats.Name);
      IF NOT Alink THEN
        LinkRoom(TargRoom, TargDir, RoomNum, OrigDir, 0, AllStats.Stats.Name);
    END;
  END
  ELSE
    Writeln('No links are possible here.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoDescribe(S : String; VAR AllStats : AllMyStats);

VAR
  I, NewDsc : INTEGER;
  HereDesc : RoomDesc;
  RoomNum : INTEGER;
  Slot : INTEGER;

BEGIN
  RoomNum := AllStats.Stats.Location;
  Slot := AllStats.Stats.Slot;
  IF GetRoomDesc(RoomNum, HereDesc) THEN
  BEGIN
    IF Length(S) > VeryShortLen THEN
      Writeln('Your detail keyword can only be ',veryshortlen:1,' characters.')
    ELSE
    IF IsRoomOwner(RoomNum, AllStats.Stats.Privd, FALSE) THEN
    BEGIN
      IF NOT (LookupDetail(I, S)) THEN
        IF NOT (AllocDetail(I, S, RoomNum)) THEN
        BEGIN
          Writeln('You have used all ',maxdetail:1,' details.');
          Writeln('To delete a detail, DESCRIBE <the detail> and delete all the text.');
        END;
      IF I <> 0 THEN
      BEGIN
        HereDesc.Detail[I] := S;
        Writeln('[ Editing detail "', HereDesc.Detail[i],'" of this room ]');
        NewDsc := HereDesc.DetailDesc[I];
        IF EditDesc(NewDsc, ,AllStats) THEN
        BEGIN
          HereDesc.DetailDesc[I] := NewDsc;
          IF NewDsc = 0 THEN
            HereDesc.Detail[I] := '';
          IF SaveRoomDesc(RoomNum, HereDesc) THEN
            LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNum);
        END;
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RoomHelp(Privd : BYTE_BOOL := FALSE);

BEGIN
  Writeln;
  Writeln('B   Edit the target room (G) "bounced in" description');
  Writeln('C   Set the room''s alignment.');
  Writeln('D   Alter the way the room description prints');
  Writeln('F   Edit the default line others will see when an exit fails');
  Writeln('G   Set the location that a dropped object really Goes to');
  Writeln('M   Define the magic object for this room');
  Writeln('N   Change how the room Name prints');
  Writeln('O   Edit the object drop description (for drop effects)');
  Writeln('P   Edit the Primary room description [the default one]');
  Writeln('R   Rename the room');
  Writeln('S   Edit the Secondary room description');
  Writeln('T   Set the trapdoor direction and chance');
  Writeln('X   Define a mystery message');
  Writeln('Y   Set a secondary mystery message');
  Writeln('Z   Change the amounts available in a shop.');

  Writeln;
  Writeln('V   View settings on this room');
  Writeln('Q/E Quit/Exit');
  IF Privd THEN
  BEGIN
    Writeln(',   Set a room attribute');
    Writeln('>   Delete a room attribute');
    Writeln('1/2   Set window');
    Writeln('A   Set special action');
  END;
  Writeln('?   This list');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoRename(VAR AllStats : AllMyStats; VAR HereDesc : RoomDesc);

VAR
  Dummy : INTEGER;
  NewName, S : String;
  Nam : LongNameRec;
  Privd : BYTE_BOOL;

BEGIN
  Privd := AllStats.Stats.Privd;
  Writeln('This room is named ',HereDesc.nicename);
  Writeln;
  GrabLine('New name: ', NewName,AllStats, , ShortLen);
  IF (Length(NewName) = 0) THEN
    Writeln('No changes.')
  ELSE
    IF LookupRoomName(newname, Dummy, TRUE, true) AND (NOT Privd) THEN
      Writeln(newname,' is not a unique room name.')
    ELSE
      HereDesc.NiceName := NewName;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ViewRoom(HereDesc : RoomDesc; AllStats : AllMyStats);

VAR
  S : String;
  tmp,I : INTEGER;
  Where : ShortString;
  ObjName : ShortNameRec;
  
BEGIN
  Writeln;
  WITH HereDesc DO
  BEGIN
    Writeln('Room:        ',nicename);
    PrintParticle(NamePrint, 'precedes roomname.', AllStats);
    Writeln('Room owner:    ', OwnTrans(Owner));
    Writeln('Alignment:     ', ReturnAlignment(Alignment, tmp));
        
    Write('Primary description is set   : ');
    Writeln(Primary <> 0);
    Write('Secondary description is set : ');
    Writeln(Secondary <> 0);
  
    CASE Which OF
      0: Writeln('Only the primary description will print');
      1: Writeln('Only the secondary description will print');
      2: Writeln('Both the primary and secondary descriptions will print');
      3: BEGIN
           Writeln('The primary description will print, followed by the seconary description');
           Writeln('if the player is holding the magic object');
         END;
      4: BEGIN
           Writeln('If the player is holding the magic object, the secondary description will print');
           Writeln('  Otherwise, the primary description will print');
         END;
      OTHERWISE Writeln('The way the room description prints is damaged');
    END;
  
    Writeln;
    FOR I := 0 to maxroomtype do
      if check_bit(heredesc.spcroom, I) then
        Writeln('Room type   : [',  heredesc.mag[i]:0, ']  ',
                GetRoomType(I));
    IF MagicObj <> 0 THEN BEGIN
      GetShortName(s_na_objnam, objname);
      Writeln('Magic object: ', Objname.idents[magicobj]);
    END;
  
    IF ObjDrop <> 0 THEN
    BEGIN
      GetRoomName(objdrop, where);
      Writeln('Dropped objects go to: ', Where ,' - ');
      Write('Drop description set : ');
      Writeln(ObjDesc <> 0);
      Write('Destination description set: ');
      Writeln(ObjDest <> 0);
    END;

    IF TrapTo <> 0 THEN
      Writeln('The trapdoor sends players ',Direct[TrapTo], ' with a chance factor of ',trapchance:1,'%');
    Write('Special action: ');
    IF Special_act in [1..maxcmds] THEN
      Writeln(get_command_by_number(special_act))
    ELSE
    IF -Special_act in [1..MaxAtmospheres] THEN
      Writeln(Atmosphere[-special_act].trigger)
    ELSE
      Writeln('none');
  
    FOR I := 1 TO MaxDetail DO
      IF Length(Detail[I]) > 0 THEN
      BEGIN
        Write('Detail "',detail[i],'" ');
        IF DetailDesc[I] > 0 THEN
          Writeln('has a description')
        ELSE
          Writeln('has no description');
      END;
    Writeln;
  END;  (* With *)
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoWindow(WindowNum : INTEGER; VAR HereDesc : RoomDesc;
                   VAR AllStats : AllMyStats);

VAR
  TargName : ShortString;
  TargNum, N : INTEGER;
  S : String;
  WindRoomDesc : RoomDesc;
  OneLiner : LineRec;
  RoomNum : INTEGER;

BEGIN
  RoomNum := AllStats.Stats.Location;
  IF (HereDesc.WindowDesc[Windownum] <>0) THEN
  BEGIN
    IF (GetRoomDesc(HereDesc.Window[WindowNum], WindRoomDesc)) THEN
    BEGIN
      TargName := WindRoomDesc.NiceName;
      IF GetLine(-HereDesc.WindowDesc[WindowNum], OneLiner) THEN
      BEGIN
        Writeln('The window looks at room ', TargName,' with this description:');
        Writeln(OneLiner.Line);
      END;
    END;
  END;
 
  IF GetName(nt_long, l_na_roomnam, 'New room: ', targnum,,AllStats) THEN
    IF TargNum = RoomNum THEN
      TargNum := 0;
  Writeln('Enter a new window description, # for people.');
  MakeLine(HereDesc.windowdesc[windownum],'window',AllStats);
  IF HereDesc.WindowDesc[WindowNum] = 0 THEN
    HereDesc.Window[WindowNum] := 0
  ELSE
    HereDesc.Window[WindowNum] := TargNum;
  IF SaveRoomDesc(RoomNum, HereDesc) THEN
    LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNum);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CustomRoom(RoomNum : INTEGER; VAR AllStats : AllMyStats);

VAR
  Done, OK : BYTE_BOOL;
  Prompt, S, Name : String;
  N, NewDsc : INTEGER;
  HereDesc : RoomDesc;
  Here : Room;
  ObjName : ShortNameRec;
  Obj : ObjectRec;
  Nam : LongNameRec;
  Privd : BYTE_BOOL;
  DummyShort : ShortString;
  Itmp : INTEGER;

BEGIN
  Privd := AllStats.Stats.Privd;
  Name := AllStats.Stats.Name;
  Done := FALSE;
  IF IsRoomOwner(RoomNum, Privd, FALSE) THEN
  BEGIN
    IF GetroomDesc(RoomNum, HereDesc) THEN
    BEGIN
      REPEAT
        GrabLine('Custom '+HereDesc.NiceName+'> ',S,AllStats, , 1);
        S := Lowcase(S);
        IF (Length(S) = 0) THEN
          S := 'q';
        CASE S[1] OF
	  'c'  :  BEGIN
		    GrabLine('Room Alignment? ', S, AllStats);
		    Itmp := LookUpAlign(S);
		    IF Itmp <> 0 THEN
		       HereDesc.alignment := Itmp * align_thres
                    ELSE
		       BadAlignment;
		  END;
          'q'  : BEGIN
                   IF GrabYes('Really quit? ', AllStats) THEN
                     Done := TRUE
                   ELSE
                     Writeln('Quit aborted.');
                 END;
          'e'  : IF SaveRoomDesc(RoomNum, HereDesc) AND
                    SetRoomName(RoomNum, HereDesc.NiceName) THEN
                      Done := TRUE;
          '?'  : RoomHelp(Privd);
          '1'  : DoWindow(1, HereDesc, AllStats);
          '2'  : DoWindow(2, HereDesc, AllStats);
          'r'  : DoRename(AllStats, HereDesc);
          '>'  : IF CheckPrivs(Privd, Name) THEN
                 BEGIN
                   ListRoomTypes;
                   Grab_Num('Type of room to delete? ', Itmp, -1,
                            maxroomtype,  -1, AllStats);
                   if (Itmp>=0) then
                     ClearBit(HereDesc.SpcRoom, Itmp);
                 END;
          'v'  : ViewRoom(HereDesc, AllStats);
          ','  : IF CheckPrivs(Privd, Name) THEN
                 BEGIN
                   ListRoomTypes;
                   Grab_Num('Type of room to add? ', Itmp, -1,
                            maxroomtype,  -1, AllStats);
                   if (Itmp >= 0) then begin
                      setbit(heredesc.spcroom, itmp);
                      Grab_num('Room magnitude? ', HereDesc.mag[Itmp],,,,
                               AllStats);
                   end;
                 END;
          't'  : BEGIN
                   GrabLine('What direction does the trapdoor exit through? ',
                            S, AllStats);
                   IF Length(S) > 0 THEN
                   BEGIN
                     LookupDir(HereDesc.Trapto, S);
                     IF (HereDesc.TrapTo <> 0) THEN
                     BEGIN
                       Writeln('Enter the chance that the player will fall');
                       Writeln('through the trapdoor (0-100) :');
                       Writeln;
                       Grab_Num('% Chance: ', HereDesc.trapchance,0,100,
                                HereDesc.trapchance,AllStats);
                     END
                     ELSE
                       HereDesc.TrapChance := 0;
                   END
                   ELSE
                   BEGIN
                     HereDesc.TrapTo := 0;
                     HereDesc.TrapChance := 0;
                   END;
                 END;
          'a'  : IF CheckPrivs(Privd, Name) THEN
                 BEGIN
                   GrabLine('Special action> ',s,AllStats);
                   HereDesc.Special_Act := Lookup_Command(S);
                   IF HereDesc.Special_Act = 0 THEN
                     HereDesc.Special_Act := -LookupAtmosphere(S);
                   IF HereDesc.Special_Act <> 0 THEN
                     EditDesc(HereDesc.Special_Effect,'person''s actions',AllStats)
                   ELSE
                   IF GrabYes('Deallocate description? ',AllStats) THEN
                     DeallocateDesc(hereDesc.special_effect);
                 END;
          's'  : IF EditDesc(hereDesc.secondary,'secondary room',AllStats) THEN;
          'p'  : IF EditDesc(hereDesc.primary,'primary room',AllStats) THEN;
          'f'  : IF EditDesc(hereDesc.ofail,'exit fail',AllStats) THEN;
          'o'  : IF MakeLine(hereDesc.objdesc,'object drop',AllStats) THEN;
          'x'  : IF MakeLine(hereDesc.rndmsg,'random message',AllStats) THEN;
          'y'  : IF EditDesc(hereDesc.xmsg2,'alternate mystery',AllStats) THEN;
          'b'  : IF MakeLine(hereDesc.objdest,'bounced in (# = object name)',
                             AllStats) THEN;
          'm'  : BEGIN
                   IF GetShortName(s_na_objnam, ObjName) THEN
                     IF HereDesc.MagicObj = 0 THEN
                       Writeln('there is currently no magic object for this room.')
                     ELSE
                       Writeln(ObjName.Idents[hereDesc.magicobj],
                               ' is currently the magic object for this room.');
                   Writeln;
                   IF GetName(nt_short, s_na_objnam,'New magic object? ',
                              HereDesc.magicobj,,AllStats) THEN;
                 END;
          'g'  : BEGIN
                   IF HereDesc.ObjDrop = 0 THEN
                     Writeln('Objects dropped fall here.')
                   ELSE BEGIN
                     GetRoomName(HereDesc.ObjDrop, DummyShort);
                     Writeln('Objects dropped fall in ', DummyShort, '.');
                   END;
                   Writeln;
                   GetName(nt_long, l_na_roomnam,'Room dropped objects go do? ',
                           n, RoomNum,AllStats);
                   OK := TRUE;
                   IF (N <> 0) AND (N <> RoomNum) THEN
                     IF (check_bit(heredesc.spcroom, rm$b_store)) THEN
                       OK := FALSE;
                   IF OK THEN
                   HereDesc.ObjDrop := N;
                 END;
          'd'  : BEGIN
                   Writeln('0)  Print primary (main) description only [default]');
                   Writeln('1)  Print only secondary description.');
                   Writeln('2)  Print both primary and secondary descriptions togther.');
                   Writeln('3)  Print primary description first; then print secondary description only if');
                   Writeln('    the player is holding the magic object for this room.');
                   Writeln('4)  Print secondary if holding the magic obj; print primary otherwise');
                   Writeln;
                   Grab_Num('How to print description? ',hereDesc.which,
                            0,4,hereDesc.which,AllStats);
                 END;
          'n'  : BEGIN
                   Write('0) ');  PrintParticle(0, 'No name is shown.', 
                                                AllStats);
                   Write('1) ');  PrintParticle(1, '...', AllStats);
                   Write('2) ');  PrintParticle(2, '...', AllStats);
                   Write('3) ');  PrintParticle(3, '...', AllStats);
                   Write('4) ');  PrintParticle(4, '...', AllStats);
                   Write('5) ');  PrintParticle(5, '...', AllStats);
                   Write('6) ');  PrintParticle(6, '...', AllStats);
                   Writeln;
                   Grab_Num('How name prints ',hereDesc.nameprint,0,6,
                          HereDesc.nameprint,AllStats);
                 END;
          'z'  : BEGIN
                   IF GetRoom(RoomNum, Here) THEN
                     FOR N := 1 TO MaxObjs DO
                       IF Here.Objs[N] MOD 1000 <> 0 THEN
                       BEGIN
                         Obj := GlobalObjects[Here.Objs[N] MOD 1000];
                         Writeln('There were ',Here.ObjHide[N],' of them.');
                         S := 'New number of '+ Obj.ObjName + ': ';
                         Grab_Num(S,Here.objhide[n],-1,99999,Here.objhide[n],AllStats);
                         IF SaveRoom(RoomNum, Here) THEN;
                       END;
                 END;
          OTHERWISE inform_badcmd;
        END;
      UNTIL Done;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomExitHelp(Privd : BYTE_BOOL := FALSE);
BEGIN
  Writeln;
  Writeln('A   Set an Alias for the exit');
  Writeln('C   Conceal an exit');
  Writeln('D   Edit the exit''s main Description');
  Writeln('E   EXIT custom (saves changes)');
  Writeln('F   Edit the exit''s failure line');
  Writeln('I   Edit the line that others see when a player goes Into an exit');
  Writeln('K   Set the object that is the Key to this exit');
  Writeln('L   Automatically look [default] / don''t look on exit');
  Writeln('O   Edit the line that people see when a player comes Out of an exit');
  Writeln('Q   QUIT Custom (throw away changes)');
  Writeln('R   Require/don''t require alias for exit; ignore direction');
  Writeln('S   Edit the success line');
  Writeln('T   Alter Type of exit (passage, door, etc)');
  Writeln('V   View exit information');
  Writeln('X   Require/don''t require exit name to be a verb');
  IF Privd THEN
    Writeln('W   What happens when you go through the exit');
  Writeln('?   This list');
  Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE AnalyzeExit(Dir : INTEGER; HereDesc : RoomDesc);

VAR
  X, Y : INTEGER;
  S : String;
  DummyShort : ShortString;
  ObjName : ShortNameRec;
  RoomName : LongNameRec;

BEGIN
  Writeln;
  WITH HereDesc.Exits[Dir] DO
  BEGIN
    IF Alias <> '' THEN
      S := '('+Alias
    ELSE
      S := '(no alias';
    IF ReqAlias THEN
      S := S + ' required)'
    ELSE
      S := S + ')';
  
    IF Toloc <> 0 THEN
    BEGIN
      GetRoomName(toloc, dummyshort);
      Writeln('The ',direct[dir],' exit ',s,' goes to ', DummyShort);
    END
    ELSE
      Writeln('The ',direct[dir],' exit goes nowhere.');
    Writeln('Hidden   : ', Hidden <> 0);
    Writeln('Exit type: ', GetExitType(Kind));
    IF ObjReq <> 0 THEN
      IF GetShortName(s_na_objnam, ObjName) THEN
        Writeln('Required object is: ',ObjName.Idents[ObjReq])
      ELSE
        Writeln('Required object is: unknown - error');

    Writeln;
    IF ExitDesc = DEFAULT_DESC THEN BEGIN
      GetLongName(l_na_roomnam, roomname);
      ExitDefault(Dir, Kind, Toloc, RoomName);
    END
    ELSE
      PrintDesc(exitdesc);
     
    IF Success = 0 THEN
      Writeln('(no success message)')
    ELSE
      PrintDesc(success);
  
    IF Fail = DEFAULT_DESC THEN
      IF Kind = EK_ACCEPTOR THEN
        Writeln('There isn'' an exit there yet.')
      ELSE
        Writeln('You can''t go that way.')
    ELSE
      PrintDesc(Fail);
  
    IF ComeOut = DEFAULT_DESC THEN
      Writeln('# has come into the room from: ',direct[dir])
    ELSE
      PrintDesc(comeout);
  
    IF Goin = DEFAULT_DESC THEN
      Writeln('# has gone ',direct[dir])
    ELSE
      PrintDesc(goin);
  
    Writeln;
    Writeln('Look automatically done : ', AutoLook);
    Writeln('Require alias to be verb: ', ReqVerb);
    EffectDecompress(Y, X, DoorEffect);
    Writeln('Type: ',x,'  Power:',y);
    Writeln;
  END;  (* With *)
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE GetKey(Dir : INTEGER; VAR HereDesc : RoomDesc;
                 VAR AllStats : AllMyStats);

VAR
  S : String;
  N : INTEGER;
  ObjName : ShortNameRec;

BEGIN
  IF GetShortName(s_na_objnam, ObjName) THEN
  BEGIN
    Writeln('Key: ');
    IF HereDesc.Exits[Dir].ObjReq = 0 THEN
      Writeln('none')
    ELSE
      Writeln(ObjName.idents[hereDesc.exits[dir].objreq]);
    N := HereDesc.Exits[Dir].ObjReq;
    GetName(nt_short, s_na_objnam,'What object is the door key? ', N, ,AllStats);
    HereDesc.Exits[Dir].ObjReq := N;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CustomExit(Dir : INTEGER; VAR AllStats : AllMyStats);

VAR
  S: String;
  Done : BYTE_BOOL;
  N, Temp, X, Y : INTEGER;
  HereDesc : RoomDesc;
  RoomNum : INTEGER;
  Privd : BYTE_BOOL;
  Dummy_s, Name : String;
  Dummy : INTEGER;

BEGIN
  RoomNum := AllStats.Stats.Location;
  Privd := AllStats.Stats.Privd;
  Name := AllStats.Stats.Name;
  Done := TRUE;
  IF GetRoomDesc(RoomNum, HereDesc) THEN
    IF CanAlterExit(Dir, RoomNum, Privd) THEN
    BEGIN
      Writeln('Customizing ',direct[dir],' exit in ',HereDesc.NiceName);
      Writeln;
      Done := FALSE;
    END
    ELSE
      Writeln('You are not allowed to alter that exit.');
  WHILE NOT(Done) DO
  BEGIN
    GrabLine('Custom '+direct[dir]+'> ',s,AllStats, , 1);
    S := lowcase(S);
    IF Length(S) = 0 THEN
      S := 'q';
    CASE S[1] OF
      '?'   : CustomExitHelp(Privd);
      'q'   : IF GrabYes('Really quit? ', AllStats) THEN
                Done := TRUE
              ELSE
                Writeln('Quit cancelled.');
      'e'   : IF SaveRoomDesc(RoomNum, HereDesc) THEN
              BEGIN
                LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNum);
                Done := TRUE;
              END;
      'k'   : GetKey(Dir, HereDesc, AllStats);
      'c'   : IF EditDesc(HereDesc.Exits[Dir].Hidden,'hidden exitfound',
                          AllStats) THEN;
      'r'   : IF CheckPrivs(Privd, Name) THEN
                DoToggle(HereDesc.Exits[Dir].ReqAlias,
                        'The alias will #be required to reference this exit.');
      'x'   : DoToggle(HereDesc.Exits[Dir].ReqVerb,
                      'The exit name will #be required to be used as a verb.');
      'l'   : DoToggle(HereDesc.Exits[Dir].AutoLook,
                 'A LOOK will #be done after someone moves through the exit.');
      'a'   : BEGIN
                GrabLine('Alternate name for the exit?',
                         dummy_s, AllStats, , VeryShortLen);
                HereDesc.Exits[dir].alias := substr(dummy_s, 1, dummy_s.length);
                HereDesc.Exits[Dir].Alias := Lowcase(HereDesc.Exits[Dir].Alias);
              END;
      'v'   : AnalyzeExit(Dir, HereDesc);
      't'   : BEGIN
                Writeln;
                Write('Select the type of your exit:');
                PrintExitTypes;
                Writeln;
                Grab_Num('Which type? ',Dummy,0,8,,AllStats);
                IF ((HereDesc.Exits[Dir].Kind IN [0,1,4,7]) OR (Privd)) THEN
                BEGIN                                       
                  HereDesc.Exits[Dir].Kind := Dummy;
                  IF (HereDesc.Exits[Dir].Kind IN [2,3,6]) THEN
                    GetKey(Dir, HereDesc, AllStats);
                END
                ELSE
                  Writeln('Sorry, that is a privd selection.');
              END;
      'f'   : IF EditDesc(HereDesc.Exits[Dir].Fail,'failure',AllStats) THEN;
      'i'   : IF EditDesc(HereDesc.Exits[Dir].Goin,
                          'go in (# = player name)',AllStats) THEN;
      'o'   : IF EditDesc(HereDesc.Exits[Dir].Comeout,
                              'come out (# = player name)',AllStats) THEN;
      'd'   : IF MakeLine(hereDesc.exits[dir].exitdesc,'look',AllStats) THEN;
      'w'   : IF CheckPrivs(Privd, Name) THEN
              BEGIN
                Writeln('Valid exit effects');
                Writeln('1  experience +/-');
                Writeln('2  wealth +/-');
                Writeln('3  bankwealth +/-');
                Writeln('4  health +/-');
                Writeln('5  mana +/-');
                Writeln('6  exp set');
                Writeln('7  class set and reset');
                Writeln('8  class set same level');
                Writeln('9  alarmed');
                Writeln('10 health <');
                Writeln('11 guardian');
                Writeln('12 modified experience');
                EffectDecompress(y,x,HereDesc.exits[dir].dooreffect);
                Writeln('Current values:  Type: ',x,'  Power:',y);
                Writeln;
                Grab_Num('Type ',n,1,12,,AllStats);
                Grab_Num('Amount ',x,,,,AllStats);
                EffectCompress(x,n,temp);
                HereDesc.Exits[Dir].DoorEffect := Temp;
              END;
      's'   : IF EditDesc(HereDesc.Exits[Dir].Success,'success',AllStats) THEN;
      OTHERWISE inform_badcmd;
    END; (* CASE *)
  END; (* WHILE *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoAccept(S : String; VAR AllStats : AllMyStats);

VAR
  Dir : INTEGER;
  HereDesc : RoomDesc;

BEGIN
  IF GetRoomDesc(AllStats.Stats.Location, HereDesc) THEN
  BEGIN
    IF LookupDir(Dir, S) THEN
    BEGIN
      IF CanMakeExit(Dir, AllStats.Stats.Location, FALSE,
                     AllStats.Stats.Privd) THEN
      BEGIN
        HereDesc.Exits[Dir].Kind := EK_ACCEPTOR;
        IF SaveRoomDesc(AllStats.Stats.Location, HereDesc) THEN
        BEGIN
          LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '',
                   AllStats.Stats.Location);
          Writeln('Someone will be able to make an exit ',direct[dir],'.');
        END;
      END;
    END
    ELSE
      Writeln('To allow others to make an exit, type ACCEPT <direction of exit>.');
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoRefuse(S : String; VAR AllStats : AllMyStats);

VAR
  Dir : INTEGER;
  OK : BYTE_BOOL;
  HereDesc : RoomDesc;

BEGIN
  IF GetRoomDesc(AllStats.Stats.Location, HereDesc) THEN
  BEGIN
    IF IsRoomOwner(AllStats.Stats.Location, AllStats.Stats.Privd, FALSE) THEN
    BEGIN
      IF LookupDir(Dir, S) THEN
      BEGIN
        WITH HereDesc.Exits[Dir] DO
        BEGIN
          IF (Kind = ek_acceptor) THEN
          BEGIN
            Kind := ek_noexit;
            OK := TRUE;
          END
          ELSE
            OK := FALSE;
        END;
        IF OK THEN
        BEGIN
          IF SaveRoomDesc(AllStats.Stats.Location, HereDesc) THEN
          BEGIN
            LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '',
                     AllStats.Stats.Location);
            Writeln('Exits ',Direct[Dir],' will be refused.');
          END;
        END
        ELSE
          Writeln('Exits were not being accepted there.');
      END
      ELSE
        Writeln('To undo an Accept, type REFUSE <direction>.');
    END
    ELSE
      Writeln('To undo an Accept, type REFUSE <direction>.');
  END
  ELSE
    Writeln('To undo an Accept, type REFUSE <direction>.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE NukeExit(Dir : INTEGER; VAR HereDesc : RoomDesc);

BEGIN
  WITH HereDesc.Exits[Dir] DO
  BEGIN
    DeallocateDesc(exitdesc);
    Exitdesc := DEFAULT_DESC;
    DeallocateDesc(fail);
    Fail := DEFAULT_DESC;
    DeallocateDesc(success);
    Success := DEFAULT_DESC;
    DeallocateDesc(comeout);
    Comeout := DEFAULT_DESC;
    DeallocateDesc(goin);
    Goin := DEFAULT_DESC;
    DoorEffect := 0;
    Objreq := 0;
    DeallocateDesc(hidden);
    Hidden := 0;
    ReqAlias := FALSE;
    ReqVerb := FALSE;
    AutoLook := TRUE;
    Alias := '';
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE RemoveExit(Dir : INTEGER; VAR HereDesc : RoomDesc; RoomNum : INTEGER;
                     Slot : INTEGER; Name : String; Privd : BYTE_BOOL := FALSE);

VAR
  TargRoom,
  TargSlot : INTEGER;
  DestRoomDesc : RoomDesc;

BEGIN
  TargRoom := HereDesc.Exits[Dir].Toloc;
  TargSlot := HereDesc.Exits[Dir].Slot;
  HereDesc.Exits[Dir].Toloc := 0;
  NukeExit(Dir, HereDesc);
  IF (HereDesc.Owner = Userid) OR (Privd) THEN
    HereDesc.Exits[Dir].Kind := 0
  ELSE
    HereDesc.Exits[Dir].Kind := EK_ACCEPTOR;
  IF SaveRoomDesc(RoomNum, HereDesc) THEN
    LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNum);

  IF GetRoomDesc(TargRoom, DestRoomDesc) THEN
  BEGIN
    IF (DestRoomDesc.Exits[TargSlot].Toloc = RoomNum) THEN
    BEGIN
      NukeExit(TargSlot, DestRoomDesc);
      DestRoomDesc.Exits[TargSlot].Toloc := 0;
      IF (DestRoomDesc.Owner = Userid) OR (Privd) THEN
        DestRoomDesc.Exits[TargSlot].Kind := EK_NOEXIT
      ELSE
        DestRoomDesc.Exits[TargSlot].Kind := EK_ACCEPTOR;
      IF SaveRoomDesc(TargRoom, DestRoomDesc) THEN
        LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', TargRoom);
    END;
  END;
  Writeln('Exit destroyed.');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoUnlink(S : String; AllStats : AllMyStats);

VAR
  Dir : INTEGER;

BEGIN
  IF LookupDir(Dir, S) THEN
  BEGIN
    IF CanAlterExit(Dir, AllStats.Stats.Location, AllStats.Stats.Privd) THEN
    BEGIN
      IF HereDesc.Exits[Dir].Toloc = 0 THEN
        Writeln('There is no exit there to unlink.')
      ELSE
        RemoveExit(Dir, HereDesc, AllStats.Stats.Location, AllStats.Stats.Slot,
                   AllStats.Stats.Name, AllStats.Stats.Privd);
    END
    ELSE
      Writeln('You are not allowed to remove that exit.');
  END
  ELSE
    Writeln('To remove an exit, type UNLINK <direction of exit>.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DelRoom(RoomNum : INTEGER);

VAR
  I : INTEGER;
  RoomName : LongNameRec;
  RoomOwn : LongNameRec;
  HereDesc : RoomDesc;

BEGIN
  IF GetRoomDesc(RoomNum, HereDesc) THEN
    FOR I := 1 TO MaxExit DO
      NukeExit(I, HereDesc);
  WITH HereDesc DO
  BEGIN
    DeallocateDesc(Primary);
    Primary := 0;
    DeallocateDesc(Secondary);
    Secondary := 0;
    DeallocateDesc(Ofail);
    Ofail := 0;
    DeallocateDesc(ObjDesc);
    Objdesc := 0;
    DeallocateDesc(RndMsg);
    Rndmsg := 0;
    DeallocateDesc(ObjDest);
    Objdest := 0;
    DeallocateDesc(WindowDesc[1]);
    Windowdesc[1] := 0;
    DeallocateDesc(WindowDesc[2]);
    Windowdesc[2] := 0;
    DeallocateDesc(Special_effect);
    Special_effect := 0;
  END;
  Deallocate(i_room,RoomNum);  { return room to free list }
  IF SaveRoomDesc(RoomNum, HereDesc) THEN
    LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNum);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE InitRoom(VAR HereDesc : RoomDesc; VAR Here : Room; S : String);

VAR
  I : INTEGER;
  RandAccept : INTEGER;

BEGIN
  HereDesc := ZERO;
  Here := ZERO;
  WITH HereDesc DO
  BEGIN
    Special_Act := 0;
    Owner := Userid;
    Nicename := S;
    Nameprint := 1;
    Primary := 0;
    Secondary := 0;
    Which := 0;
    Special_Effect := 0;
    Magicobj := 0;
    Parm := 0;
    FOR I := 1 TO MaxExit DO
      InitExit(I, HereDesc);
    Objdrop := 0;
    Objdesc := DEFAULT_DESC;
    ObjDest := DEFAULT_DESC;
    FOR I := 1 TO MaxWindow DO
    BEGIN
      Window[I] := 0;
      Windowdesc[I] := DEFAULT_DESC;
    END;
    FOR I := 1 TO MaxDetail DO
    BEGIN
      Detail[i] := '';
      Detaildesc[i] := DEFAULT_DESC;
    END;
    Trapto := 0;
    Trapchance := 0;
    RndMsg := DEFAULT_DESC;
    Xmsg2 := DEFAULT_DESC;
    Spcroom := 0;
    FOR I := 0 TO 31 DO
      Mag[I] := 0;
    ExitFail := DEFAULT_DESC;
    Ofail := DEFAULT_DESC;
    ExitAlignment := 50;
    FOR I := 1 to MAXEXIT DO
       DummySpare[I] := 0;
    Alignment := 50;
    RandAccept := Rnd(6);
    Exits[RandAccept].Kind := EK_ACCEPTOR;
  END;  (* WITH *)

  WITH Here DO
  BEGIN
    FOR I := 1 TO Maxpeople DO
      Here.People[I] := ZERO;
    FOR I := 1 TO MaxObjs DO
    BEGIN
      Objs[I] := 0;
      ObjHide[I] := 0;
    END;
    Goldhere := 0;
    For I := 1 TO MAXEXIT DO
      ExitBlocked[I] := 0;
    Extra1 := 0;
  END; (* WITH *)
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CreateRoom(S : String);

VAR
  Roomno : INTEGER;
  Dummy : INTEGER;
  I, Z : INTEGER;
  RandAccept:integer;
  Here : Room;
  HereDesc : RoomDesc;
  RoomName, RoomOwn : LongnameRec;
  Good : BYTE_BOOL;

BEGIN
  IF LookUpRoomName(s, dummy, TRUE, TRUE) THEN
    Writeln('That room name has already been used.  Please give a unique room name.')
  ELSE
  IF Allocate(i_room,roomno) THEN
  BEGIN
    Good := FALSE;
    InitRoom(HereDesc, Here, S);
    IF SaveRoom(RoomNo, Here) AND SaveRoomDesc(RoomNo, HereDesc) THEN
    BEGIN
      LogEvent(0, 0, E_READ_ROOMDESC, 0, 0, 0, 0, '', RoomNo);
      IF SetRoomName(RoomNo, Lowcase(S)) THEN
        IF SetRoomOwner(RoomNo, LowCase(Userid)) THEN
        BEGIN
          Writeln('Room created.');
          Good := TRUE;
        END;
    END;
    IF NOT(Good) THEN
    BEGIN
      Writeln('Unable to create room - internal error.');
      Deallocate(I_Room, RoomNo);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE DoCreateRoom(S : String; VAR AllStats : AllMyStats);

VAR
  CurRooms : INTEGER;
  Here : Room;
  S_String : ShortString;

BEGIN
  IF AllowRoomOwnership(AllStats.Stats.Log, Userid) THEN
  BEGIN
    IF LinksPossible(AllStats.Stats.Location, AllStats.Stats.Privd) THEN
    BEGIN
      IF Length(S) = 0 THEN
        GrabLine('Room name: ', S, AllStats, , ShortLen);
      IF Length(S) = 0 THEN
        Writeln('Please enter the name of the room next time.')
      ELSE
        Createroom(S);
    END
    ELSE
    BEGIN
      Writeln('You may not create any new exits here.  Go to a place where you can create');
      Writeln('an exit before making a new room.');
    END;
  END
  ELSE
    Writeln('You may not create any more rooms.');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ClearPeople(Loc : INTEGER);

VAR
  I : INTEGER;
  AnInt : IntArray;

BEGIN
  IF GetInt(N_LOCATION, AnInt) THEN
  BEGIN
    FOR I := 1 TO MaxPlayers DO
      IF AnInt[I] = LOC THEN
        Anint[I] := 1;
    IF SaveInt(N_Location, AnInt) THEN;
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION Findnumexits(HereDesc : RoomDesc) : INTEGER;

VAR
  I : INTEGER;
  Sum : INTEGER;

BEGIN
  Sum := 0;
  FOR I := 1 TO MaxExit DO
    IF HereDesc.Exits[I].Toloc <> 0 THEN
      Sum := Sum + 1;
  FindNumExits := Sum;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ZapRoom(Loc : INTEGER; AllStats : AllMyStats);

VAR
  HereDesc : RoomDesc;
  OldRoom : Room;

BEGIN
  OldRoom := here;
  IF GetRoomDesc(Loc, HereDesc) AND GetRoom(Loc, Here) THEN
  BEGIN
    IF IsRoomOwner(Loc, AllStats.Stats.Privd, FALSE) THEN
    BEGIN
      ClearPeople(loc);
      IF FindNumPeople = 0 THEN 
      BEGIN
        IF FindNumExits(HereDesc) = 0 THEN  
        BEGIN
          IF FindNumObjs = 0 THEN 
          BEGIN
            DelRoom(Loc);
            Writeln('Room deleted.');
          END
          ELSE Writeln('You must remove all of the objects from that room first.');
        END 
        ELSE Writeln('You must delete all of the exits from that room first.');
      END 
      ELSE Writeln('Sorry, you cannot destroy a room if people are still in it.');
    END 
    ELSE Writeln('You are not the owner of that room.');
  END;
  here := oldroom;
END;

(* -------------------------------------------------------------------------- *)

END.
