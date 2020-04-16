int count1bits(int *val, int sbit, int ebit)
{
  int mask, count = 0;
  mask = 1 << (sbit-1);
  while (sbit < ebit)
  {
    if (mask & *val) count++;
    mask = mask << 1;
    sbit++;
  }
  return count;
}

int testbit(int *add, int bit)
{
  return ((1<<(bit-1)) & *add)?1:0;
}

int setbit(int *add, int bit)
{
  int mask, ret;
  mask = 1 << (bit-1);
  ret = *add & mask;
  *add = *add | mask;
  return ret?1:0;
}

int clearbit(int *add, int bit)
{
  int mask, ret;
  mask = 1 << (bit-1);
  ret = *add & mask;
  if (ret) *add = *add - mask;
  return ret?1:0;
}

int getbits(int *add, int sbit, int nbit)
{
  int mask = 0, val = 0, loop;
  mask = 1 << (sbit-1);
  for (loop=0;loop<nbit;loop++)
  {
    val = val * 2;
    if (*add & mask) val++;
    mask = mask * 2;
  }
  return val;
}

int setbits(int *add, int sbit, int nbit, int new_mask)
{
  int mask = 0, val = 0, loop;
  mask = 1 << (sbit-1);   /* mask for the lowest bit */
  for (loop=0;loop<nbit;loop++)
  {
    /* double our value, then add 1 if it this bit is set in the # passed */
    val = val * 2;
    if (*add & mask) val++;
    /* set bit in address if set in mask.. else clear it if it isn't clear */
    if (new_mask & 1)
     *add = *add | mask;
    else
      if (*add & mask) *add = *add - mask;
    new_mask >> 1; /* next bit */
    mask = mask * 2; /* mask the next bit */
  }
  return val;
}

