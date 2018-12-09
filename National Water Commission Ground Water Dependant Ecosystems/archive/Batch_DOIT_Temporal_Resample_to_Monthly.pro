; ##############################################################################################
; NAME: Batch_DOIT_Temporal_Resample_to_monthly.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 21/02/2011
; DLM: 21/02/2011
;
; DESCRIPTION:  
;
; INPUT:        
;
; OUTPUT:       
;               
; PARAMETERS:   Via pop-up dialog widgets.
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
;               FUNCTION_WIDGET_Date.pro
;               FUNCTION_WIDGET_Droplist.pro
;               FUNCTION_WIDGET_No_Data.pro
;               FUNCTION_WIDGET_Select_Ratio.pro
;               FUNCTION_WIDGET_Set_Bands.pro
;               
;               For more information contact Garth.Warren@csiro.au
;               
; ##############################################################################################



FUNCTION SEGMENT_FUNCTION, IN_ELEMENTS, SEGMENT
  ;---------------------------------------------------------------------------------------------
  ; USING ON THE SEGMENT VALUE GET THE SEGMENT LENGTH
  SEGMENT_LENGTH = ROUND((IN_ELEMENTS)*SEGMENT)
  ; GET THE COUNT OF SEGMENTS WITHIN THE CURRENT IMAGE
  COUNT_S_TMP = CEIL((IN_ELEMENTS) / SEGMENT_LENGTH)
  COUNT_S = COUNT_S_TMP[0]
  ; SET THE INITIAL SEGMENT START-POSITION AND END-POSITION
  SEGMENT_START = 0
  SEGMENT_END = FLOAT(SEGMENT_LENGTH)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [SEGMENT, COUNT_S, SEGMENT_START, SEGMENT_END, SEGMENT_LENGTH]
END



