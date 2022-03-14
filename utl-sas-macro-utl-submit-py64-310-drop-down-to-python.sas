%let pgm=utl-sas-macro-utl-submit-py64_310-drop-down-to-python;

  SAS macro utl_submit_py64_310 to drop down to python from SAS

  You can even execute Python inside a datastep using DOSUBL at data execution time

  In this presentation I will demonstate the macro interface to Python.

   Agenda

       1. Pass macro variable sex from SAS to python which contains M to subset male students
          As a side note R has a package, SqlRender, which supports paramatized SQL.
          Could not find a similar python package. Basically '&sex' becomes @sex where
          @sex references a R variable.
       2. Python will read the sashelp.class table
       3. Python will compute the mean weight for male students by age
       4. Python will compute the total number of students in the class
       5. Python will create a macro variable NUMBER_STUDENTS and pass this back to a SAS
          macro variable.
       6. Python will create a transport file with mean male weights by age.
          Was unable to figure out how to populate the label with the long Python name.

Macros on end and in github

  Macros
  https://tinyurl.com/58pp9nz6
  https://github.com/rogerjdeangelis/utl-macros-used-in-many-of-rogerjdeangelis-repositories

  This presentation is at

  github
  https://tinyurl.com/5hfvbtsv
  https://github.com/rogerjdeangelis/utl-sas-macro-utl-submit-py64-310-drop-down-to-python

  and on Youtube

  https://www.youtube.com/channel/UCUzsiGhcv3OFovLJTazTc2w

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

options  validvarname=upcase;

libname sd1 "d:/sd1";

data sd1.class;
  set sashelp.class;
run;quit;

/**************************************************************************************/
/*                                                                                    */
/* Up to 40 obs SD1.CLASS total obs=19 11MAR2022:12:00:44                             */
/*                                                                                    */
/* Obs    NAME       SEX    AGE    HEIGHT    WEIGHT                                   */
/*                                                                                    */
/*   1    Alfred      M      14     69.0      112.5                                   */
/*   2    Alice       F      13     56.5       84.0                                   */
/*   3    Barbara     F      13     65.3       98.0                                   */
/*   4    Carol       F      14     62.8      102.5                                   */
/*   5    Henry       M      14     63.5      102.5                                   */
/*   6    James       M      12     57.3       83.0                                   */
/*   7    Jane        F      12     59.8       84.5                                   */
/*   8    Janet       F      15     62.5      112.5                                   */
/*   9    Jeffrey     M      13     62.5       84.0                                   */
/*  10    John        M      12     59.0       99.5                                   */
/*  11    Joyce       F      11     51.3       50.5                                   */
/*  12    Judy        F      14     64.3       90.0                                   */
/*  13    Louise      F      12     56.3       77.0                                   */
/*  14    Mary        F      15     66.5      112.0                                   */
/*  15    Philip      M      16     72.0      150.0                                   */
/*  16    Robert      M      12     64.8      128.0                                   */
/*  17    Ronald      M      15     67.0      133.0                                   */
/*  18    Thomas      M      11     57.5       85.0                                   */
/*  19    William     M      15     66.5      112.0                                   */
/*                                                                                    */
/**************************************************************************************/

/*           _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| `_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
*/

/**************************************************************************************/
/*                                                                                    */
/*  Up to 40 obs from MALEAGES total obs=6 14MAR2022:09:00:07                         */
/*                                                                                    */
/*  Obs    MALE_GEN    BY_AGE    AVERAGE_    AGE_COUN                                 */
/*                                                                                    */
/*   1        M          11         85.0         1                                    */
/*   2        M          12        103.5         3                                    */
/*   3        M          13         84.0         1                                    */
/*   4        M          14        107.5         2                                    */
/*   5        M          15        122.5         2                                    */
/*   6        M          16        150.0         1                                    */
/*                                                                                    */
/*                                                                                    */
/*  AND WE GET THE MACRO VARIABLE WITH NUMBER OF STUDENTS FROM PYTHON                 */
/*                                                                                    */
/*  %put STUDENTS IN CLASS TABLE &=NUMBER_STUDENTS;                                   */
/*                                                                                    */
/*  STUDENTS IN CLASS TABLE NUMBER_STUDENTS=19                                        */
/*                                                                                    */
/**************************************************************************************/

/*
 _ __  _ __ ___   ___ ___  ___ ___
| `_ \| `__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
*/

/* You need to clear the enviroment when doing development and rerunning */

%symdel number_students sex / nowarn;

%utlfkil(d:/xpt/maleAges.xpt);

proc datasets lib=work nodetails nolist mt=data mt=view;
 delete maleAges ;
run;quit;

/* we will pass this to R */
%let sex=M;

