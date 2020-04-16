[INHERIT ('MONCONST','MONTYPE','MONGLOBL')]

MODULE MonAttk(OUTPUT);

%include 'headers.txt'
%include 'equip.inc'

PROCEDURE MaybeDrop(VAR AllStats : AllMyStats);

VAR
  I, ObjNum : INTEGER;
  S : String;
  Nams : ShortNameRec;

BEGIN
  I := Rnd(MaxHold);
  ObjNum := AllStats.MyHold.Holding[I];
  IF (ObjNum <> 0) AND (AllStats.MyHold.Slot[i]=0) THEN
  BEGIN
    IF PlaceObj(ObjNum, AllStats.Stats.Location, AllStats.MyHold.Condition[I],
                AllStats.MyHold.Charges[I], TRUE, , , AllStats) THEN
    BEGIN
      DropObj(I, AllStats);
      IF GetShortName(s_na_objnam, Nams) THEN
      BEGIN
        Writeln('The ',Nams.Idents[ObjNum],' has slipped out of your hands.');
        LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_SLIPPED, 0,0,0,
                 0, Nams.Idents[ObjNum], AllStats.Stats.Location);
      END;
    END;
  END;
END;

PROCEDURE ShowDamage(ObjName : ShortString; Mag : INTEGER; MyName : String;
                     MySlot : INTEGER; Location : INTEGER);

VAR
  S : String;

