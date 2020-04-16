[inherit('sys$library:starlet','sys$library:pascal$lib_routines','monconst',
         'montype')]
MODULE SEND_MAIL;
TYPE
  item_list_3 = RECORD
    buf_len : $uword;
    it_code : $uword;
    buf_adr : unsigned;
    ret_len : unsigned;
  END;

VAR
  dummy   : array [1..1] of item_list_3 := zero;
  inlist  : array [1..2] of item_list_3;
  context : unsigned := 0;  
  subject : string;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_begin(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_add_address(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_add_attribute(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_add_bodypart(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_message(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[ASYNCHRONOUS,EXTERNAL]
PROCEDURE mail$send_end(VAR con: unsigned;
          VAR inlist: ARRAY [$l1..$u1:integer] OF item_list_3;
          VAR outlist: ARRAY [$l2..$u2:integer] OF item_list_3); EXTERNAL;

[GLOBAL]
procedure mail_user(user : packed array[$l1..$u1:integer] of char;
                    filen : packed array[$l2..$u2:integer] of char);
begin

{ Initialization of Information }

  subject := 'Introduction to Monster';

{ Mail$Send_Begin - Initializes Mail Sending Context }

  inlist[1].buf_len := 0;
  inlist[1].it_code := mail$_send_no_pers_name;
  inlist[1].buf_adr := 0;
  inlist[2] := zero;
  mail$send_begin(context, inlist, dummy);

{ Mail$Send_Add_Address - Specifies to Whom the Mail is for }

  inlist[1].buf_len := length(user);
  inlist[1].it_code := mail$_send_username;
  inlist[1].buf_adr := iaddress(user);
  inlist[2] := zero;
  mail$send_add_address(context, inlist, dummy);

{ Mail$Send_Add_Attribute - Adds Subject line }

  inlist[1].buf_len := length(subject);
  inlist[1].it_code := mail$_send_subject;
  inlist[1].buf_adr := iaddress(subject);
  inlist[2] := zero;
  mail$send_add_attribute(context, inlist, dummy);

{ Mail$Send_Add_Bodypart - Specifies the File to be Sent }

  inlist[1].buf_len := length(filen);
  inlist[1].it_code := mail$_send_filename;
  inlist[1].buf_adr := iaddress(filen);
  inlist[2] := zero;
  mail$send_add_bodypart(context, inlist, dummy);

{ Mail$Send_Message - Sends the Actual Message }

  mail$send_message(context, dummy, dummy);

{ Mail$Send_End - Ends the Mail Sending Routine }

  mail$send_end(context, dummy, dummy);

END;

end. (* Module sendmail *)
