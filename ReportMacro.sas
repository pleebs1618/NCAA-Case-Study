libname swimout 'C:\SAS WORK';

data all_swimmers;
    set resultsClean unattached disqualified;
    length team $30;
    if teamState = "Unattach" then team = "Unattached";
    else team = scan(teamState, 1, '-');
run;

proc sort data=all_swimmers out=team_sorted;
    by team LastName FirstName event;
run;

data swimout.team_sorted;
    set team_sorted;
run;

%macro team_report(team=);
	%if %length(&team) > 0 %then %let team = %upcase(%sysfunc(strip(&team)));


    /* List of known teams */
    proc sort data=team_sorted(keep=team) nodupkey out=unique_teams;
        by team;
    run;

    /* Determine mode: specific team vs all */
    %if "&team" = "" %then %do;
        /* Report for all teams */
        data _null_;
            set team_sorted;
            by team;
            file print;

            if first.team then do;
                put "==============================";
                put "TEAM REPORT FOR: " team;
                put "==============================";
            end;

            put FirstName $15. LastName $15. gender $6. age 3. event $25. sas_time time8.2;
        run;
    %end;
    %else %do;
        /* Verify that team exists without PROC SQL */
        %let found = 0;
        data _null_;
            set unique_teams;
            if upcase(team) = "&team" then call symputx('found', 1);
        run;

        %if &found = 0 %then %do;
            %put NOTE: Invalid team name "&team" — no report generated.;
        %end;
        %else %do;
            /* Report for specific team */
            data _null_;
                set team_sorted;
                where upcase(team) = "&team";
                by team;
                file print;

                if _N_ = 1 then do;
                    put "==============================";
                    put "TEAM REPORT FOR: " team;
                    put "==============================";
                end;

                put FirstName $15. LastName $15. gender $6. age 3. event $25. sas_time time8.2;
            run;
        %end;
    %end;
%mend;

%team_report();

ods pdf file='C:\SAS WORK\TeamReport.pdf' style=journal;

title "All Team Swimmer Report";
proc print data=swimout.team_sorted label noobs;
    by team;
    id team;
    var FirstName LastName gender age event sas_time;
    label 
        FirstName = "First Name"
        LastName  = "Last Name"
        gender    = "Gender"
        age       = "Age"
        event     = "Event"
        sas_time  = "Time";
    format sas_time time12.2;
run;

ods pdf close;
