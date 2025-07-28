options fullstimer source source2 msglevel=i mprint notes;
options sastrace=",,,s" sastraceloc=saslog nostsuffix;
proc options;
run;
libname _all_ list;

libname swimout 'C:\SAS WORK';

%let filepath = C:\MeetResults_SourceData.txt;

data resultsClean invalid unattached disqualified;
	infile "&filepath" firstobs=10 truncover;
	length team $30 line $200 genderLabel $6 eventLabel $30 validationMessage $20 
	       stateCode $2 genderCode 8 gender $6 event $100 rawCourse $20 parsedCourse $10 
	       combinedDistanceCourse $20 eventCode 8 FirstName $30 LastName $30 Name $70
	       teamState $8 team $30 time $10 points 8 sas_time 8
	       placetest $10 placeToken $10 LastPart $100 testScan $20;
	format sas_time time12.3;

	retain team teamState genderCode event gender validGenderFlag distance combinedDistanceCourse eventCode;

	keep validationMessage team teamState genderCode eventCode Name FirstName LastName age sas_time time regionCode combinedDistanceCourse gender event;


	input line $200.;

	validNameFlag = 0;
	validAgeFlag = 0;
	validRegionFlag = 0;
	unattachedFlag = 0;
	disqualifiedFlag = 0;
	validationMessage = ' ';
	regionCode = .;

	if prxmatch('/^(Women|Men)\b/', line) then do;
		gender = scan(line, 1);
		if gender = "Women" then genderCode = 1;
		else if gender = "Men" then genderCode = 2;
		else do;
			genderCode = 0;
			validationMessage = 'Invalid Gender';
		end;
		validGenderFlag = 1;

		event = substr(line, length(gender) + 2);
		rawCourse = scan(event, 4, ' ');

		select (rawCourse);
			when ("Freestyle") parsedCourse = "Free";
			when ("Backstroke") parsedCourse = "Back";
			when ("Breaststroke") parsedCourse = "Breast";
			when ("Butterfly") parsedCourse = "Fly";
			when ("IM") parsedCourse = "IM";
			otherwise parsedCourse = "Unknown";
		end;

		distance = scan(event, 2, ' ');
		combinedDistanceCourse = catx(' ', distance, parsedCourse);

		select (combinedDistanceCourse);
			when ("50 Free") eventCode = 1;
			when ("100 Free") eventCode = 2;
			when ("200 Free") eventCode = 3;
			when ("400 Free", "500 Free") eventCode = 4;
			when ("800 Free", "1000 Free") eventCode = 5;
			when ("1500 Free", "1650 Free") eventCode = 6;
			when ("50 Back") eventCode = 7;
			when ("100 Back") eventCode = 8;
			when ("200 Back") eventCode = 9;
			when ("50 Breast") eventCode = 10;
			when ("100 Breast") eventCode = 11;
			when ("200 Breast") eventCode = 12;
			when ("50 Fly") eventCode = 13;
			when ("100 Fly") eventCode = 14;
			when ("200 Fly") eventCode = 15;
			when ("100 IM") eventCode = 16;
			when ("200 IM") eventCode = 17;
			when ("400 IM") eventCode = 18;
			otherwise eventCode = .;
		end;

		return;
	end;
	else if prxmatch('/^\s*$/', line) then return;
	else if prxmatch('/^\s*\d+\.\d+\b/', line) then return;
	else if prxmatch('/^\s*\d{1,2}:\d{2}\.\d{2}/', line) then return;

	else if prxmatch('/^\s*\d+/', line) or prxmatch('/^\s*--/', line) then do;
		placetest = scan(line, 1, ' ');
		if strip(placetest) = "--" then disqualifiedFlag = 1;
		else if notdigit(placetest) = 0 then place = input(placetest, 8.);

		firstSpacePos = index(line, ' ');
		commaPos = index(line, ',');
		placeToken = scan(line, 1, ' ');
		placeLength = length(placeToken);

		LastName = strip(substr(line, placeLength + 2, commaPos - placeLength - 2));
		LastPart = scan(line, 2, ',');

		testScan = scan(LastPart, 2, ' ');
		valueIndex = 2;

		if notdigit(testScan) = 1 then do;
			FirstName = catx(' ', scan(LastPart, 1, ' '), scan(LastPart, 2, ' '));
			valueIndex = 3;
		end;
		else FirstName = scan(LastPart, 1, ' ');

		Name = catx(' ', FirstName, upcase(LastName));

		if missing(FirstName) or missing(LastName) then validationMessage = 'Missing Name';
		else validNameFlag = 1;

		age = input(scan(LastPart, valueIndex, ' '), 8.);
		if age < 18 or age > 100 then validationMessage = 'Invalid Age';
		else validAgeFlag = 1;

		teamState = scan(LastPart, valueIndex + 1, ' ');
		if teamState = "Unattach" then unattachedFlag = 1;
		else stateCode = scan(teamState, 2, '-');

		time = scan(LastPart, valueIndex + 2, ' ');
		points = input(scan(LastPart, valueIndex + 3, ' '), 8.);

		if not missing(time) then do;
			if countc(time, ':') = 1 then do;
				minutes = input(scan(time, 1, ':'), best.);
				seconds = input(scan(time, 2, ':'), best.);
				sas_time = 60 * minutes + seconds;
			end;
			else if countc(time, ':') = 0 then sas_time = input(time, best.);
			else sas_time = .;
		end;

		select (stateCode);
			when ("AK") regionCode = 56;
			when ("AZ") regionCode = 48;
			when ("AR") regionCode = 23;
			when ("CO") regionCode = 32;
			when ("CT") regionCode = 5;
			when ("FL") regionCode = 14;
			when ("GA") regionCode = 45;
			when ("HI") regionCode = 39;
			when ("IN") regionCode = 16;
			when ("IA") regionCode = 40;
			when ("KY") regionCode = 41;
			when ("MD") regionCode = 9;
			when ("MI") regionCode = 19;
			when ("NC") regionCode = 13;
			when ("ND") regionCode = 52;
			when ("NJ") regionCode = 7;
			when ("NM") regionCode = 42;
			when ("OH") regionCode = 17;
			when ("OK") regionCode = 27;
			when ("OR") regionCode = 37;
			when ("SC") regionCode = 55;
			when ("SD") regionCode = 54;
			when ("UT") regionCode = 34;
			when ("VA") regionCode = 12;
			otherwise regionCode = .;
		end;

		if regionCode ne . then validRegionFlag = 1;
		else validationMessage = 'Invalid Region';

		if validAgeFlag and validNameFlag and validGenderFlag then do;
			if disqualifiedFlag then output disqualified;
			else if unattachedFlag then output unattached;
			else if validRegionFlag then output resultsClean;
			else output invalid;
		end;
		else output invalid;
	end;
