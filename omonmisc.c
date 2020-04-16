#include <stdio.h>
#include <trmdef.h>
#include <ssdef.h>
#include <descrip.h>
#include <iodef.h>
#include <string.h>
#include <stdlib.h>

#include <libdef.h>
#include <libdtdef.h>
#include <ctype.h>
#include <unixlib.h>
#include <math.h>
#include <dvidef.h>
#include "pascal.h"

#define short_wait 0.10
#define med_wait   0.30

extern int checkevents(), allevents();

extern int lib$signal(), lib$disable_ctrl(), lib$enable_ctrl();
extern int lib$init_timer(), sys$assign(), sys$qiow(), sys$setpri();
extern int lib$wait(), rand(), lib$cvtf_from_internal_time();
extern int lib$spawn(), lib$stat_timer(), lib$get_ef();
extern int sys$clref(), sys$qio(), sys$setimr(), sys$bintim();
extern int lib$cvtf_to_internal_time(), sys$waitfr();
extern int sys$setef(), sys$crembx(), lib$getdvi();

/* ---------------------------------------------------------------------- */
struct iosb_type {
  unsigned short status, length;
  unsigned short other[2];
};

struct itemlistcell {
  unsigned short buffer_length, item_code;
  unsigned buffer_addr, return_addr;
};

typedef unsigned long uquad[2];
/* ---------------------------------------------------------------------- */
unsigned long timercontext;
unsigned in_chan = 0, out_chan = 0, mbx_chan = 0;
unsigned long input_ef = 0, wait_ef = 0, dummy_ef = 0;
uquad delta_timer, wait_timer;

struct itemlistcell list[6];
/* ---------------------------------------------------------------------- */
static unsigned status;
#define CheckStatus(_msg) if (!(status & 1)) { printf("%s",_msg); \
                                               lib$signal(status); }
/* ---------------------------------------------------------------------- */
struct dsc$descriptor_s dummy_d = { 0, DSC$K_DTYPE_T, DSC$K_CLASS_S, 0 };
#define fill_descrip(_d, _s) {_d.dsc$a_pointer = _s; \
                              _d.dsc$w_length = strlen(_s); }
/* ---------------------------------------------------------------------- */
void spawn(STRING *comm)
{
  term_string(comm);
  fill_descrip(dummy_d, comm->string)
  status = lib$spawn(&dummy_d, 0, 0, 0, 0, 0, 0);
  CheckStatus("lib$spawn");
}

int getticks(void)
{
  long int code = 1;
  uquad time;
  float seconds;
  status = lib$stat_timer(&code, &time, &timercontext);
  CheckStatus("lib$stat_timer");
  code = LIB$K_DELTA_SECONDS_F;
  status = lib$cvtf_from_internal_time(&code, &seconds, &time);
  CheckStatus("lib$cvtf_from_internal_time");
  return (int)(seconds * 10.0);
}

int rnd(int val)
{
  return (rand()%val) + 1;
}

void wait(float seconds)
{
  int wait_timer[2];
  wait_timer[0] = -10000000 * seconds;
  wait_timer[1] = -1;
  status = sys$setimr(wait_ef, wait_timer, 0, 142, 0);
  CheckStatus("sys$setimr");
  status = sys$waitfr(wait_ef);
  CheckStatus("sys$waitfr");
}

static int get_pid(int parent)
{
  if (parent) return getppid();
  return getpid();
}

static void boostpriority(void)
{
  int pid;
  pid = get_pid(0);
  status = sys$setpri(&pid, 0, 6, 0, 0, 0);
  pid = get_pid(1);
  status = sys$setpri(&pid, 0, 6, 0, 0, 0);
}

void freeze(float secs, AllStats *ams)
{
  int end, didcheck = 0;
  end = (int)(10.0 * secs) + getticks();
  while (getticks() < end)
  {
    if (getticks() > ams->tick.tkallevent)
      allevents(&1, &didcheck, ams);
    wait(short_wait);
  }
  if (!didcheck) checkevents(&FALSE, &TRUE, &FALSE, ams);
}

#define putchars(_str) printf("%s", _str)

int pending = 0;

struct iosb_type iosb, mbx_iosb;
unsigned char mbxread[214];
unsigned char inp[6];
unsigned char pic = 0;

extern void launch_qio();

void mbx_read_done()
{
  pending += mbx_iosb.length;
  launch_qio();
}

void launch_qio()
{
  status = sys$qio(input_ef, mbx_chan, IO$_READVBLK, &mbx_iosb,
                   mbx_read_done, 0, mbxread, sizeof(mbxread), 0, 0, 0, 0);
  CheckStatus("sys$qio mbxread");
}

static unsigned char keyget(void)
{                    

  list[5].buffer_length = 1;
  list[5].item_code = TRM$_PICSTRNG;
  list[5].buffer_addr = (int)(&pic);
  list[5].return_addr = 0;

  if (pending <= 0) return 0;
  printf("attempting the qio\n");
  status = sys$qiow(input_ef, in_chan, IO$_READVBLK+IO$M_EXTEND,
                    &iosb, 0, 0, inp, sizeof(inp), 0, 0, list,
                    sizeof(list));
  CheckStatus("sys$qiow in loop");
  pending--;
  return inp[1];
}

char *prompt = "", *line = "", gecho = 1;

#define resetline printf("\015\033[K%s%s", prompt, line)
#define fixprompt printf("\012%s%s", prompt, gecho?line:"");

