; ##############################################################################################
; NAME: Time_Series_DOIT_Raster_Arithmetic.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 31/06/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool performs simple arithmetic on the input data. The user may select whether 
;              to add the values of the two input data; subtract Y from X, or X from Y; multiply 
;              the input data; or divide the values of X by Y, or Y by X.
;
; INPUT:       Two single-band (i.e. file) datasets; for multi-band files each band must be saved   
;              as a single input file. The input data must have the file date included in the file   
;              name (see NOTES).
;
; OUTPUT:      One single-band output per input pair (see description).
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT INPUT X: see INPUT
;              
;              2.  SELECT INPUT Y: see INPUT
;              
;              3.  SELECT THE DATATYPE OF INPUT X: The datatype of the input rasters e.g. byte, 
;                  integer, float etc.
;              
;              4.  SELECT THE DATATYPE OF INPUT Y: The datatype of the input rasters e.g. byte, 
;                  integer, float etc.
;              
;              5.  DEFINE AN INPUT NODATA VALUE FOR INPUT X: if the input data contains a 'fill' 
;                  or 'nodata' value that you want to exclude from the processing select YES.
;              
;              5.1   DEFINE THE INPUT NODATA VALUE FOR INPUT X (optional; if YES in 5.): The  
;                    input nodata value.              
;              
;              6.  DEFINE AN INPUT NODATA VALUE FOR INPUT Y: if the input data contains a 'fill'
;                  or 'nodata' value that you want to exclude from the processing select YES.
;                          
;              6.1   DEFINE THE INPUT NODATA VALUE FOR INPUT Y (optional; if YES in 6.): The  
;                    input nodata value.
;                    
;              7.  SELECT THE GRID OPERATION: select the operation (grid math) to apply to the 
;                  input data.
;              
;              8.  Define the output filename prefix: A string that will be added to the start of 
;                  the output filename/s. The operation type, year and DOY are added to the   
;                  output filename after the prefix.
;              
;              9.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;              
; NOTES:       The input data must have identical dimensions.
;              
;              FILE DATES:
;              
;              The input data are sorted by date (in ascending order). Lines 223 to 234 
;              control how the date is extracted from the input raster file name. For example,
;              in the filename: MOD09A1.005.OWL.5VariableModel.2004329.hdr
;               
;              The year '2004', and day-of-year (DOY) '329', is extracted by the line:
;              
;              DMY = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FNS, 31, 35)
;              
;              Where, '31' is the character position of the first number in 2004. Similarly,
;              '35' is the character position of the first number in 326.
;              
;              Input X and Y must have matching dates (as identified above).
;              
;              FUNCTIONS:
;               
;              This program calls one or more external functions. You will need to compile the  
;              necessary functions in IDL, or save the functions to the current IDL workspace  
;              prior to running this tool. To open a different workspace, select Switch  
;              Workspace from the File menu.
;               
;              Functions used in this program include:
;               
;              FUNCTION_WIDGET_Radio_Button
;              FUNCTION_GET_Julian_Day_Number_YYYYDOY
;              FUNCTION_GET_Julian_Day_Number_DDMMYYYY
;              FUNCTION_WIDGET_Enter_Value
;              FUNCTION_WIDGET_Enter_String
;
;              For more information contact Garth.Warren@csiro.au
;
; ###############################################################################################


