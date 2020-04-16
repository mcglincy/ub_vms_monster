[inherit ('monconst','montype','monglobl','sys$library:starlet')]

MODULE MailBox(INPUT, OUTPUT);

%include 'headers.txt'

(* -------------------------------------------------------------------------- *)
 
[ASYNCHRONOUS] PROCEDURE Lib$Signal (
	%IMMED Condition_Value : UNSIGNED;
	%IMMED Number_Of_Arguments : INTEGER := %IMMED 0;
	%IMMED FAO_Argument : [LIST,UNSAFE] INTEGER); EXTERNAL;

VAR
  ItemList : ARRAY[1..2] OF ItemListCell;
  Translation : String;
  Status : UNSIGNED;
  MboxType : INTEGER := 0;   (* Temporary *)
  Channel : $UWORD;
  MboxFile : FILE OF String;

[GLOBAL]
PROCEDURE CreateKeyboard;

VAR
  Status : UNSIGNED;
  Tfunc : INTEGER := 0;
  TimeOut : INTEGER := 1;
  Init : CHAR := ZERO;

BEGIN
  Status := $ASSIGN(%stdescr 'SYS$INPUT', IN_chan,,);
  IF NOT ODD(Status) THEN
    LIB$SIGNAL(Status);

  List[1].Buffer_Length := 0;
  List[1].Item_code := trm$_editmode;
  List[1].Buffer_Addr := trm$k_em_rdverify;
  List[1].Return_Addr := 0;

(* Allow some space for overflow of escape characters.  This will *)
(* prevent partial escape sequence errors.                        *)

  List[2].Buffer_Length := 0;
  List[2].Item_code := trm$_esctrmovr;
  List[2].Buffer_Addr := 5;
  List[2].Return_Addr := 0;

(* Set the offset to 0, which otherwise would be after the initial string. *)

  List[3].Buffer_Length := 0;
  List[3].Item_code := trm$_inioffset;
  List[3].Buffer_Addr := 0;
  List[3].Return_Addr := 0;

(* Set the function modifiers. *)

  tfunc := trm$m_tm_noedit +
           trm$m_tm_nofiltr +
           trm$m_tm_norecall +
           trm$m_tm_escape;

  List[4].Buffer_Length := 0;
  List[4].Item_code := trm$_modifiers;
  List[4].Buffer_Addr := tfunc;
  List[4].Return_Addr := 0;

  List[5].Buffer_Length := 0;
  List[5].Item_code := trm$_timeout;
  List[5].Buffer_Addr := TimeOut;
  List[5].Return_Addr := 0;

(* Define the initial string. *)

  List[6].Buffer_Length := length(init);
  List[6].Item_code := trm$_inistrng;
  List[6].Buffer_Addr := iaddress(init);
  List[6].Return_Addr := 0;
END;

END.
