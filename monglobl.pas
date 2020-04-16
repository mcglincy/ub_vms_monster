[INHERIT ('MONCONST','MONTYPE','MONRAND'), environment ('monglobl')]

MODULE MonGlobl;

VAR
(* ------------------------------------------------------------------------- *)

  F_Names : ARRAY[1..NumberFiles] OF String := ('events.mon','roomdesc.mon',
      'character.mon','lnam.mon','snam.mon','rsnam.mon','desc.mon',
      'randoms.mon','intfile.mon','monsters.mon','spells.mon','objects.mon',
      'index.mon','line.mon','universe.mon','atmosphere.mon','kills.mon',
      'rooms.mon');

(* ------------------------------------------------------------------------- *)

  AR : AllRabType := ZERO;
  AF : AllFabType := ZERO;

  EventFile : FILE OF EventArray;
  RoomDescFile : FILE OF RoomDesc;
  RealShortNameFile : FILE OF RealShortNameRec;
  ShortNameFile : FILE OF ShortNameRec;
  LongNameFile : FILE OF LongNameRec;
  DescFile : FILE OF DescRec;
  UnivFile : FILE OF Universe;
  IndexFile : FILE OF IndexRec;
  LineFile : FILE OF LineRec;
  IntFile : FILE OF IntArray;
  ObjFile : FILE OF ObjectRec;
  SpellFile : FILE OF SpellRec;
  MonsterFile : FILE OF ClassRec;
  CharFile : FILE OF CharRec;
  AtmosFile : FILE OF AtmosphereRec;
  KillFile : FILE OF KillRec;
  RoomFile : FILE OF Room;
  RandFile : FILE OF RandRec;

(* ------------------------------------------------------------------------- *)

        Atmosphere : ARRAY[1..MaxAtmospheres] OF AtmosphereRec;

(* ------------------------------------------------------------------------- *)

  conjin  : ARRAY [1..11] of shortstring :=
    ('am','was','i','my','you''ve','your','are','you''re','yours','you','me');

  conjout : ARRAY [1..11] of shortstring :=
    ('are','were','you','your','i''ve','my','am','i am','mine','me','you');

(* ------------------------------------------------------------------------- *)

     Alignments: array[1..MaxAlign] of shortstring := (

		'good',		{ align_good }
		'neutral',	{ align_nuetral }
		'evil'		{ align_evil }

		);

(* ------------------------------------------------------------------------ *)

 KilledGuardian : ARRAY [1..MaxExit] OF BYTE_BOOL;

(* ------------------------------------------------------------------------ *)

 Direct : ARRAY[1..MaxExit] OF String :=
         ('north','south','east','west','up','down');

 DirectShort : ARRAY[1..MaxExit] OF String :=
	 ('n','s','e','w','u','d');

(* ------------------------------------------------------------------------ *)

(* A list of all of the things that an object is able to affect *)
(* I.E. Their named representation *)

	stat: array[1..maxstat] of shortstring := (
'group specific','class specific','base health','level health','base mana',
'level mana','base steal','level steal','move silent','level move silent',
'move speed','heal speed','attack speed','claw base dmg','claw random dmg',
'claw level dmg','spell to cast','experience gain','weapon usage','size',
'hear noise','level weapon usage','poison chance','control','invisibility',
'see invisible','base damage','random damage','base armor','deflect armor',
'spell armor','smallest fit','largest fit','condition','breakchance',
'breakmagnitude','charges','magic spell','spell destroy %','throw base damage',
'throw random damage','throw range','throw behavior','cursed','UNUSED-2',
'UNUSED-3','no throw','bomb base damage','bomb random damage','bomb fuse time',
'UNUSED-4','trap','UNUSED-5','UNUSED-6','UNUSED-7',
'UNUSED-8','drop destroy','crystal radius','teleporter','UNUSED-9');

(* ------------------------------------------------------------------------ *)

(* A list of all of the "places" that an object can be equipped *)
(* I.E. Their named representation *)

	Equipment: ARRAY [0..MaxEquipment] of ShortString :=(
'Not Equippable','Sword hand','Shield hand','Two handed','Body',
'Head','Eyes','Neck','Back','Upper Torso','Arms','Wrist','Ring',
'Hands','Waist','Legs','Feet','Backpack','Pouch','Quiver');

(* ------------------------------------------------------------------------ *)

   MidNightNotYet : BYTE_BOOL := FALSE;

(* ------------------------------------------------------------------------ *)

   All : AllMyStats := ZERO;
   Debug : [global] ARRAY[1..DEBUG_MAX] OF BYTE_BOOL :=
           (FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);

(* We read all of the stats on objects spells monsters and randoms into *)
(* memory at the beggining of the game *)
   GlobalSpells : ARRAY[1..MaxSpells] OF SpellRec;
   GlobalObjects : ARRAY[1..MaxIndex] OF ObjectRec;
   GlobalClasses : ARRAY[1..MaxClasses] OF ClassRec;
   GlobalRandoms : ARRAY[1..MAXRANDOMS] OF RandRec;

(* ------------------------------------------------------------------------ *)

	RSN : ARRAY[1..RSNR_MAX] OF RealShortNameRec;
	SN  : ARRAY[1..S_NA_MAX] OF ShortNameRec;
	LN  : ARRAY [1..L_NA_MAX] OF LongNameRec;
	Short_name_loaded : BOOLEAN := FALSE;
	RealShort_name_loaded : BOOLEAN := FALSE;
	Long_name_loaded : BOOLEAN := FALSE;

(* ------------------------------------------------------------------------ *)

  in_chan : $UWORD;

(* ------------------------------------------------------------------------ *)
(* The following stuff was added adhoc, because we switched from reading *)
(* characters by SMG routines, to reading them through mailboxes *)

CONST
  NumKeys = 42;

VAR
   Code : ARRAY [1..NumKeys,1..5] OF INTEGER := ZERO;
   Name : ARRAY [1..NumKeys] OF INTEGER := ZERO;
   List : ARRAY [1..7] OF ItemListCell := ZERO;

(* ------------------------------------------------------------------------ *)

   HereDesc : RoomDesc;  (* Many routines assume that this is current! *)
   Here : Room;          (* This is assummed to be current by many routines *)

(* ------------------------------------------------------------------------ *)

END.
