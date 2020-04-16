[inherit('montype', 'monconst', 'monglobl', 'sys$library:starlet')]

MODULE HandleEvent(input,output);

%include 'headers.txt'

[EXTERNAL] PROCEDURE ActMonster(VAR AllStats : AllMyStats); extern;

PROCEDURE SetPlaySlot(Name : ShortString; Slot, Log, Hide, Health : INTEGER);
BEGIN
  Here.People[Slot].Kind := Log;
  Here.People[Slot].Name := Name;
  Here.People[Slot].Hiding := Hide;
  Here.People[Slot].Health := Health;
END;

[GLOBAL]
PROCEDURE HandleEvent(CanDie : BYTE_BOOL := TRUE; Timed : BYTE_BOOL := FALSE;
                      VAR Event : AnEvent; VAR AllStats : AllMyStats);

VAR
  N : INTEGER;

  Send,
  SendLog,
  Act,
  Targ,
  TargLog,
  P1, P2, P3, P4, P5, P6, P7,
  tmp, TheRoom : INTEGER;
  S : String;
  EMsg : ShortString;
  AString : String := ')unknown(';
  Pers : ShortnameRec;
  Classes : IntArray;
  SomeClass : ClassRec;
  Charac : CharRec;
  MySlot : INTEGER;
  MyLog : INTEGER;
  MyLoc : INTEGER;
  MyName : String;
  Pre : String;
  Time : INTEGER;
BEGIN
  Time := GetTicks;
  MySlot := AllStats.Stats.Slot;
  MyLog := AllStats.Stats.Log;
  MyLoc := AllStats.Stats.Location;
  MyName := AllStats.Stats.Name;
  AllStats.Stats.Printed := TRUE;
  Send := Event.Send;
  SendLog := Event.SendLog;
  Act := Event.Action;
  Targ := Event.Targ;
  TargLog := Event.TargLog;
  P1 := Event.Param[1];
  P2 := Event.Param[2];
  P3 := Event.EParam[1];
  P4 := Event.EParam[2];
  P5 := Event.EParam[3];
  P6 := Event.EParam[4];
  P7 := Event.EParam[5];
  EMsg := Event.EMsg;
  S := Event.Msg;
  TheRoom := Event.Loc;

  IF DEBUG[DEBUG_HandleEvent] THEN
  BEGIN
    WITH Event DO
    BEGIN
      Writeln('Incoming event : Send: ',Send:0,'SendLog : ',SendLog:0,' Act/Targ: ',Act:0,'/',Targ:0,
              ' P(1..7) ',P1:0,' ',P2:0, ' ',P3:0, ' ',P4:0, ' ',P5:0, ' ',
              P6:0, ' ',P7:0, ' Room: ',Loc:0);
      Writeln('String: ',S);
    END;
  END;

  CASE Act OF
    E_HALT: HALT;
    E_SETNAME: BEGIN
      CASE P1 OF
       nt_realshort: RSN[P2].Idents[P3] := Emsg;
       nt_short:     SN[P2].Idents[P3] := Emsg;
       nt_long:      LN[P2].Idents[P3] := Emsg;
      END;
      AllStats.Stats.Printed := FALSE;
    END;
    E_STEALSUCCEED: BEGIN
      AllStats.Stats.Printed := FALSE;
    END;
    E_PICKSUCCEED: BEGIN
      tmp := ROUND(AllStats.Stats.Steal * 100 / (P2+1));
      Writeln('Chance of steal: ', P2:0, ' Real: ', tmp:0);
    END;
    E_SETPSLOT: BEGIN
      SetPlaySlot(S, Send, SendLog, P3, P1);
      AllStats.Stats.Printed := FALSE;
    END;
    E_READ_ROOMDESC: BEGIN
      IF GetRoomDesc(AllStats.Stats.Location, HereDesc, FALSE) THEN;
      AllStats.Stats.Printed := FALSE;
    END;
    E_READSPELL : BEGIN
                    IF NOT GetSpell(P1, GlobalSpells[P1]) THEN
                      Writeln('Error reading in new spell!')
                    ELSE AllStats.Stats.Printed :=FALSE;
                  END;
    E_READOBJECT : BEGIN
                     IF NOT GetObj(P1, GlobalObjects[P1]) THEN
                       Writeln('Error reading in new spelld!')
                     ELSE AllStats.Stats.Printed := FALSE;
                   END;
    E_READATMOSPHERE : BEGIN
                         ReadAtmosphere;
                         AllStats.Stats.Printed := FALSE;
                       END;
    E_ATMOSPHERE :
      IF (SendLog <> MyLog) THEN
        EventAtmosphere(Targ, Here.People[Send].Name, P1, AllStats);
    E_READHOLD : BEGIN
                   IF TargLog = MyLog THEN
                     EquipmentStats(AllStats);
                   AllStats.Stats.Printed := FALSE;
                 END;
    E_EXIT: BEGIN
              if Here.People[send].Kind = sendlog then
                here.people[send] := zero;
              IF (P2 < 0) THEN Pre := '(Invisible) '
              ELSE IF (P2 > 0) THEN Pre := '(Hiding) '
                   ELSE Pre := '';
              IF (((P2 = 0) OR (AllStats.Stats.Privd)) AND
                  (SendLog <> MyLog)) THEN
              BEGIN
                IF HereDesc.Exits[P1].Goin = DEFAULT_DESC THEN
                  Writeln(Pre, s,' has gone ',direct[P1],'.')
                ELSE
                IF (HereDesc.Exits[P1].Goin <> 0) THEN
                BEGIN
                  Write(pre);
                  BlockSubs(HereDesc.exits[P1].goin,s)
                END
                ELSE
                  AllStats.Stats.Printed := FALSE;
              END ELSE
                AllStats.Stats.Printed := FALSE;
            END;
    E_ENTER: BEGIN
               SetPlaySlot(S, Send, SendLog, P2, P3);
               IF (P2 < 0) THEN Pre := '(Invisible) '
               ELSE IF (P2 > 0) THEN Pre := '(Hiding) '
               ELSE Pre := '';
               IF (((P2 = 0) OR (AllStats.Stats.Privd)) AND
                   (SendLog <> MyLog)) THEN
               BEGIN
                 IF HereDesc.Exits[P1].ComeOut = DEFAULT_DESC THEN
                   Writeln(Pre, s,' has come into the room from ',
                           direct[P1],'.')
                 ELSE
                 IF IsDescription(HereDesc.exits[P1].comeout) THEN
                 BEGIN
                   Write(pre);
                   BlockSubs(HereDesc.exits[P1].comeout,s);
                 END
                 ELSE
                   AllStats.Stats.Printed := FALSE;
               END ELSE
                 AllStats.Stats.Printed := FALSE;
             END;
    E_BEGIN: BEGIN
      SetPlaySlot(S, Send, SendLog, P3, P1);
      IF (SendLog <> MyLog) THEN
        Writeln(S,' appears in a brilliant burst of multicolored light.')
      ELSE
        AllStats.Stats.Printed := FALSE;
    END;
    E_QUIT: begin
      IF Here.People[Send].Kind = SendLog THEN
        Here.people[Send] := ZERO;
      IF (SendLog <> MyLog) THEN
        Writeln(S,' vanishes in a brilliant burst of multicolored light.')
      ELSE
        AllStats.Stats.Printed := FALSE;
    END;

    E_SAY:
    IF SendLog <> MyLog THEN
    BEGIN
      SetPlaySlot(Emsg, Send, SendLog, Here.People[Send].Hiding, P1);
      IF Length(S) + Length(Emsg) > 73 THEN
      BEGIN
        Writeln(Emsg,' says,');
        Writeln('"',s,'"');
      END
      ELSE
      begin
        IF (Rnd(100) < 50) OR (Length(S) > 50) THEN
          Writeln(Emsg,': "',s,'"')
        else
          Writeln(Emsg,' says, "',s,'"');
      END;
    END ELSE
      AllStats.Stats.Printed := FALSE;

    E_HIDESAY: BEGIN
                 Writeln('An unidentified voice speaks to you:');
                 Writeln('"',s,'"');
               END;

    E_ANNOUNCE: IF (((TargLog=0) AND (P1=0)) OR (TargLog=MyLog) OR 
                   (P1 = AllStats.Stats.Group)) AND (SendLog <> MyLog) THEN
                  Writeln(s)
                ELSE
                  AllStats.Stats.Printed := FALSE;

    E_SHUTDOWN: IF SendLog = MyLog THEN
                  Writeln('You shutdown the game: ',S)
                ELSE
                BEGIN
                  Writeln('MONSTER SHUTDOWN: ',s);
                  AllStats.Stats.Done := TRUE;
                END;

    E_HPOOFOUT: BEGIN
      IF Here.People[Send].Kind = SendLog THEN
        Here.people[send] := zero;
      IF AllStats.Stats.Privd THEN
        Writeln('Great wisps of blue smoke drift out of the shadows.')
      ELSE
        AllStats.Stats.Printed := FALSE;
    END;

    E_POOFIN:
    IF SendLog <> MyLog THEN
    BEGIN
      SetPlaySlot(S, Send, SendLog, Here.People[Send].Hiding, P4);
