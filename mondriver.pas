[inherit ('monconst','montype','monglobl')]

PROGRAM Monster(INPUT, OUTPUT);

%include 'headers.txt'

BEGIN
  Setup_Guts;
  Init(All);
  All.Stats.Privd := FALSE;
  IF NOT(All.Stats.Done) THEN
  BEGIN
    PreStart(All);
    IF NOT(All.Stats.Done) THEN
    BEGIN
      IF EnterUniverse(,All) THEN
      BEGIN
        All.Stats.Privd := TRUE;
        Parser('poof three',FALSE,All);
        Parser('sheet',FALSE,All);
        Parser('who',FALSE,All);
        Parser('west',FALSE,All);
        Parser('west',FALSE,All);
        Parser('west',FALSE,All);
        Parser('west',FALSE,All);
        Parser('who',FALSE,All);
        Parser('look',FALSE,All);
        Parser('get gold 100',FALSE,All);
        Parser('att homer',FALSE,All);
        Parser('pun homer',FALSE,All);
        Parser('name testing',FALSE,All);
        Parser('pun testing',FALSE,All);
        LeaveUniverse(, All);
        DeassignChannel(MyChannel, All.Stats.Log);
      END
      ELSE
        Writeln('You attempt to enter the Monster universe, but a strange force repels you.');
    END;
  END;
  Finish_Guts;
END.
