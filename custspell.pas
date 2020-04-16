[INHERIT ('MONCONST', 'MONTYPE', 'MONGLOBL')]

MODULE CustSpell(OUTPUT);

%include 'headers.txt'

FUNCTION IsReal(Num : String) : BYTE_BOOL;
VAR
  Dummy : REAL;
BEGIN
  Readv(Num, Dummy, ERROR := CONTINUE);
  IsReal := StatusV = 0;
END;

FUNCTION Realize (Num : String) : INTEGER;
VAR
  Dummy : REAL;
BEGIN
  Readv(Num, Dummy, Error := CONTINUE);
  Realize := ROUND(Dummy*100);
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ShowSpellEffects;

BEGIN
  Writeln('1)  Cure poison');
  Writeln('2)  Strength');
  Writeln('3)  Speed');
  Writeln('4)  Invisibility');
  Writeln('5)  See invisible');
  Writeln('6)  Heal');
  Writeln('7)  Hurt');
  Writeln('8)  Sleep');
  Writeln('9)  Push');
  Writeln('10) Announce');
  Writeln('11) Command (Warning: Executes with privs)');
  Writeln('12) Distance hurt');
  Writeln('13) Detect magic');
  Writeln('14) Find person');
  Writeln('15) Locate ');
  Writeln('16) Weak');
  Writeln('17) Slow');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ViewEffect(VAR Spell : SpellRec; EffectNum : INTEGER);

BEGIN
  if spell.effect[effectnum].prompt then writeln('There is a prompt.') else
  writeln('There is no prompt.');
  if spell.effect[effectnum].caster then writeln('The spell will affect the caster.')
  else writeln('The spell will not go out of it''s way to affect the caster.');
  if spell.effect[effectnum].all then writeln('The spell will affect everyone.')
  else writeln('The spell will affect one person.');
  write('Spell effect: ');
  case spell.effect[effectnum].effect of
  1:write('Cure poison');
  2:write('Strength');
  3:write('Speed');
  4:write('Invisibility');
  5:write('See invisible');
  6:write('Heal');
  7:write('Hurt');
  8:write('Sleep');
  9:write('Push');
  10:write('Announce');
  11:write('Command');
  12:write('Distance hurt');
  13:write('Detect magic');
  14:write('Find person');
  15:write('Locate');
  16:write('Weak');
  17:write('Slow');
  otherwise write('<no effect>');
  end;
  with spell.effect[effectnum] do
    writeln('  ',m1:4,' / ',m2:4,' / ',m3:4,' / ',m4:4);
end;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomSpellEffectHelp;

BEGIN
  Writeln('A - All people in room affected.');
  Writeln('C - Caster affected.');
  Writeln('E - Spell effect.');
  Writeln('N - Name of effect');
  Writeln('P - Prompt required.');
  Writeln('S - Command executes with Privs?');
  Writeln('V - View Effect Options');
  Writeln('1 - Spell parm 1 (Base magnitudes)');
  Writeln('2 - Spell parm 2 (Level attributes)');
  Writeln('3 - Spell parm 3 (Random magnitudes/base time)');
  Writeln('4 - Spell parm 4 (Random level magnitudes/level time');
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomSpellEffect(Sn : INTEGER; VAR Spell : SpellRec;
                            VAR AllStats : AllMyStats);

VAR
  EffectNum, N : INTEGER;
  G, S : String;
  Done : BYTE_BOOL;

