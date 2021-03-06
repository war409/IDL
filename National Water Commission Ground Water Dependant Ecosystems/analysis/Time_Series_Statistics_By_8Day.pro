; ##############################################################################################
; NAME: Time_Series_Statistics_By_8Day.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NWC Groundwater Dependent Ecosystems Atlas.
; DATE: 09/03/2011
; DLM: 19/04/2011
;
; DESCRIPTION:  This program calculates the mean, standard deviation, minimum, maximum, median 
;               variance, and/or the sum of the input gridded data on a cell-by-cell basis. The
;               statistics are calculated on a MODIS 8-day basis.
;
; INPUT:        Two or more single band gridded date-sets.
;
; OUTPUT:       One single band flat binary raster per input date-set and statistic. Each output  
;               contains the mean, standard deviation, minimum, maximum, median, variance, or 
;               sum of the inputs for the selected month.
;
; PARAMETERS:   Via pop-up dialog widgets.
; 
;               Also, see line 79. Set a string variable to contain a prefix that is added to the 
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
;               Functions used in this program include:
;               
;               FUNCTION_WIDGET_Date
;               FUNCTION_WIDGET_Droplist
;               FUNCTION_WIDGET_No_Data
;               FUNCTION_WIDGET_Checklist
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


;-----------------------------------------------------------------------------------------------
FUNCTION MODIS_8Day_Dates
  COMPILE_OPT idl2
  Dates_2000 = INDGEN(46) * 8 +  JULDAY(1,1,2000)
  Dates_2001 = INDGEN(46) * 8 +  JULDAY(1,1,2001)
  Dates_2002 = INDGEN(46) * 8 +  JULDAY(1,1,2002)
  Dates_2003 = INDGEN(46) * 8 +  JULDAY(1,1,2003)
  Dates_2004 = INDGEN(46) * 8 +  JULDAY(1,1,2004)
  Dates_2005 = INDGEN(46) * 8 +  JULDAY(1,1,2005)
  Dates_2006 = INDGEN(46) * 8 +  JULDAY(1,1,2006)
  Dates_2007 = INDGEN(46) * 8 +  JULDAY(1,1,2007)
  Dates_2008 = INDGEN(46) * 8 +  JULDAY(1,1,2008)
  Dates_2009 = INDGEN(46) * 8 +  JULDAY(1,1,2009)
  Dates_2010 = INDGEN(46) * 8 +  JULDAY(1,1,2010)
  Dates_2011 = INDGEN(46) * 8 +  JULDAY(1,1,2011)
  Dates_2012 = INDGEN(46) * 8 +  JULDAY(1,1,2012)
  Dates = [Dates_2000, Dates_2001, Dates_2002, Dates_2003, Dates_2004, Dates_2005, Dates_2006, $
    Dates_2007, Dates_2008, Dates_2009, Dates_2010, Dates_2011, Dates_2012]
  RETURN, Dates ; Return a full list of all possible MODIS 8-day [julian day] dates for the years 2000 to 2011.
END
;-----------------------------------------------------------------------------------------------


