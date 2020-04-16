[external] PROCEDURE ReadInAllRandoms; extern;

[external] function putrandommonstertoken(loc : integer;
	randtype : integer) : byte_bool; extern;

[external] procedure putrandom(s : string; var allstats : allmystats); extern;

[external] function israndommonster(people : peoplerec) : byte_bool; extern;

[external] procedure customrandom(randomnum : integer;
	var allstats : allmystats); extern;

[external] procedure createrandom(s : string;
	var allstats : allmystats); extern;

[external] procedure zaprandom(num : integer); extern;

[external] procedure actwander(var allstats : allmystats); extern;

[external] procedure followme(var allstats : allmystats;
	dir : integer); extern;

[external] procedure actmonster(var allstats : allmystats); extern;