BEGIN
  Done := FALSE;
  Grab_Num('Spell effect number, (0 for failure effect)', EffectNum, 0,
           MaxSpellEffect, -1, AllStats);
  IF EffectNum IN [0..MaxSpellEffect] THEN
  REPEAT    
    GrabLine('Spell effect>',s,AllStats, , 1);
    IF S = '' THEN
      S := 'q';
    S := LowCase(s);
    CASE S[1] OF
      '?'  : CustomSpellEffectHelp;
      'v'  : ViewEffect(Spell, EffectNum);
      'q'  : Done := TRUE;
      's'  : BEGIN
	       Spell.CommandPriv := NOT
			Spell.CommandPriv;
               Write('The spell''s command will ');
	       IF NOT Spell.CommandPriv THEN
                  Write('not ');
	       Writeln('execute with priv''s.');
	     END;
      'p'  : BEGIN
	       Spell.Effect[EffectNum].Prompt := NOT
                                                 Spell.Effect[EffectNum].Prompt;
	       IF Spell.Effect[EffectNum].Prompt THEN
                 Writeln('The spell will request a target prompt.')
	       ELSE
                 Writeln('The spell will not prompt for a target.');
	     END;
      'c'  : BEGIN
	       Spell.Effect[EffectNum].Caster := NOT
                    Spell.Effect[EffectNum].Caster;
               IF Spell.Effect[EffectNum].Caster THEN
                 Writeln('The spell will affect caster.')
	       ELSE
                 Writeln('The spell won''t go out of it''s way to affect the caster.');
	     END;
      'a'  : BEGIN
	       Spell.Effect[EffectNum].All := NOT Spell.Effect[EffectNum].All;
	       IF Spell.Effect[EffectNum].All THEN
                 Writeln('The spell will affect everyone.')
	       ELSE
                 Writeln('The spell won''t affect everyone.');
	     END;
      'e'  : BEGIN
	       ShowSpellEffects;
	       Grab_Num('Spell effect:',n,0,17,spell.effect[effectnum].effect,
                         AllStats);
	       Spell.Effect[EffectNum].Effect := N;
      	     END;
      'n'  : BEGIN
	       Writeln('** for no change');
	       IF Spell.Effect[Effectnum].Name <> '' THEN
		 Writeln('Current name:',spell.effect[effectnum].name);
	       GrabLine('New name: ',s,AllStats, , ShortLen);
	       IF S <> '**' THEN
                 Spell.Effect[Effectnum].Name := S
	       ELSE
                 Writeln('No changes.');
	     END;
      '1'  : BEGIN
	       CASE  Spell.Effect[EffectNum].Effect OF
	        sp_announce : BEGIN
			        Writeln('0 All rooms, normal');
			        Writeln('1 A group (M2) ');
			        Writeln('2 A single person');
                                Writeln('3 Announce');
                                Writeln('4 Message');
			        G := 'Announce type';
		              END;
	        sp_push	    : G := 'Direction spell will push';
	        sp_weak,
	        sp_strength : G := 'Strength modifier';
	        sp_slow,
	        sp_speed    : G := 'Speed modifier';
	        sp_heal	    : G := 'Heal base';
	        sp_hurt,
                sp_dist	    : G := 'Damage base';
	        sp_sleep    : G := 'Base sleep time';
                sp_cure     : G := 'Cure (0) or Poison (1)';
	        otherwise     G := 'useless parameter';
	       END;
	       GrabLine(G + ': ',s,AllStats);
               IF IsReal(S) THEN
               BEGIN
                 N := Realize(s);
                 IF G <> 'Base sleep time' THEN
                   N := Round(n/100);
	         Spell.Effect[EffectNum].M1 := N;
	       END;
             END;
      '2'  : BEGIN
	       CASE Spell.Effect[EffectNum].Effect OF
                 sp_weak,
	         sp_strength : G := 'Level strength modifier';
	         sp_slow,
		 sp_speed    : G := 'Level speed modifier';
		 sp_heal     : G := 'Level heal base';
		 sp_hurt     : G := 'Level damage base';
		 sp_dist     : G := 'Random damage';
		 sp_sleep    : G := 'Level base sleep time';
                 sp_announce : IF Spell.Effect[EffectNum].M1 = 1 THEN
                                 G := 'Group to cast to'
                               ELSE
                                 G := 'useless parameter';
		 OTHERWISE     G := 'useless parameter';
	       END;
	       GrabLine(g+': ',s,AllStats);
               IF IsReal(S) THEN
               BEGIN
                 N := Realize(s);
                 IF G <> 'Level base sleep time' THEN
                   N := Round(n/100);
	         Spell.Effect[EffectNum].M2 := N;
	       END;
             END;
      '3'  : BEGIN
	       CASE Spell.Effect[EffectNum].Effect OF
                 sp_weak,
	         sp_slow,
	         sp_strength,
		 sp_speed,
		 sp_invisible,
		 sp_seeinvisible  : G := 'Base time spell lasts';
	         sp_heal          : G := 'Random heal';
	         sp_hurt          : G := 'Random damage';
         	 sp_dist          : G := 'Spell range';
	         sp_sleep         : G := 'Random sleep time';
	         OTHERWISE          G := 'useless parameter';
	       END;
	       GrabLine(g+': ',s,AllStats);
               IF IsReal(S) THEN
               BEGIN
                 N := Realize(s);
                 IF (G <> 'Random sleep time') AND
                    (G <> 'Base time spell lasts') THEN
                   N := Round(n/100);
	         Spell.Effect[EffectNum].M3 := N;
	       END;
             END;
      '4'  : BEGIN
	       CASE Spell.Effect[EffectNum].Effect OF
                 sp_slow,
                 sp_weak,
	         sp_strength,
                 sp_speed,
                 sp_invisible,
                 sp_seeinvisible  : G := 'Random time spell lasts';
	         sp_heal          : G := 'Random level heal';
	         sp_hurt          : G := 'Random level damage';
	         sp_dist : BEGIN
		             G := 'Spell behavior';
		             Writeln('0 Normal');
		             Writeln('1 Bounces off walls');
		             Writeln('2 Returns to caster!');
		             Writeln('3 Damages entire path');
		           END;
	         sp_sleep         : G := 'Random level sleep time';
	         OTHERWISE          G := 'useless parameter';
	       END;
	       GrabLine(G +': ',s,AllStats);
               IF IsReal(S) THEN
               BEGIN
                 N := Realize(s);
                 IF (G <> 'Random time spell lasts') AND
                    (G <> 'Random level sleep time') THEN
                 N := Round(n/100);
	         Spell.Effect[EffectNum].M4 := N;
               END;
	     END;
    END;  (* Case Statement *)
  UNTIL Done;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomSpellHelp;

