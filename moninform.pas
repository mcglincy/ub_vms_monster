[INHERIT ('monconst', 'montype')]

MODULE MonInform(OUTPUT);

%include 'headers.txt'

[GLOBAL]
PROCEDURE Inform_Destroy(S  : String);
BEGIN
  Writeln('The '+s+' was destroyed.');
END;

[GLOBAL]
PROCEDURE Inform_NoGo;
BEGIN
  Writeln('You can''t go that way.');
END;

[GLOBAL]
PROCEDURE Inform_NoPrivs(Name : String);
BEGIN
  Writeln('Sorry, ',Name,', but that requires "Privs".  Maybe next year.');
END;

[GLOBAL]
FUNCTION CheckPrivs(Privd : BYTE_BOOL; Name : String) : BYTE_BOOL;
BEGIN
  CheckPrivs := Privd;
  IF NOT Privd THEN 
    Inform_NoPrivs(Name);
END;

[GLOBAL]
PROCEDURE Inform_NoRoom;
BEGIN
  Writeln('There is not enough room here.');
END;

[GLOBAL]
PROCEDURE Inform_Contact(S : String);
BEGIN
  Writeln(S,' notify ',CONTACT_USERID,'.');
END;

[GLOBAL]
PROCEDURE Inform_BadCmd;
BEGIN
  Writeln('Bad command.  Type help for a list of commands.');
END;

[GLOBAL]
PROCEDURE Inform_BadAttrib;
BEGIN
  Writeln('Bad attribute.  Use ? for more help.');
END;

[GLOBAL]
PROCEDURE Inform_NotHolding;
BEGIN
  Writeln('You''re not holding that.  To see what you''re holding, type INV.');
END;

[GLOBAL]
PROCEDURE Inform_Sticky(S: String);
BEGIN
 Writeln('The '+ S +' is sticky.');
END;

[GLOBAL]
PROCEDURE Inform_NoFight;
BEGIN
  Writeln('You cannot fight here.');
END;

[GLOBAL]
PROCEDURE Inform_NoAlterExit;
BEGIN
  Writeln('You are not allowed to alter that exit.');
END;

END.
