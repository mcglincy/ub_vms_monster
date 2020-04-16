#include <stdio.h>
#include <time.h>

unsigned preset[2];

void short_time_setup(void)
{
  sys$gettim(preset);
}

int short_time(void)
{
  unsigned time[2], status;
  status = sys$gettim(time);  /* 100 nano second units (10^-7) */
  return (preset[0] - time[0]) + (preset[1]-time[1]) / 1000000;
}

int seconds_time(void)
{
  return time(NULL) & 0x00FFFFFF;
}

int check_bit(int *value, int bit)
{
  return (*value & (1 << bit ) )!=0;
}