BEGIN
  Writeln('A Alignment');
  Writeln('C Class that can cast');
  Writeln('D Caster''s message'); 
  Writeln('E Edit spell effects'); 
  Writeln('F Failure message');
  Writeln('G Group that can cast');
  Writeln('L Minimum level');
  Writeln('M Mana drain');
  Writeln('N Spell name');
  Writeln('O Object required');
  Writeln('P Percent failure');
  Writeln('R Room to be in');
  Writeln('S Silent');
  Writeln('T Casting time');
  Writeln('U Need to memorize');
  Writeln('V Views spell');
  Writeln('X Object consumed');
  Writeln('Z Reveals');
  Writeln('1 Victim''s message');
  Writeln('2 Spell Command');
END;

(* -------------------------------------------------------------------------- *)

FUNCTION YesNo(Thing : BYTE_BOOL) : ShortString;

BEGIN
  IF Thing THEN YesNo := 'Yes'
  ELSE YesNo := 'No';
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE CustomSpellView(VAR Spell : SpellRec);

VAR
  Nam : LongNameRec;
  Class : ClassRec;
  i,tmp   : INTEGER;
  DummyShort : ShortString;

BEGIN
  Writeln('Spell name          ',spell.name);
  Write('Spell Effect        ');
  FOR i := 0 TO MaxSpellEffect DO
  BEGIN
    Write(i:1,': ');
    CASE spell.effect[i].effect OF
      1  : Write('Cure poison');
      2  : Write('Strength');
      3  : Write('Speed');
      4  : Write('Invisibility');
      5  : Write('See invisible');
      6  : Write('Heal');
      7  : Write('Hurt');
      8  : Write('Sleep');
      9  : Write('Push');
      10 : Write('Announce');
      11 : Write('Command');
      12 : Write('Distance hurt');
      13 : Write('Detect magic');
      14 : Write('Find person');
      15 : Write('Locate');
      16 : Write('Weak');
      17 : Write('Slow');
    OTHERWISE Write('<no effect>');
    END;
    IF I < MaxSpellEffect THEN
      Write(', ');
  END;
  Writeln;

  Write('Alignment           '); PrintAlignment(spell.alignment);
  Writeln('Mana drain          ',spell.mana:0);
  Writeln('Level mana drain    ',spell.levelmana:0);
  Writeln('Percent failure     ',spell.chanceoffailure:0);
  Writeln('Minimum level       ',spell.minlevel:0);
  Writeln('Casting time        ',spell.castingtime:0);
  Writeln('Group that can cast ',spell.group:0);
  Write  ('Class that can cast ');
  IF Spell.Class <> 0 THEN
  BEGIN
    IF GetClass(Spell.Class, Class) THEN
      Writeln(Class.Name);
  END
  ELSE
    Writeln('Any class.');
  Write  ('Room to be in       ');
  IF Spell.Room <> 0 THEN BEGIN
    GetRoomName(spell.room, DummyShort);
    Writeln(DummyShort);
  END
  ELSE
    Writeln('Any room.');
  Write  ('Object required     ');
  IF Spell.ObjRequired <> 0 THEN
    Writeln(ObjPart(spell.objrequired))
  ELSE
    Writeln('None.');
  Writeln('Object consumed     ',YesNo(spell.objconsumed));
  Writeln('Need to memorize    ',YesNo(spell.memorize));
  Writeln('Silent              ',YesNo(spell.silent));
  Writeln('Reveals             ',YesNo(spell.reveals));
  Writeln('Command             ',Spell.Command);
  Writeln('    Exec''s w/privs? ', YesNo(spell.CommandPriv));
  Writeln('Caster''s message:');
  BlockSubs(spell.casterdesc,'[victim''s name]');
  Writeln('Victim''s message:');
  BlockSubs(spell.victimdesc,'[caster''s name]');
  Writeln('Failure message:');
  BlockSubs(spell.failuredesc,'[caster''s name]');
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CustomSpell(Sn : INTEGER; VAR AllStats : AllMyStats);

