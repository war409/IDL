; ##############################################################################################
; NAME: Time_Series_Statistics_By_Month_special.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 09/03/2011
; DLM: 25/05/2011
;
; DESCRIPTION:  This program calculates the mean, standard deviation, minimum, maximum, median 
;               variance, and/or the sum of the input data on a cell-by-cell basis. The statistics
;               are calculated on a monthly basis.
;               
;               This program was originally written to calculate statistics using 8-day MODIS-type 
;               inputs. As such the tool calculates statistics using all available inputs that  
;               overlap with a given month. That is to say, rather than using only those files marked  
;               as belonging to a particular month, the code also uses inputs from the previous month 
;               if the 8-day period of an earlier file overlaps into the next month. The number of days  
;               that a particular input has in common with the month of focus is recorded in the  
;               array 'dayfactor'. These values may be used to modify the statistics to account for 
;               proportion of days (of the 8-day input) included in the given month. Currently  
;               only the Sum calculation makes use of 'dayfactor'.
;               
;               In addition to above, I have included code that should be used when the inputs are
;               daily grids, as opposed to 8-day grids.
;               
;               See code for more details. When using either 8-day or daily inputs simply comment out
;               the section marked as belonging to the input type not being used. See lines 230 to 258, 
;               and 334.
;
; INPUT:        Two or more single band date-sets.
;
; OUTPUT:       One single band flat binary raster per input date-set and statistic. Each output  
;               contains the mean, standard deviation, minimum, maximum, median, variance, or 
;               sum of the inputs for the selected month.
;
; PARAMETERS:   Via pop-up dialog widgets.
; 
;               Also, see line 82. Set a string variable to contain a prefix that is added to the 
;               start of the output file names.
;   
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               To identify the workspace (CWD) run the following from the IDL command line: 
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


;-----------------------------------------------------------------------------------------------
FUNCTION FUNCTION_Segment, Elements, Segment
  Segment_Length = ROUND((Elements)*Segment) ; Using the segment value get the segment length.
  Count_S_TMP = CEIL((Elements) / Segment_LENGTH) ; Get the count of segments based on the input grid size.
  Count_S = Count_S_TMP[0]
  Segment_Start = 0 ; Set the initial segment start position.
  Segment_End = FLOAT(Segment_LENGTH) ; Set the initial segment end position.
  RETURN, [Segment, Count_S, Segment_Start, Segment_End, Segment_Length] ; Return values to main program.
END
;-----------------------------------------------------------------------------------------------


