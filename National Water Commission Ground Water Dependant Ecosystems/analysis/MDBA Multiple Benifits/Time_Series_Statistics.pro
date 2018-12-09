; ##############################################################################################
; NAME: Time_Series_Statistics.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: WfHC MDBA MBP
; DATE: 08/03/2011
; DLM: 17/07/2011
;
; DESCRIPTION:  This program calculates the mean, standard deviation, minimum, maximum, median 
;               variance, and/or sum of the input gridded data on a cell-by-cell basis.
;
; INPUT:        Two or more single band date-sets.
;
; OUTPUT:       One single band flat binary raster per input date-set and statistic. Each output  
;               contains the mean, standard deviation, minimum, maximum, median, variance, or 
;               sum of the inputs.
;
; PARAMETERS:   Via pop-up dialog widgets.
;   
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               FUNCTION_WIDGET_Droplist
;               FUNCTION_WIDGET_Checklist
;               FUNCTION_WIDGET_Set_Value_Conditional
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


PRO Time_Series_Statistics
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Time_Series_Statistics'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  Prefix = 'rain.s1102.2001.2010.12.LT.monthly' ; Set a string prefix for the output file names.
  ;---------------------------------------------------------------------------------------------  
  ; Select the input data:
  Path='T:\gamma\rain\rain.monthly.sum\'
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
  ; Set the statistic:
  In_Statistic = FUNCTION_WIDGET_Checklist(TITLE='Provide Input', VALUE=['Mean', 'Standard Deviation', $
    'Variance', 'Minimum', 'Maximum', 'Median', 'Sum'], LABEL='Select one or more statistics:') 
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  No_DATA = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', ACCEPT_STRING='Set a grid value to NaN', $
    DECLINE_STRING='Do not set a grid value to NaN', DEFAULT='-999.00', /FLOAT)
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------  
  ; Set the output folder:
  Path='T:\gamma\rain\rain.long.term\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; Build outputs:
  ;-------------- ; Mean:
  IF In_Statistic[0] EQ 1 THEN BEGIN 
    File_Mean = Out_Directory + Prefix + '.Mean' + '.img' ; Set the output file name
    OPENW, UNIT_Mean, File_Mean, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Mean ; Close the output file.
  ENDIF
  ;-------------- ; Standard Deviation:
  IF In_Statistic[1] EQ 1 THEN BEGIN 
    File_StdDev = Out_Directory + Prefix + '.StdDev' + '.img' ; Set the output file name
    OPENW, UNIT_StdDev, File_StdDev, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_StdDev ; Close the output file.
  ENDIF
  ;-------------- ; Variance:
  IF In_Statistic[2] EQ 1 THEN BEGIN 
    File_Variance = Out_Directory + Prefix + '.Var' + '.img' ; Set the output file name
    OPENW, UNIT_Variance, File_Variance, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Variance ; Close the output file.
  ENDIF
  ;-------------- ; Minimum:
  IF In_Statistic[3] EQ 1 THEN BEGIN 
    File_Min = Out_Directory + Prefix + '.Min' + '.img' ; Set the output file name
    OPENW, UNIT_Min, File_Min, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Min ; Close the output file.  
  ENDIF
  ;-------------- ; Maximum:
  IF In_Statistic[4] EQ 1 THEN BEGIN 
    File_Max = Out_Directory + Prefix + '.Max' + '.img' ; Set the output file name
    OPENW, UNIT_Max, File_Max, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Max ; Close the output file.  
  ENDIF
  ;-------------- ; Median:
  IF In_Statistic[5] EQ 1 THEN BEGIN 
    File_Median = Out_Directory + Prefix + '.Median' + '.img' ; Set the output file name
    OPENW, UNIT_Median, File_Median, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Median ; Close the output file.  
  ENDIF
  ;-------------- ; Sum:
  IF In_Statistic[6] EQ 1 THEN BEGIN 
    File_Sum = Out_Directory + Prefix + '.Sum' + '.img' ; Set the output file name
    OPENW, UNIT_Sum, File_Sum, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Sum ; Close the output file.  
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Segment loop:
  ;---------------------------------------------------------------------------------------------    
  In_First = READ_BINARY(In_Files[0], DATA_TYPE=In_DataType) ; Open the first input file.
  Elements = (N_ELEMENTS(In_First)-1) ; Get the number of grid elements (cells).  
  Result = FUNCTION_Segment(Elements, 0.1000) ; Call the segment function.
  ;-------------- ; Set segment parameters:
  Segment = Result[0]
  Count_S = LONG(Result[1])
  Segment_Start = LONG(Result[2]) 
  Segment_End = LONG(Result[3])
  Segment_Length = LONG(Result[4])
  ;-------------- ; Segment loop:
  FOR s=0, Count_S-1 DO BEGIN
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------------------------------------------------------------------------------------
    ; Update segment loop parameters and build arrays:
    ;-------------------------------------------------------------------------------------------
    IF s GE 1 THEN BEGIN ; Update the segment parameters:
      Segment_Start = LONG(Segment_Start + Segment_Size) ; Update segment start position.
      Segment_End = LONG((s+1)*Segment_Size) ; Update segment end position.
    ENDIF
    ;-------------- ; In the final loop fix the end position if segment length is not a round integer.
    IF s EQ Count_S-1 THEN Segment_End = LONG(Elements) ; Update end position.
    ;-------------- ; Get the current segment size:
    Segment_Size = LONG(Segment_End - Segment_Start)+1 ; Get the current segment size.
    ;-------------- ; Create empty arrays to hold analysis data:
    Matrix_Data = MAKE_ARRAY(N_ELEMENTS(In_Files), Segment_Size, /FLOAT) ; Create an array to hold grid data for all files.
    IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN XDeviation = MAKE_ARRAY(N_ELEMENTS(In_Files), Segment_Size, /FLOAT)
    ;-------------------------------------------------------------------------------------------
    ; File loop (get data and fill arrays):
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file.
      Data = READ_BINARY(In_Files[i], DATA_TYPE=In_DataType) ; Open the i-th file.
      Data_Segment = Data(Segment_Start:Segment_End) ; Get data slice (segment).
      Matrix_Data[i,*] = Data_Segment ; Fill data array.
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; Calculate Statistics:
    ;-------------------------------------------------------------------------------------------
    ; Set NaN:
    IF (No_DATA[0] NE -1) THEN BEGIN
      k = WHERE(Matrix_Data EQ FLOAT(NaN), NaN_Count)
      IF (NaN_Count GT 0) THEN Matrix_Data[k] = !VALUES.F_NAN
    ENDIF
    ;-------------- ; Calculate the mean:
    IF (In_Statistic[0] EQ 1) OR (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN
      Data_Mean = (TRANSPOSE(TOTAL(Matrix_Data, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(Matrix_Data), 1)))
    ENDIF
    ;-------------- ; Calculate X Deviation:
    IF (In_Statistic[1] EQ 1) OR (In_Statistic[2] EQ 1) THEN BEGIN ; StdDev and Var only:
      FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file.
        ; Calculate the X Deviation and Add:
        XDeviation += (TRANSPOSE(TOTAL(Matrix_Data[i,*], 1, /NAN)) - TRANSPOSE(TOTAL(Data_Mean, 1, /NAN)))^2  
      ENDFOR
    ENDIF
    ;-------------- ; Write mean:
    IF In_Statistic[0] EQ 1 THEN BEGIN
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Mean, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Mean[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF       
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
      Data_StdDev = SQRT(TRANSPOSE(TOTAL(XDeviation, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(Matrix_Data), 1)))
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_StdDev, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_StdDev[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF        
      IF (Out_DataType EQ 1) THEN Data_StdDev = BYTE(Data_StdDev) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Data_StdDev = FIX(Data_StdDev + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Data_StdDev = LONG(Data_StdDev + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Data_StdDev = DOUBLE(Data_StdDev) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Data_StdDev = UINT(Data_StdDev + 0.5) ; Convert to unsigned Integer.
      IF (In_Statistic[1] EQ 1) THEN BEGIN
        OPENU, UNIT_StdDev, File_StdDev, /APPEND, /GET_LUN
        WRITEU, UNIT_StdDev, Data_StdDev 
        FREE_LUN, UNIT_StdDev
      ENDIF
    ENDIF
    ;-------------- ; Calculate the variance and write data:
    IF In_Statistic[2] EQ 1 THEN BEGIN
      Data_Var = ((TRANSPOSE(TOTAL(Data_StdDev, 1, /NAN))))^2
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Var, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Var[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF  
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
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Min, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Min[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF        
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
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Max, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Max[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF              
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
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Median, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Median[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF             
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
      Data_Sum = TOTAL(Matrix_Data, 1, /NAN)
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Sum, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Sum[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF        
      IF (Out_DataType EQ 1) THEN Data_Sum = BYTE(Data_Sum) ; Convert to Byte.
      IF (Out_DataType EQ 2) THEN Data_Sum = FIX(Data_Sum + 0.5) ; Convert to Integer.
      IF (Out_DataType EQ 3) THEN Data_Sum = LONG(Data_Sum + 0.5) ; Convert to LONG
      IF (Out_DataType EQ 5) THEN Data_Sum = DOUBLE(Data_Sum) ; Convert to DOUBLE
      IF (Out_DataType EQ 12) THEN Data_Sum = UINT(Data_Sum + 0.5) ; Convert to unsigned Integer.
      OPENU, UNIT_Sum, File_Sum, /APPEND, /GET_LUN
      WRITEU, UNIT_Sum, Data_Sum 
      FREE_LUN, UNIT_Sum
    ENDIF
    ;-------------------------------------------------------------------------------------------
    Seconds = (SYSTIME(1)-LoopStart) ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for segment ', STRTRIM(s+1, 2), $
      ' of ', STRTRIM(Count_S, 2)
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