VAR
  Itmp,N : INTEGER;
  S : String;
  Done : BYTE_BOOL;
  Spell : SpellRec;
  SpellNam : ShortNameRec;
  Privd : BYTE_BOOL;

BEGIN
  Privd := AllStats.Stats.Privd;
  Done := FALSE;
  IF Privd THEN
  BEGIN
    Spell := GlobalSpells[Sn];
    REPEAT
      GrabLine(Spell.Name + '> ',S,AllStats, , 1);
      IF S = '' THEN 
        S := 'q';
      S := Lowcase(s);
      CASE S[1] OF
   	'v'  :  CustomSpellView(Spell);
        '?'  :  CustomSpellHelp;
	'e'  :  CustomSpellEffect(Sn, Spell,AllStats);
        'q'  :  Done := TRUE;
        '2'  :  GrabLine('Command: ', Spell.Command, AllStats);
        'n'  :  BEGIN
	          Writeln('Current spell name:',spell.name);
                  GrabLine('Change to: ',s,AllStats, , ShortLen);
                  IF NOT LookUpName(nt_short, s_na_spell, n, s) THEN
	    	    IF S <> '' THEN
		    BEGIN
		      Spell.Name := S;
                      IF GetShortName(s_NA_Spell, SpellNam) THEN
                      BEGIN
		        SpellNam.Idents[Sn] := Lowcase(s);
                        IF SaveShortName(s_NA_Spell, SpellNam) THEN;
                      END;
                    END
	          ELSE Writeln('A spell by that name already exists.')
	        END;
	'm'  :  BEGIN            
                  Grab_Num('Mana drain: ',n,,,,AllStats);
	          Spell.Mana := N;
	          Grab_Num('Level mana drain: ',n,,,,AllStats);
	          Spell.LevelMana := N;
 	        END;
	'd'  :  IF EditDesc(spell.casterdesc ,'caster''s',AllStats) THEN;
	'1'  :  IF EditDesc(spell.victimdesc ,'target''s',AllStats) THEN;
	'a'  :  BEGIN
		  GrabLine('Spell Alignment? ', S, AllStats);
		  Itmp := LookUpAlign(S);
		  IF Itmp <> 0 THEN
		    spell.alignment := Itmp * align_thres
		  ELSE
		    BadAlignment;
		END;
        'f'  :  IF EditDesc(spell.failuredesc ,'failure',AllStats) THEN;
    	'l'  :  Grab_Num('Minimum level: ',spell.minlevel,,,,AllStats);
	'c'  :  Grab_Num('Class that can cast: ',spell.class,,,,AllStats);
	'g'  :  Grab_Num('Group that can cast: ',spell.group,,,,AllStats);
	'r'  :  IF GetName(nt_long, l_na_roomnam, 'Room required to be in: ',
                           spell.room,, AllStats) THEN;
	'p'  :  Grab_Num('Chance of failure:',spell.chanceoffailure,0,100,
                         0,AllStats);
	't'  :  BEGIN
                  GrabLine('Casting time: ', S, AllStats);
                  IF IsReal(S) THEN
                    Spell.CastingTime := Realize(S)
                  ELSE
                    Writeln('Invalid time.');
                END;
	'o'  :  IF GetName(nt_short, s_na_objnam, 'OBJECT required for spell ',
                          Spell.ObjRequired,,AllStats) THEN;
	'x'  :  BEGIN
	          Spell.ObjConsumed := NOT Spell.ObjConsumed;
	          IF Spell.ObjConsumed THEN
                    Writeln('Object will be consumed.')
	          ELSE
                    Writeln('Object will not be consumed.');
	        END;
	's'  :  BEGIN
	          Spell.silent := not spell.silent;
                  IF Spell.Silent THEN 
                    Writeln('Spell will be silent.')
	          ELSE
                    Writeln('Spell will not be silent.');
                END;
 	'u'  :  BEGIN
	          Spell.Memorize := NOT Spell.Memorize;
                  IF Spell.Memorize THEN
                    Writeln('Spell must be memorized.')
	          ELSE
                    Writeln('The spell does not have to be memorized.');
	        END;
	'z'  :  BEGIN
                  Spell.Reveals := NOT Spell.Reveals;
                  IF Spell.Reveals THEN
                    Writeln('Spell will reveal caster.')
                  ELSE
                    Writeln('Spell will not reveal caster.')
	        END;
      END;
    UNTIL Done;
    IF SaveSpell(SN, Spell) THEN
      LogEvent(0, 0, E_READSPELL, 0, 0, SN, 0, '', R_ALLROOMS);
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE ZeroSpell(VAR Spell : SpellRec);

