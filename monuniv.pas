[Inherit ('monconst', 'montype', 'monglobl')]

MODULE MonUniv(Input, Output);

%include 'headers.txt'

PROCEDURE View_Universe (U : Universe);

VAR
  Loop : INTEGER;

BEGIN
  WITH U DO
  BEGIN
    WriteLN ('Name = ', Name);
    WriteLn ('Desc = ', Desc);
    WriteLN ('Universe Specific Ops :');
    FOR Loop := 1 TO MaxUnivSpecificOps DO
      IF UnivSpecificOps[Loop].Length <> 0 THEN
        WriteLn ('   ',UnivSpecificOps[Loop]);
  END;
END;

(* -------------------------------------------------------------------------- *)

FUNCTION ChangeOp (VAR U : Universe; Add : BYTE_BOOL) : BYTE_BOOL;

VAR
  OpName : String;
  Loop : INTEGER;
  Done : BYTE_BOOL;

BEGIN
  Done := FALSE;
  Write ('Op username to ');
  IF Add THEN
    Write('add? ')
  ELSE
    Write('remove? ');
  ReadLn (OpName);
  OpName := LowCase (OpName);
  Loop := 1;
  WHILE (Loop <= MaxUnivSpecificOps) AND (NOT Done) DO
  BEGIN
    IF U.UnivSpecificOps[Loop] = OpName THEN
    BEGIN
      IF Add THEN
        Writeln(OpName,' is already a universe specific op.')
      ELSE
      BEGIN
        U.UnivSpecificOps[Loop] := '';
        Writeln('Op removed.');
      END;
      Done := TRUE;
    END
    ELSE
      IF (U.UnivSpecificOps[Loop].LENGTH = 0) THEN
      BEGIN
        IF Add THEN
        BEGIN
          U.UnivSpecificOps[Loop] := OpName;
          Writeln('Universe specific op added.');
          Done := TRUE;
        END
        ELSE
          Loop := Loop + 1;
      END
      ELSE
        Loop := Loop + 1;
  END;
  IF NOT Done THEN
    IF Add THEN
      WriteLn ('Universe specific op table is full.')
    ELSE
      Writeln(Opname, ' was not an op.');
  ChangeOp := DONE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Rebuild_Universe : BYTE_BOOL;

VAR
  Loop: INTEGER;
  Univ : Universe;

BEGIN
  WriteLn ('Rebuilding universe file....');
  Univ := ZERO;
  WITH Univ DO
  BEGIN
    Name := 'Monster';
    Desc := 'May your blade burn red and your luck true.';
  END;  (* With *)
  Rebuild_Universe := SaveUniv(1, Univ);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION Edit_Universe : BYTE_BOOL;

VAR
  Choice : INTEGER;
  UnivNum : INTEGER;
  U : Universe;
  S : String;
  Done : BYTE_BOOL;
  Status : BYTE_BOOL;
  Index : IndexRec;

  PROCEDURE WriteMenu;

  BEGIN
    WriteLn ('--- Edit Universe Menu ---');
    WriteLn;
    WriteLn ('1) Change Universe name.');
    WriteLn ('2) Change Universe desc.');
    WriteLn ('3) Add a universe specific op.');
    WriteLn ('4) Remove a universe specific op.');
    WriteLn ('5) View Universe.');
    Writeln ('R) Rebuild the universe file.');
    WriteLn ('Q) Quit.');
  END;

  PROCEDURE GetShortString (Prompt : String; VAR S : ShortString);

  VAR
    n : String;
    UnivNum : INTEGER;

  BEGIN
    Write (Prompt);
    ReadLn (N);
    IF n = '' THEN
      WriteLn ('No change.')
    ELSE
      S := N;
  END;

  PROCEDURE GetString (Prompt : String; VAR S : String);

  VAR
    n : String;
    UnivNum : INTEGER;

  BEGIN
    Write (Prompt);
    ReadLn (N);
    IF n = '' THEN
      WriteLn ('No change.')
    ELSE
      S := N;
  END;

BEGIN
  Done := FALSE;
  Status := GetUniv(1, U);
  IF Status THEN
  BEGIN
    REPEAT
      S := ' ';
      Write ('Edit Universe> ');
      ReadLn (S);
      CASE S.Body[1] OF
        '1' : GetShortString ('Name : ', U.Name);
        '2' : GetString ('Desc : ', U.Desc);
        '3' : IF ChangeOp (U, TRUE) THEN;
        '4' : IF ChangeOp (U, FALSE) THEN;
        '5' : View_Universe (U);
        'R' : BEGIN
                Write('Are you sure you want to rebuild the universe file? ');
                ReadLn (S);
                IF S.Body[1] IN ['y','Y'] THEN 
    		  Status := Rebuild_Universe;
              END;
        '?', 'h', 'H' : WriteMenu;
        'q','Q' : Done := TRUE;
      END;  (* Case statement *)
    UNTIL Done;
    Edit_Universe := SaveUniv(1, U);
  END
  ELSE
    Edit_Universe := FALSE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION IsUnivSpecificOp (SomeOne : String) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Univ : Universe;

BEGIN
  IsUnivSpecificOp := FALSE;
  IF GetUniv(1, Univ) THEN
    FOR Loop := 1 TO MaxUnivSpecificOps DO
      IF Lowcase(Univ.UnivSpecificOps[Loop]) = LowCase (SomeOne) THEN
         IsUnivSpecificOp := TRUE;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION SelectUniverse(Privd : BYTE_BOOL) : BYTE_BOOL;

VAR
  Loop : INTEGER;
  Choice : String;
  NumbUniv : INTEGER;
  Done : BYTE_BOOL;
  Status : BYTE_BOOL;
  Counter : INTEGER;
  Univ  : Universe;

BEGIN
  Done := FALSE;
  WriteLn('Welcome to Monster.');
  WriteLn;
  REPEAT
    IF NOT GetUniv(1, Univ) THEN
    BEGIN
      IF Privd THEN
      BEGIN
        IF Rebuild_Universe THEN
          Done := FALSE
      END
      ELSE
      BEGIN
        Writeln;
        WriteLn ('There are no valid universes at this time.');
        SelectUniverse := FALSE;
        Done := TRUE;
      END;
    END
    ELSE
    BEGIN
      SelectUniverse := TRUE;
      Done := TRUE;
      Writeln('You are now traveling into the land of ',Univ.Name,'.');
      Writeln(Univ.Desc);
    END;
  UNTIL Done;
  WriteLn;
END;

END.
