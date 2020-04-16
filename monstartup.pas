[inherit ('montype','monglobl','monconst','monrand')]

MODULE StartUp;

%include 'headers.txt'

[GLOBAL]
FUNCTION OpenAllFiles(SysMaint : BYTE_BOOL) : BYTE_BOOL;

VAR
  Good : BYTE_BOOL;

BEGIN
  Good := FALSE;
  IF OpenFile(UnivFile, F_Universe, SIZE(Universe)) THEN
    IF SelectUniverse(SysMaint) THEN
      Good := TRUE;
  IF Good THEN
  BEGIN
    IF OpenFile(RoomDescFile, F_RoomDesc, SIZE(RoomDesc)) AND
       OpenFile(EventFile, F_Event, SIZE(EventArray)) AND
       OpenFile(CharFile, F_Character, SIZE(CharRec)) AND
       OpenFile(LongNameFile, F_LongName, SIZE(LongNameRec)) AND
       OpenFile(ShortNameFile, F_ShortName, SIZE(ShortNameRec)) AND
       OpenFile(DescFile, F_Desc, SIZE(DescRec)) AND
       OpenFile(RealShortNameFile, F_RealShortName,  SIZE(RealShortNameRec)) AND
       OpenFile(Intfile, F_Int, SIZE(IntArray)) AND
       OpenFile(Monsterfile, F_Monster, SIZE(ClassRec)) AND
       OpenFile(Spellfile, F_Spell, SIZE(SpellRec)) AND
       OpenFile(Objfile, F_Object, SIZE(ObjectRec)) AND
       OpenFile(Indexfile, F_Index, SIZE(IndexRec)) AND
       OpenFile(Linefile, F_Line, SIZE(LineRec)) AND
       OpenFile(Atmosfile, F_Atmosphere, SIZE(AtmosphereRec)) AND
       OpenFile(KillFile, F_Kill, SIZE(KillRec)) AND
       OpenFile(RandFile, F_Rand, SIZE(RandRec)) AND
       OpenFile(RoomFile, F_Room, SIZE(Room)) THEN
      Good := TRUE
    ELSE
      Good := FALSE;
  END;
  OpenAllFiles := Good;
END;

[GLOBAL]
PROCEDURE ReadGlobalNames;
VAR
  Loop : INTEGER;
BEGIN
  FOR Loop := 1 TO RSNR_MAX DO
    GetRealShortName(Loop, RSN[Loop]);
  FOR Loop := 1 TO S_NA_MAX DO
    GetShortName(Loop, SN[Loop]);
  FOR Loop := 1 TO L_NA_MAX DO
    GetLongName(Loop, LN[Loop]);
  Short_name_loaded := TRUE;
  Realshort_name_loaded := TRUE;
  Long_name_loaded := TRUE;
END;

END.