VAR
  I : INTEGER;

BEGIN
  WITH Spell DO
  BEGIN
    Mana := 0;
    LevelMana := 0;
    Casterdesc := DEFAULT_DESC;
    Victimdesc := DEFAULT_DESC;
    Alignment := DEFAULT_ALIGN;
    Failuredesc := DEFAULT_DESC;
    Minlevel := 0;
    Class := 0;
    Group := 0;
    Room := 0;
    Chanceoffailure := 0;
    Castingtime := 0;
    Objrequired := 0;
    Objconsumed := FALSE;
    Silent := FALSE;
    Reveals := TRUE;
    Memorize := FALSE;
  END;
  FOR I := 0 TO MaxSpellEffect DO
  WITH Spell.Effect[I] DO
  BEGIN
    Effect := 0;
    Name := '';
    All := FALSE;
    Caster := FALSE;
    Prompt := FALSE;
    M1 := 0;
    M2 := 0;
    M3 := 0;
    M4 := 0;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CreateSpell(S : String; VAR Stat : StatType);

VAR
  N : INTEGER;
  Spell : SpellRec;
  SpellNam : ShortNameRec;

BEGIN
  IF Stat.Privd THEN
  BEGIN
    IF Allocate(i_spell, N) THEN
    BEGIN
      ZeroSpell(Spell);
      Spell.Name := s;
      IF SaveSpell(N, Spell) THEN
      BEGIN
        IF GetShortName(s_na_spell, SpellNam) THEN
        BEGIN
          SpellNam.Idents[N] := Lowcase(S);
          IF SaveShortName(s_na_spell, Spellnam) THEN
          BEGIN
            Writeln('Done');
            LogEvent(0, 0, E_READSPELL, 0, 0, N, 0, '', R_ALLROOMS);
          END
          ELSE
          BEGIN
            Writeln('Error saving spell names.  Deallocating.');
            Deallocate(I_SPELL, N);
            IF DeleteSpell(N, Spell) THEN;
          END
        END
        ELSE
        BEGIN
          Writeln('Error reading spell names.  Deallocating.');
          Deallocate(I_SPELL, N);
          IF DeleteSpell(N, Spell) THEN;
        END;
      END
      ELSE
      BEGIN
        Writeln('Error saving spell.  Deallocating.');
        Deallocate(I_SPELL, N);
      END;
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE ZapSpell(SpellNum : INTEGER);

VAR
  Spell : SpellRec;

BEGIN
  Spell := GlobalSpells[SpellNum];
  DeallocateDesc( Spell.casterdesc);
  DeallocateDesc( Spell.victimdesc);
  DeallocateDesc( Spell.failuredesc);
  Deallocate( I_SPELL, Spellnum);
END;

END.