PRO Time_Series_Statistics_By_8Day
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Statistics_By_Month'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'rain_BAWAP_' ; Set a string prefix for the output file names.
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='C:\temp\PET\pet\'
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
  IF (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
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
  ; Set the output folder:
  Path='C:\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;--------------------------------------------------------------------------------------------- 
  ; Date loop:
  ;---------------------------------------------------------------------------------------------
  
  
  
  All_8Day = MODIS_8Day_Dates() ; Get a list of all valid 8-day dates for years 2000 to 2012.
  ; Get the valid 8-day dates that fall within the range of dates covered by the input data:
  Index_8Day = Where((All_8Day GE In_Dates[0]) AND (All_8Day LE In_Dates[N_ELEMENTS(In_Dates)-1]))
  Dates_8Day = All_8Day[Index_8Day] ; Get a list of all valid 8-day dates covered by the input data.
  
  
  
  ;-------------- ; Loop through each 8-day period:
  FOR i=0, N_ELEMENTS(Dates_8Day)-1 DO BEGIN ; FOR i
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Manipulate dates:
    i8Day = Dates_8Day[i] ; Set the ith 8-day period.
    CALDAT, i8Day, Month_Min, Day_Min, Year_Min ; Convert Julian dates to calendar dates.
    CALDAT, i8Day+7, Month_Max, Day_Max, Year_Max ; As above. Get the calendar for the last date in the 8-day period.
    iDate_Start = JULDAY(Month_Min, Day_Min, Year_Min) ; Set the start date. (M,D,YYYY)
    iDate_End = JULDAY(Month_Max, Day_Max, Year_Max) ; Set the end date.
    iIndex = WHERE((In_Dates GE iDate_Start) AND (In_Dates LE iDate_End)) ; Get an index of file dates that fall within the 8-day period.
    Files_In = In_Files[iIndex] ; Get the list of files that fall within the 8-day period.
    FNSs_In = FNS[iIndex] ; Get the list of files-short that fall within the 8-day period.
    Dates_In = In_Dates[iIndex] ; Get the list of file dates that fall within the 8-day period.
    ;-------------- ; Get date as DOY:
    DayOfYear = (JULDAY(Month_Min, Day_Min, Year_Min) - JULDAY(1, 1, Year_Min) + 1) ; Get date as DOY.
    IF DayOfYear LE 9 THEN DayOfYear_string = '00' + STRING(STRTRIM(DayOfYear, 2)) ; Add leading zero to DOY.
    IF DayOfYear GT 9 and DayOfYear LE 99 THEN DayOfYear_string = '0' + STRING(STRTRIM(DayOfYear, 2)) ; Add leading zero to DOY.
    IF DayOfYear GT 99 THEN DayOfYear_string = STRING(STRTRIM(DayOfYear, 2))
    ;-------------- ; Get dates as strings:
    IF Month_Min LE 9 THEN M_string = '0' + STRING(STRTRIM(Month_Min, 2)) ELSE M_string = STRING(STRTRIM(Month_Min, 2)) ; Add leading zero.
    IF Day_Min LE 9 THEN D_string = '0' + STRING(STRTRIM(Day_Min, 2)) ELSE D_string = STRING(STRTRIM(Day_Min, 2)) ; Add leading zero.
    Date_string = STRTRIM(Year_Min, 2) + M_string + D_string ; Set the output file name date string (YYYYMMDD).
    DOY_string = STRTRIM(Year_Min, 2) + DayOfYear_string ; Set the output file name date string (YYYYDOY).
    ;-------------- ; Build output file, mean:
    IF In_Statistic[0] EQ 1 THEN BEGIN
      File_Mean = Out_Directory + Prefix + DOY_string + '.Mean' + '.img' ; Set the output file name
      OPENW, UNIT_Mean, File_Mean, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Mean ; Close the output file.
    ENDIF
    ;-------------- ; Build output file, standard deviation:
    IF In_Statistic[1] EQ 1 THEN BEGIN 
      File_StdDev = Out_Directory + Prefix + DOY_string + '.StdDev' + '.img' ; Set the output file name
      OPENW, UNIT_StdDev, File_StdDev, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_StdDev ; Close the output file.
    ENDIF
    ;-------------- ; Build output file, variance:
    IF In_Statistic[2] EQ 1 THEN BEGIN 
      File_Variance = Out_Directory + Prefix + DOY_string + '.Var' + '.img' ; Set the output file name
      OPENW, UNIT_Variance, File_Variance, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Variance ; Close the output file.
    ENDIF
    ;-------------- ; Build output file, minimum:
    IF In_Statistic[3] EQ 1 THEN BEGIN 
      File_Min = Out_Directory + Prefix + DOY_string + '.Min' + '.img' ; Set the output file name
      OPENW, UNIT_Min, File_Min, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Min ; Close the output file.  
    ENDIF
    ;-------------- ; Build output file, maximum:
    IF In_Statistic[4] EQ 1 THEN BEGIN 
      File_Max = Out_Directory + Prefix + DOY_string + '.Max' + '.img' ; Set the output file name
      OPENW, UNIT_Max, File_Max, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Max ; Close the output file.  
    ENDIF
    ;-------------- ; Build output file, median:
    IF In_Statistic[5] EQ 1 THEN BEGIN 
      File_Median = Out_Directory + Prefix + DOY_string + '.Median' + '.img' ; Set the output file name
      OPENW, UNIT_Median, File_Median, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Median ; Close the output file.  
    ENDIF
    ;-------------- ; Build output file, sum:
    IF In_Statistic[6] EQ 1 THEN BEGIN 
      File_Sum = Out_Directory + Prefix + DOY_string + '.Sum' + '.img' ; Set the output file name
      OPENW, UNIT_Sum, File_Sum, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_Sum ; Close the output file.  
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Segment loop:
    ;-------------------------------------------------------------------------------------------    
    In_First = READ_BINARY(In_Files[0], DATA_TYPE=In_DataType) ; Open the first input file.
    Elements = (N_ELEMENTS(In_First)-1) ; Get the number of grid elements (cells).      
    Result = FUNCTION_Segment(Elements, 0.1000) ; Call the segment (tiling) function.
    ;-------------- ; Set the segment loop parameters:
    Segment = Result[0]
    Count_S = LONG(Result[1])
    Segment_Start = LONG(Result[2]) 
    Segment_End = LONG(Result[3])
    Segment_Length = LONG(Result[4])
    ;-------------- ; Segment loop:
    FOR s=0, Count_S-1 DO BEGIN
      LoopStartSegment = SYSTIME(1) ; Get loop start time.
      ;-----------------------------------------------------------------------------------------
      ; Update segment loop parameters and build arrays:
      ;-----------------------------------------------------------------------------------------
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
      IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN XDeviation = MAKE_ARRAY(N_ELEMENTS(Files_In), Segment_Size, /FLOAT)
      ;-----------------------------------------------------------------------------------------
      ; File loop (get data and fill arrays):
      ;-----------------------------------------------------------------------------------------
      FOR f=0, N_ELEMENTS(Files_In)-1 DO BEGIN ; Loop through each input file.
        Data = READ_BINARY(Files_In[f], DATA_TYPE=In_DataType) ; Open the f-th file.
        Data_Segment = Data(Segment_Start:Segment_End) ; Get data slice (segment).
        Matrix_Data[f,*] = Data_Segment ; Fill data array.
      ENDFOR
      ;-----------------------------------------------------------------------------------------
      ; Calculate statistics:
      ;-----------------------------------------------------------------------------------------
      ; Set NaN:
      IF No_DATA[0] NE -1 THEN BEGIN
        k = WHERE(Matrix_Data EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Matrix_Data[k] = !VALUES.F_NAN
      ENDIF ELSE NaN_Count = 0
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
        IF (Out_DataType EQ 1) THEN Data_Mean = BYTE(Data_Mean) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Mean = FIX(Data_Mean + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Mean = LONG(Data_Mean + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Mean = DOUBLE(Data_Mean) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Mean = UINT(Data_Mean + 0.5) ; Convert to unsigned Integer.
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
        IF (Out_DataType EQ 1) THEN Out_StdDev = BYTE(Out_StdDev) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Out_StdDev = FIX(Out_StdDev + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Out_StdDev = LONG(Out_StdDev + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Out_StdDev = DOUBLE(Out_StdDev) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Out_StdDev = UINT(Out_StdDev + 0.5) ; Convert to unsigned Integer.
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
        IF (Out_DataType EQ 1) THEN Data_Var = BYTE(Data_Var) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Var = FIX(Data_Var + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Var = LONG(Data_Var + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Var = DOUBLE(Data_Var) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Var = UINT(Data_Var + 0.5) ; Convert to unsigned Integer.
        OPENU, UNIT_Variance, File_Variance, /APPEND, /GET_LUN
        WRITEU, UNIT_Variance, Data_Var 
        FREE_LUN, UNIT_Variance
      ENDIF
      ;-------------- ; Calculate the minimum and write data:
      IF In_Statistic[3] EQ 1 THEN BEGIN 
        Data_Min = MIN(Matrix_Data, DIMENSION=1, /NAN)
        k = WHERE(FINITE(Data_Min, /NAN), NaN_Count)
        IF (NaN_Count GT 0) THEN Data_Min[k] = FLOAT(NaN) ; Reset NaN.
        IF (Out_DataType EQ 1) THEN Data_Min = BYTE(Data_Min) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Min = FIX(Data_Min + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Min = LONG(Data_Min + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Min = DOUBLE(Data_Min) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Min = UINT(Data_Min + 0.5) ; Convert to unsigned Integer.
        OPENU, UNIT_Min, File_Min, /APPEND, /GET_LUN
        WRITEU, UNIT_Min, Data_Min 
        FREE_LUN, UNIT_Min
      ENDIF
      ;-------------- ; Calculate the maximum and write data:
      IF In_Statistic[4] EQ 1 THEN BEGIN 
        Data_Max = MAX(Matrix_Data, DIMENSION=1, /NAN)
        k = WHERE(FINITE(Data_Max, /NAN), NaN_Count)
        IF (NaN_Count GT 0) THEN Data_Max[k] = FLOAT(NaN) ; Reset NaN.
        IF (Out_DataType EQ 1) THEN Data_Max = BYTE(Data_Max) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Max = FIX(Data_Max + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Max = LONG(Data_Max + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Max = DOUBLE(Data_Max) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Max = UINT(Data_Max + 0.5) ; Convert to unsigned Integer.
        OPENU, UNIT_Max, File_Max, /APPEND, /GET_LUN
        WRITEU, UNIT_Max, Data_Max 
        FREE_LUN, UNIT_Max 
      ENDIF
      ;-------------- ; Calculate the median and write data:
      IF In_Statistic[5] EQ 1 THEN BEGIN
        Data_Median = MEDIAN(Matrix_Data, DIMENSION=1, /EVEN)
        k = WHERE(FINITE(Data_Median, /NAN), NaN_Count)
        IF (NaN_Count GT 0) THEN Data_Median[k] = FLOAT(NaN) ; Reset NaN.
        IF (Out_DataType EQ 1) THEN Data_Median = BYTE(Data_Median) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Median = FIX(Data_Median + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Median = LONG(Data_Median + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Median = DOUBLE(Data_Median) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Median = UINT(Data_Median + 0.5) ; Convert to unsigned Integer.
        OPENU, UNIT_Median, File_Median, /APPEND, /GET_LUN
        WRITEU, UNIT_Median, Data_Median 
        FREE_LUN, UNIT_Median
      ENDIF
      ;-------------- ; Calculate the sum and write data:
      IF In_Statistic[6] EQ 1 THEN BEGIN
        Data_Sum = TOTAL(Matrix_Data, 1, /NAN) ; Sum.
        IF (Out_DataType EQ 1) THEN Data_Sum = BYTE(Data_Sum) ; Convert to Byte.
        IF (Out_DataType EQ 2) THEN Data_Sum = FIX(Data_Sum + 0.5) ; Convert to Integer.
        IF (Out_DataType EQ 3) THEN Data_Sum = LONG(Data_Sum + 0.5) ; Convert to LONG
        IF (Out_DataType EQ 5) THEN Data_Sum = DOUBLE(Data_Sum) ; Convert to DOUBLE
        IF (Out_DataType EQ 12) THEN Data_Sum = UINT(Data_Sum + 0.5) ; Convert to unsigned Integer.
        OPENU, UNIT_Sum, File_Sum, /APPEND, /GET_LUN
        WRITEU, UNIT_Sum, Data_Sum 
        FREE_LUN, UNIT_Sum
      ENDIF
      ;---------------------------------------------------------------------------------------- 
      Minutes = (SYSTIME(1)-LoopStartSegment)/60 ; Get the file loop end time.
      PRINT, '    Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for segment ', STRTRIM(s+1, 2), $
        ' of ', STRTRIM(Count_S, 2)
      ;----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------   
    Minutes = (SYSTIME(1)-LoopStart)/60 ; Get the file loop end time.
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for date ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(Dates_8Day), 2)
    ;-------------------------------------------------------------------------------------------      
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Get the program end time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2),   ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