%utl_submit_py64_310("
import pyperclip;
from os import path;
import pandas as pd;
import xport;
import xport.v56;
import pyreadstat;
import numpy as np;
from pandasql import sqldf;
from pandasql import PandaSQL;
pdsql = PandaSQL(persist=True);
sqlite3conn = next(pdsql.conn.gen).connection.connection;
sqlite3conn.enable_load_extension(True);
sqlite3conn.load_extension('c:/temp/libsqlitefunctions.dll');
clx, meta = pyreadstat.read_sas7bdat('d:/sd1/class.sas7bdat');
maleAges = pdsql('''
       select
           sex           as MALE_GENDER
          ,age           as BY_AGE
          ,avg(weight)   as AVERAGE_WEIGHT
          ,count(age)    as AGE_COUNT
       from
          clx
       where
          sex = ""&sex""
       group
          by age
       ''');
maleAges.info();
print(maleAges);
pyperclip.copy(len(clx.index));
pyreadstat.write_xport(maleAges, dst_path='d:/xpt/maleAges.xpt', file_format_version=5,table_name='maleAges');
",return=NUMBER_STUDENTS);

%put STUDENTS IN CLASS TABLE &=NUMBER_STUDENTS;

libname xpt xport "d:/xpt/maleAges.xpt";

proc contents data=xpt._all_;
run;quit;

proc print data=xpt.maleAges;
run;quit;

data maleAges;
  set xpt.maleAges;
run;quit;

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|
 _ __ ___   __ _  ___ _ __ ___  ___
| `_ ` _ \ / _` |/ __| `__/ _ \/ __|
| | | | | | (_| | (__| | | (_) \__ \
|_| |_| |_|\__,_|\___|_|  \___/|___/

*/

%macro utlfkil
    (
    utlfkil
    ) / des="delete an external file";


    /*-------------------------------------------------*\
    |                                                   |
    |  Delete an external file                          |
    |   From SAS macro guide                            |
    |  Sample invocations                               |
    |                                                   |
    |  WIN95                                            |
    |  %utlfkil(c:\dat\utlfkil.sas);                    |
    |                                                   |
    |                                                   |
    |  Solaris 2.5                                      |
    |  %utlfkil(/home/deangel/delete.dat);              |
    |                                                   |
    |                                                   |
    |  Roger DeAngelis                                  |
    |                                                   |
    \*-------------------------------------------------*/

    %local urc;

    /*-------------------------------------------------*\
    | Open file   -- assign file reference              |
    \*-------------------------------------------------*/

    %let urc = %sysfunc(filename(fname,%quote(&utlfkil)));

    /*-------------------------------------------------*\
    | Delete file if it exits                           |
    \*-------------------------------------------------*/

    %if &urc = 0 and %sysfunc(fexist(&fname)) %then %do;
        %let urc = %sysfunc(fdelete(&fname));
        %put xxxxxx &fname deleted xxxxxx;
    %end;
    %else %do;
        %put xxxxxx &fname not found xxxxxx;
    %end;

    /*-------------------------------------------------*\
    | Close file  -- deassign file reference            |
    \*-------------------------------------------------*/

    %let urc = %sysfunc(filename(fname,""));

  run;

%mend utlfkil;


%macro utl_submit_py64_310(
      pgm
     ,return=  /* name for the macro variable from Python */
     )/des="Semi colon separated set of python commands - drop down to python";

  * delete temporary files;
  %utlfkil(%sysfunc(pathname(work))/py_pgm.py);
  %utlfkil(%sysfunc(pathname(work))/stderr.txt);
  %utlfkil(%sysfunc(pathname(work))/stdout.txt);

    /* clear clipboard */
  filename _clp clipbrd;
  data _null_;
    file _clp;
    put " ";
  run;quit;

  filename py_pgm "%sysfunc(pathname(work))/py_pgm.py" lrecl=32766 recfm=v;
  data _null_;
    length pgm  $32755 cmd $1024;
    file py_pgm ;
    pgm=resolve(&pgm);
    semi=countc(pgm,";");
      do idx=1 to semi;
        cmd=cats(scan(pgm,idx,";"));
        if cmd=:". " then
           cmd=trim(substr(cmd,2));
         put cmd $char384.;
         putlog cmd ;
      end;
  run;quit;
  %let _loc=%sysfunc(pathname(py_pgm));
  %let _stderr=%sysfunc(pathname(work))/stderr.txt;
  %let _stdout=%sysfunc(pathname(work))/stdout.txt;
  filename rut pipe  "d:\Python310\python.exe &_loc 2> &_stderr";
  data _null_;
    file print;
    infile rut;
    input;
    put _infile_;
  run;
  filename rut clear;
  filename py_pgm clear;

  data _null_;
    file print;
    infile "%sysfunc(pathname(work))/stderr.txt";
    input;
    put _infile_;
  run;

  filename rut clear;
  filename py_pgm clear;

  * use the clipboard to create macro variable;
  %if "&return" ^= "" %then %do;
    filename clp clipbrd ;
    data _null_;
     infile clp;
     input;
     putlog "*******  " _infile_;
     call symputx("&return",_infile_,"G");
    run;quit;
  %end;

%mend utl_submit_py64_310;

/*                                               _
 _ __ ___   __ _  ___ _ __ ___     ___ _ __   __| |
| `_ ` _ \ / _` |/ __| `__/ _ \   / _ \ `_ \ / _` |
| | | | | | (_| | (__| | | (_) | |  __/ | | | (_| |
|_| |_| |_|\__,_|\___|_|  \___/   \___|_| |_|\__,_|

*/