PRO Time_Series_Statistics_By_Month_special
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Statistics_By_Month_special'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'MOD09Q1.MOD09A1.CMRSET.' ; Set a string prefix for the output file names.
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='H:\war409\gamma\cmrset\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[SORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(In_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(In_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  In_Dates = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates.
  IF In_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_Files = In_Files[SORT(In_Dates)] ; Sort file name by date.
    FNS = FNS[SORT(In_Dates)] ; Sort file name by date.
    Dates_Unique = In_Dates[UNIQ(In_Dates)] ; Get unique input dates.
    Dates_Unique = Dates_Unique[SORT(Dates_Unique)] ; Sort the unique dates.   
    Dates_Unique = Dates_Unique[UNIQ(Dates_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  In_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (In_DataType EQ 7) OR (In_DataType EQ 8) OR (In_DataType EQ 9) OR (In_DataType EQ 10) OR (In_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; Select the output data type:
  Out_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (Out_DataType EQ 0) OR (Out_DataType EQ 1) OR (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set an output scaling factor:
  IF (Out_DataType EQ 1) OR (Out_DataType EQ 2) OR (Out_DataType EQ 3) THEN BEGIN
    Scaling = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: Scaling', ACCEPT_STRING='Set a Scaling Value', $
      DECLINE_STRING='Do Not Set a Scaling Value', DEFAULT='10.00', /FLOAT)
  ENDIF ELSE Scaling = -1
  ;---------------------------------------------------------------------------------------------  
  ; Set No Data:
  IF (In_DataType EQ 1) OR (In_DataType EQ 2) OR (In_DataType EQ 12) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999', /INTEGER)
  IF (In_DataType EQ 3) OR (In_DataType GE 13) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999', /LONG)
  IF In_DataType EQ 4 THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999.00', /FLOAT)
  IF (In_DataType EQ 5) OR (In_DataType EQ 6) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999.00', /DOUBLE) 
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------
  ; Set the statistic:
  In_Statistic = FUNCTION_WIDGET_Checklist(TITLE='Provide Input', VALUE=['Mean', 'Standard Deviation', $
    'Variance', 'Minimum', 'Maximum', 'Median', 'Sum'], LABEL='Select one or more statistics:')
  ;---------------------------------------------------------------------------------------------
  ; Set long-term mean inputs:
  Path='H:\war409\gamma\cmrset\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  LT_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select Long-Term Mean Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF LT_Files[0] EQ '' THEN RETURN ; Error check.
  LT_Files = LT_Files[SORT(LT_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(LT_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(LT_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(LT_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(LT_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(LT_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  LT_Dates = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates.
  IF LT_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    LT_Files = LT_Files[SORT(LT_Dates)] ; Sort file name by date.
    FNS = FNS[SORT(LT_Dates)] ; Sort file name by date.
    Dates_LT = LT_Dates[UNIQ(LT_Dates)] ; Get unique input dates.
    Dates_LT = Dates_LT[SORT(Dates_LT)] ; Sort the unique dates.   
    Dates_LT = Dates_LT[UNIQ(Dates_LT)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;-------------- ; Select the input data type:
  LT_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (LT_DataType EQ 7) OR (LT_DataType EQ 8) OR (LT_DataType EQ 9) OR (LT_DataType EQ 10) OR (LT_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='H:\war409\gamma\cmrset\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;--------------------------------------------------------------------------------------------- 
  ; Year loop:
  ;---------------------------------------------------------------------------------------------  
  ; Query the input dates to get a list of all the months and years included in the inputs:
  CALDAT, In_Dates, In_Months, In_Days, In_Years ; Convert input Julian dates to input calendar dates.
  Unique_Years = In_Years[UNIQ(In_Years)] ; Get a list of unique input years.
  ;-------------- ; Loop through each input year:
  FOR i=0, N_ELEMENTS(Unique_Years)-1 DO BEGIN ; FOR i (Year)
    LoopStartTime_Year = SYSTIME(1) ; Get the loop start time.
    ;-------------- ; Manipulate dates:
    iYear = Unique_Years[i] ; Set the ith year.
    Year_Index = WHERE(In_Years EQ iYear) ; Get an index of dates that fall in the current iYear.
    Month_Min = MIN(In_Months[Year_Index]) ; Get the minimum month of the minimum year.
    Month_Max = MAX(In_Months[Year_Index]) ; Get the maximum month of the maximum year.
    Month_Min_Index = WHERE(In_Months[Year_Index] EQ Month_Min) ; Get an index of the minimum month and year dates.
    Month_Max_Index = WHERE(In_Months[Year_Index] EQ Month_Max) ; Get an index of the maximum month and year dates.
    Day_Min = MIN(In_Days[Month_Min_Index]) ; Get the minimum day of the minimum month and year.
    Day_Max = MAX(In_Days[Month_Max_Index]) ; Get the maximum day of the maximum month and year.
    iDate_Start = JULDAY(Month_Min, Day_Min, iYear) ; Set the start date (M,D,YYYY).
    iDate_End = JULDAY(Month_Max, Day_Max, iYear) ; Set the end date (M,D,YYYY).
    iIndex = WHERE((In_Dates GE iDate_Start) AND (In_Dates LE iDate_End)) ; Get an index of file-dates that belong to the current month.
    iDates_In = In_Dates[iIndex] ; Get the list of file-dates that belong to the current month.
    CALDAT, iDates_In, iMonths_In, iDays_In, iYears_In ; Convert Julian dates to calendar dates.
    Unique_Months = iMonths_In[UNIQ(iMonths_In)] ; Get a list of unique file-months for the current year.
    ;-------------------------------------------------------------------------------------------
    ; Month loop:
    ;-------------------------------------------------------------------------------------------
    FOR j=0, N_ELEMENTS(Unique_Months)-1 DO BEGIN ; FOR j (Month)
      LoopStartTime_Month = SYSTIME(1) ;  Get the loop start time.
      jMonth = Unique_Months[j] ; Set the jth month.
      ;-------------- ; Set the count of days per month:
      IF jMonth EQ 1 THEN BEGIN 
        Day_Count = 31
      ENDIF
      IF jMonth  EQ 2 THEN BEGIN
        pDay_Count = 31
        IF (((399+(iYear MOD 400))/400-(3+(iYear MOD 4))/4) EQ 1) OR (iYear EQ 2000) THEN Day_Count = 29 ELSE Day_Count = 28 ; Leap year check.
      ENDIF
      IF jMonth EQ 3 THEN BEGIN
        Day_Count = 31
        IF (((399+(iYear MOD 400))/400-(3+(iYear MOD 4))/4) EQ 1) OR (iYear EQ 2000) THEN pDay_Count = 29 ELSE pDay_Count = 28
      ENDIF
      IF (jMonth EQ 4) THEN BEGIN 
        Day_Count = 30
        pDay_Count = 31
      ENDIF
      IF jMonth EQ 5 THEN BEGIN 
        Day_Count = 31
        pDay_Count = 30
      ENDIF
      IF jMonth EQ 6 THEN BEGIN 
        Day_Count = 30
        pDay_Count = 31
      ENDIF
      IF jMonth EQ 7 THEN BEGIN 
        Day_Count = 31
        pDay_Count = 30
      ENDIF
      IF jMonth EQ 8 THEN BEGIN 
        Day_Count = 31
        pDay_Count = 31
      ENDIF
      IF jMonth EQ 9 THEN BEGIN 
        Day_Count = 30
        pDay_Count = 31
      ENDIF
      IF jMonth EQ 10 THEN BEGIN 
        Day_Count = 31
        pDay_Count = 30
      ENDIF
      IF jMonth EQ 11 THEN BEGIN 
        Day_Count = 30
        pDay_Count = 31
      ENDIF
      IF jMonth EQ 12 THEN BEGIN 
        Day_Count = 31
        pDay_Count = 30
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; Set 8-day inputs: (turn off if the inputs are daily)
      ;-----------------------------------------------------------------------------------------
      IF jMonth EQ 1 THEN Date_Start = JULDAY(jMonth, 1, iYear) ; Set the start date (M,D,YYYY).
      IF jMonth NE 1 THEN Date_Start = JULDAY(jMonth-1, pDay_Count-7, iYear) ; Set the start date (M,D,YYYY).
      Date_End = JULDAY(jMonth, Day_Count, iYear) ; Set the end date.
      jIndex = WHERE((In_Dates GE Date_Start) AND (In_Dates LE Date_End)) ; Get an index of file-dates that belong to the current date period.
      
      CALDAT, LT_Dates, LT_Months, LT_Days, LT_Years
      LT_Date = JULDAY(LT_Months, LT_Days, iYear) ; Set the end date.
      ltIndex = WHERE((LT_Date GE Date_Start) AND (LT_Date LE Date_End)) ; Get an index of LT file-dates that belong to the current date period.
      
      ;-------------- ; Get files and dates:
      File_LT = LT_Files[ltIndex] ; Get the LT file that belongs to the current date period.
      Files_In = In_Files[jIndex] ; Get the list of files that belong to the current date period.
      Dates_In = In_Dates[jIndex] ; Get the list of file-dates that belong to the current date period.
      IF jMonth LE 9 THEN M_string = '0' + STRING(STRTRIM(jMonth, 2)) ELSE M_string = STRING(STRTRIM(jMonth, 2)) ; Add leading zero.
      Date_string = STRTRIM(iYear, 2) + M_string ; Set the output filename date string.
      ;-------------- ; Set the dayfactor array:
      dayfactor = MAKE_ARRAY(N_ELEMENTS(Dates_In), /INTEGER) ; Create the empty dayfactor array.
      FOR d=0, N_ELEMENTS(Dates_In)-1 DO BEGIN ; Loop through each element in the dayfactor array.
        CALDAT, Dates_In[d], Month, Day, Year ; Convert the current Julian date to calendar date.
        IF (Month LT jMonth) THEN dayfactor[d] = 8-((pDay_Count-Day)+1)
        IF (Month EQ jMonth) AND (Day_Count-8 LT Day) THEN dayfactor[d] = (Day_Count-Day) + 1
        IF (Month EQ jMonth) AND (Day_Count-8 GE Day) THEN dayfactor[d] = 8
      ENDFOR
      
      ;-----------------------------------------------------------------------------------------
      ; Set daily inputs: (turn off if the inputs are 8-day)
      ;-----------------------------------------------------------------------------------------
      ;Date_Start = JULDAY(jMonth, 1, iYear) ; Set the start date (M,D,YYYY).
      ;Date_End = JULDAY(jMonth, Day_Count, iYear) ; Set the end date.
      ;jIndex = WHERE((In_Dates GE Date_Start) AND (In_Dates LE Date_End)) ; Get an index of file-dates that belong to the current date period.
      ;Files_In = In_Files[jIndex] ; Get the list of files that belong to the current date period.
      ;Dates_In = In_Dates[jIndex] ; Get the list of file-dates that belong to the current date period.
      ;IF jMonth LE 9 THEN M_string = '0' + STRING(STRTRIM(jMonth, 2)) ELSE M_string = STRING(STRTRIM(jMonth, 2)) ; Add leading zero.
      ;Date_string = STRTRIM(iYear, 2) + M_string ; Set the output filename date string.
      ;-----------------------------------------------------------------------------------------
      IF In_Statistic[0] EQ 1 THEN BEGIN ; Build output file, mean:
        File_Mean = Out_Directory + Prefix + Date_string + '01' + '.mean' + '.img' ; Set the output file name
        OPENW, UNIT_Mean, File_Mean, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Mean ; Close the output file.
      ENDIF
      IF In_Statistic[1] EQ 1 THEN BEGIN ; Build output file, standard deviation:
        File_StdDev = Out_Directory + Prefix + Date_string + '01' + '.stddev' + '.img' ; Set the output file name
        OPENW, UNIT_StdDev, File_StdDev, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_StdDev ; Close the output file.
      ENDIF
      IF In_Statistic[2] EQ 1 THEN BEGIN ; Build output file, variance:
        File_Variance = Out_Directory + Prefix + Date_string + '01' + '.var' + '.img' ; Set the output file name
        OPENW, UNIT_Variance, File_Variance, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Variance ; Close the output file.
      ENDIF
      IF In_Statistic[3] EQ 1 THEN BEGIN ; Build output file, minimum:
        File_Min = Out_Directory + Prefix + Date_string + '01' + '.min' + '.img' ; Set the output file name
        OPENW, UNIT_Min, File_Min, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Min ; Close the output file.  
      ENDIF
      IF In_Statistic[4] EQ 1 THEN BEGIN ; Build output file, maximum:
        File_Max = Out_Directory + Prefix + Date_string + '01' + '.max' + '.img' ; Set the output file name
        OPENW, UNIT_Max, File_Max, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Max ; Close the output file.  
      ENDIF
      IF In_Statistic[5] EQ 1 THEN BEGIN ; Build output file, median:
        File_Median = Out_Directory + Prefix + Date_string + '01' + '.median' + '.img' ; Set the output file name
        OPENW, UNIT_Median, File_Median, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Median ; Close the output file.  
      ENDIF
      IF In_Statistic[6] EQ 1 THEN BEGIN ; Build output file, sum:
        File_Sum = Out_Directory + Prefix + Date_string + '01' + '.sum' + '.img' ; Set the output file name
        OPENW, UNIT_Sum, File_Sum, /GET_LUN ; Create the output file.
        FREE_LUN, UNIT_Sum ; Close the output file.  
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; Segment loop:
      ;-----------------------------------------------------------------------------------------    
      In_First = READ_BINARY(In_Files[0], DATA_TYPE=In_DataType) ; Open the first input file.
      Elements = (N_ELEMENTS(In_First)-1) ; Get the number of grid elements (cells).      
      Result = FUNCTION_Segment(Elements, 0.1000) ; Call the segment function.
      ;-------------- ; Set the segment loop parameters:
      Segment = Result[0]
      Count_S = LONG(Result[1])
      Segment_Start = LONG(Result[2]) 
      Segment_End = LONG(Result[3])
      Segment_Length = LONG(Result[4])
      ;-------------- ; Segment loop:
      FOR s=0, Count_S-1 DO BEGIN
        LoopStartTime_Segment = SYSTIME(1) ; Get the loop start time.
        ;---------------------------------------------------------------------------------------
        ; Update segment loop parameters and build arrays:
        ;---------------------------------------------------------------------------------------
        IF s GE 1 THEN BEGIN ; Update the segment parameters:
          Segment_Start = LONG(Segment_Start + Segment_Size) ; Update segment start position.
          Segment_End = LONG((s+1)*Segment_Size) ; Update segment end position.
        ENDIF
        ;-------------- ; In the final loop fix the end position if segment length is not a round integer.
        IF s EQ Count_S-1 THEN Segment_End = LONG(Elements) ; Update end position.
        ;-------------- ; Get the current segment size:
        Segment_Size = LONG(Segment_End - Segment_Start)+1 ; Get the current segment size.
        ;-------------- ; Create empty arrays to hold analysis data:
        Matrix_Data = MAKE_ARRAY(N_ELEMENTS(Files_In), Segment_Size, /FLOAT)  
        Matrix_LT = MAKE_ARRAY(Segment_Size, /FLOAT)
        IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN XDeviation = MAKE_ARRAY(N_ELEMENTS(Files_In), Segment_Size, /FLOAT)
        dayfactor_Segment = MAKE_ARRAY(N_ELEMENTS(Files_In), Segment_Size, /INTEGER)
        ;---------------------------------------------------------------------------------------
        ; File loop (get data and fill arrays):
        ;---------------------------------------------------------------------------------------
        FOR f=0, N_ELEMENTS(Files_In)-1 DO BEGIN ; Loop through each input file.
          Data = READ_BINARY(Files_In[f], DATA_TYPE=In_DataType) ; Open the f-th file.
          Data_Segment = Data(Segment_Start:Segment_End) ; Get data slice (segment).
          Matrix_Data[f,*] = Data_Segment ; Fill data array.
        ENDFOR
        ;-------------- ;  Fill dayfactor segment array:
        FOR f=0L, Segment_Size-1 DO dayfactor_Segment[*,f] = dayfactor
        ;-------------- ;  Fill LT data array:
        ltData = READ_BINARY(File_LT, DATA_TYPE=LT_DataType)
        Matrix_LT = ltData(Segment_Start:Segment_End)
        ;---------------------------------------------------------------------------------------
        ; Calculate statistics:
        ;---------------------------------------------------------------------------------------
        ; Set NaN:
        IF No_DATA[0] NE -1 THEN BEGIN
          k = WHERE(Matrix_Data EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN Matrix_Data[k] = !VALUES.F_NAN
        ENDIF ELSE NaN_Count = 0
        
        Matrix_Data = Matrix_Data * 0.001
        
        ;-------------- ; Calculate the mean:
        IF (In_Statistic[0] EQ 1) OR (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN
          Data_Mean = (TRANSPOSE(TOTAL(Matrix_Data, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(Matrix_Data), 1)))
        ENDIF
        ;-------------- ; Calculate X Deviation:
        IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN ; StdDev and Var only:
          FOR f=0, N_ELEMENTS(Files_In)-1 DO BEGIN ; Loop through each input file.
            ; Calculate the X Deviation and Add:
            XDeviation += (TRANSPOSE(TOTAL(Matrix_Data[f,*], 1, /NAN)) - TRANSPOSE(TOTAL(Data_Mean, 1, /NAN)))^2  
          ENDFOR
        ENDIF
        ;-------------- ; Get the count of non-NaN (valid) cells.
        IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN ; StdDev and Var only:
          Valid_Count = TOTAL(FINITE(Matrix_Data), 1)
        ENDIF
        ;-------------- ; Write mean:
        IF In_Statistic[0] EQ 1 THEN BEGIN
          k = WHERE(FINITE(Data_Mean, /NAN), NaN_Count)
          IF (NaN_Count GT 0) THEN Data_Mean[k] = FLOAT(NaN) ; Reset NaN.
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Mean = FIX((Data_Mean * Scaling[1]) + 0.5) ELSE Data_Mean = FIX(Data_Mean + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Mean = LONG((Data_Mean * Scaling[1]) + 0.5) ELSE Data_Mean = LONG(Data_Mean + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Mean = Data_Mean
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Mean = DOUBLE(Data_Mean)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Mean = UINT((Data_Mean * Scaling[1]) + 0.5) ELSE Data_Mean = UINT(Data_Mean + 0.5)
          ENDIF
          OPENU, UNIT_Mean, File_Mean, /APPEND, /GET_LUN
          WRITEU, UNIT_Mean, Data_Mean 
          FREE_LUN, UNIT_Mean
        ENDIF
        ;-------------- ; Calculate the standard deviation and write data:
        IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN
          IF (N_ELEMENTS(Valid_Count) LT 2) THEN Data_StdDev = MAKE_ARRAY(Segment_Size, VALUE=!VALUES.F_NAN, /FLOAT) ELSE BEGIN
            Data_StdDev = SQRT(TRANSPOSE(TOTAL(XDeviation, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(Matrix_Data), 1))) 
          ENDELSE
          Out_StdDev = Data_StdDev
          k = WHERE(FINITE(Out_StdDev, /NAN), NaN_Count)
          IF (NaN_Count GT 0) THEN Out_StdDev[k] = FLOAT(NaN) ; Reset NaN.
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Out_StdDev = FIX((Out_StdDev * Scaling[1]) + 0.5) ELSE Out_StdDev = FIX(Out_StdDev + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Out_StdDev = LONG((Out_StdDev * Scaling[1]) + 0.5) ELSE Out_StdDev = LONG(Out_StdDev + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Out_StdDev = Out_StdDev
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Out_StdDev = DOUBLE(Out_StdDev)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Out_StdDev = UINT((Out_StdDev * Scaling[1]) + 0.5) ELSE Out_StdDev = UINT(Out_StdDev + 0.5)
          ENDIF
          IF (In_Statistic[1] EQ 1) THEN BEGIN
            OPENU, UNIT_StdDev, File_StdDev, /APPEND, /GET_LUN
            WRITEU, UNIT_StdDev, Out_StdDev 
            FREE_LUN, UNIT_StdDev
          ENDIF  
        ENDIF
        ;-------------- ; Calculate the variance and write data:
        IF In_Statistic[2] EQ 1 THEN BEGIN 
          IF (N_ELEMENTS(Valid_Count) LT 2) THEN Data_Var = MAKE_ARRAY(Segment_Size, VALUE=!VALUES.F_NAN, /FLOAT) ELSE BEGIN
            Data_Var = ((TRANSPOSE(TOTAL(Data_StdDev, 1, /NAN))))^2 
          ENDELSE
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Var = FIX((Data_Var * Scaling[1]) + 0.5) ELSE Data_Var = FIX(Data_Var + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Var = LONG((Data_Var * Scaling[1]) + 0.5) ELSE Data_Var = LONG(Data_Var + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Var = Data_Var
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Var = DOUBLE(Data_Var)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Var = UINT((Data_Var * Scaling[1]) + 0.5) ELSE Data_Var = UINT(Data_Var + 0.5)
          ENDIF
          OPENU, UNIT_Variance, File_Variance, /APPEND, /GET_LUN
          WRITEU, UNIT_Variance, Data_Var 
          FREE_LUN, UNIT_Variance
        ENDIF
        ;-------------- ; Calculate the minimum and write data:
        IF In_Statistic[3] EQ 1 THEN BEGIN 
          Data_Min = MIN(Matrix_Data, DIMENSION=1, /NAN)
          k = WHERE(FINITE(Data_Min, /NAN), NaN_Count)
          IF (NaN_Count GT 0) THEN Data_Min[k] = FLOAT(NaN) ; Reset NaN.
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Min = FIX((Data_Min * Scaling[1]) + 0.5) ELSE Data_Min = FIX(Data_Min + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Min = LONG((Data_Min * Scaling[1]) + 0.5) ELSE Data_Min = LONG(Data_Min + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Min = Data_Min
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Min = DOUBLE(Data_Min)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Min = UINT((Data_Min * Scaling[1]) + 0.5) ELSE Data_Min = UINT(Data_Min + 0.5)
          ENDIF
          OPENU, UNIT_Min, File_Min, /APPEND, /GET_LUN
          WRITEU, UNIT_Min, Data_Min 
          FREE_LUN, UNIT_Min
        ENDIF
        ;-------------- ; Calculate the maximum and write data:
        IF In_Statistic[4] EQ 1 THEN BEGIN 
          Data_Max = MAX(Matrix_Data, DIMENSION=1, /NAN)
          k = WHERE(FINITE(Data_Max, /NAN), NaN_Count)
          IF (NaN_Count GT 0) THEN Data_Max[k] = FLOAT(NaN) ; Reset NaN.
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Max = FIX((Data_Max * Scaling[1]) + 0.5) ELSE Data_Max = FIX(Data_Max + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Max = LONG((Data_Max * Scaling[1]) + 0.5) ELSE Data_Max = LONG(Data_Max + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Max = Data_Max
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Max = DOUBLE(Data_Max)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Max = UINT((Data_Max * Scaling[1]) + 0.5) ELSE Data_Max = UINT(Data_Max + 0.5)
          ENDIF
          OPENU, UNIT_Max, File_Max, /APPEND, /GET_LUN
          WRITEU, UNIT_Max, Data_Max 
          FREE_LUN, UNIT_Max 
        ENDIF
        ;-------------- ; Calculate the median and write data:
        IF In_Statistic[5] EQ 1 THEN BEGIN
          Data_Median = MEDIAN(Matrix_Data, DIMENSION=1, /EVEN)
          k = WHERE(FINITE(Data_Median, /NAN), NaN_Count)
          IF (NaN_Count GT 0) THEN Data_Median[k] = FLOAT(NaN) ; Reset NaN.
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Median = FIX((Data_Median * Scaling[1]) + 0.5) ELSE Data_Median = FIX(Data_Median + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Median = LONG((Data_Median * Scaling[1]) + 0.5) ELSE Data_Median = LONG(Data_Median + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Median = Data_Median
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Median = DOUBLE(Data_Median)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Median = UINT((Data_Median * Scaling[1]) + 0.5) ELSE Data_Median = UINT(Data_Median + 0.5)
          ENDIF
          OPENU, UNIT_Median, File_Median, /APPEND, /GET_LUN
          WRITEU, UNIT_Median, Data_Median 
          FREE_LUN, UNIT_Median
        ENDIF
        ;-------------- ; Calculate the sum and write data:
        IF In_Statistic[6] EQ 1 THEN BEGIN ; Data_Sum = TOTAL(Matrix_Data, 1, /NAN) ; Vanilla Sum.
          ;-------------- ; Calculate 8-day based sum (convert mean mm/d to mm/month): Day_Count * ((ET1*b1/c) + (ET2*b2/c) + (ET3*b3/c) + (ET4*b4/c))
          dayfactor_valid = FLOAT(dayfactor_Segment)
          k = WHERE(FINITE(Matrix_Data, /NAN), NaN_Count)
          dayfactor_valid[k] = !VALUES.F_NAN ; Set NaN in dayfactor where input data equals NaN.
          valid_sum = TOTAL(dayfactor_valid, 1, /NAN) ; Set the count of days in the given month with non-NaN values.
          Matrix_Valid = MAKE_ARRAY(N_ELEMENTS(Files_In), Segment_Size, /FLOAT) ; Create array to hold valid count.
          FOR f=0L, N_ELEMENTS(Files_In)-1 DO Matrix_Valid[f,*] = valid_sum ; Fill array.
          Data_Sum = Day_Count * (TOTAL(Matrix_Data * (dayfactor_Segment / Matrix_Valid), 1, /NAN))
          ;-------------- ; Check for missing data:
          l = WHERE((valid_sum EQ 0.00), valid_count)
          IF valid_count GT 0 THEN Data_Sum[l] = Matrix_LT[l]
          ;-------------- ; Write:
          IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
            IF (Scaling[0] NE -1) THEN Data_Sum = FIX((Data_Sum * Scaling[1]) + 0.5) ELSE Data_Sum = FIX(Data_Sum + 0.5)
          ENDIF
          IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
            IF (Scaling[0] NE -1) THEN Data_Sum = LONG((Data_Sum * Scaling[1]) + 0.5) ELSE Data_Sum = LONG(Data_Sum + 0.5)
          ENDIF
          IF (Out_DataType EQ 4) THEN BEGIN ; Float:
            Data_Sum = Data_Sum
          ENDIF
          IF (Out_DataType EQ 5) THEN BEGIN ; Double:
            Data_Sum = DOUBLE(Data_Sum)
          ENDIF
          IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
            IF (Scaling[0] NE -1) THEN Data_Sum = UINT((Data_Sum * Scaling[1]) + 0.5) ELSE Data_Sum = UINT(Data_Sum + 0.5)
          ENDIF
          OPENU, UNIT_Sum, File_Sum, /APPEND, /GET_LUN
          WRITEU, UNIT_Sum, Data_Sum 
          FREE_LUN, UNIT_Sum
        ENDIF
        ;-------------------------------------------------------------------------------------- 
        Minutes = (SYSTIME(1)-LoopStartTime_Segment)/60 ; Get the file loop end time
        PRINT, '      Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for segment ', STRTRIM(s+1, 2), $
          ' of ', STRTRIM(Count_S, 2)
        ;--------------------------------------------------------------------------------------
      ENDFOR
      ;----------------------------------------------------------------------------------------
      Minutes = (SYSTIME(1)-LoopStartTime_Month)/60 ; Get the file loop end time
      PRINT, '    Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for month ', STRTRIM(j+1, 2), $
        ' of ', STRTRIM(N_ELEMENTS(Unique_Months), 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------   
    Minutes = (SYSTIME(1)-LoopStartTime_Year)/60 ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for year ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(Unique_Years), 2)
    ;-------------------------------------------------------------------------------------------      
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Subtract End-Time from Start-Time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2),   ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

