[INHERIT ('monconst','montype','monglobl')]

MODULE MonAlign(INPUT, OUTPUT);

%include 'headers.txt'

[GLOBAL]
PROCEDURE PrintAlignment( A : INTEGER; NeedNewLine : BYTE_BOOL := TRUE; 
				DoLvl : BYTE_BOOL := FALSE;
				DoValue : BYTE_BOOL := FALSE;
				Style : INTEGER := Style_Capitalized );

VAR
  tmp,tmp2 : INTEGER;

BEGIN
   IF (A >= 0) AND (A <= (align_thres*maxalign)) THEN
   BEGIN
     Write(ReturnAlignment(A, tmp, Style));
     IF DoValue THEN
	Write('   (Absolute Level: ',A:2,')');  { print the absolute level }
     IF DoLvl THEN
     BEGIN
	tmp2 := A - (align_thres * tmp);
	Write('   (Level: ', tmp2:2, ')');  { print out the alignment level }
     END;
     IF NeedNewLine THEN Writeln;
   END
   ELSE
   BEGIN
     Write('%PrintAlignment: Unknown Error');
     IF NeedNewLine THEN Writeln;
   END;
END;

(*---------------------------------------------------------------------*)

[GLOBAL]
FUNCTION ReturnAlignment( A : INTEGER; VAR Adj : INTEGER; 
				Style : INTEGER := Style_Capitalized ) 
				: STRING;

BEGIN
   IF (A >= 0) AND (A <= (align_thres*maxalign)) THEN
   BEGIN
     Adj := (A DIV align_thres);
     CASE Adj OF
	1,2,3: ReturnAlignment := Styler(Alignments[Adj], Style);
     OTHERWISE ReturnAlignment := 'Undefined';
     END;
   END
   ELSE
     ReturnAlignment := '%ReturnAlignment: Unknown Error';
END;

[GLOBAL]
PROCEDURE BadAlignment;
VAR
  I : INTEGER;
BEGIN
  Writeln('The alignment you entered is not one of:');
  FOR I := 1 TO MaxAlign DO
    WriteLn('   ',Alignments[I]);
  Writeln('No changes made.');
END;

[GLOBAL] 
PROCEDURE TallyAlignments;
(* This will count up all the players in each alignment class *)

VAR
  I : INTEGER;
  al : INTEGER;
  G, N, E, U : INTEGER;
  AllStats : AllMyStats;
  AnInt : IntArray;
  CharCoal : CharRec;
  Pers : ShortNameRec;
  Index : IndexRec;

BEGIN
  G := 0;
  N := 0;
  E := 0;
  U := 0;
  Write('Counting up alignments... ');
  IF GetShortName(s_NA_Pers, Pers) AND GetIndex(I_Player, Index) THEN; 

  FOR I := 1 TO Index.Top DO
  BEGIN
     IF Index.Free[I] = FALSE THEN
     BEGIN
        GetChar(I, CharCoal);
	CASE CharCoal.Alignment OF
	  align_nuetral: N := N + 1;
	  align_evil: E := E + 1;
	  align_good: G := G + 1;
	OTHERWISE 
          BEGIN
	    U := U + 1;
            Writeln(Pers.Idents[I],' has an undefined alignment!');
          END;
	END;
     END;
  END;
  Writeln('done.'); Writeln;
  Writeln('Good      : ', G:3, ' players.');
  Writeln('Neutral   : ', N:3, ' players.');
  Writeln('Evil      : ', E:3, ' players.');
  Writeln('Undefined : ', U:3, ' players.');
END;

END.
