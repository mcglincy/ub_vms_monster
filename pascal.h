#define MAXEXIT 6
#define MAXTIMEDEVENTS 20
#define MAXHOLD 7

typedef struct string STRING;
struct string {
  unsigned char low;
  unsigned char high;
  char string[80];
};

typedef struct {
  unsigned char low, high;
  char string[12];
} VERYSHORTSTRING;

typedef struct {
  unsigned char low, high;
  char string[20];
} SHORTSTRING;

typedef struct {
  VERYSHORTSTRING realid, userid;
  char privd, sysmaint, loggedact, ingame;
  int lasthit;
  STRING lasthitstring;
  int location;
  STRING name;
  int maxrooms, maxobj, class, group, monstertype, slot, log;
  int experience, mana, health;
  char poisoned;
  int movespeed, attackspeed, size, weaponuse, poisonchance;
  int movesilent, steal, wealth, bank, kills, death, healspeed;
  int control, lasthittime;
  char done;
  int universe, eventnum, alleventnum;
  char brief, highlight, printed;
  int alignment, memory, hidedelay, shadowdamagepercent;
} stattype;

typedef struct {
  int holding[MAXHOLD], slot[MAXHOLD], charges[MAXHOLD], condition[MAXHOLD];
  STRING weapon;
  int basearmor, deflectarmor, spellarmor, spelldeflectarmor;
  int basedamage, randomdamage, breakchanceleft, breakchanceright;
  int breakmagnitudeleft, breakmagnituderight, maxmana, maxhealth;
} holdobj;

typedef struct {
  int tkinvisible;
  char invisible;
  int tksee;
  char seeinvisible;
  int tkstrength, strength, tkspeed, mvspeed;
  int attspeed, tkhealth, health, tkmana, mana;
  int tkevent, tkallevent, tkrandmove, tkrandact, tkrandomevent;
} tktimetype;

typedef struct {
  char notext;
  int opcheckcomm;
  char frozen, pinganswered;
} opstuff;

typedef struct {
  STRING line[10];
  int point, last;
} commandtype;

typedef struct {
  int send, sendlog, action, targ, targlog, param[2];
  STRING msg;
  int loc;
  SHORTSTRING emsg;
  int eparam[5];
} anevent;

typedef char foundexittype[MAXEXIT];
typedef anevent timedeventtype[MAXTIMEDEVENTS];

typedef struct {
  foundexittype foundexits, killedguardian;
  char exithandled;
  int blocking;
} exitstuff;

typedef struct {
  char room;
} memorytype;

typedef struct {
  stattype stats;
  holdobj myhold;
  tktimetype tick;
  opstuff op;
  exitstuff exit;
  timedeventtype timedevents;
  commandtype commands;
  memorytype inmem;
} AllStats;

#define term_string(_string) _string->string[_string->low + _string->high*256] = 0;
#define set_length(_str, _len) _str->low = _len % 256; _str->high = _len >> 8;
