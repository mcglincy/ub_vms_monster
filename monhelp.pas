[INHERIT ('MONCONST', 'MONTYPE', 'MONGLOBL')]

MODULE MonHelp(INPUT, OUTPUT);

%include 'parser.pas'
%include 'headers.txt'

VAR
  NumCust : INTEGER := 16;
  CustCmds : ARRAY [1..16] OF INTEGER := (c_accept, c_alink, c_create, 
	c_claim,
	c_custom, c_desc, c_destroy, c_disown, c_duplicate, c_edit,
	c_link, c_nuke, c_objects, c_refuse, c_rooms, c_unlink);

  NumNormal : INTEGER := 42;
  NormalCmds: ARRAY [1..42] OF INTEGER := (c_attack, c_brief, c_cast, 
	c_down, c_drop, c_east, c_equip, c_express, c_get, 
	c_help, c_hide, c_highlight, c_inv, c_learn, 
	c_lob, c_look, c_make, c_north, c_operators, 
	c_pickpocket, c_ping, c_punch, 
	c_quit, c_rest, c_unhide, c_say, c_search, c_self, 
	c_sell, c_sheet, c_show, c_south, c_steal, c_throw, c_up, 
	c_use, c_version, c_wear, c_west, c_whisper, c_who, c_wield);

  NumPrivd: INTEGER := 23;
  PrivdCmds: ARRAY [1..23] OF INTEGER := (c_announce, c_change, 
	c_check, c_cia, c_class, c_copy, c_dcl, 
	c_find, c_grab, c_setnam, c_players, c_poof, 
	c_possess, c_priv, c_public, c_remotepoof, c_system, 
	c_togop, c_unblock, c_universe, c_unwho, c_whois, c_zap);

PROCEDURE HelpCommand(S : string; Privd : BYTE_BOOL);
VAR
  Cmd : String;
  CmdNum, AtmosNum : INTEGER;
BEGIN
  Cmd := Bite(S);
  Cmd := Lowcase(Cmd);

 (*  AtmosNum := LookupAtmosphere(Cmd); *)
  CmdNum := Lookup_Command(Cmd);

  CASE CmdNum OF
  (*********************** Customization Commands *************************)
  c_accept: Writeln;
  c_alink: Writeln;
  c_create: Writeln;
  c_claim: Writeln;
  c_custom:  Writeln;
  c_desc: Writeln;
  c_destroy: Writeln;
  c_disown: Writeln;
  c_duplicate: Writeln;
  c_edit: Writeln;
  c_link: Writeln;
  c_nuke:  Writeln;
  c_objects: Writeln;
  c_refuse: Writeln;
  c_rooms: Writeln;
  c_unlink: Writeln;
  (************************** Normal Commands *******************************)
  c_attack:
     BEGIN 
        Writeln('   ATTACK [Name]');
	Writeln('   Use this command to ATTACK an opponent! You must specify who you want');
	Writeln('to attack, obviously, by giving their name. Be sure to attack people of opposite alignment.');
	Writeln('More experience is awarded for vanquishing a person of opposite alignment.');
      END;
  c_brief: Writeln('   Places room descriptions in BRIEF mode. Toggle back and forth.');
  c_cast:  
      BEGIN
	Writeln('   CAST [Spell]');
	Writeln('   Cast a particular spell. You might have to LEARN it first.');
      END;
  c_drop: Writeln('   DROP an item from your inventory into the current room.');
  c_east,c_north,c_south,c_west,c_up,c_down: 
     BEGIN
	Writeln('   Typing one of these commands allows you to move in a particular');
	Writeln('direction, provided an exit exists. You can abbreviate the commands');
	Writeln('by merely typing the first letter.');
     END;
  c_equip: 
     BEGIN
	Writeln('   EQUIP [Item]');
	Writeln('   Equip (wear) a certain item. Simply having the item in your possession is');
	Writeln('not enough!');
     END;
  c_express: 
     BEGIN
	Writeln('   EXPRESS [Sentence]');
	Writeln('   Will print on other players screen an expression with your name preceding');
	Writeln('it. Example: If your name is ''Foobar'' typing ''EXP frowns deeply'' will');
	Writeln('put on other players screens: ''Foobar frowns deeply''. The other players');
	Writeln('must be in the same room as you to see the message.');
     END;
  c_get:  Writeln;
  c_help: Writeln;
  c_hide: Writeln;
  c_highlight: Writeln;
  c_inv: Writeln;
  c_learn:  Writeln;
  c_lob: Writeln;
  c_look:Writeln;
  c_make: Writeln;
  c_operators: Writeln;
  c_pickpocket: Writeln;
  c_ping: Writeln;
  c_punch: Writeln;
  c_quit: Writeln;
  c_rest: Writeln;
  c_unhide: Writeln;
  c_say:  Writeln;
  c_search: Writeln;
  c_self:Writeln;
  c_sell: Writeln;
  c_sheet: Writeln;
  c_show: Writeln;
  c_steal: Writeln;
  c_throw: Writeln;
  c_use: Writeln;
  c_version: Writeln;
  c_wear: Writeln;
  c_whisper: Writeln;
  c_who: Writeln;
  c_wield: Writeln;
  (********************* Privd Commands ************************)
  c_announce: Writeln;
  c_change: Writeln;
  c_check: Writeln;
  c_cia: Writeln;
  c_class:  Writeln;
  c_copy: Writeln;
  c_dcl: Writeln;
  c_find: Writeln;
  c_grab: Writeln;
  c_setnam: Writeln;
  c_players: Writeln;
  c_poof: Writeln;
  c_possess:Writeln;
  c_priv:Writeln;
  c_public: Writeln;
  c_remotepoof: Writeln;
  c_system: Writeln;
  c_togop: Writeln;
  c_unblock: Writeln;
  c_universe:Writeln;
  c_unwho: Writeln;
  c_whois: Writeln;
  c_zap: Writeln;
  OTHERWISE Writeln('Help not available! Command lookup failure?');
  END;
  Writeln;