PRO Time_Series_DOIT_Raster_Arithmetic
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Raster_Arithmetic'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT X:
  PATH='C:\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_X = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT INPUT X', FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_X[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT Y:
  IN_Y = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT INPUT Y', FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_Y[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_Y = IN_Y[SORT(IN_Y)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE DATA TYPE OF INPUT X
  VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  DT_X = FUNCTION_WIDGET_Radio_Button('SELECT THE DATATYPE OF INPUT X', VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE DATA TYPE OF INPUT Y
  DT_Y = FUNCTION_WIDGET_Radio_Button('SELECT THE DATATYPE OF INPUT Y', VALUES)
  ;---------------------------------------------------------------------------------------------
  ; DATA CHECK:
  ;-----------------------------------
  ; OPEN THE FIRST INPUT FILES
  X_ONE = READ_BINARY(IN_X[0], DATA_TYPE=DT_X)
  Y_ONE = READ_BINARY(IN_Y[0], DATA_TYPE=DT_Y)
  ;--------------
  ; GET THE NUMBER OF ELEMENTS
  ELEMENTS_X = N_ELEMENTS(X_ONE)-1
  ELEMENTS_Y = N_ELEMENTS(Y_ONE)-1
  ;--------------
  ; ERROR CHECK:
  IF ELEMENTS_X NE ELEMENTS_Y THEN BEGIN
    PRINT,''
    PRINT,'INPUTS MUST HAVE IDENTICAL DIMENSIONS'
    RETURN
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SET NODATA STATUS FOR INPUT X
  NASTATUS_X = FUNCTION_WIDGET_Radio_Button('DEFINE AN INPUT NODATA VALUE FOR INPUT X', ['YES', 'NO'])
  ;--------------
  ; SET THE NODATA VALUE FOR INPUT X
  IF NASTATUS_X EQ 0 THEN BEGIN
    NAVALUE_X = FUNCTION_WIDGET_Enter_Value('DEFINE THE INPUT NODATA VALUE FOR INPUT X  ', 255.00)
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; SET NODATA STATUS FOR INPUT Y
  NASTATUS_Y = FUNCTION_WIDGET_Radio_Button('DEFINE AN INPUT NODATA VALUE FOR INPUT Y', ['YES', 'NO'])
  ;--------------
  ; SET THE NODATA VALUE FOR INPUT Y
  IF NASTATUS_Y EQ 0 THEN BEGIN
    NAVALUE_Y = FUNCTION_WIDGET_Enter_Value('DEFINE THE INPUT NODATA VALUE FOR INPUT Y  ', 255.00)
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SET THE DATE TYPE FOR INPUT X
  D_TYPE_X = RADIO_BUTTON_WFUNCTION_WIDGET_Radio_ButtonIDGET('SELECT THE DATE TYPE FOR INPUT X', ['DOY/YEAR', 'DD/MM/YYYY'])
  ;---------------------------------------------------------------------------------------------
  ; SET THE DATE TYPE FOR INPUT Y
  D_TYPE_Y = FUNCTION_WIDGET_Radio_Button('SELECT THE DATE TYPE FOR INPUT Y', ['DOY/YEAR', 'DD/MM/YYYY'])
  ;---------------------------------------------------------------------------------------------
  ; SET THE OPERATION
  O_TYPE = FUNCTION_WIDGET_Radio_Button('SELECT THE GRID OPERATION', ['X + Y','X - Y','Y - X','X * Y','X / Y','Y / X'])
  ;--------------
  ; SET OPERATION NAME
  IF O_TYPE EQ 0 THEN O_NAME = '.XplusY.'
  IF O_TYPE EQ 1 THEN O_NAME = '.XminusY.'
  IF O_TYPE EQ 2 THEN O_NAME = '.YminusX.'
  IF O_TYPE EQ 3 THEN O_NAME = '.XtimesY.'
  IF O_TYPE EQ 4 THEN O_NAME = '.XdivY.'
  IF O_TYPE EQ 5 THEN O_NAME = '.YdivX.'
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILENAME PREFIX
  PREFIX = FUNCTION_WIDGET_Enter_String('Define the output filename prefix:  ', '') 
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; GET DATES:
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;-----------------------------------
  ; GET FNAME_SHORT
  FNAME_START_X = STRPOS(IN_X, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH_X = (STRLEN(IN_X)-FNAME_START_X)-4
  ;--------------------------------------
  ; GET FNAME_SHORT
  FNAME_START_Y = STRPOS(IN_Y, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH_Y = (STRLEN(IN_Y)-FNAME_START_Y)-4
  ;-------------------------------------- 
  ; GET FILE NAME ARRAY
  FN_X = MAKE_ARRAY(1, N_ELEMENTS(IN_X), /STRING)
  FOR a=0, N_ELEMENTS(IN_X)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FN_X[*,a] += STRMID(IN_X[a], FNAME_START_X[a], FNAME_LENGTH_X[a])
  ENDFOR
  ;--------------------------------------
  ; GET FILE NAME ARRAY
  FN_Y = MAKE_ARRAY(1, N_ELEMENTS(IN_Y), /STRING)
  FOR a=0, N_ELEMENTS(IN_Y)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FN_Y[*,a] += STRMID(IN_Y[a], FNAME_START_Y[a], FNAME_LENGTH_Y[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; GET UNIQUE FILE DATES:
  ;--------------------------------------
  IF D_TYPE_X EQ 0 THEN BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY_X = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FN_X, 40, 44)
  ENDIF ELSE BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY_X = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(FN_X, 33, 37, 39)
  ENDELSE 
  ;--------------  
  IF D_TYPE_Y EQ 0 THEN BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY_Y = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FN_Y, 33, 37)
  ENDIF ELSE BEGIN
    ; GET_FNAME_DMY_DDMMYYYY(FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY_Y = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(FN_Y, 17, 21, 23)
  ENDELSE
  ;--------------------------------------
  ; COMBINE DATE LISTS
  DMY = [[DMY_X], [DMY_Y]]
  ; GET UNIQUE DATES
  UNIQ_DATE = DMY[UNIQ(DMY)]  
  ; SORT DATES (ASCENDING)
  UNIQ_DATE = UNIQ_DATE[SORT(UNIQ_DATE)]
  ; GET UNIQUE DATES 2
  UNIQ_DATE = UNIQ_DATE[UNIQ(UNIQ_DATE)]
  ; SET DATE COUNT
  COUNT_D = N_ELEMENTS(UNIQ_DATE)
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, COUNT_D-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ;*******************************************************************************************
    ; GET DATA:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; GET i-TH DATE FILES:
    ;--------------------------------------
    ; CONVERT JULDAY TO CALDAY
    CALDAT, UNIQ_DATE[i], iM, iD, iY
    ; GET DAY OF YEAR
    DOY = JULDAY(iM, iD, iY) - JULDAY(1, 0, iY)
    ; DOY ZERO CHECK
    IF (DOY LE 9) THEN DOY = '00' + STRING(STRTRIM(DOY,2))
    IF (DOY LE 99) AND (DOY GT 9) THEN DOY = '0' + STRING(STRTRIM(DOY,2))
    ;--------------------------------------
    ; GET FILES WITH THE i-TH DATE
    INDEX_X = WHERE(DMY_X EQ UNIQ_DATE[i], COUNT_X)
    INDEX_Y = WHERE(DMY_Y EQ UNIQ_DATE[i], COUNT_Y)
    ;--------------------------------------
    ; ERROR CHECK:
    IF COUNT_X EQ 0 THEN CONTINUE
    IF COUNT_Y EQ 0 THEN CONTINUE
    ;--------------
    ; ERROR CHECK:
    IF COUNT_X GT 1 THEN RETURN
    IF COUNT_Y GT 1 THEN RETURN
    ;-----------------------------------
    ; GET FILES WITH THE i-TH DATE
    FILE_X = IN_X[INDEX_X]
    FILE_Y = IN_Y[INDEX_Y]
    ;-------------------------------------------------------------------------------------------    
    ; GET DATA:
    ;-----------------------------------
    ; READ DATA
    DATA_X = READ_BINARY(FILE_X, DATA_TYPE=DT_X)
    DATA_Y = READ_BINARY(FILE_Y, DATA_TYPE=DT_Y)
    ;-----------------------------------
    ; DATA TYPE CHECK
    IF (DT_X LT 4) AND (DT_X GT 5) THEN DATA_X = FLOAT(DATA_X)
    IF (DT_Y LT 4) AND (DT_Y GT 5) THEN DATA_Y = FLOAT(DATA_Y)
    ;--------------
    ; SET NAN
    IF NASTATUS_X EQ 0 THEN BEGIN
      x = WHERE(DATA_X EQ FLOAT(NAVALUE_X), COUNT_X)
      IF (COUNT_X GT 0) THEN DATA_X[x] = !VALUES.F_NAN
    ENDIF
    ;--------------  
    ; SET NAN
    IF NASTATUS_Y EQ 0 THEN BEGIN
      y = WHERE(DATA_Y EQ FLOAT(NAVALUE_Y), COUNT_Y)
      IF (COUNT_Y GT 0) THEN DATA_Y[y] = !VALUES.F_NAN
    ENDIF
    ;------------------------------------------------------------------------------------------- 
    ;*******************************************************************************************
    ; CALCULATE OUTPUT:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; APPLY ARRAY OPERATION
    IF O_TYPE EQ 0 THEN DATA_OUT = TOTAL([[DATA_X], [DATA_Y]], 2, /DOUBLE, /NAN)
    IF O_TYPE EQ 1 THEN DATA_OUT = (DATA_X - DATA_Y)
    IF O_TYPE EQ 2 THEN DATA_OUT = (DATA_Y - DATA_X)
    IF O_TYPE EQ 3 THEN DATA_OUT = (DATA_X * DATA_Y)
    IF O_TYPE EQ 4 THEN DATA_OUT = (DATA_X / DATA_Y)
    IF O_TYPE EQ 5 THEN DATA_OUT = (DATA_Y / DATA_X)
    ;-------------------------------------------------------------------------------------------
    ; WRITE OUTPUT:
    ;-------------------------------------------------------------------------------------------
    ; SET THE OUTPUT FILENAME
    ;-----------------------------------
    ; BUILD THE OUTPUT FILENAME
    FNAME_OUT = OUT_DIRECTORY + PREFIX + O_NAME + STRTRIM(iY, 2) + STRTRIM(DOY, 2) + '.img'
    ;--------------
    OPENW, UNIT_OUT, FNAME_OUT, /GET_LUN ; CREATE THE FILE
    WRITEU, UNIT_OUT, DATA_OUT ; APPEND DATA TO THE OUTPUT FILE
    FREE_LUN, UNIT_OUT ; CLOSE THE OUTPUT FILE
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR DATE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_D, 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR ; FOR i
  ;---------------------------------------------------------------------------------------------
  ; PRINT SCRIPT INFORMATION:
  ;-----------------------------------
  ; GET END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Temporal_Raster_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END