run;

data multi_named_people;
    set resultsClean unattached disqualified;

    length fullName $100;
    fullName = catx(' ', FirstName, LastName);

    if countw(fullName, ' ') > 2 then output;
run;

/* --- SORT AND TOP 10 --- */
proc sort data=resultsClean out=sortedResults;
    by genderCode eventCode sas_time;
run;

/* --- TOP TEN SWIMMERS FORMATTED NICELY --- */

data top10;
    set sortedResults;
    by genderCode eventCode;
    retain rank;
    if first.eventCode then rank = 1;
    else rank + 1;
    if rank <= 10;
run;


ods pdf file='C:\Users\jobyun\OneDrive - SAS\Documents\Top10SplitTables.pdf' style=journal;

title "Top 10 Swimmers by Gender and Event";
proc sort data=top10;
    by gender combinedDistanceCourse;
run;

proc print data=top10 label noobs;
    by gender combinedDistanceCourse;
    id gender combinedDistanceCourse;
    var rank FirstName LastName age sas_time regionCode;
	label gender="Gender" combinedDistanceCourse = "Event" rank = "Position" sas_time= "Time";
	format sas_time time12.3;
run;

ods pdf file='C:\SAS WORK\MultiNamedSwimmers.pdf' style=journal;

title "Swimmers with Multiple-Word Names";
proc print data=swimout.multi_named_people label noobs;
    var FirstName LastName teamState age event;
    label 
        FirstName = "First Name"
        LastName = "Last Name"
        teamState = "Team State"
        age = "Age"
        event = "Event";
run;

ods pdf close;
