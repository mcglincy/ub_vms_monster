[Environment ('monconst')]

MODULE MonConst;

CONST

(* ------------------------------------------------------------------------- *)
(* Previously, this section was in privuser.pas *)

(*  The next 5 people are privileged people inside of the game *)

PROGRAMMER_1    = 'MASLIB';             { The programmer for the game }
PROGRAMMER_2    = 'v177mbfs';           { The programmer for the game }
MM_userid	= 'masmonst';		{ Monster Manager	}
MVM_userid	= 'v063l2rq';	        { Monster Vice Manager	}
FAUST_1_userid  = 'maslib';             { Dr. Faustus           }
FAUST_2_userid	= 'yyyyyyyy';	        { Dr. Faustus		}
MPGR_userid	= 'v177mbfs';		{ The wandering programmer }

(*-----------------------------------------------------------------------*)
	vt_alphanum = 1;
	vt_alpha = 2;
	vt_numeric = 3;
(*-----------------------------------------------------------------------*)

	Style_Normal = 0;  	{ leave string as is }
	Style_Capitalized = 1; 	{ capitalize it }
	Style_AllCaps = 2; 	{ dump all in caps }
	Style_AllLower = 3; 	{ dump all in lower }

(* ------------------------------------------------------------------------- *)

(* The default number of rooms and objects that new players can create *)

MAX_ROOM	= 0;

(* Where the universe file is located *)
(* mon_disk should be define in the following format : *)
(* ------------------------------------------------------------------------- *)
(* Do not change anything below this point                                   *)
(* ------------------------------------------------------------------------- *)

(* $ define mon_disk disk:[directory] *)
(* All of the datafiles are kept in the Root directory (It is a logical) *)

Root	= 'mon_disk:';

(* Who to contact if something goes wrong *)

CONTACT_userid	= 'masmonst or masdough@ubvms.cc.buffalo.edu';

DEBUG_Max = 6;
DEBUG_Files = 1;
DEBUG_Timer = 2;
DEBUG_LogEvent = 3;
DEBUG_HandleEvent = 4;
DEBUG_Ticker = 5;
DEBUG_Room = 6;

(* ------------------------------------------------------------------------- *)
	(* What is effected by the spell/weapon/object... *)
        FX_HEALTH = 1;
        FX_WEALTH = 2;
        FX_HUNGER = 3;
        FX_CREATEOBJ = 4;
        FX_FREEZE = 5;
        FX_KILL = 6;
        FX_MANA = 7;
        FX_EXPERIENCE = 8;
        FX_CLASS = 9;
        FX_LOCATION = 10;
        FX_BANKWEALTH = 11;
        FX_NAME = 12;