PRO Batch_DOIT_Temporal_Resample_to_monthly
  ;---------------------------------------------------------------------------------------------
  T_TIME = SYSTIME(1) ; Get the program start time
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Batch_DOIT_Temporal_Resample_to_monthly'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; Input/Output:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  SILO_Mask = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\SILO.Land.Mask.aust.5000m.img'
  Mask = READ_BINARY(SILO_Mask, DATA_TYPE=4)
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  PATH='\\File-wron\TimeSeries\Climate\usilo\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Data', FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES)
  IF IN_FILES[0] EQ '' THEN RETURN ; Error check
  IN_FILES = IN_FILES[SORT(IN_FILES)] ; Sort the input file list
  ;--------------
  ; Remove the file path from the input file names:
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4 ; Get the length of each path-less file name
  FNS = MAKE_ARRAY(N_ELEMENTS(IN_FILES), /STRING) ; Create an array to store the input file names
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ENDFOR
  ;--------------
  IN_DATES = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates
  IF IN_DATES[0] NE -1 THEN BEGIN ; Check for valid dates
    IN_FILES = IN_FILES[SORT(IN_DATES)] ; Sort file name by date
    FNS = FNS[SORT(IN_DATES)] ; Sort file name by date
    DATES_UNIQUE = IN_DATES[UNIQ(IN_DATES)] ; Get unique input dates
    DATES_UNIQUE = DATES_UNIQUE[SORT(DATES_UNIQUE)] ; Sort the unique dates    
    DATES_UNIQUE = DATES_UNIQUE[UNIQ(DATES_UNIQUE)] ; Get unique input dates
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  IN_DT = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (IN_DT EQ 7) OR (IN_DT EQ 8) OR (IN_DT EQ 9) OR (IN_DT EQ 10) OR (IN_DT EQ 11) THEN BEGIN ; Data type check
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  IF (IN_DT EQ 1) OR (IN_DT EQ 2) OR (IN_DT EQ 12) THEN NoDATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', /INTEGER)
  IF (IN_DT EQ 3) OR (IN_DT GE 13) THEN NoDATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', /LONG)
  IF IN_DT EQ 4 THEN NoDATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', /FLOAT)
  IF (IN_DT EQ 5) OR (IN_DT EQ 6) THEN NoDATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', /DOUBLE) 
  IF (NoDATA[0] NE -1) THEN NAN = NoDATA[1] ; Set NaN value
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD  
  VALUES = ['Mean of period', 'Median of period', 'Minimum of period', 'Maximum of period', 'Sum of period']
  METHOD_RESAMPLE = FUNCTION_WIDGET_Droplist(TITLE='Select the resample method', VALUE=VALUES)
  ;--------------
  ; SET RESAMPLE METHOD STRING
  IF METHOD_RESAMPLE EQ 0 THEN METHOD = 'Mean'
  IF METHOD_RESAMPLE EQ 1 THEN METHOD = 'Median'
  IF METHOD_RESAMPLE EQ 2 THEN METHOD = 'Minimum'
  IF METHOD_RESAMPLE EQ 3 THEN METHOD = 'Maximum'
  IF METHOD_RESAMPLE EQ 4 THEN METHOD = 'Sum'
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  PATH='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF OUT_DIRECTORY EQ '' THEN RETURN ; Error check
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; Date Loops:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; Query the input dates to get a list of months and years:
  CALDAT, IN_DATES, iM, iD, iY ; Convert Julian dates to calendar dates.
  YEARS_UNIQUE = iY[UNIQ(iY)] ; Get a list of unique years.
  ;--------------------------------------------------------------------------------------------- 
  ; Year loop:
  ;---------------------------------------------------------------------------------------------   
  FOR i=0, N_ELEMENTS(YEARS_UNIQUE)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------  
    iYear = YEARS_UNIQUE[i] ; Set the ith year.
    iDate_Start = JULDAY(1, 1, iYear) ; Set the start date. (M,D,YYYY)
    iDate_End = JULDAY(12, 31, iYear) ; Set the end date.
    iINDEX = WHERE(((IN_DATES GE iDate_Start) AND (IN_DATES LE iDate_End)), COUNT1) ; Get files that fall within the date period
    iDATES_IN = IN_DATES[iINDEX]
    CALDAT, iDATES_IN, iM, iD, iY ; Convert Julian dates to calendar dates.
    MONTHS_UNIQUE = iM[UNIQ(iM)] ; Get a list of unique months.
    ;------------------------------------------------------------------------------------------- 
    ; Month loop:
    ;-------------------------------------------------------------------------------------------
    FOR j=0, N_ELEMENTS(MONTHS_UNIQUE)-1 DO BEGIN ; FOR j
    ;-------------------------------------------------------------------------------------------  
      L_TIME = SYSTIME(1) ; Get the file loop start time
      ;-----------------------------------------------------------------------------------------
      jMonth = MONTHS_UNIQUE[j] ; Set the jth month.
      ;-------------- ; Set days per month:
      IF jMonth EQ 1 THEN eDay = 31
      IF jMonth  EQ 2 THEN BEGIN
        IF (((399+(iYear MOD 400))/400-(3+(iYear MOD 4))/4) EQ 1) OR (iYear EQ 2000) THEN eDay = 29 ELSE eDay = 28 ; Leap year check.
      ENDIF
      IF jMonth EQ 3 THEN eDay = 31
      IF jMonth EQ 4 THEN eDay = 30
      IF jMonth EQ 5 THEN eDay = 31
      IF jMonth EQ 6 THEN eDay = 30
      IF jMonth EQ 7 THEN eDay = 31
      IF jMonth EQ 8 THEN eDay = 31
      IF jMonth EQ 9 THEN eDay = 30
      IF jMonth EQ 10 THEN eDay = 31
      IF jMonth EQ 11 THEN eDay = 30
      IF jMonth EQ 12 THEN eDay = 31
      ;-------------- ; Get files:
      jDate_Start = JULDAY(jMonth, 1, iYear) ; Set the start date. (M,D,YYYY)
      jDate_End = JULDAY(jMonth, eDay, iYear) ; Set the end date.
      jINDEX = WHERE(((IN_DATES GE jDate_Start) AND (IN_DATES LE jDate_End)), COUNT2) ; Get files that fall within the date period
      FILES_IN = IN_FILES[jINDEX] ; Get files.
      FNS_IN = FNS[jINDEX]
      CALDAT, jDate_Start, sM, sD, sY ; Get the start date in calender format.
      IF sD LE 9 THEN sD_string = '0' + STRING(STRTRIM(sD,2)) ELSE sD_string = STRING(STRTRIM(sD,2))
      IF sM LE 9 THEN sM_string = '0' + STRING(STRTRIM(sM,2)) ELSE sM_string = STRING(STRTRIM(sM,2))
      Date_string = STRTRIM(sY, 2) + sM_string + sD_string ; Set the output file name date string
      PRINT, ''
      PRINT, '  ', Date_string
      PRINT, ''
      ;-----------------------------------------------------------------------------------------
      OUT_FNAME = OUT_DIRECTORY + Date_string + '_rain_Monthly_' + METHOD + '.flt' ; Build the output file name.
      OPENW, UNIT_OUT, OUT_FNAME, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT_OUT ; Close the output file.
      ;-----------------------------------------------------------------------------------------
      ; Segment loop:
      ;-----------------------------------------------------------------------------------------    
      IN_EXAMPLE = READ_BINARY(FILES_IN[0], DATA_TYPE=IN_DT) ; Open the first input file.
      IN_ELEMENTS = N_ELEMENTS(IN_EXAMPLE)-1 ; Get the number of elements.
      RESULT = SEGMENT_FUNCTION(IN_ELEMENTS, 0.1000) ; Call the segment function.
      ;-------------- ; Set segment parameters:
      SEGMENT = RESULT[0]
      COUNT_S = RESULT[1]
      SEGMENT_START = RESULT[2] 
      SEGMENT_END = RESULT[3]
      SEGMENT_LENGTH = RESULT[4]
      SEGMENT_END_TMP = SEGMENT_END
      SEGMENT_START_TMP = SEGMENT_START 
      ;----------------------------------------------------------------------------------------- 
      FOR s=0, COUNT_S-1 DO BEGIN ; FOR s 
        ;---------------------------------------------------------------------------------------
        ; Update the segment parameters:
        IF s GE 1 THEN BEGIN
          ; Update segment start position.
          IF s EQ 1 THEN SEGMENT_START_TMP = LONG(SEGMENT_START_TMP + SEGMENT_LENGTH)+1
          IF s GT 1 THEN SEGMENT_START_TMP = LONG(SEGMENT_START_TMP + SEGMENT_LENGTH)
          SEGMENT_END_TMP = LONG((s+1)*SEGMENT_LENGTH) ; Update segment end position.
        ENDIF
        ;-------------- ; In the final loop fix the end position if segment length is not integer.
        IF s EQ COUNT_S-1 THEN SEGMENT_END_TMP = LONG((IN_ELEMENTS - SEGMENT_START_TMP) + SEGMENT_START_TMP) ; Update end position.
        ;---------------------------------------------------------------------------------------
        SEGMENT_SIZE = LONG(SEGMENT_END_TMP - SEGMENT_START_TMP)+1 ; Get the current segment size.
        ;---------------------------------------------------------------------------------------
        ; File loop:
        ;---------------------------------------------------------------------------------------    
        MATRIX_X = MAKE_ARRAY(N_ELEMENTS(FILES_IN), SEGMENT_SIZE, /FLOAT) ; Create an array to hold grid data for all files in month j. 
        ;--------------
        FOR t=0, N_ELEMENTS(FILES_IN)-1 DO BEGIN ; FOR t
          DATA = READ_BINARY(FILES_IN[t], DATA_TYPE=IN_DT) ; Open the t-th file.
          DATA_IN = DATA(SEGMENT_START_TMP:SEGMENT_END_TMP) ; Get data slice (segment).
          MATRIX_X[t,*] = DATA_IN ; Fill MATRIX_X   
        ENDFOR
        ;--------------------------------------------------------------------------------------- 
        ; Calculate monthly composite:
        ;---------------------------------------------------------------------------------------
        IF NoDATA[0] NE -1 THEN BEGIN ; Set NaN
          k = WHERE(MATRIX_X EQ FLOAT(NAN), COUNT_k)
          IF (COUNT_k GT 0) THEN MATRIX_X[k] = !VALUES.F_NAN
        ENDIF
        ;---------------------------------------------------------------------------------------
        IF N_ELEMENTS(FILES_IN) GE 2 THEN BEGIN
          ; GET MEAN
          IF METHOD_RESAMPLE EQ 0 THEN DATA_OUT = (TRANSPOSE(TOTAL(MATRIX_X, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_X), 1)))
          ;--------------
          ; GET MEDIAN
          IF METHOD_RESAMPLE EQ 1 THEN DATA_OUT = MEDIAN(MATRIX_X, DIMENSION=1, /EVEN) 
          ;--------------
          ; GET MINIMUM
          IF METHOD_RESAMPLE EQ 2 THEN DATA_OUT = MIN(MATRIX_X, DIMENSION=1, /NAN)
          ;--------------
          ; GET MAXIMUM
          IF METHOD_RESAMPLE EQ 3 THEN DATA_OUT = MAX(MATRIX_X, DIMENSION=1, /NAN)
          ;--------------
           IF METHOD_RESAMPLE EQ 4 THEN DATA_OUT = TOTAL(MATRIX_X, 1, /NAN)
        ENDIF ELSE BEGIN
          DATA_OUT = READ_BINARY(FILES_IN[0], DATA_TYPE=IN_DT) ; Set out data.
        ENDELSE
        ;--------------
        k = WHERE(Mask(SEGMENT_START_TMP:SEGMENT_END_TMP) EQ 0.00, COUNT_k)
        IF (COUNT_k GT 0) THEN DATA_OUT[k] = FLOAT(-999)
        ;---------------------------------------------------------------------------------------
        ; Append data:
        ;---------------------------------------------------------------------------------------
        OPENU, UNIT_OUT, OUT_FNAME, /APPEND, /GET_LUN
        WRITEU, UNIT_OUT, DATA_OUT 
        FREE_LUN, UNIT_OUT
        ;---------------------------------------------------------------------------------------
      ENDFOR
      ;-----------------------------------------------------------------------------------------
      MINUTES = (SYSTIME(1)-L_TIME)/60 ; Get the file loop end time
      PRINT, '  Processing time: ', STRTRIM(MINUTES, 2), ' minutes, for month ', STRTRIM(j+1, 2), $
        ' of ', STRTRIM(N_ELEMENTS(MONTHS_UNIQUE), 2), ' and Year ',  STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(YEARS_UNIQUE), 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  MINUTES = (SYSTIME(1)-T_TIME)/60 ; Get the program end time
  HOURS = MINUTES/60 ; Convert minutes to hours
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Batch_DOIT_Temporal_Resample_to_monthly'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END      
  
  
  
  