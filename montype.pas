[INHERIT ('MONCONST','SYS$LIBRARY:STARLET'), ENVIRONMENT ('MONTYPE')]

MODULE MonType;

(* All type declerations for monster are handled in here *)

TYPE
  BYTE_BOOL = [BIT] BOOLEAN;
  FabPtr = ^Fab$Type;
  RabPtr = ^Rab$Type;
  AllRabType = ARRAY [1..NumberFiles] OF RabPtr;
  AllFabType = ARRAY [1..NumberFiles] OF FabPtr;

  ItemListCell = RECORD
    CASE INTEGER OF
      1 : ( Buffer_Length : [WORD] 0..65535;
            Item_Code : [WORD] 0..65535;
            Buffer_Addr : UNSIGNED;
            Return_Addr : UNSIGNED; );
      2 : ( Terminator : UNSIGNED; )
    END; (* CASE *)

  IosbType = [QUAD,UNSAFE] RECORD
    Status, 
    Word1,
    Word2,
    Word3 : [WORD] -32768..32767;
  END;

  Ident = PACKED ARRAY [1..12] OF CHAR;
  String = VARYING[NormLen] of CHAR;
  ShortString = VARYING[ShortLen] of CHAR;
  VeryShortString = VARYING[VeryShortLen] of CHAR;
  $UWORD = [WORD]0..65535;
  Unsafe_File = [UNSAFE] FILE of CHAR;

  Percentage = 0..100;

  Saying = RECORD
    KeyWord : String;    (* What word will make the random say the saying *)
    Saying : String;     (* What the random says in response to the keyword *)
  END;

  AtmosphereREC = RECORD
    Trigger	:ShortString; (* Nonsense commands to print messages on terms*)
    Isee	:String;      (* What is printed to me when i say trigger *)
    Eventsee	:String;      (* What others see when i say trigger *)
    ISeeExtra	:String;      (* What I see when i say trigegr # *)
    EventSeeExtra:String;     (* What others see when i say trigger # *)
    Owner : ShortString;      (* Who made the atmosphere command up. *)
  END;

  Exit =  RECORD
    ToLoc   : INTEGER;      { Room this exit goes to }
    Kind    : INTEGER;      { What kind of exit is this }
    Slot    : INTEGER;      { Which direction does it come out in }
    ExitDesc,               { one liner description of exit  }
    DoorEffect,             { what happens when going through a door!! }
    Fail,                   { description if can't go thru   }
    Success,                { desc while going thru exit     }
    Goin,                   { what others see when you go into the exit }
    ComeOut : INTEGER;      { what others see when you come out of the exit }
    Hidden  : INTEGER;      { if exit's hidden...block #}
    ObjReq  : INTEGER;      { object required to pass this exit }
    Alias   : VeryShortString; { alias for the exit dir, a keyword }
    ReqVerb : BYTE_BOOL;      { require alias as a verb to work }
    ReqAlias: BYTE_BOOL;      { require alias only (no direction) to }
                            { pass through the exit }
    AutoLook: BYTE_BOOL;      { do a look when user comes out of exit }
  END;

  IndexRec = RECORD
    Free:  PACKED ARRAY [1..MaxIndex] of BYTE_BOOL;  (* obvious *)
    Top: INTEGER;   { max records available }
    InUse: INTEGER; { record #s in use }
  END;

  RealShortNameRec = RECORD
    Idents : Array[1..MaxGroup] OF ShortString;
  END;

  ShortNameRec = RECORD
    Idents: ARRAY [1..MaxPlayers] of ShortString;
  END;

  LongNameRec = RECORD
    Idents: ARRAY[1..MaxRoom] of ShortString;
  END;

  ObjectRec = RECORD
    ObjName   : ShortString;   { duplicate of name of object }
    Kind      : INTEGER;       { what kind of object this is }
    LineDesc  : INTEGER;       { liner desc of object Here }
    Wear      : INTEGER;       { where object is equipped }
    Weight    : INTEGER;       { move speed modifier }
    Examine   : INTEGER;       { desc block for close inspection }
    Worth     : INTEGER;       { how much it cost to make (in gold) }
    NumExist  : INTEGER;       { number in existence }
    Sticky    : BYTE_BOOL;       { can they ever get it? }
    GetObjReq : INTEGER;       { object required to get this object }
    GetFail   : INTEGER;       { fail-to-get description }
    GetSuccess: INTEGER;       { successful picked up description }
    UseObjReq : INTEGER;       { object require to use this object }
    UseLocReq : INTEGER;       { place have to be to use this object }
    UseFail   : INTEGER;       { fail-to-use description }
    UseSuccess: INTEGER;       { successful use of object description }
    Particle  : INTEGER;       { a,an,some, etc... "particle" is not }
                               { be right, but hey, it's in the code }
    Component : ARRAY [1..MaxComponent] OF INTEGER;
                               { components of the particular object.}
    Parms : ARRAY [1..MaxParm] of INTEGER;
    D1: INTEGER;               { extra description # 1 }
    D2: INTEGER;               { extra description # 2 }
    Holdability : INTEGER;     { how easy to hold object (% to hold) }
    Alignment 	: INTEGER;
    Extra2	: INTEGER;
  END;

  AnEvent = RECORD
    Send,              { slot of sender }
    SendLog,           { log of sender }
    Action,            { what event this is, E_something }
    Targ,              { opt target of action }
    TargLog : INTEGER; { log of target }
    Param : ARRAY [1..2] OF INTEGER;
    Msg: String;    { string for SAY and other cmds }
    Loc: INTEGER;   { room that event is targeted for }
    Emsg : ShortString;
    EParam : ARRAY[1..5] OF INTEGER;
  END;
  EventArray = record
    events : ARRAY [1..NumEvents] of AnEvent;
    point : integer;
  end;

  PeopleREC = RECORD
    Kind       : INTEGER;         { Log number of the person in the slot }
    Targ       : INTEGER;         { who is the npc after? }
    DEL1       : VeryShortString; { actual userid of person }
    Name       : ShortString;     { chosen name of person }
    Hiding     : INTEGER;         { degree to which they're hiding }
    NextAct    : INTEGER;
    DEL3 : INTEGER;         { last thing that this person did }
    DEL4       : BYTE_BOOL;         { Can others see me }
    Health,
    DEL5       : INTEGER;
  END;

	ClassRec = RECORD
		Group : INTEGER;(* What group is this type *)
		Name, 		   (* What name is it on the sheet *)
	 	WhoName : ShortString; (* What do others see as the name *)
		BaseHealth,	(* MAX health at level 0 *)
 		LevelHealth,    (* Health this class gets per level *)
		BaseMana,	(* Mana this class has at level 0 *)
		LevelMana,   	(* Mana this class gets per level *)
		BaseSteal,	(* What percent of the time can i steal *)
		LevelSteal,     (* How good my steal increases per level *)
		MoveSilent,     (* How good this class moves through shadows *)
		MoveSilentLevel,(* How much the move silent raises per level *)
		MoveSpeed,      (* How fast ths class is *)
		AttackSpeed,    (* How fast can this class hit other players *)
		HealSpeed,      (* How fast does this class heal *)
		BaseDamage,     (* The minimum the 'claws' do at level 0 *)
		RndDamage,      (* How much more can I attach with claws for *)
		LevelDamage,    (* How much the claws raise per level *)
		Armor,          (* The base armor for this class *)
		ExpAdd,         (* How much exp. this class gives to other's *)
		WeaponUse,      (* How good is the class with a weapon *)
                LevelWeaponUse,
		Size,           (* How big is this class *)
		HearNoise,      (* How good at over hearing things *)
		PoisonChance,	(* How often does this class poison other's *)
		Control,        (* How well can it control it's actions *)
		MyVoid,         (* Where do this class go when I dies *)
		SpellArmor,     (* How much protection against spells *)
		MonsterType,    (* Generally used just for randoms *)
                                (* This is a bit mask to determine the *)
                                (* actions of the random. *)
                Alignment,
                HideDelay,
                ShadowDamagePercent,
                P1, P2 : INTEGER;
	END;

        EffectRec = RECORD
	  Effect	:INTEGER;   (* What type of effect is it *)
	  Name		:ShortString; (* The name of the effect *)
	  All		:BYTE_BOOL;   (* Does it hurt everyone in the room *)
	  Caster	:BYTE_BOOL;   (* Does it hurt the caster *)
	  Prompt	:BYTE_BOOL;   (* Does it ask for user input *)
	  M1,M2,M3,M4	:INTEGER;   (* The magnitude of this effect *)
        END;

        SpellRec = Record
          Name		:ShortString;   (* The spell's name *)
          Mana		:INTEGER;       (* How much mana does it cost *)
          LevelMana	:INTEGER;       (* How much mana does it cost/level *)
	  CasterDesc	:INTEGER;	(* Index of a desc. block *)
	  VictimDesc	:INTEGER;       (* Index of a desc block *)
          Alignment	:INTEGER;       (* Spell Alignment *)
          FailureDesc	:INTEGER;       (* Index of a desc block *)
          MinLevel	:INTEGER;       (* Minimum level needed to cast *)
          Class		:INTEGER;       (* What class casn cast it *)
          Group		:INTEGER;       (* What group can cast it *)
	  Room		:INTEGER;       (* Where do I have to be to cast it *)
	  Effect	:ARRAY [0..MaxSpellEffect] of EffectRec; (* effects *)
	  ChanceOfFailure:INTEGER;      (* What percent of the time fails *)
          CastingTime	:INTEGER;       (* How long does it take to cast *)
          ObjRequired	:INTEGER;    (* What do I have to be holding to cast *)
          ObjConsumed	:BYTE_BOOL;       (* Is the object destroyed *)
	  Silent	:BYTE_BOOL;    (* Does it tell others I am casting it *)
	  Reveals	:BYTE_BOOL;       (* Does it reveal me *)
	  Memorize	:BYTE_BOOL;       (* Do I need to learn it *)
	  Command	:String; 	(* Command to execute *)
	  CommandPriv	:BYTE_BOOL;	(* Execute it with Privs? *)
	  Extra1, Extra2, Extra3 : INTEGER;
        END;

	DescREC = RECORD
		Lines: ARRAY [1..DescMax] of String; (* Lines in a block *)
		DescLen: INTEGER;  { number of lines in this block }
	END;

	LineRec = RECORD
           Line : String;   (* The text of a line *)
        END;

	CharREC = record
		MaxRooms	:INTEGER; (* How many rooms can i own *)
		MaxObjs		:INTEGER; (* How many objs can i own *)
		Self		:INTEGER; (* A block of text (my descrip.) *)
		Health		:INTEGER; (* What is my health *)
		Mana		:INTEGER; (* How much mana do i have *)
		Wealth		:INTEGER; (* How much money do i have *)
	 	BankWealth	:INTEGER; (* How much money is in the bank *)
		Kills		:INTEGER; (* How many kills do i have *)
		Poisoned	:BYTE_BOOL; (* Am i poisoned *)
		Spell		:ARRAY [1..MaxSpells] of INTEGER; (* spells *)
		Equip		:ARRAY [1..MaxHold] of BYTE_BOOL;
		Item		:ARRAY [1..MaxHold] of INTEGER;
		Condition	:ARRAY [1..MaxHold] of INTEGER;
		Charges		:ARRAY [1..MaxHold] of INTEGER;
                Deaths          :INTEGER; (* How many times I have died *)


		Personality	:INTEGER;

(* Personality is a bit-compress field defined as follows: 	*)
(* Bits		Function				   	*)
(* ------------------------------------------------------------ *)
(*  0 -  8	1st Most Hated Person				*)
(*  9 - 17 	2nd Most Hated Person				*)
(* 18 - 26	3rd Most Hated Person				*)
(* 27 - 28	General Disposition				*)
(*    (00)	Good/Benign (Doenst attack anyone - runs away)  *)
(*    (01)	Normal (Attacks when attacked)			*)
(*    (10) 	Patriotic (Attacks opposing classes and 	*)
(*				alignments)			*)
(*    (11)	Evil (Attacks anyone at random)			*)

		Sentry		:INTEGER;

(* The following is for Sentry Randoms 				*)
(*  0 -  1      Sentry Bits.					*)
(*    (00)	Guards a room.					*)
(*    (01)	Guards a person.				*)
(*    (10)	Guards an object.				*)
(*    (11)	Guards an exit.					*)
(*  2 - 32	Room/Person/Object #				*)
(*		If an exit then: Room # and direction		*)

		Alignment	:INTEGER;

		Memory		:INTEGER;

(* Memory is not used - be sure to change LoadStats if you      *)
(* alter this variable name 					*)

		Extra5		:INTEGER;
		Extra6		:INTEGER;
		Extra7		:INTEGER;
		Extra8		:INTEGER;
	END;

  RoomDesc = RECORD
    Special_Act	:INTEGER;
    Owner	:VeryShortString; { who owns the room }
    NiceName	:String;	{ pretty name for location }
    NamePrint	:INTEGER;	{ Preposition for room name printing }
    Primary	:INTEGER;	{ room descriptions }
    Secondary	:INTEGER;       { another description }
    Which	:INTEGER;	{ Which descrip prints prim and/or secondary }
    Special_Effect:INTEGER;     { A special effect for this room (block file) }
    MagicObj	:INTEGER;	{ special object for this room }
    Parm	:INTEGER;
    Exits	:ARRAY [1..MaxExit] of Exit;  (* The exits *)
    ObjDrop	:INTEGER;	{ where objects go when they're dropped }
    ObjDesc	:INTEGER;	{ what it says when they're dropped }
    ObjDest	:INTEGER;	{ what it says in target room when
					  "bounced" object comes in }
    Window	:ARRAY [1..MaxWindow] of INTEGER; { what rooms I can see into }
    WindowDesc	:ARRAY [1..MaxWindow] of INTEGER; { what it says }
    Detail	:ARRAY [1..MaxDetail] of VeryShortString;
    DetailDesc	:ARRAY [1..MaxDetail] of INTEGER;
    TrapTo	:INTEGER;	{ where the "trapdoor" goes }
    TrapChance	:INTEGER;	{ how often the trapdoor works }
    RndMsg	:INTEGER;	{ message that randomly prints }
    Xmsg2	:INTEGER;	{ another random block }
    SpcRoom	:INTEGER;	{ special type of room }
    Extra1	:INTEGER;	{ Special type magnitude!}
    ExitFail	:INTEGER;	{ default fail description for exits }
    OFail	:INTEGER;	{ what other's see when you fail, default }
    ExitAlignment : INTEGER;    { Bitpacked alignment of room exits }
    DUMMYSPARE    : ARRAY [1..MaxExit] OF INTEGER;
    Alignment   : INTEGER;	{ Bitpacked alignment of room itself }
    RandomShow	: INTEGER;
    Extra2 	: INTEGER;
    Mag : ARRAY [0..31] of INTEGER;
  END;

  Room = RECORD
    People	:ARRAY [1..MaxPeople] of PeopleRec; { people in the room }
    Objs	:ARRAY [1..MaxObjs] of INTEGER;	{ refs to object file }
    ObjHide	:ARRAY [1..MaxObjs] of INTEGER;	{ how much an object is hidden }
    GoldHere	:INTEGER;	{ gold in the room }
    ExitBlocked :ARRAY [1..MaxExit] OF INTEGER;
    Extra1      : INTEGER;
  END;

  IntArray	 = ARRAY [1..MaxPlayers] of INTEGER; (* class/location/... *)

  Universe = RECORD
    Name		:ShortString;  (* Name of the universe *)
    Desc		:String;       (* A description of the universe *)
    UnivSpecificOps	:ARRAY [1..MaxUnivSpecificOps] of String;
    Daemon              :ShortString;
    Random              :ShortString;
  END;

  StatType = RECORD
    RealId,
    Userid : VeryShortString;     (* What userid am i playing *)

    Privd : BYTE_BOOL;		  (* Am I privd *)
    Sysmaint : BYTE_BOOL;           (* Am I a  system Maintenance person *)
    LoggedAct : BYTE_BOOL;          (* Am I doing a special action *)
    InGame : BYTE_BOOL;             (* Is this actually a game session *)

    LastHit : Integer;            (* who did i hit last *)
    LastHitString : String;       (* message for the last hit *)
    Location : INTEGER;           (* what room am i in *)
    Name : String;                (* What is my name *)

    MaxRooms : INTEGER;           (* How many rooms can i have *)
    MaxObj : INTEGER;             (* How many objects can i own *)

    Class : INTEGER;		  (* What class am I *)
    Group : INTEGER;              (* What group am i in *)
    MonsterType : INTEGER;        (* "Type" of monster that this is *)

    Slot : INTEGER;               (* the slot in the room *)
    Log : INTEGER;                (* My slot entry for the file (I_Class...) *)
    Experience : INTEGER;         (* how much experience i have *)
    Mana : INTEGER;               (* how much mana do i have *)
    Health : INTEGER;             (* how much health i have *)
    Poisoned : BYTE_BOOL;           (* Am i poisoned *)
    MoveSpeed : INTEGER;          (* How fast do i move *)
    AttackSpeed : INTEGER;        (* how fast do i attack *)
    Size : INTEGER;               (* How big am i *)
    WeaponUse : INTEGER;          (* How good am i with a weapon *)
    PoisonChance : INTEGER;       (* What is the chance of me poisoning *)
    MoveSilent : INTEGER;         (* How good can i move through shadows *)
    Steal : INTEGER;              (* Am i a good thief *)
    Wealth : INTEGER;             (* How much money do i have *)
    Bank : INTEGER;               (* How much do i have in the bank *)
    Kills : INTEGER;              (* How many people have i killed *)
    Deaths : INTEGER;             (* How many times have i died *)
    HealSpeed : INTEGER;
    Control : INTEGER;
    LastHitTime : INTEGER;	  (* Time (ms) that I was last hit *)
    Done : BYTE_BOOL;               (* Am i done playing *)
    Universe : INTEGER;           (* What universe am i in *)
    EventNum : INTEGER;           (* What event am i on *)
    AllEventNum : INTEGER;        (* What event(for all rooms) am i on *)
    Brief : BYTE_BOOL;              (* is the printing mode brief *)
    HighLight : BYTE_BOOL;
    Printed : BYTE_BOOL;
    Alignment : INTEGER;	  (* My religious affiliation *)
    Memory : INTEGER;		  (* Memories...  *)
    HideDelay : INTEGER;
    ShadowDamagePercent : INTEGER;
  END;

  HoldObj = RECORD
    Holding : ARRAY [1..MaxHold] OF INTEGER;
    Slot : ARRAY [1..MaxHold] OF INTEGER;
    Charges : ARRAY [1..MaxHold] OF INTEGER;
    Condition : ARRAY [1..MaxHold] OF INTEGER;
    Weapon : String;              (* my weapon name *)
  
    BaseArmor : INTEGER;          (* my armor *)
    DeflectArmor : INTEGER;       (* more armor *)

    SpellArmor : INTEGER;         (* yet more armor *)
    SpellDeflectArmor : INTEGER;   (* DUH! *)
    BaseDamage : INTEGER;         (* The minimum damage for each shot *)
    RandomDamage : INTEGER;       (* how much additional damage i can do *)
    BreakChanceLeft : INTEGER;    (* chance of me beraking someone's weapon *)
    BreakChanceRight : INTEGER;   (* chance of me beraking someone's weapon *)
    BreakMagnitudeLeft : INTEGER; (* how much it will break *)
    BreakMagnitudeRight : INTEGER;(* how much it will break *)
    MaxMana : INTEGER;   (* The max mana i can have - based upon obj effects *)
    MaxHealth : INTEGER;
  END;
  
  TkTimeType = RECORD
    TkInvisible : INTEGER;
    Invisible : BYTE_BOOL;
    TkSee : INTEGER;
    SeeInvisible : BYTE_BOOL;
    TkStrength : INTEGER;
    Strength : INTEGER;
    TkSpeed : INTEGER;
    MvSpeed : INTEGER;
    AttSpeed : INTEGER;
    TkHealth : INTEGER;
    Health : INTEGER;
    TkMana : INTEGER;
    Mana : INTEGER;
    TkEvent : INTEGER;
    TkAllEvent : INTEGER;
    TkRandMove : INTEGER;
    TkRandAct : INTEGER;
    TkRandomEvent : INTEGER;
  END;

  OPStuff = RECORD
    NoText : BYTE_BOOL;
    OpCheckComm : INTEGER;
    Frozen : BYTE_BOOL;
    PingAnswered : BYTE_BOOL
  END;

  CommandType = RECORD
    Line : PACKED ARRAY[1..10] OF String;
    Point : INTEGER;  (* Last command *)
    Last : INTEGER;
  END;

  FoundExitType = ARRAY[1..MaxExit] OF BYTE_BOOL;
  TimeEventType = ARRAY[1..MaxTimedEvents] OF AnEvent;

  ExitStuff = RECORD
    FoundExits : FoundExitType;
    KilledGuardian : FoundExitType;
    ExitHandled : BYTE_BOOL;
    Blocking : INTEGER;
  END;

  MemoryType = RECORD
    Room : BYTE_BOOL;
  END;

  AllMyStats = RECORD
    Stats : StatType;
    MyHold : HoldObj;
    Tick : TkTimeType;
    Op : OpStuff;
    Exit : ExitStuff;
    TimedEvents : TimeEventType;
    Commands : CommandType;
    InMem : MemoryType;
  END;

  KillRec = RECORD
    WeKilled : ARRAY [1..MaxGroup] OF INTEGER;
  END;

END.
