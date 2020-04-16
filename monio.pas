[inherit ('monconst','montype','sys$library:starlet')]

MODULE MonIO(OUTPUT);

%include 'headers.txt'

VAR
   sp : String := '                                                                              ';

[GLOBAL] 
PROCEDURE CenterText(S : String; Width : INTEGER := 80; 
			NewLine : BYTE_BOOL := TRUE);
VAR
   i : INTEGER;
BEGIN
   sp.length := (Width - Length(S)) DIV 2;
   Write(sp,S);
   IF NewLine THEN Writeln;
END;

END.