BEGIN
  S := ObjName;
  CASE Mag OF
    1     : s:=s+' is notched!';
    2     : s:=s+' glances harshly off the armor.';
    3..5  : s:=s+' rings dully off the armor.';
    6..10 : s:=s+' splinters.';
    11..25: s:=s+' partially shatters.';
    26..99: s:=s+' explodes in a burst of sparks.';
  100..200: s:=s+' erupts into a thousand pieces.';
  otherwise s:=s+' winkes out of existance.';
  END;
  LogEvent(MySlot, 0, E_MSG, 0,0,0,0, MyName+'''s '+s, Location);
  Writeln('Your '+s);
END;

PROCEDURE DamageAWeapon(LeftHand : BYTE_BOOL; VAR AllStats : AllMyStats);

VAR
  I, Mag : INTEGER;
  Obj : ObjectRec;
  Charac : CharRec;

BEGIN
  FOR I := 1 TO MaxHold DO
  IF AllStats.MyHold.Slot[I] <> 0 THEN
  BEGIN
    Obj := GlobalObjects[AllStats.MyHold.Holding[I]];
    IF (LeftHand AND (Obj.Wear = OW_SHIELDHAND)) OR
       ((NOT LeftHand) AND ((Obj.Wear = OW_SWORDHAND) OR
   	 (Obj.Wear = OW_TWOHAND))) THEN
    BEGIN
      IF LeftHand THEN
        Mag := AllStats.MyHold.BreakMagnitudeLeft
      ELSE
        Mag := AllStats.MyHold.BreakMagnitudeRight;
      AllStats.MyHold.Condition[I] := AllStats.MyHold.Condition[I] - Mag;
      ShowDamage(Obj.ObjName,Mag, AllStats.Stats.Name, AllStats.Stats.Slot,
                 AllStats.Stats.Location);
      IF AllStats.MyHold.Condition[I] <= 0 THEN
        DropObj(I, AllStats);
      IF GetChar(AllStats.Stats.Log,Charac) THEN
      BEGIN
        Charac.Condition[I] := AllStats.MyHold.Condition[I];
        IF SaveChar(AllStats.Stats.Log, Charac) THEN;
      END;
    END;
  END;
END;

[GLOBAL]
PROCEDURE DamageWeapon(Force : INTEGER; VAR AllStats : AllMyStats);

VAR
  Rand : INTEGER;

BEGIN
  Rand := Rnd(100);
  IF (AllStats.MyHold.BreakChanceLeft * Force DIV 15) > Rand THEN
    DamageAWeapon(TRUE, AllStats);
  IF (AllStats.MyHold.BreakChanceRight * Force DIV 15) > Rand THEN
    DamageAWeapon(FALSE, AllStats);
END;

[GLOBAL]
PROCEDURE TakeHit(P : INTEGER; CanDie : BYTE_BOOL := TRUE;
                  VAR AllStats : AllMyStats);

VAR
  I : INTEGER;

BEGIN
  IF P <> 0 THEN
  BEGIN
    IF(AllStats.Exit.Blocking <> 0)THEN
      P := ROUND(P * 1.5 / Count1Bits(Here.ExitBlocked[AllStats.Exit.Blocking],
						0,9));
    PoorHealth(P, TRUE, FALSE, CanDie, AllStats);
    MaybeDrop(AllStats);
  END;
END;

[GLOBAL]
FUNCTION PunchForce(Sock : INTEGER) : INTEGER;

VAR
  P : INTEGER;

BEGIN
  IF Sock IN [1..7] THEN p:= 25
  ELSE IF Sock in [8..12] THEN P := 50
  ELSE IF Sock in [13..15] THEN P := 75
  ELSE IF Sock in [16] THEN P := 100;
  PunchForce := P;
END;

PROCEDURE PutPunch(Sock : INTEGER; S : String);

BEGIN
  CASE Sock OF
     1 : Writeln('You deliver a quick jab to ',s,'''s jaw.');
     2 : Writeln('You swing at ',s,' and miss.');
     3 : Writeln('A quick punch, but it only grazes ',s,'.');
     4 : Writeln(s,' doubles over after your jab to the stomach.');
     5 : Writeln('Your punch lands square on ',s,'''s face!');
     6 : Writeln('You nail ',s,' right upside the head, dizzying him for a moment.');
     7 : Writeln('A good swing, but it misses ',s,' by a mile!');
     8 : Writeln('Your punch is blocked by ',s,'.');
     9 : Writeln('Your roundhouse blow sends ',s,' reeling.');
    10 : Writeln('You land a solid uppercut on ',s,'''s chin.');
    11 : Writeln(s,' fends off your blow.');
    12 : Writeln(s,' ducks and avoids your punch.');
    13 : Writeln('You thump ',s,' in the ribs.');
    14 : Writeln('You catch ',s,'''s face on your elbow.');
    15 : Writeln('You knock the wind out of ',s,' with a punch to the chest.');
    16 : Writeln('Your senses dull as adrenaline rushes through your body, you desperatly attack.');
    OTHERWISE Writeln('Your senses dull as adrenaline rushes through your body, you desperatly attack.');
  END;
END;

PROCEDURE PutAttack(Sock : INTEGER; S, W : String);

BEGIN
  IF Sock > 500 THEN Writeln('You vaporize ',s,'''s putrid body.')
  ELSE IF Sock > 400 THEN Writeln('You attack ',s,' with blinding speed and power!!!')
  ELSE IF Sock > 300 THEN Writeln('You deliver an almost deadly blow to ',s,' with your ',w,'!!')
  ELSE IF Sock > 200 THEN Writeln('Your ',w,' creams ',s,'''s poor little body!!')
  ELSE IF Sock > 150 THEN Writeln('Your ',w,' hits ',s,' very hard!')
  ELSE IF Sock > 100 THEN Writeln('Your ',w,' hits ',s,' with incredible force!')
  ELSE IF Sock > 50 THEN Writeln('Your ',w,' hits ',s,', good.')
  ELSE IF Sock > 0 THEN Writeln(s,' is grazed by your ',w,'.')
  ELSE Writeln('You miss ',s,' with your ',w,'.');
END;

[GLOBAL]
PROCEDURE GetPunch(Sock : INTEGER; S : String);

BEGIN
  CASE Sock OF
    1 : Writeln(s,' delivers a quick jab to your jaw!');
    2 : Writeln(s,' swings at you but misses.');
    3 : Writeln(s,'''s fist grazes you.');
    4 : Writeln('You double over after ',s,' lands a mean jab to your stomach!');
    5 : Writeln('You see stars as ',s,' bashes you in the face.');
    6 : Writeln('You only feel the breeze as ',s,' swings wildly.');
    7 : Writeln(s,'''s swing misses you by a yard.');
    8 : Writeln('With lightning reflexes you block ',s,'''s punch.');
    9 : Writeln(s,'''s blow sends you reeling.');
   10 : Writeln('Your head snaps back from ',s,'''s uppercut!');
   11 : Writeln('You parry ',s,'''s attack.');
   12 : Writeln('You duck in time to avoid ',s,'''s punch.');
   13 : Writeln(s,' thumps you hard in the ribs.');
   14 : Writeln('Your vision blurs as ',s,' elbows you in the head.');
   15 : Writeln(s,' knocks the wind out of you with a punch to your chest.');
   16 : Writeln(s,' screams, then in a blinding motion attacks you.');
   OTHERWISE Writeln(s,' screams, then in a blinding motion attacks you.');
  END;
END;

[GLOBAL]
PROCEDURE GetAttack(Sock : INTEGER; S: String; W : String);

BEGIN
 IF Sock > 500 THEN Writeln(s,' vaporizes you!')
 ELSE IF Sock> 400 THEN Writeln(s,' attacks you with blinding speed and power, ARRRG!!')
 ELSE IF Sock> 300 THEN Writeln(s,'''s ',w,' nearly splits you in two!!!')
 ELSE IF Sock> 200 THEN Writeln(s,'''s ',w,' creams your poor little body!!')
 ELSE IF Sock> 150 THEN Writeln(s,'''s ',w,' hits you very hard!')
 ELSE IF Sock> 100 THEN Writeln(s,'''s ',w,' hits you hard.')
 ELSE IF Sock> 50 THEN Writeln(s,'''s ',w,' hits you good.')
 ELSE IF Sock> 1 THEN Writeln('You are grazed by ',s,'''s ',w,'.')
 ELSE Writeln(s,' misses you with a ',w,'.');
END;

[GLOBAL]
PROCEDURE ViewPunch(A, B : String; P : INTEGER);

BEGIN
  CASE P OF
     1 : Writeln(a,' jabs ',b,' in the jaw.');
     2 : Writeln(a,' throws a wild punch at the air.');
     3 : Writeln(a,'''s fist barely grazes ',b,'.');
     4 : Writeln(b,' doubles over in pain with ',a,'''s punch');
     5 : Writeln(a,' bashes ',b,' in the face.');
     6 : Writeln(a,' takes a wild swing at ',b,' and misses.');
     7 : Writeln(a,' swings at ',b,' and misses by a yard.');
     8 : Writeln(b,'''s punch is blocked by ',a,'''s quick reflexes.');
     9 : Writeln(b,' is sent reeling from a punch by ',a,'.');
    10 : Writeln(a,' lands an uppercut on ',b,'''s head.');
    11 : Writeln(b,' parrys ',a,'''s attack.');
    12 : Writeln(b,' ducks to avoid ',a,'''s punch.');
    13 : Writeln(a,' thumps ',b,' hard in the ribs.');
    14 : Writeln(a,'''s elbow connects with ',b,'''s head.');
    15 : Writeln(a,' knocks the wind out of ',b,'.');
    16 : Writeln(a,' screams, then in a blurred motion attacks ',b,'.');
  END;
END;

[GLOBAL]
PROCEDURE ViewAttack(A, B : String; Sock : INTEGER; W : String);

BEGIN
 IF Sock > 500 THEN Writeln(a,' vaporizes ',b,'''s putrid body.')
 ELSE IF Sock > 400 THEN Writeln(a,' attacks ',b,' with blinding speed and power!!!')
 ELSE IF Sock > 300 THEN Writeln(a,'''s ',w,' nearly splits ',b,' in two!!')
 ELSE IF Sock > 200 THEN Writeln(a,'''s ',w,' creams ',b,'''s poor little body!!')
 ELSE IF Sock > 150 THEN Writeln(a,'''s ',w,' hits ',b,' with incredible force!')
 ELSE IF Sock > 100 THEN Writeln(a,'''s ',w,' hits ',b,' hard!')
 ELSE IF Sock > 50  THEN Writeln(a,'''s ',w,' hits ',b,', good.')
 ELSE IF Sock > 1   THEN Writeln(b,' is grazed by ',a,'''s ',w,'.')
 ELSE Writeln(a,' misses ',b,' with a ',w,'.');
END;

[GLOBAL]
PROCEDURE DescHealth(N : INTEGER; Header : ShortString := '');

BEGIN
  IF Header = '' THEN
    Write(Here.People[N].Name,' ')
  ELSE
    Write(header,' ');
  CASE Here.People[N].Health OF
    1700..MAXINT : Writeln('is in ultimate health.');
    1400..1699   : Writeln('is in incredible health.');
    1200..1399   : Writeln('is in extraordinary health.');
    1000..1199   : Writeln('is in tremendous condition.');
    850..999     : Writeln('is in superior condition.');
    700..849     : Writeln('is in exceptional health.');
    500..699     : Writeln('is in good health.');
    350..499     : Writeln('looks a little bit dazed.');
    200..349     : Writeln('has some minor wounds.');
    100..199     : Writeln('is suffering from some serious wounds.');
    50..99       : Writeln('is in critical condition.');
    1..49        : Writeln('is near death.');
    OTHERWISE      Writeln('is dead.');
  END;
END;

[GLOBAL]
PROCEDURE DoPunch(S : String; VAR AllStats : AllMyStats);

VAR
  Sock, N : INTEGER;
  MySlot : INTEGER;
  TargLog : INTEGER;

BEGIN
  MySlot := AllStats.Stats.Slot;
  IF (Check_bit(HereDesc.SpcRoom, rm$b_nofight)) THEN
    Inform_nofight
  ELSE
  BEGIN
    IF S <> '' THEN
    BEGIN
      IF ParsePers(N, TargLog, S, TRUE) THEN
      BEGIN
        IF N = MySlot THEN
        BEGIN
          AllStats.Stats.LastHit := 0;
          Writeln('You catch yourself off guard with an elbow to the ribs, arrg!');
          PoorHealth(100, FALSE, FALSE, TRUE, AllStats);
	  LogEvent(MySlot, AllStats.Stats.Log, E_MSG, 0, 0, 0, 0,
                   AllStats.Stats.Name + ' is heading for the void.',
                   AllStats.Stats.Location);
        END
        ELSE
        BEGIN
     	  IF Here.People[MySlot].Hiding > 0 THEN
          BEGIN
            Here.People[MySlot].Hiding := 0;
            IF SaveRoom(AllStats.Stats.Location, Here) THEN;
            LogEvent(MySlot, AllStats.Stats.Log, E_HIDEPUNCH, N,0,0,0,
                     AllStats.Stats.Name, AllStats.Stats.Location);
            Writeln('You pounce unexpectedly on ',here.people[n].name,'!');
          END
          ELSE
          BEGIN
	    Sock := Rnd(NumPunches);
            IF (AllStats.Stats.Health < 75) THEN
              Sock:=16;
	    PutPunch(sock, here.people[n].name);
	    LogEvent(MySlot, AllStats.Stats.Log, E_PUNCH, N, 0, Sock, 0,
                     '', AllStats.Stats.Location);
  	  END;
	  IF AllStats.Stats.AttackSpeed > 0 THEN
            Freeze(AllStats.Stats.AttackSpeed/100, AllStats)
        END;
      END;
    END
    ELSE Writeln('To punch somebody, type PUNCH <personal name>.');
  END;
END;

PROCEDURE AttackPrime(N : INTEGER; VAR Sock : INTEGER; AttackName : String;
                      Stat : StatType; Weapon : String);
VAR
  Log : INTEGER;
  TempS : String;
  DieRoomName : ShortString;

BEGIN
  Log := Here.People[N].Kind;
  IF Rnd(100) < Stat.PoisonChance THEN
  BEGIN
    LogEvent(Stat.Slot, Stat.Log, E_POISON, N, 0,0,0, Weapon,Stat.Location);
    Writeln('You''ve poisoned ', Here.People[N].Name,'!');
  END;
  IF Weapon <> 'claws' THEN
    Sock := TRUNC(Sock*(Stat.WeaponUse/100));
  PutAttack(Sock, AttackName, Weapon);
  IF IsRandom(Log) THEN
  BEGIN
    Here.People[N].Health := Here.People[N].Health - Sock;
    LogEvent(Stat.Slot, Stat.Log, E_ATTACK, N, 0,Sock,0,Weapon,Stat.Location);
    LogEvent(N, Log, E_WEAKER, 0, 0, Here.People[N].Health, 0,
             Here.People[N].Name, Stat.Location);
    IF (Here.People[N].Health <= 0) THEN
    BEGIN

(* MWG *)
    IF Length(Here.People[N].Name) + 20 + Length(Here.People[Stat.Slot].Name)
       > 80 THEN 
      TempS := Here.People[N].Name + ' has been slain.'    
    ELSE TempS := Here.People[Stat.Slot].Name + ' is hacking ' + 
               Here.People[N].Name + '.';

      LogEvent(N, Log, E_DIED, 0, Stat.Log, Stat.Group,
               GlobalRandoms[-log].Experience,  TempS, R_ALLROOMS);
      IF GlobalRandoms[-Log].Gold > 0 THEN
      BEGIN
        here.goldhere := Here.GoldHere + GlobalRandoms[-Log].Gold;
        Writev(Temps, 'When ', here.people[n].name, ' died, ', 
               GlobalRandoms[-Log].Gold:0, ' gold fell to the ground.');
        LogEvent(N, log, E_MSG, 0, 0, 0, 0, Temps, Stat.Location);
      END;
      Here.People[N].kind := 0;
  END;
    SaveRoom(Stat.Location, here);
  END
  ELSE
    LogEvent(Stat.Slot, Stat.Log, E_ATTACK, N, 0,Sock,0,Weapon,Stat.Location);
END;
                                                                              
[GLOBAL]
PROCEDURE DoAttack(S : String; VAR AllStats : AllMyStats);

VAR
  Sock, N : INTEGER;
  AttackName : String;
  TargLog : INTEGER;

BEGIN
  IF (check_bit(HereDesc.SpcRoom, rm$b_nofight)) THEN
    Inform_nofight
  ELSE
  BEGIN
    IF S <> '' then
    BEGIN
      IF AllStats.Stats.AttackSpeed > 0 THEN
        Freeze(AllStats.Stats.AttackSpeed/200, AllStats);
      IF ParsePers(N, TargLog, S, TRUE) THEN
      BEGIN
        AttackName := Here.People[N].Name;
        IF (AllStats.MyHold.BaseDamage + AllStats.MyHold.RandomDamage = 0) THEN
          Writeln('You have not wielded a weapon!')
        ELSE
        BEGIN
          IF Here.People[AllStats.Stats.Slot].Hiding > 0 THEN
          BEGIN
     	    LogEvent(AllStats.Stats.Slot, AllStats.Stats.Log, E_MSG, N,
                     TargLog,0,0,'Surprise!!!',AllStats.Stats.Location);
            Here.People[AllStats.Stats.Slot].Hiding := 0;
            IF SaveRoom(AllStats.Stats.Location, Here) THEN;
    	    Sock := AllStats.MyHold.BaseDamage + 
     	            Round( 7*AllStats.MyHold.RandomDamage/10);
            Sock := Sock + Round(AllStats.Stats.ShadowDamagePercent*sock/100);
     	    Writeln('You unexpectedly attack ',AttackName,'!');
   	  END
          ELSE
            Sock := AllStats.MyHold.BaseDamage +
                    Rnd(AllStats.MyHold.RandomDamage);
          IF AllStats.Stats.Privd THEN
	    Writeln('[++ Gonna spank em with: ', AllStats.MyHold.Weapon);
          AttackPrime(N, Sock, AttackName, AllStats.Stats,
                      AllStats.MyHold.Weapon);
          IF AllStats.Stats.Privd THEN Writeln('+++Sock+++ [',sock:0,']');
 	  IF AllStats.Stats.AttackSpeed > 0 THEN
            Freeze(AllStats.Stats.AttackSpeed/200, AllStats);
        END;
      END;  (* Parse pers *)
    END
    ELSE
      Writeln('To nail somebody with your weapon, type ATTACK <game name>.');
  END;
END;

END.
