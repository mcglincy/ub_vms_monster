[Inherit   ('monconst', 'montype')]

MODULE MonEdit(INPUT, OUTPUT);

%include 'headers.txt'

PROCEDURE EditHelp;

BEGIN
	Writeln;
	Writeln('A	Append text to end');
	Writeln('C	Check text for correct length with parameter substitution (#)');
	Writeln('D #	Delete line #');
	Writeln('E	Exit & save changes');
	Writeln('I #	Insert lines before line #');
	Writeln('L	Print out description');
	Writeln('Q	Quit: THROWS AWAY CHANGES');
	Writeln('F	Replace text with text of file');
	Writeln('R #	Replace text of line #');
	Writeln('Z	Zap all text');
	Writeln('@	Throw away text & exit with the default description');
	Writeln('?	This list');
	Writeln;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditReplace(VAR HereDsc : DescREC; LineNumber : INTEGER;
                      VAR AllStats : AllMyStats);

VAR
  Prompt,
  ReplacementString : String;

BEGIN
  IF (LineNumber > HereDsc.DescLen) OR (LineNumber < 1) THEN
    writeln('Bad line number')
  ELSE
  BEGIN
    Writev(Prompt, LineNumber:2 ,': ');
    GrabLine(Prompt,ReplacementString,AllStats);
    IF ReplacementString <> '**' then
       HereDsc.Lines[LineNumber] := ReplacementString;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditInsert(VAR HereDsc : DescREC; LineNumber : INTEGER);

VAR
  Loop : INTEGER;

BEGIN
  IF HereDsc.DescLen = DescMax then
    Writeln('You have already used all ',DescMax:1,' lines of text.')
  ELSE
  BEGIN
    IF (LineNumber < 1) OR (LineNumber > HereDsc.DescLen) THEN
    BEGIN
      Writeln('Invalid line #; valid lines are between 1 and ',HereDsc.DescLen:1);
      Writeln('Use A (add) to add text to the end of your description.');
    END
    ELSE
    BEGIN
      FOR Loop := Heredsc.DescLen + 1 DOWNTO LineNumber + 1 DO
	HereDsc.Lines[Loop] := HereDsc.Lines[Loop-1];
      HereDsc.DescLen := HereDsc.DescLen + 1;
      Heredsc.Lines[LineNumber] := '';
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditDoInsert(VAR HereDsc : DescREC; LineNumber : INTEGER;
                       VAR AllStats : AllMyStats);

VAR
  ReplacementString : String;
  Prompt : String;

BEGIN
  IF HereDsc.DescLen = DescMax then
     Writeln('You have already used all ',DescMax:1,' lines of text.')
  ELSE 
  BEGIN
    IF (LineNumber < 1) or (LineNumber > HereDsc.DescLen) THEN
    BEGIN
      Writeln('Invalid line #; valid lines are between 1 and ',heredsc.desclen:1);
      Writeln('Use A (add) to add text to the end of your description.');
    END
    ELSE
    BEGIN
      REPEAT
        Writev(Prompt, LineNumber:1, ': ');
        GrabLine(Prompt,ReplacementString,AllStats);
        IF ReplaceMentString <> '**' THEN
        BEGIN
          EditInsert(HereDsc, LineNumber);  { put the blank line in }
          HereDsc.Lines[LineNumber] := ReplacementString;
          LineNumber := LineNumber + 1;
        END;
      UNTIL (HereDsc.DescLen = DescMax) or (ReplacementString = '**');
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditShow(HereDsc : DescREC);

VAR
  Loop : INTEGER;

BEGIN
  Writeln;
  IF HereDsc.DescLen = 0 THEN
     Writeln('[no text]')
  ELSE
    FOR Loop := 1 TO HereDsc.DescLen DO
      Writeln(Loop:2,': ',Heredsc.Lines[Loop]);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CheckSubst(HereDsc : DescREC);

VAR
  Loop : INTEGER;

BEGIN
  IF HereDsc.DescLen > 0 THEN
  BEGIN
    FOR Loop := 1 TO HereDsc.DescLen DO
      IF (Index(HereDsc.Lines[Loop],'#') > 0) AND 
	(Length(HereDsc.Lines[Loop]) > 59) THEN
    Writeln('Warning: line ',Loop:1,' may be too long for correct parameter substitution.');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE EditAppend(VAR HereDsc : DescREC; VAR AllStats : AllMyStats);

VAR
  Prompt,
  NewLine : String;
  StillAdding : BYTE_BOOL;

BEGIN
  IF HereDsc.DescLen = DescMax THEN
     Writeln('You have already used all ',DescMax:1,' lines of text.')
  ELSE
  BEGIN
    StillAdding := TRUE;
    Writeln('Enter text.  Terminate with ** at the beginning of a line.');
    Writeln('You have ',DescMax:1,' lines maximum.');
    Writeln;
    WHILE (HereDsc.DescLen < DescMax) AND (StillAdding) DO
    BEGIN
      Writev(Prompt,HereDsc.DescLen+1:2,': ');
      GrabLine(Prompt,NewLine,AllStats);
      IF NewLine = '**' THEN
         StillAdding := FALSE
      ELSE
      BEGIN
	HereDsc.DescLen := HereDsc.DescLen + 1;
	HereDsc.Lines[HereDsc.DescLen] := NewLine;
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ReplaceFromFile(VAR HereDsc : DescREC);

VAR
  Loop : INTEGER;
  TextFile : TEXT;
  FileName,
  TheLine : String;