static int nextkey(AllStats *ams)
{
  int ticks, keycode;
  char dummy;
  do {
    if (ams->stats.ingame)
    {
      ticks = getticks();
/*
      printf("ticks is : %d (event: %d) (all: %d) \n", ticks,
             ams->tick.tkevent, ams->tick.tkallevent);
*/
      if (ticks > ams->tick.tkevent) checkevents(&FALSE, &TRUE, &FALSE, ams);
      if (ticks > ams->tick.tkallevent) allevents(&0, &dummy, ams);
      if (ams->stats.printed) fixprompt;
      ams->stats.printed = FALSE;
    }
    keycode = keyget();
    if (!keycode) wait(med_wait);
  } while (!keycode);
  return keycode;
}

void grabline(STRING *_prompt, STRING *_s, AllStats *ams,
              char echo, int maxlen)
{
  int keycode, len = 0, pos = 0, loop;
  char *curs;
  gecho = echo;
  prompt = _prompt->string;
  term_string(_prompt);
  line = _s->string;
  *line = 0;
  fixprompt;
  while ((keycode = nextkey(ams)) != 13)
  {
    switch (keycode)
    {
    case 8:
    case 127:
      if (pos != 0)
      {
        for (loop = pos +1; loop < len; loop++) line[loop-1] = line[loop];
        len--;
        pos--;
        line[len] = 0;
        printf("\010 \010");
      }
      break;
    case 21:
      len = pos = *line = 0;
      resetline;
      break;
    case 23:
      resetline;
      break;
    case 2:
      boostpriority;
      printf("Boosting priority\n\n");
      resetline;
      break;
    default:
      if ((keycode>=32) && (keycode<=126))
      {
        if (len < maxlen)
        {
          pos++;
          for (loop=len+1;loop>pos;loop++) line[loop] = line[loop-1];
          line[pos-1] = keycode;
          len++;
          line[len] = 0;
          if (echo) printf("%c", keycode);
        }
        else printf("Exceeded length (%d)\n", keycode);
      }
      else printf("Read in a %d(%c)\n", keycode, keycode);
      break;
    }
  }
  printf("\015");
  set_length(_s, len);
}

$DESCRIPTOR(out_chan_d, "SYS$OUTPUT");
$DESCRIPTOR(in_chan_d, "SYS$INPUT");

static char init = 0;
static createkeyboard(void)
{
  memset(list, 0, sizeof(list));
  list[0].item_code = TRM$_EDITMODE;
  list[0].buffer_addr = TRM$K_EM_RDVERIFY;

  list[1].item_code = TRM$_ESCTRMOVR;
  list[1].buffer_addr = 4;

  list[2].item_code = TRM$_INIOFFSET;

  list[3].item_code = TRM$_MODIFIERS;
  list[3].buffer_addr = TRM$M_TM_NOEDIT +   TRM$M_TM_NOFILTR +
                        TRM$M_TM_ESCAPE;
/*
  list[6].item_code = TRM$_TIMEOUT;
  list[6].item_code = 0;
*/
  list[4].buffer_length = 1;
  list[4].item_code = TRM$_INISTRNG;
  list[4].buffer_addr = (int)&init;
}

unsigned long save_dcl_ctrl;

$DESCRIPTOR(delta_timer_d, "0000 00:00:00.01");
$DESCRIPTOR(wait_timer_d, "0000 00:00:00.30");
char mbxname[40];
$DESCRIPTOR(mbxname_d, mbxname);

void setup_guts(void)
{
  unsigned long mask;
  printf("Should seed random number generator!\n");
  status = sys$crembx(0, &mbx_chan, 0, 0, 0, 0, 0, 0);
  CheckStatus("sys$crembx");
  status = lib$getdvi(&DVI$_DEVNAM, &mbx_chan, 0, 0,  &mbxname_d,
                      &mbxname_d.dsc$w_length);
  CheckStatus("lib$getdvi");
  status = sys$assign(&in_chan_d, &in_chan, 0, &mbxname_d, 0);
  CheckStatus("sys$assign in_chan");
  launch_qio();
  status = sys$assign(&out_chan_d, &out_chan, 0, 0, 0);
  CheckStatus("sys$assign");
  status = lib$get_ef(&input_ef);
  CheckStatus("lib$get_ef");
  status = sys$bintim(&delta_timer_d, delta_timer);
  CheckStatus("sys$bintim");
  status = lib$get_ef(&wait_ef);
  CheckStatus("lib$get_ef wait_ef");
  status = lib$get_ef(&dummy_ef);
  CheckStatus("lib$get_ef dummy_ef");
  createkeyboard();
  lib$init_timer(&timercontext);
  mask = 0x2000000;
  status = lib$disable_ctrl(&mask, &save_dcl_ctrl);
  CheckStatus("lib$disable_ctrl");
}

void finish_guts(void)
{
  status = lib$enable_ctrl(&save_dcl_ctrl);
  CheckStatus("lib$enable_ctrl");
}

void grab_num(STRING *prompt, int *ret, int min, int max, int def, AllStats *ams)
{
  int tmp = 0, neg = 0;
  char *str;
  STRING temp;
  str = temp.string;
  grabline(prompt, &temp, ams, TRUE, 80);
  term_string((&temp));
  if (*str == '-') { neg = 1; str++; }
  if (!isdigit(*str)) {
    *ret = def;
    return;
  }
  while (isdigit(*str)) tmp = tmp * 10 + *str++ - '0';
  *ret = neg?-tmp:tmp;
}

int grabyes(STRING *prompt, AllStats *ams)
{
  STRING s;
  grabline(prompt, &s, ams, TRUE, 1);
  term_string((&s));
  if (s.string[0] && (tolower(s.string[0]) == 'y')) return TRUE;
  return FALSE;
}

int readyes(STRING *prompt)
{
  char string[80];

  term_string(prompt);
  printf("%s", prompt);
  gets(string);
  if (*string && (tolower(string[0]) == 'y')) return TRUE;
  return FALSE;
}