(* ------------------------------------------------------------------------ *)
        (* Define a bunch of maximum values *)
        maxrandoms = 20;
	maxwindow = 2;       (* How many windows there can be in a room *)
	maxgroup = 50;       (* How many groups of players there can be *)
	maxspells = 100;     (* How many spells there can be *)
	maxspelleffect = 4;  (* How many effects a spell can have *)
        MaxUnivSpecificOps = 5; (* How many extra ops per universe *)
	maxatmospheres = 100;   { Max number of atmosphere commands }
	maxstat = 60;		{ Magical properties of items	}
	maxcomponent = 7;	{ number of object components	}
	maxconj = 11;		{ max number of conjugations	}
	maxequipment = 19;	{ max number of equipment slot types }
	maxclasses = 255;	{ max number of monster types possible }
	maxobjs = 15;		{ max objects allow on floor in a room }
	maxpeople = 10;		{ max people allowed in a room }
	maxplayers = 300;	{ max log entries to make for players }
	maxexit = 6;		{ 6 exits from each loc: NSEWUD }
	maxalign = 3;		{ 3 primary alingments: nice, nuet, naughty }
	maxroom = 1000;		{ Total maximum ever possible	}
	maxdetail = 5;		{ max num of detail keys/descriptions per room }
	maxtimedevents = 20;	{ timed events!?!? }
	numeventrec = 20;	{ event slots per mailbox } 
	maxindex = 10000;	{ top value for bitmap allocation }
	maxhold = 7;		{ max # of things a player can be holding }
	maxhide = 15;		{ max depth a person can be hidden }
	numevents = 30;		{ # of different event records to be maintained }
	numpunches = 15;	{ # of different kinds of punches there are }
	maxparm = 20;		{ parms for object USEs }
	descmax = 10;		{ lines per description block }

	c_error		= 0;
(* ------------------------------------------------------------------------ *)

	veryshortlen = 12;	{ very short string length for userid's etc }
	shortlen = 20;		{ ordinary short string }
        normlen = 80;           { normal string length }

(* ------------------------------------------------------------------------ *)

	DEFAULT_DESC = 32000;	{ A virtual one liner record number that
				  really means "use the default one liner
				  description instead of reading one from
				  the file" }

(* ------------------------------------------------------------------------ *)

	QuitWait = 30;		{ Means you must not have been attacked for
				  at least three seconds before attempting 
				  to quit. }

(* ------------------------------------------------------------------------ *)

	{ The following allignments are merely *thresholds*. As long as
	  your alignment is less than or equal to the number given, you 
	  are within that alignment }

	align_top     = 100;
	align_thres   = align_top DIV maxalign ;
	align_good    = 1 * align_thres;  {  0 .. 33 }
	align_nuetral = 2 * align_thres;  { 34 .. 66 }
	align_evil    = 3 * align_thres;  { 67 .. 99 }
	DEFAULT_ALIGN = align_nuetral;
	
(* ------------------------------------------------------------------------ *)

{ File mnemonics }

  NumberFiles  = 18;
  F_Event      = 1;
  F_RoomDesc   = 2;
  F_Character  = 3;
  F_LongName   = 4;
  F_ShortName  = 5;
  F_RealShortName = 6;
  F_Desc       = 7;
  F_Rand       = 8;
  F_Int        = 9;
  F_Monster    = 10;
  F_Spell      = 11;
  F_Object     = 12;
  F_Index      = 13;
  F_Line       = 14;
  F_Universe   = 15;
  F_Atmosphere = 16;
  F_Kill       = 17;
  F_Room       = 18;

(* ------------------------------------------------------------------------ *)

{ Mnemonics for directions }
	north = 1;
	south = 2;
	east = 3;
	west = 4;
	up = 5;
	down = 6;

(* ------------------------------------------------------------------------ *)

        RM_MAX = 10;
        RM_FIGHTER = 1;

(* ------------------------------------------------------------------------ *)

{ Index record mnemonics }
        I_MAX = 11;
	I_BLOCK = 1;	{ true if description block is not used		}
	I_LINE = 2;	{ true if line slot is not used			}
	I_ROOM = 3;	{ true if room slot is not in use		}
	I_PLAYER = 4;	{ true if slot is not occupied by a player	}
	I_ASLEEP = 5;	{ true if player is not playing			}
	I_OBJECT = 6;	{ true if object record is not being used	}
        I_CLASS = 7;    { true if class slot is not being used          }
        I_SPELL = 8;    { true if spell record is not being used        }
	I_RAND = 9;     { true is random record is not being used	}

        I_GROUPNAME = 11; { true if the group slot is not begin used    }

(* ------------------------------------------------------------------------ *)

{ Integer record mnemonics }
	num_ints = 5;		{ Number of N_Integer Records }
	n_class = 1;		{ player's class }
	n_experience = 2;	{ player's experience }
	n_location = 3;		{ room location }
	n_alignment = 4;	{ player's alignment }
	n_privd = 5;		{ is player an op? }

(* ------------------------------------------------------------------------ *)

(* Convenient ways to access some special rooms *)
	R_ALLROOMS	=  0;
	R_GREATHALL	=  1;
	R_VOID		=  2;

(* ------------------------------------------------------------------------ *)
          
{ magic attribute mnemonics }
	M_LOCATE  = 10;		{ gives player privd. WHO list }

	M_POOFING = 40;		{ allows player to "poof" }
	M_LINKING = 51;		{ allows player to link anywhere }

(* ------------------------------------------------------------------------ *)

{ object kind mnemonics }

	O_BLAND = 0;	      	{ bland object, good for keys }

	O_EQUIP= 1;
        O_SCROLL = 2;
        O_WAND   = 3;
        O_MISSILE = 7;
	O_MISSILELAUNCHER = 8;
	O_SBOOK = 104;
	O_BANKING_MACHINE = 106;

(* ------------------------------------------------------------------------ *)

        { name_types }
	nt_max = 3;
	nt_realshort = 1;
	nt_short = 2;
	nt_long = 3;

(* ------------------------------------------------------------------------ *)

	{ LongNamfile mnemonics}
	l_na_max = 2;	{max number of name records}
	l_na_roomnam = 1;	{roomname}
	l_na_roomown = 2;	{roomowner}

(* ------------------------------------------------------------------------ *)

	{ ShortNamFile mnemonics }
        s_na_max = 9;	{ Max number of short name records }
	s_na_pers = 1;	{personal name}
	s_na_user = 2;	{user id}
	s_na_objnam = 3;	{object names}
	s_na_objown = 4;	{object owners}
	s_na_date = 5;	{date of last play}
	s_na_time = 6;	{time of last play}
	s_na_rannam = 7;	{random monster names}
	s_na_spell = 8;	{spell names}
        s_na_mailbox = 9;    {mailbox names}

(* ------------------------------------------------------------------------ *)

	{ RealShortName mnemonics }
	RSNR_Max = 3;
	RSNR_GroupName = 1;  (* Hold the names of group's. *)
        RSNR_Class = 2;
        RSNR_WhoName = 3;

(* ------------------------------------------------------------------------ *)

{Character attribute mnemonics}
	att_class	=1;
	att_bankwealth	=2;
	att_wealth	=3;
	att_health	=4;
	att_experience	=5;
	att_name	=6;
	att_mana	=7;
	att_rooms	=8;
	att_objects	=9;
	att_alignment	=10;
	att_kills	=11;
	att_deaths	=12;

(* ------------------------------------------------------------------------ *)

{Spell Mnemonics}
	sp_cure		=1;
	sp_strength	=2;
	sp_speed	=3;
	sp_invisible	=4;
	sp_seeinvisible	=5;
	sp_heal		=6;
	sp_hurt		=7;
	sp_sleep	=8;
        sp_push		=9;
        sp_announce	=10;
	sp_command	=11;
	sp_dist		=12;
	sp_whatis	=13;
	sp_find_person	=14;
	sp_locate	=15;
        sp_weak         =16;
        sp_slow         =17;

(* ------------------------------------------------------------------------ *)

{Roomtype}
	rm$b_store	=0;
	rm$b_nofight	=1;
	rm$b_nohide	=2;
	rm$b_hardhide	=3;
	rm$b_objdestroy	=4;
	rm$b_treasure	=5;
	rm$b_random	=6;
	rm$b_group	=7;
	rm$b_lair	=8;
	rm$b_minlevel	=9;
	rm$b_maxlevel	=10;
	rm$b_heal	=11;
	maxroomtype	=11; (* How many diff. types of rooms there can be *)

(* ------------------------------------------------------------------------ *)

{exit kinds}
	ek_noexit	=0;
	ek_open		=1;
	ek_needkey	=2;
	ek_neednokey	=3;
	ek_randomfail	=4;
	ek_acceptor	=5;
	ek_needobject	=6;
	ek_openclose	=7;
	ek_password	=8;

(* ------------------------------------------------------------------------ *)

{exittypes}
	ex_exp		=1;
	ex_wealth	=2;
	ex_bankwealth	=3;
	ex_health	=4;
	ex_mana		=5;
	ex_expset	=6;
	ex_classreset	=7;
	ex_classset	=8;
	ex_alarmed	=9;
	ex_healthless	=10;
	ex_guardian	=11;
	ex_expmodified	=12;

(* ------------------------------------------------------------------------ *)

{Action mnemonics}
        act_clear       =0;     { clear an action }
	act_detail	=1;	{ pseudo command for log_action of desc exit }
	act_custom	=2;	{ customizing something }
	act_usecrystal	=3;	{ using a crystal ball }
	act_deposit 	=4;	{ depositing money in the bank }
	act_withdraw	=5;	{ withdrawing money from the bank }
	act_make	=6;	{ making something }

	act_system	=8;	{ in system mode }

(* ------------------------------------------------------------------------ *)

{ Event Mnemonics }
	E_EXIT = 1;		{ player left room			}
	E_ENTER = 2;		{ player entered room			}
	E_begin = 3;		{ player joined game here		}
	E_QUIT = 4;		{ player here quit game			}
	E_SAY = 5;		{ someone said something		}
	E_MSG = 6;		{ player set his personal name		}
	E_POSSESS = 7;		{ player gets possessed ;)		}
	E_POOFIN = 8;		{ someone poofed into this room		}
	E_POOFOUT = 9;		{ someone poofed out of this room	}
	E_DETACH = 10;		{ a link has been destroyed		}
        E_READHOLD = 11;        { Used to force a player to reread objects }
	E_NEWEXIT = 12;		{ someone made an exit here		}
	E_BOUNCEDIN = 13;	{ an object "bounced" into the room	}
	E_EXAMINE = 14;		{ someone is examining something	}
	E_FOUND = 16;		{ player found something		}
	E_SEARCH = 17;		{ player is searching room		}
        E_READATMOSPHERE = 18;  { force a player to read in atmos commands }
	E_HIDOBJ = 19;		{ someone hid an object here		}
	E_UNHIDE = 20;		{ voluntarily revealed themself		}
	E_FOUNDYOU = 21;	{ someone found someone else hiding	}
	E_PUNCH = 22;		{ someone has punched someone else	}
        E_READ_ROOMDESC = 23;   { Read in  a room description           }
        E_SETPSLOT = 24;        { Read in a room description            }
	E_DROP = 25;		{ someone dropped an object		}
        E_SELL = 26;
	E_IHID = 27;		{ tell others that I have hidden (!)	}
	E_NOISES = 28;		{ strange noises from hidden people	}
	E_PING = 29;		{ send a ping to a potential ghost	}
	E_PONG = 30;		{ ping answered				}
	E_HIDEPUNCH = 31;	{ someone hidden is attacking		}
	E_SLIPPED = 32;		{ attack caused obj to drop unwillingly }
        E_READSPELL = 33;
        E_READOBJECT = 34;
	E_HPOOFOUT = 35;	{ someone hiding poofed	out		}
	E_FAILGO = 36;		{ a player failed to go through an exit }
	E_HPOOFIN = 37;		{ someone poofed into a room hidden	}
	E_TRYPUNCH = 38;	{ someone failed to punch someone else	}
	E_PINGONE = 39;		{ someone was pinged away . . .		}
	E_CLAIM = 40;		{ someone claimed this room		}
	E_DISOWN = 41;		{ owner of this room has disowned it	}
	E_WEAKER = 42;		{ person is weaker from battle		}
	E_OBJCLAIM = 43;	{ someone claimed an object		}
	E_OBJDISOWN = 44;	{ someone disowned an object		}
        E_RANDOMMSG = 45;       { used to send commands to randoms      }
	E_WHISPER = 46;		{ someone whispers to someone else	}
	E_TAKE = 47;		{ takes something			}
        E_GETGOLD = 48;         { someone picked up some gold           }
	E_DESTROY = 52;		{ someone has destroyed an object	}
	E_HIDESAY = 53;		{ anonymous say				}
	E_OBJPUBLIC = 54;	{ someone made an object public		}

	E_UNMAKE = 56;		{ remove typedef for object		}
	E_LOOKDETAIL = 57;	{ looking at a detail of this room	}
	E_ACCEPT = 58;		{ made an "accept" exit here		}
	E_REFUSE = 59;		{ got rid of an "accept" exit here	}
	E_DIED = 60;		{ someone died and evaporated		}
	E_LOOKYOU = 61;		{ someone is looking at you		}
	E_FAILGET = 62;		{ someone can't get something		}
	E_FAILUSE = 63;		{ someone can't use something		}
	E_CHILL = 64;		{ someone scrys you			}
	E_NOISE2 = 65;		{ say while in crystal ball		}
	E_LOOKSELF = 66;	{ someone looks at themself		}
	E_INVENT = 67;		{ someone takes inventory		}
	E_POOFYOU = 68;		{ MM poofs someone away . . . .		}
	E_WHO = 69;		{ someone does a who			}
	E_PLAYERS = 70;		{ someone does a players		}
	E_VIEWSELF = 71;	{ someone views a self description	}
	E_REALNOISE = 72;	{ make the real noises message print	}
	E_ALTNOISE = 73;	{ alternate mystery message		}
	E_MIDNIGHT = 74;	{ it's midnight now, tell everyone	}
	E_ATTACK = 75;		{ sombody attacks sombody else with a weapon }
	E_CHANGE = 76;		{ someone's attributes are changed }
	E_TRYATTACK = 77;	{ missed because of armor or other }
	E_LOB = 78;		{ A bomb was lobbed into this room }
	e_trap = 79;		{ A trap of some sort somewhere }
	e_clear = 80;		{ To clear a trap or something }
	E_S_SPELL = 82;		{ General spell actions }
	E_SHUTDOWN = 84;	{ Kick all players out }
	E_ANNOUNCE = 85;	{ Game wide message }
	E_ATMOSPHERE = 86;	{ Atmosphere messages. }
	E_S_DIST = 88;          { distance spell into room }
        E_BLOCKEXIT = 89;       { block or unblock exit }
	e_doneaction = 99;	{ done w/ action }
	E_ACTION = 100;	  	{ base command action event }
	E_Made_Save = 101;      { Player made saving throw.}
        E_MissileWhiz = 102;	{ A missile enters a room.}
        E_MissileHit = 103;	{ A missile strikes a player.}
	E_STEALFAIL = 106;	{ A thief fails to steal from someone.}
	E_STEALSUCCEED = 107;   { A thief succeeds in stealing from someone.}
	E_STEALRESPONSE = 108;	{ The thief can pick up the object now.}
	E_PICKSUCCEED = 109;    { A thief has picked your pocket!'}
	E_PICKRESPONSE = 110;   { The thief can pick up his gold now!}
	E_REMOTE = 111;		{ Remote control a hapless user!}
	E_OPCHECK = 112;	{ Ops are spying on you.}
	E_SETNAME = 113;	{ Someone set something in the name blocks }
        E_ENERGYDRAIN = 114;	{ Energy drain. }
	E_MOUNT	= 115;		{ Mounting a mount. }
	E_DISMOUNT = 116;	{ DisMount from a mount.}
        E_TRYSPELL = 117;

	E_SPECifIC = 119;
        E_POISON = 120;
	E_S_EFFECT = 121;
        E_HALT = 122;
        E_NEWMBX = 123;
        E_DELMBX = 124;
END.