(* Need to update room here... *)
      IF ((P3 = 0) AND (P6 <> 1)) THEN
        Writeln('In an explosion of golden light ',s,' poofs into the room.')
      ELSE
        IF AllStats.Stats.Privd THEN
          Writeln('Some wisps of blue smoke drift about in the shadows.')
        ELSE
          AllStats.Stats.Printed := FALSE;
    END ELSE
      AllStats.Stats.Printed := FALSE;

    E_POOFOUT:
    IF SendLog <> MyLog THEN
    BEGIN
      IF (Here.People[Send].Kind = SendLog) THEN
        Here.People[Send] := zero;
      IF ((P3 = 0) AND (P6 <> 1)) THEN
        Writeln(s,' vanishes from the room in a cloud of blue smoke.')
      ELSE
        IF AllStats.Stats.Privd THEN
          Writeln('Some wisps of blue smoke drift about in the shadows.')
        ELSE
          AllStats.Stats.Printed := FALSE;
    END ELSE
      AllStats.Stats.Printed := FALSE;

    E_DETACH:  Writeln(s,' has destroyed the exit ', direct[P1], '.');
    E_NEWEXIT: Writeln(s,' has created an exit here.');
    E_SEARCH:
      IF SendLog <> MyLog THEN
        Writeln(S, ' seems to be looking for something.')
      ELSE
        AllStats.Stats.Printed := FALSE;

    E_FOUND: begin
      if getroom(theroom, here) then;
      IF SendLog <> MyLog THEN
        Writeln(S, ' appears to have found something.')
      ELSE
        AllStats.Stats.Printed := FALSE;
    END;

    E_UNHIDE: begin
      Writeln(S,' has stepped out of the shadows.');
      here.people[send].hiding := 0;
    end;
    E_FOUNDYOU: BEGIN
      Here.People[Targ].Hiding := 0;
      IF Targ = MySlot THEN
        Writeln('You''ve been discovered by ',S,'!')
      ELSE
        Writeln(Here.People[Send].Name,' has found ',
                Here.People[Targ].Name,' hiding in the shadows!');
    END;
    E_CHANGE: BEGIN
      IF TargLog = MyLog THEN
      BEGIN
        Write('Your ',AttribName(P1),' has changed to: ');
        CASE P1 OF
	  Att_Kills  : BEGIN
            IF GetChar(Allstats.Stats.Log, Charac) THEN
              AllStats.Stats.Kills := Charac.Kills;
            AttribAssignValue(AllStats.Stats.Log, P1,
                             AllStats.Stats.Kills);
	  END;
	  Att_Deaths  : BEGIN
            IF GetChar(Allstats.Stats.Log, Charac) THEN
              AllStats.Stats.Deaths := Charac.Deaths;
            AttribAssignValue(AllStats.Stats.Log, P1,
                             AllStats.Stats.Deaths);
	  END;
          Att_Health : BEGIN 
            IF GetChar(Allstats.Stats.Log, Charac) THEN
              AllStats.Stats.Health := Charac.Health;
            FixHealth(AllStats.Stats.Health, AllStats.MyHold.MaxHealth);
            AttribAssignValue(AllStats.Stats.Log, P1,
                             AllStats.Stats.Health);
            IF GetRoom(AllStats.Stats.Location, Here) THEN
            BEGIN
              Here.People[MySlot].Health := AllStats.Stats.Health;
              IF SaveRoom(AllStats.Stats.Location, Here) THEN;
            END;
          END;
          ATT_Mana : BEGIN
            IF GetChar(AllStats.Stats.Log, Charac) THEN
              AllStats.Stats.Mana := Charac.Mana;
            FixMana(AllStats.Stats, AllStats.MyHold.MaxMana);
            AttribAssignValue(AllStats.Stats.Log, P1, AllStats.Stats.Mana);
          END;
          ATT_Wealth : IF GetChar(AllStats.Stats.Log, Charac) THEN
                         AllStats.Stats.Wealth := Charac.Wealth;
          ATT_BankWealth : IF GetChar(AllStats.Stats.Log, Charac) THEN
                             AllStats.Stats.Bank := Charac.BankWealth;
          ATT_Experience : BEGIN
            IF GetInt(N_Experience, Classes) THEN
              AllStats.Stats.Experience := Classes[AllStats.Stats.Log];
            EquipmentStats(AllStats);
          END;
          ATT_OBJECTS : IF GetChar(AllStats.Stats.Log, Charac) THEN
                          AllStats.Stats.maxObj := Charac.MaxObjs;
          ATT_ROOMS : IF GetChar(AllStats.Stats.Log, Charac) THEN
                         AllStats.Stats.MaxRooms := Charac.MaxRooms;
          ATT_NAME : BEGIN
            IF GetShortName(s_na_pers, Pers) THEN
            BEGIN
              S := Pers.Idents[MyLog];
              AString := MyName + ' is now known as ' + s;
              MyName := s;
              AllStats.Stats.Name := MyName;
              IF GetRoom(AllStats.Stats.Location, Here) THEN
              BEGIN
                Here.People[MySlot].Name := MyName;
                IF SaveRoom(MyLoc, Here) THEN;
                IF (Here.People[MySlot].Hiding = 0) THEN
                  LogEvent(MySlot, MyLog, E_MSG, 0,0,0,0, Astring, MyLoc);
              END;
            END;
          END;
          ATT_Alignment : BEGIN
              IF GetChar(AllStats.Stats.Log, Charac) THEN
	      BEGIN
                 AllStats.Stats.Alignment := Charac.Alignment;
                 AString := MyName + ' has changed alignment to '
                         + ReturnAlignment(AllStats.Stats.Alignment, tmp);
                 LogEvent(MySlot, MyLog, E_MSG, 0,0,0,0, Astring, MyLoc);
              END;
          END;
          Att_Class : BEGIN
            IF GetInt(N_Class, Classes) THEN
            BEGIN
              AllStats.Stats.Class := Classes[MyLog];
              IF GetClass(Classes[MyLog], SomeClass) THEN
                LogEvent(MySlot, MyLog, E_MSG, 0,0,0,0, MyName +
                         ' is now '+a_an(SomeClass.Name)+'.', MyLoc);
              EquipmentStats(AllStats);
            END;
          END;
          OTHERWISE Writeln('Invalid attribute.');
        END;  (* Case *)
        Writeln(AttribValue(AllStats.Stats.Log, P1));
      END   (* Was it me? *)
      ELSE
      BEGIN
        if getroom(allstats.stats.location, here) then;
        AllStats.Stats.Printed := FALSE;
      END;
    END;

    E_PUNCH:
      IF SendLog <> MyLog THEN
      BEGIN
        IF GetRoom(AllStats.Stats.Location, Here) THEN
        BEGIN
          IF Targ = MySlot THEN
          BEGIN
            StartHighlight;
            GetPunch(P1, Here.People[Send].Name);
            AllStats.Stats.LastHit := SendLog;
            AllStats.Stats.LastHitString := Here.People[Send].Name+'''s fists of fury.';
            TakeHit(PunchForce(P1), CanDie, AllStats);
            StopHighlight;
            (* MWG                          
               AllStats.Tick.TkHealth := 300;  *)
          END
          ELSE
            ViewPunch(Here.People[Send].Name, Here.People[Targ].Name, P1);
        END;
      END ELSE
        AllStats.Stats.Printed := FALSE;
    E_S_DIST: BEGIN
      IF SendLog <> MyLog THEN
      BEGIN
        IF (TargLog = MyLog) OR (Targ = 0) THEN
          StartHighlight;
        Write('A ',s,' flies into the room hitting ');
        IF (TargLog = MyLog) or (Targ=0) THEN
        BEGIN
          AllStats.Stats.LastHit := SendLog;
          AllStats.Stats.LastHitString := 'a ' + s;
          IF TargLog = MyLog THEN
            Writeln('you!')
          ELSE
            Writeln('everyone!');
          PoorHealth(P1, FALSE, TRUE, CanDie, AllStats);
          StopHighlight;
        END
        ELSE
          IF GetShortName(s_NA_Pers, Pers) THEN
            Writeln(Pers.Idents[Targ]+'.')
          ELSE
            Writeln('UNKNOWN.');
      END
      ELSE
        AllStats.Stats.Printed := FALSE;
    END;

    E_MADE_SAVE:
      IF SendLog <> MyLog THEN
        Writeln(Here.People[Send].Name,' resisted the ',s,' spell.')
      ELSE
        AllStats.Stats.Printed := FALSE;

    E_S_SPELL:
      IF SendLog <> MyLog THEN
      BEGIN
        AString := Here.People[Send].Name;
        CASE P1 OF
          1 : Writeln(AString,' casts a ',s,' spell.');
          2 : Writeln(AString,'''s ',s,' spell fails.');
          3 : Writeln(AString,' just learned a ',s,' spell.');
          4 : Writeln(AString,' failed to learn a ',s,' spell.');
          OTHERWISE AllStats.Stats.Printed := FALSE;
        END; (* Case *)
      END ELSE
        AllStats.Stats.Printed := FALSE;

    E_BLOCKEXIT:
      IF SendLog <> MyLog THEN
      BEGIN
        AString := Here.People[Send].Name;
        Write(AString,' ',S,' the ');
        CASE P1 OF
        	north:	Write('northern');
        	south:	Write('southern');
         	east:	Write('eastern');
         	west:	Write('western');
         	up:	Write('upward');
      	  	down:	Write('downward');
        END;
        Writeln(' exit.');
        Here.ExitBlocked[P1] := P2;
      END ELSE
        AllStats.Stats.Printed := FALSE;

    E_ATTACK:
      IF SendLog <> MyLog THEN
      BEGIN
        AString := Here.People[Send].Name;
        IF Here.People[Send].Kind = SendLog THEN
        BEGIN
          Here.People[Send].NextAct := P2;
          IF Targ = MySlot THEN
          BEGIN
            StartHighlight;
            GetAttack(P1, AString, S);  (* Print it out *)
            TakeHit(P1, CanDie, AllStats);   (* Take the damage *)
            StopHighlight;
            AllStats.Stats.LastHit := SendLog;
            AllStats.Stats.LastHitString := AString+'''s '+s;
            AllStats.Stats.LastHitTime := Time;
        (* MWG     
            AllStats.Tick.TKHealth := 300;  *)
          END
          ELSE
          BEGIN
            ViewAttack(AString, Here.People[Targ].Name, P1, S);
            IF (Rnd(100)<40) AND (Here.People[MySlot].Hiding<>0) THEN
              NoiseHide(70, AllStats.Stats);
          END;
        END;  (* Is the person still in the room *)
      END ELSE
        AllStats.Stats.Printed := FALSE;

(* End of new event conversion *)
    E_MSG: IF (P1 = 0) THEN
           BEGIN
             IF (TargLog = 0) OR (Targ = MyLog) THEN
               Writeln(S);
           END
	   ELSE
           IF P1 = DEFAULT_DESC THEN
             AllStats.Stats.Printed := FALSE
           ELSE
           IF (Targ = MySlot) OR (Targ = 0) THEN
             Blocksubs(P1, S)
	   ELSE
             AllStats.Stats.Printed := FALSE;    
    E_TAKE:
      IF SendLog <> Mylog THEN
      BEGIN
        IF GetRoom(AllStats.Stats.Location, Here) THEN
          AString := Here.People[Send].Name;
        Writeln(AString + ' has picked up '+s+'.');
      END ELSE
        AllStats.Stats.Printed := FALSE;
    E_GETGOLD: BEGIN
                 IF (Here.GoldHere < P1) THEN P1 := Here.GoldHere;
                 IF (Here.GoldHere < 0) THEN P1 := 0;
                 Here.GoldHere := Here.GoldHere - P1;
                 IF SendLog = MyLog THEN
                 BEGIN
                   AllStats.Stats.Wealth := AllStats.Stats.Wealth + P1;
                   Writeln('You pick up ', P1:0, ' gold.');
                 END ELSE
                   Writeln(S, ' has picked up ', P1:0, ' gold.');
               END;
    E_SELL: BEGIN
              Here.Objs[P3] := P4;
              Here.ObjHide[P3] := P5;
              Writeln(S);
	    END;
    E_DROP: BEGIN
              IF (P1 = 1) THEN
              BEGIN
                Here.GoldHere := Here.GoldHere + P3;
                IF SendLog <> MyLog THEN
                  Writeln(S, ' has dropped ', P3:0, ' gold.')
                ELSE Writeln('You drop ', P3:0, ' gold.');
              END
              ELSE
              BEGIN
                IF SendLog <> MyLog THEN
                BEGIN
                  Here.Objs[P3] := P4;
                  Here.ObjHide[P3] := P5;
                  IF (P2 = 0) THEN (* Not silent *)
                    IF HereDesc.ObjDesc <> 0 THEN
                      PrintSubs(HereDesc.ObjDesc, ObjPart(P3))
                    ELSE
                      Writeln(S);
                END ELSE
                  AllStats.Stats.Printed := FALSE;
              END;
            END;
    E_LOB: BEGIN
             IF Timed THEN
             BEGIN
               Writeln(s+' *EXPLODES*!');
               AllStats.Stats.LastHit := SendLog;
               AllStats.Stats.LastHitString := S;
               PoorHealth(P1, FALSE, FALSE, CanDie, AllStats);
             END
             ELSE
             IF TheRoom = MyLoc THEN
             BEGIN
               Writeln(s+' just flew into the room.');
               Event.Targ := Event.Targ + GetTicks;
               TimeBufferEvent(Event, AllStats.TimedEvents);
             END
             ELSE
               AllStats.Stats.Printed := FALSE;
           END;
    E_BOUNCEDIN: begin
      if getroom(theroom, here) then;
      IF IsDescription(P2) THEN
        PrintSubs(P2, ObjPart(P1))
      ELSE
        Writeln(ObjPart(P1),' has bounced into the room.');
    end;
    E_EXAMINE: Writeln(S);
    E_IHID: begin
      here.people[send].kind := sendlog;
      here.people[send].name := s;
      here.people[send].hiding := p1;
      IF SendLog <> MyLog THEN
        Writeln(S,' has hidden in the shadows.')
      ELSE
        AllStats.Stats.Printed := FALSE;
    end;
    E_NOISES: IF NOT IsDescription(P2) THEN
                ShowNoises(P1)
              ELSE
                PrintDesc(P2);
    E_ALTNOISE: IF NOT IsDescription(P2) THEN
                  ShowAltNoise(P1)
                ELSE
                  BlockSubs(P2, MyName);
    E_REALNOISE: IF P1 > RND(100) THEN
                   ShowNoises(P1+100)
                 ELSE
                 IF AllStats.Stats.Privd THEN
                   Writeln('Your perfect ears hear somebody in the shadows.')
                 ELSE
                   AllStats.Stats.Printed := FALSE;
(* end of new event conversions *)
    E_HIDOBJ: BEGIN
      IF GetRoom(AllStats.Stats.Location, Here) THEN
        AString := Here.People[Send].Name;
      Writeln(AString,' has hidden the ',s,'.');
    END;
    E_PING: IF Targ = MySlot THEN
            BEGIN
              Writeln(S,' is pinging you.');
              LogEvent(MySlot, MyLog, E_PONG, Send, SendLog, 0,0,'',MyLoc);
            END
            ELSE
              Writeln(S,' is pinging ',Here.People[Targ].Name,'.');
    E_PONG: BEGIN
              AllStats.Op.PingAnswered := TRUE;
              AllStats.Stats.Printed := FALSE;
            END;
    E_HIDEPUNCH: IF Targ = MySlot THEN
                 BEGIN
                   Writeln(S,' pounces on you from the shadows!');
                   TakeHit(2,CanDie, AllStats);
                 END
                 ELSE
                 BEGIN
                   IF GetRoom(AllStats.Stats.Location, Here) THEN
                     Writeln(S,' jumps out of the shadows and attacks ',
                             Here.People[Targ].Name,'.');
                 END;
    E_SLIPPED: BEGIN
                 IF GetRoom(AllStats.Stats.Location, Here) THEN
                   AString := Here.People[Send].Name;
                 Writeln('The ',s,' has slipped from ', AString,'''s hands.');
               END;
    E_FAILGO: IF (P1 >= 1) AND (P1 <= MaxExit) THEN
    BEGIN
      IF IsDescription(P2) THEN
        BlockSubs(P2, S)
      ELSE
      BEGIN
        Writeln(S,' has failed to go ', Direct[P1],'.')
      END;
    END
    ELSE
      AllStats.Stats.Printed := FALSE;
    E_TRYATTACK: BEGIN
      IF GetRoom(AllStats.Stats.Location, Here) THEN
        AString := Here.People[Send].Name;
        IF P1 > 99 THEN
          IF TargLog = MyLog THEN
            Writeln('Your weapon is deflected by ',AString,'''s armor.')
          ELSE
            Writeln(S, ' is blocked by ',AString,'''s armor.')
        ELSE
          IF P1 > 0 THEN
            IF TargLog = MyLog THEN
              Writeln('Your weapon damage is reduced by ',AString,'''s armor.')
            ELSE
              Writeln(s,' damage is reduced by ',AString,'''s armor.');
      IF TargLog = MyLog THEN
        DamageWeapon(P1, AllStats);
    END;
    E_TRYSPELL: BEGIN       
                  IF Targ = MySlot THEN
                    Write('Your')
                  ELSE
                    Write(S);
                  Write(' spell is ');
                  CASE P1 OF
                     1..33:  Write('slightly');
                     34..66: Write('significantly');
                     67..99: Write('greatly');
                     OTHERWISE Write('totally');
                  END;
                  AString := Here.People[Send].Name;
                  Writeln(' diffused by ',AString,'''s armor.');
                END;
    E_PINGONE: IF Targ = MySlot THEN
               BEGIN
                 Writeln('The Monster program regrets to inform you that a destructive ping has');
                 Writeln('destroyed your existence.  Please accept our apologies.');
                 Xpoof(R_Void, AllStats, 1);
                END
                ELSE
                  Writeln(s,' shimmers and vanishes from sight.');
    E_CLAIM:  Writeln(S,' has claimed this room.');
    E_DISOWN: Writeln(S,' has disowned this room.');
    E_WEAKER: BEGIN
                IF Here.People[Send].Kind = SendLog then
                begin
                  Here.People[Send].Name := S;
                  Here.People[Send].Health := P1;
                  DescHealth(Send, S);
                end;
              END;
    E_OBJCLAIM: BEGIN
                  AString := Here.People[Send].Name;
                  Writeln(AString,' is now the owner of the ',s,'.');
                END;
    E_OBJDISOWN: BEGIN
                   AString := Here.People[Send].Name;
                   Writeln(AString,' has disowned the object ',s,'.');
                 END;
    E_WHISPER:  BEGIN
                  AString := Here.People[Send].Name;
                  IF Targ = MySlot THEN
                  BEGIN
                    IF Length(S) < 39 THEN
                      Writeln(AString,' whispers to you, "',s,'"')
                    ELSE
                    BEGIN
                      Writeln(AString,' whispers something to you:');
                      Write(AString,' whispers, ');
                      IF Length(S) > 50 THEN
                        Writeln;
                      Writeln('"',s,'"');
                    END;
                  END
                  ELSE
                  IF (AllStats.Stats.Privd) OR (Rnd(100) > 90) THEN
                  BEGIN
                    Writeln('You overhear ',AString,' whispering to ',here.people[targ].name,'!');
                    Write(AString,' whispers, ');
                    IF Length(S) > 50 THEN
                      Writeln;
                    Writeln('"',s,'"');
                  END
                  ELSE
                    Writeln(AString,' is whispering to ',here.people[targ].name,'.');
                END;
    E_DESTROY:    Writeln(s);
    E_OBJPUBLIC:  Writeln('The object ',s,' is now public.');
    E_UNMAKE:     BEGIN
                    AString := Here.People[Send].Name;
                    Writeln(AString,' has unmade ',s,'.');
                  END;
    E_LOOKDETAIL: BEGIN
                    AString := Here.People[Send].Name;
                    Writeln(AString, ' is looking at the ',s,'.');
                  END;
    E_ACCEPT:     Writeln(S,' has accepted an exit here.');
    E_REFUSE:     Writeln(S,' has refused an Accept here.');
    E_DIED:       BEGIN
                    Writeln(s);
                    IF TargLog = MyLog THEN
                    BEGIN
                      AllStats.Stats.Kills := AllStats.Stats.Kills + 1;
                      SaveKiller(P1, AllStats.Stats.Group);
                      DieChangeExperience(P2, AllStats.Stats.Experience,
                                          AllStats.Stats);
                      EquipmentStats(AllStats);
                    END;
                  END;         
    E_LOOKYOU:    BEGIN
                    AString := Here.People[Send].Name;
                    IF Targ = MySlot THEN
                      Writeln(AString,' is looking at you.')
                    ELSE
                      Writeln(AString,' looks at ',Here.People[Targ].Name,'.');
                  END;
    E_LOOKSELF:   Writeln(S,' is making a self-appraisal.');
    E_FAILGET:    Writeln(S,' fails to get ',ObjPart(P1),'.');
    E_FAILUSE:    Writeln(S,' fails to use ',ObjPart(P1),'.');
    E_CHILL:      IF NOT IsDescription(P1) THEN
                    Writeln('A chill wind blows over you.')
                  ELSE
                    PrintDesc(P1);
    E_NOISE2: BEGIN
                IF P1>50 THEN
                  CASE P2 OF
                     1: Writeln('Strange, gutteral noises sound from everywhere.');
                     2: Writeln('A chill wind blows past you, almost whispering as it ruffles your clothes.');
                     3: Writeln('Muffled voices speak to you from the air!');
                     OTHERWISE Writeln('The air vibrates with a chill shudder.');
                  END
                ELSE
                  Writeln('You hear a whisper,"',s,'"');
              END;
    E_INVENT: Writeln(S,' is taking inventory.');
    E_POOFYOU: BEGIN
                 IF TargLog = MyLog THEN
                 BEGIN
                   Writeln;
                   Writeln(S,' directs a firey burst of bluish energy at you!');
                   Writeln('Suddenly, you find yourself hurtling downwards through misty blue clouds.');
                   Writeln('Your descent slows, the smoke clears, and you find yourself in a new place...');
                   Writeln;
                   Xpoof(P1, AllStats);
                 END
                 ELSE
                   AllStats.Stats.Printed := FALSE;
               END;
    E_WHO: CASE P1 OF
             0 : Writeln(S,' produces a "who" list and reads it.');
             1 : Writeln(S,' is seeing who''s playing Monster.');
             OTHERWISE Writeln(S,' checks the "who" list.');
           END;
    E_PLAYERS:     BEGIN
                     AString := Here.People[Send].Name;
                     Writeln(AString,' checks the "players" list.');
                   END;
    E_VIEWSELF:    BEGIN
                     AString := Here.People[Send].Name;
                     Writeln(AString,' is reading ',s,'''s self-description.');
                   END;
    E_MissileWhiz: Writeln(S);
    E_MissileHit:  IF P1 = MySlot THEN
                   BEGIN
                     AllStats.Stats.LastHit := SendLog;
                     AllStats.Stats.LastHitString := S;
                     Writeln('You are struck by ' + s);
                     PoorHealth(P2, TRUE, FALSE, CanDie, AllStats);
                   END
                   ELSE
                     IF GetRoom(AllStats.Stats.Location, Here) THEN
                       Writeln(Here.People[P1].Name + ' is struck by ' + s);
    E_STEALFAIL: IF (Targ = MySlot) THEN
                   Writeln(S)
                 ELSE
                   AllStats.Stats.Printed := FALSE;
    E_REMOTE : BEGIN
                 AllStats.Stats.Printed := FALSE;
                 IF ((TargLog = MyLog) OR (TargLog = 0)) THEN
                 BEGIN
                   Parser(S, AllStats);
                   AllStats.Stats.Printed := TRUE;
                 END;
               END;
    E_OPCHECK: BEGIN
                 AllStats.Stats.Printed := FALSE;
                 CASE P1 OF
                    0 : IF AllStats.Stats.Privd THEN 
                        BEGIN
                          Writeln(s);
                          AllStats.Stats.Printed := TRUE;
                        END;
                    1 : IF AllStats.Stats.Privd THEN
                          LogEvent(0, 0,E_ANNOUNCE, Send, SendLog, 0,0,
                           '[Name = '+MyName+'] [Realid = '+Userid+
                           '] [Userid = '+AllStats.Stats.Userid+']', R_ALLROOMS);

                    2 : IF TargLog = MyLog THEN
                          AllStats.Op.OpCheckComm := SendLog;
                    3 : IF TargLog = MyLog THEN
                          AllStats.Op.OpCheckComm := 0;
                    6 : IF (TargLog = MyLog) THEN
                        BEGIN
                          AllStats.Op.Frozen := TRUE;
                          AllStats.Stats.Printed := TRUE;
                          Writeln('You have been frozen.');
                        END;
                    7 : IF (TargLog = MyLog) THEN 
                        BEGIN
                          AllStats.Op.Frozen := FALSE;
                          AllStats.Stats.Printed := TRUE;
                          Writeln('You have been set free.');
                        END;
                 END;  (* Case Statement *)
               END;
    E_ENERGYDRAIN: BEGIN
                     IF GetRoom(AllStats.Stats.Location, Here) THEN
                       AString := Here.People[Send].Name;
                     IF Targ = MySlot THEN
                     BEGIN
                       Writeln(AString, ' has drained vital essence from you!');
                       ChangeExp(P1, MyLog, AllStats.Stats.Experience)
                     END
                     ELSE
                       Writeln(AString,' has draind vital essence from ',
                               Here.People[Targ].Name,'.');
                   END;
    E_S_EFFECT: BEGIN
                  IF GetRoom(AllStats.Stats.Location, Here) THEN
                    AString := Here.People[Send].Name;
                  IF ((Targ = MySlot) OR (TargLog = 0)) THEN
                  BEGIN
                    StartHighlight;
                    AllStats.Stats.LastHit := SendLog;
                    AllStats.Stats.LastHitString := AString+'''s '+s;
                    Write(AString,' casts a ',s,' spell at ');
                    IF Targ = 0 THEN
                      Writeln('everyone.')
                    ELSE
                      Writeln('you.');
                    Effect(P1, P2, S, AllStats);
                    StopHighlight;
                  END
                  ELSE 
                  BEGIN
                    AString := Here.People[Targ].Name;
                    IF SendLog = TargLog THEN
                      AString := 'himself';
                    Writeln(Here.People[Send].Name, ' casts a ',S,' spell at ',
                            AString,'.');
                  END;
                END;
   E_POSSESS: BEGIN
                IF TargLog = MyLog THEN
                BEGIN
                  Writeln('Your body is being taken over by ',S,'.');
                  DoPossess(S, FALSE, AllStats);
                END
                ELSE
                  AllStats.Stats.Printed := FALSE;
              END;
    E_POISON: BEGIN
                AString := Here.People[Send].Name;
                IF (Targ = MySlot) THEN
                BEGIN
                  IF NOT(MakeSavingThrow('poison',
                    AllStats.Stats.Experience, MySlot, MyLoc)) THEN
                  BEGIN
                    IF NOT AllStats.Stats.Poisoned THEN
                      Writeln('You''ve been poisoned by ',AString,'''s ',s);
                    AllStats.Stats.Poisoned := TRUE;
                  END
                END
                ELSE
                  Writeln(AString,' has poisoned ', Here.People[Targ].Name);
              END;
    OTHERWISE
      Writeln('*** Bad Event ***(', act:0,')');
  END;
END;

(* -------------------------------------------------------------------------- *)

PROCEDURE DoTimedEvent(VAR AllStats : AllMyStats);

var
  loop, ticks : integer;

BEGIN
  ticks := getticks;
  for loop := 1 to maxtimedevents do
  begin
    if (ticks>allstats.timedevents[loop].targ) then
    begin
      if (allstats.timedevents[loop].loc = allstats.stats.location) and
         (allstats.timedevents[loop].action <> 0) then
      begin
        HandleEvent(TRUE, TRUE, allstats.timedevents[loop], AllStats);
        AllStats.TimedEvents[loop].Action := 0;
      end
      else
        AllStats.TimedEvents[Loop].Action := 0;
    end;
  end;
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CheckEvents(Silent : BYTE_BOOL := FALSE; CanDie : BYTE_BOOL := TRUE;
		      Timed : BYTE_BOOL := FALSE; VAR AllStats : AllMyStats);

VAR
  ea : EventArray;
  slot : integer;
  myev : integer;

BEGIN
  slot := (allstats.stats.location mod (numeventrec-1)) + 1;
  if getevent(slot, ea, false) then
  begin
    AllStats.Tick.TkEvent := getticks + 5;
    myev := allstats.stats.eventnum;
    WHILE ((ea.point <> allstats.stats.eventnum) and
           (myev = allstats.stats.eventnum)) DO
    BEGIN
      IF DEBUG[DEBUG_HandleEvent] THEN
        writeln('roomonly: Ea.point ',ea.point:0,
                'myevent ', allstats.stats.eventnum:0);
      allstats.stats.eventnum := allstats.stats.eventnum + 1;
      myev := myev + 1;
      if (myev > numevents) then
        myev := 1;
      if allstats.stats.eventnum > numevents then
        allstats.stats.eventnum := 1;
      IF (ea.events[allstats.stats.eventnum].Loc = AllStats.Stats.Location) AND
(*
         (ea.events[allstats.stats.eventnum].SendLog <> Allstats.stats.Log) AND
*)
        ((ea.events[allstats.stats.eventnum].TargLog = AllStats.Stats.Log) or
         (ea.events[allstats.stats.eventnum].TargLog = 0)) THEN
        HandleEvent(CanDie, Timed, ea.events[allstats.stats.eventnum],
                    AllStats);
        SaveRoom(AllStats.Stats.Location, here);
    END;
  end;
  DoTimedEvent(AllStats);
END;

(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE CheckAllEvents(Silent : BYTE_BOOL := FALSE; CanDie : BYTE_BOOL := TRUE;
		      Timed : BYTE_BOOL := FALSE; VAR AllStats : AllMyStats);

VAR
  ea : EventArray;
  myev : integer;

BEGIN
  if getevent(numeventrec, ea, false) then
  begin
(*    writeln("Getticks: ", getticks);*)
    AllStats.Tick.TkAllEvent := GetTicks + 10;
(*    writeln("set to: ", allstats.tick.tkallevent);*)
    myev := allstats.stats.alleventnum;
    WHILE ((ea.point <> allstats.stats.alleventnum) and
           (myev = allstats.stats.alleventnum)) DO
    BEGIN
      IF DEBUG[DEBUG_HandleEvent] THEN
        writeln('GLOBAL: Ea.point ',ea.point:0,
                'myall ', allstats.stats.alleventnum:0);
      myev := myev + 1;
      if (myev > numevents) then myev := 1;
      allstats.stats.alleventnum := allstats.stats.alleventnum + 1;
      if allstats.stats.alleventnum > numevents then
        allstats.stats.alleventnum := 1;
      HandleEvent(CanDie, Timed, ea.events[allstats.stats.alleventnum],
                  AllStats);
    END;
  END;
END;

(* -------------------------------------------------------------------------- *)
[EXTERNAL] PROCEDURE ActWander(VAR AllStats : AllMyStats); extern;
(* -------------------------------------------------------------------------- *)

[GLOBAL]
PROCEDURE AllEvents(Silent:BYTE_BOOL := false; VAR DidCheck : BYTE_BOOL;
                    VAR AllStats : AllMyStats);

VAR
  TickCount, I : INTEGER;
  SomeEvent : AnEvent;

BEGIN
  DidCheck := FALSE;
  TickCount := GetTicks;

  IF TickCount > AllStats.Tick.TkEvent THEN
    CheckEvents(Silent, TRUE, FALSE, AllStats);
  IF TickCount > AllStats.Tick.TkAllEvent then
    CheckAllEvents(Silent, TRUE, FALSE, AllStats);
  IF TickCount > AllStats.Tick.TkRandMove then
    ActWander(AllStats);
  IF TickCount > AllStats.Tick.TkRandAct then
    ActMonster(AllStats);

  IF (TickCount > AllStats.Tick.TKHealth) AND (AllStats.Tick.Tkhealth <> 0) THEN
  BEGIN
    IF Debug[DEBUG_Ticker] THEN
      Writeln('Checking ticker health.');
    TimeHealth(AllStats);
  END;

  IF (TickCount > AllStats.Tick.TKMana) AND (AllStats.Tick.TkMana <> 0) THEN
  BEGIN
    IF Debug[DEBUG_Ticker] THEN
      Writeln('Checking ticker mana.');
    TimeMana(AllStats);
  END;

  IF AllStats.Tick.Invisible AND (TickCount >= AllStats.Tick.TkInvisible)
     AND (AllStats.Tick.TkInvisible <> -1) THEN
  BEGIN
   IF Debug[DEBUG_Ticker] THEN
      Writeln('Checking ticker invisible.');
    TimeInvisible(AllStats.Tick, AllStats.Stats.Location,
                  AllStats.Stats.Slot, AllStats.Stats.Log);
  END;

  IF AllStats.Tick.SeeInvisible AND (TickCount >= AllStats.Tick.TkSee)
     AND (AllStats.Tick.TkSee <> 0) THEN
  BEGIN
    IF Debug[DEBUG_Ticker] THEN
      Writeln('Checking ticker see invisible.');
    TimeSee(AllStats.Tick, AllStats.Stats.Name, AllStats.Stats.Slot,
            AllStats.Stats.Log, AllStats.Stats.Location, FALSE);
  END;

  IF (AllStats.Tick.TkStrength <> 0) AND (TickCount >= AllStats.Tick.TkStrength) THEN
    TimeStrength(AllStats);

  IF (AllStats.Tick.TkSpeed <> 0) AND (TickCount >= AllStats.Tick.TkSpeed) THEN
    TimeSpeed(AllStats);

  IF (TickCount >= AllStats.Tick.TkRandomEvent) THEN
  BEGIN
    AllStats.Tick.TkRandomEvent := TickCount + 40;
    IF Debug[DEBUG_Ticker] THEN
      Writeln('Checking ticker events.');
    RndEvent(AllStats);
    TimeUnwho(AllStats.Stats.Log, AllStats.Stats.Location, 
              AllStats.Stats.Privd);
  END;
END;

(* -------------------------------------------------------------------------- *)

END.