BEGIN
  Loop := 0;
  Write('Filename (default is .txt)? ');
  Readln(FileName);
  IF Index(FileName,'.') = 0 THEN
     FileName := FileName+'.txt';
  OPEN (TextFile, FileName, HISTORY:=READONLY, ERROR:=CONTINUE);
  IF STATUS(TextFile) = 0 THEN
  BEGIN
    HereDsc.DescLen := 0;
    RESET (TextFile);
    Readln(TextFile,TheLine);
    WHILE (Loop < DescMax) AND (NOT EOF(TextFile)) DO
    BEGIN
      Loop := Loop + 1;
      HereDsc.DescLen := Loop;
      HereDsc.Lines[HereDsc.DescLen] := TheLine;
      Readln(TextFile,TheLine);
    END; {while}
    Writeln('Inserted ',HereDsc.DescLen:0,' lines.');
    CLOSE (TextFile);
  END {if}
  ELSE
    Writeln('%Error opening file: Nothing Replaced');
END; {replace_from_file}

(* -------------------------------------------------------------------------- *)

PROCEDURE EditDelete(VAR HereDsc : DescREC; LineNumber : INTEGER);

VAR
  Loop : INTEGER;

BEGIN
  IF HereDsc.DescLen = 0 THEN
     writeln('No lines to delete')
  ELSE
    IF (LineNumber > HereDsc.DescLen) OR (LineNumber < 1) THEN
       Writeln('Bad line number - ', LineNumber:0)
    ELSE
      IF (LineNumber = 1) AND (HereDsc.DescLen = 1) THEN
         HereDsc.DescLen := 0
      ELSE
      BEGIN
        FOR Loop := LineNumber TO HereDsc.DescLen-1 DO
	  HereDsc.Lines[Loop] := HereDsc.Lines[Loop + 1];
        HereDsc.DescLen := HereDsc.DescLen - 1;
      END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
FUNCTION EditDesc(VAR Dsc : INTEGER; Message : String := '';
                  VAR AllStats : AllMyStats) : BYTE_BOOL;

VAR
  Cmd : CHAR;
  S : String;
  Done : BYTE_BOOL := FALSE;
  LineNumber : INTEGER;
  OneLiner : LineRec;
  HereDsc : DescRec;
  IsBlock : BYTE_BOOL := FALSE;

BEGIN
  IF Message <> '' THEN
     Writeln('Editing ',Message,' description block.');
  IF NOT IsDescription(Dsc) THEN
  BEGIN
    Dsc := 0;
    HereDsc.DescLen := 0;
    Done := FALSE;
  END
  ELSE
  BEGIN
    IF Dsc > 0 THEN
    BEGIN
      Done := NOT GetDesc(Dsc, HereDsc);
      IsBlock := TRUE;
    END
    ELSE
    BEGIN
      IF Dsc < 0 then
      BEGIN
        Done := NOT GetLine(ABS(Dsc), OneLiner);
        HereDsc.Lines[1] := OneLiner.Line;
        HereDsc.DescLen := 1;
        IsBlock := FALSE;
      END
      ELSE
      BEGIN
        Done := TRUE;
        Writeln('Something is wrong with block_edit.');
      END;
    END;
  END;

{Done converting to block for editing}

  EditDesc := TRUE;
  IF HereDsc.DescLen = 0 THEN
    EditAppend(HereDsc, AllStats);
  WHILE NOT Done DO
  BEGIN
    Writeln;
    REPEAT
      GrabLine('EDIT> ',S,AllStats);
      S := Trim(S);
    UNTIL Length(S) > 0;
    S := LowCase(S);
    Cmd := S[1];
    S := TRIM(SUBSTR(S, 2, Length(S)-1));
    IF IsNum(S) THEN
      LineNumber := Number(S)
    ELSE
      LineNumber := 0;

    CASE Cmd OF
      '?':EditHelp;
      'a':EditAppend(HereDsc,AllStats);
      'z':HereDsc.DescLen := 0;
      'f':ReplaceFromFile(HereDsc);
      'c':CheckSubst(HereDsc);
      'l':EditShow(HereDsc);
      'd':EditDelete(HereDsc, LineNumber);
      'e':BEGIN
            CheckSubst(HereDsc);
            EditDesc := DeAllocateDesc(Dsc);

(* Set up the new description *)

	    IF HereDsc.DescLen = 1 THEN
	    BEGIN
	      IF Allocate(I_Line,Dsc) THEN
	      BEGIN
		OneLiner.Line := HereDsc.Lines[1];
                EditDesc := SaveLine(Dsc, OneLiner);
		Dsc := -Dsc;
	      END
	      ELSE
	      BEGIN
		Writeln('I could not allocate any lines.');
		EditDesc := FALSE;
	      END;
	    END
            ELSE
	    IF HereDsc.DescLen > 1 THEN
	    BEGIN
	      IF Allocate(I_Block,Dsc) THEN
	      BEGIN
		IF SaveDesc(Dsc, HereDsc) THEN
                   EditDesc := TRUE
                ELSE
                BEGIN
  		  Writeln('Error saving descrition block.');
                  EditDesc := FALSE;
                END;
	      END
	      ELSE
	      BEGIN
		Writeln('I could not allocate any blocks.');
		EditDesc := FALSE;
	      END;
	    END
            ELSE
            IF HereDsc.DescLen = 0 THEN
              Dsc := 0;
	    Done := TRUE;
	  END;
      'r':EditReplace(HereDsc, LineNumber, AllStats);
      '@':BEGIN 
	    DeAllocateDesc(Dsc);
	    Dsc := DEFAULT_DESC;
	    Done := TRUE;
            EditDesc := TRUE;
	  END;
      'i':EditDoInsert(HereDsc, LineNumber, AllStats);
      'q':IF GrabYes('Throw away changes, are you sure? ',AllStats) THEN
	  BEGIN
	    Done := TRUE;
	  END;
      OTHERWISE Inform_Badcmd;
    END;
  END;   (* WHILE Loop *)
END;

END.
