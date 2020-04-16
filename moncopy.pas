[INHERIT ('monconst','montype','monglobl')]

MODULE MonCopy(OUTPUT);

%include 'headers.txt'

PROCEDURE PrintOptions;
BEGIN
  Writeln('c - class');
END;

PROCEDURE CopyClass(VAR AllStats : AllMyStats);
VAR
  From, Tos : String;
  OldClass, NewClass : INTEGER;
  Found : BYTE_BOOL;
  Class : ClassRec;
BEGIN
  GrabLine('Copy from class: ', From, AllStats);
  IF LookupName(nt_realshort, rsnr_class, OldClass, From, FALSE, FALSE) THEN
  BEGIN
    GrabLine('Copy to class: ', ToS, AllStats);
    Found := LookupName(nt_realshort, rsnr_class, NewClass, ToS, FALSE);
    IF NOT Found THEN
      Writeln('You must create the class first.')
    ELSE
    BEGIN
      IF GetClass(OldClass, Class) THEN
        SaveClass(NewClass, Class);
    END;
  END;
END;

[GLOBAL]
PROCEDURE DoCopy(S : String; VAR AllStats : AllMyStats);
VAR
  Ltype, Lsize : INTEGER;

BEGIN
  Ltype := 0;
  IF (Length(S) > 0) THEN
  BEGIN
    CASE S[1] OF
      'c' : CopyClass(AllStats);
      OTHERWISE PrintOptions;
    END;
  END ELSE PrintOptions;
END;

END.