END;

PROCEDURE HelpAtmosphere;
VAR
  I : INTEGER;
  Count : INTEGER;
BEGIN
  CenterText('Atmosphere Help');
  Writeln;
  CenterText('Available atmosphere commands are:');
  Writeln;
  Count := 1;
  FOR I := 1 TO MaxAtmospheres DO
  BEGIN
    IF Atmosphere[I].Trigger <> '' THEN
    BEGIN
      WriteNice(Atmosphere[I].Trigger,20);
      IF Count MOD 4 = 0 THEN
        Writeln;
      Count := Count + 1;
    END;
  END;
  Writeln; Writeln;
  Writeln('  You can use atmosphere commands several ways. Either just');
  Writeln('type the command name or type the command name with a person''s');
  Writeln('name after it to direct the command at them. You can also add');
  Writeln('your own atmosphere commands with the EDIT command. Fun for the');
  Writeln('whole family!');
  Writeln;
END;


PROCEDURE HelpCustomization;
VAR
  I : INTEGER;
  Count : INTEGER;
BEGIN
  CenterText('Customization Help');
  Writeln;
  CenterText('Available Customization commands are:');
  Writeln;
  FOR I := 1 TO NumCust DO
  BEGIN
    WriteNice(Get_command_by_number(CustCmds[I]),20);
    IF I MOD 4 = 0 THEN
      Writeln;
  END;
  Writeln; Writeln;
END;

PROCEDURE HelpNormal;
VAR
  I : INTEGER;
  Count : INTEGER;
BEGIN
  CenterText('Normal Help');
  Writeln;
  CenterText('Available Normal commands are:');
  Writeln;
  FOR I := 1 TO NumNormal DO
  BEGIN
    WriteNice(get_command_by_number(NormalCmds[I]),20);
    IF I MOD 4 = 0 THEN
      Writeln;
  END;
  Writeln; Writeln;
END;


PROCEDURE HelpPrivd;
VAR
  I : INTEGER;
  Count : INTEGER;
BEGIN
  CenterText('Privileged Help');
  Writeln;
  CenterText('Available Privd commands are:');
  Writeln;
  FOR I := 1 TO NumPrivd DO
  BEGIN
    WriteNice(get_command_by_number(PrivdCmds[I]),20);
    IF I MOD 4 = 0 THEN
      Writeln;
  END;
  Writeln; Writeln;
END;


[GLOBAL] 
PROCEDURE DoHelp(S : String;  AllStats : AllMyStats) ;
(* Main help menu                                          *)
VAR
   Privd : BYTE_BOOL;
   max,num : INTEGER;
   tmps : String;

BEGIN
  Privd := AllStats.Stats.Privd;

  CenterText('Monster Help');
  CenterText('------------');
  Writeln;
  IF S = '' THEN
  BEGIN
     CenterText('Choose one of the following catagories:');
     Writeln;
     CenterText('0 ...          Quit');
     CenterText('1 ...    Atmosphere');
     CenterText('2 ... Customization');
     CenterText('3 ...        Normal');
     max := 3;
     IF Privd THEN
     BEGIN  
       CenterText('4 ...   Priviledged');
       max := 4;
     END;
     tmps := Spaces(30) + 'Option Number? ';
     Writeln;
     Grab_Num(tmps, num, 1, max, 0, AllStats);
     Writeln; Writeln; Writeln;
     CASE num OF
       1 : HelpAtmosphere;
       2 : HelpCustomization;
       3 : HelpNormal;
       4 : HelpPrivd;
     END;
  END
  ELSE
     HelpCommand(S, Privd);

END;

END.
