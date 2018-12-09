; ##############################################################################################
; NAME: BATCH_DOIT_Create_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 01/07/2010
; DLM: 19/10/2010
;
; DESCRIPTION: This tool create one PNG file for each input file or band.
;
; INPUT:       One or more ENVI compatible single-band OR multi-band grids. The current input file 
;              filter is set as: ['*.tif','*.img','*.flt','*.bin'] 
;
; OUTPUT:      One PNG file (.png) for each input file or band.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT THE INPUT DATA: see INPUT
;               
;              2.  Define an input nodata value: If your input data contains a 'fill' or 'nodata' 
;                  value that you want to exclude from the processing select YES.
;               
;              2.1 Define the input nodata value (optional; if YES in 2.): The input nodata value.
;               
;              3.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;               
;              4.  Load Color Tables: Select a colour table. The output png will display data
;                  using the selected colour ramp.
;                  
;              5.  Set display limits: Select YES to set a new minimum and a new maximum 
;                  value (see 5.1).
;               
;              5.1 Define the new display limits (optional; if YES in 5.): Select new minimum and
;                  maximum values. 
;                  
;                  This feature can be used to standardise the output colour ramp  
;                  for a series of input data, or to display a subset - narrow range of values - 
;                  with greater contrast. 
;                  
;                  For example, say the input contains values from 0 to 100. The user knows a
;                  -priori that most values fall between 10 and 30. The user may apply a new display 
;                  minimum of 10 and maximum of 30. Values between 10 and 30 are stretched to make 
;                  optimum use of the available PNG brightness levels (0-255 RGB), and hence display  
;                  the selected value range with the best possible contrast. You should use this 
;                  feature with care as data outside of the selected range are effectively removed; 
;                  values less than the minimum are set as 0, values greater than the maximum are 
;                  set as 255.
;              
; NOTES:       An interactive ENVI session is needed to run this tool.
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
;              FUNCTION_WIDGET_Enter_Value
;              FUNCTION_WIDGET_Enter_Value_Pair
;              XCOLORS (by David Fanning, see: www.dfanning.com/programs/xcolors.pro)
;               
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Create_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Create_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA:
  PATH = 'C:\'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin'], $
    /MUST_EXIST, /MULTIPLE_FILES)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; GET FILENAME SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  FNS = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FNS[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  NT = FUNCTION_WIDGET_Radio_Button('Define an input nodata value?  ', ['YES', 'NO'])
  ;--------------
  ; SET THE NODATA VALUE
  IF NT EQ 0 THEN NAN_VALUE = FUNCTION_WIDGET_Enter_Value('Define the input nodata value:  ', 255.00)   
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  PATH = 'C:\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SET THE COLOR TABLE TYPE
  XCOLORS, /BLOCK, COLORINFO=COLORINFO_STRUCT
  ;--------------
  ; SET COLOR TABLE PARAMETERS
  CT_RED = COLORINFO_STRUCT.R
  CT_GREEN = COLORINFO_STRUCT.G
  CT_BLUE = COLORINFO_STRUCT.B
  CT_TYPE = COLORINFO_STRUCT.TYPE
  CT_NAME = COLORINFO_STRUCT.NAME
  CT_INDEX = COLORINFO_STRUCT.INDEX
  ;---------------------------------------------------------------------------------------------
  ; SET THE CONTRAST STRETCH STATUS
  S_STATUS = FUNCTION_WIDGET_Radio_Button('Set display limits?  ', ['YES', 'NO'])
  ;---------------------------------------------------------------------------------------------
  ; SET THE CONTRAST STRETCH PARAMETERS:
  ;-----------------------------------
  IF S_STATUS EQ 0 THEN BEGIN
    ; REPEAT...UNTIL STATEMENT: 
    CHECK_P = 0
    REPEAT BEGIN ; START 'REPEAT'
    ;--------------
    S_VALUES = FUNCTION_WIDGET_Enter_Value_Pair('Define the new display limits  ', 'Minimum ', 'Maximum', 0.0000, 100.0000)
    ;--------------
    ; SET PARAMETERS
    LOW = S_VALUES[0]
    HIGH = S_VALUES[1]
    ;--------------    
    ; ERROR CHECK
    IF (HIGH LE LOW) THEN BEGIN
      PRINT, ''
      PRINT, 'THE INPUT IS NOT VALID: ', 'THE HIGH STRETCH VALUE MUST BE GREATER THAN THE LOW STRETCH VALUE'
      CHECK_P = 1
    ENDIF ELSE CHECK_P = 0  
    ;-------------- 
    ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
    ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;-----------------------------------
    FILE_IN = IN_FILES[i] ; SET THE i-TH FILE
    FNS_IN = FNS[i] ; SET THE i-TH FILENAME
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE ; OPEN FILE
    ;--------------
    ; GET FILE INFORMATION
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DT
    ; SET INPUT FILE DIMENSIONS
    DIMS_IN = [NS, NL]
    ; SET OUTPUT FILE DIMENSIONS
    DIMS_OUT = DIMS_IN / 1
    ;-------------------------------------------------------------------------------------------
    IF NB GT 1 THEN BEGIN ; (BAND)
      ;-----------------------------------
      FOR b=0, NB-1 DO BEGIN ; BAND LOOP
        ;-----------------------------------
        DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=b) ; GET DATA (BAND)
        ;---------------------------------- 
        ; DATA TYPE CHECK
        IF (DT LT 4) AND (DT GT 5) THEN DATA = FLOAT(DATA)
        ;--------------
        IF NT EQ 0 THEN BEGIN
          n = WHERE(DATA EQ FLOAT(NAN_VALUE), COUNT_NAN) ; GET NODATA POSITION
          IF (COUNT_NAN GT 0) THEN DATA[n] = !VALUES.F_NAN ; SET NODATA
        ENDIF
        ;--------------
        INDEX_NAN = WHERE(FINITE(DATA, /NAN), COUNT_NAN) ; GET FINITE NODATA COUNT
        INDEX_INFINITE = WHERE(FINITE(DATA, /INFINITY), COUNT_INFINITY) ; GET INFINITE NODATA COUNT
        COUNT_NODATA = COUNT_NAN + COUNT_INFINITY ; GET NODATA COUNT
        ;---------------------------------------------------------------------------------------
        IF S_STATUS EQ 0 THEN BEGIN ; APPLY NEW LIMITS (BAND):
          ;-------------------------------------------------------------------------------------
          l = WHERE(DATA LT LOW, COUNT_l) ; GET POSITION OF VALUES LT LOW
          IF (COUNT_l GT 0) THEN DATA[l] = LOW ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
          h = WHERE(DATA GT HIGH, COUNT_h) ; GET POSITION OF VALUES GT HIGH
          IF (COUNT_h GT 0) THEN DATA[h] = HIGH ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE
          ;-------------------------------------------------------------------------------------
        ENDIF 
        ;---------------------------------------------------------------------------------------
        ; APPLY CONTRAST STRETCH:
        ;-----------------------------------
        RANGE_X = 255 ; SET NEW HISTOGRAM RANGE  
        RANGE_DATA = (MAX(DATA, /NAN) - MIN(DATA, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
        SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
        INTERCEPT = (SLOPE * MIN(DATA, /NAN)) ; CALCULATE INTERCEPT
        DATA = FIX((SLOPE*DATA)-INTERCEPT) ; APPLY STRETCH
        DATA_PNG = BYTE(TEMPORARY(DATA)) ; CONVERT DATATYPE TO BYTE
        ;---------------------------------------------------------------------------------------
        ; WRITE DATA:
        ;-----------------------------------
        ; UPDATE COLOR TABLE TO SHOW NODATA AS YELLOW
        IF COUNT_NODATA GT 0 THEN CT_RED[0]=255
        IF COUNT_NODATA GT 0 THEN CT_GREEN[0]=255 
        ;--------------
        BNAME = BNAMES[b] ; SET BANDNAME
        OUTNAME = OUT_DIRECTORY + FNS_IN + '.' + BNAME + '.png' ; BUILD OUTNAME
        WRITE_PNG, OUTNAME, DATA_PNG, CT_RED, CT_GREEN, CT_BLUE, /ORDER ; SAVE PNG
        ;---------------------------------------------------------------------------------------
      ENDFOR
      ;-----------------------------------------------------------------------------------------
      ; PRINT LOOP INFORMATION:
      ;-----------------------------------   
      ; GET END TIME
      SECONDS = (SYSTIME(1)-L_TIME)
      ;--------------
      PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR BAND ', STRTRIM(b+1, 2), ' OF ', $
        STRTRIM(NB, 2), ' FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
      ;-----------------------------------------------------------------------------------------    
    ENDIF ELSE BEGIN ; (FILE)
      ;-----------------------------------------------------------------------------------------
      DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=0) ; GET DATA (FILE)
      ;----------------------------------
      ; DATA TYPE CHECK
      IF (DT LT 4) AND (DT GT 5) THEN DATA = FLOAT(DATA)
      ;--------------
      IF NT EQ 0 THEN BEGIN
        n = WHERE(DATA EQ FLOAT(NAN_VALUE), COUNT_NAN) ; GET NODATA POSITION
        IF (COUNT_NAN GT 0) THEN DATA[n] = !VALUES.F_NAN ; SET NODATA
      ENDIF
      ;--------------
      INDEX_NAN = WHERE(FINITE(DATA, /NAN), COUNT_NAN) ; GET FINITE NODATA COUNT
      INDEX_INFINITE = WHERE(FINITE(DATA, /INFINITY), COUNT_INFINITY) ; GET INFINITE NODATA COUNT
      COUNT_NODATA = COUNT_NAN + COUNT_INFINITY ; GET NODATA COUNT
      ;-----------------------------------------------------------------------------------------
      IF S_STATUS EQ 0 THEN BEGIN ; APPLY NEW LIMITS (FILE):
        ;---------------------------------------------------------------------------------------
        l = WHERE(DATA LT LOW, COUNT_l) ; GET POSITION OF VALUES LT LOW
        IF (COUNT_l GT 0) THEN DATA[l] = LOW ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
        h = WHERE(DATA GT HIGH, COUNT_h) ; GET POSITION OF VALUES GT HIGH
        IF (COUNT_h GT 0) THEN DATA[h] = HIGH ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE
        ;---------------------------------------------------------------------------------------
      ENDIF 
      ;-----------------------------------------------------------------------------------------
      ; APPLY CONTRAST STRETCH:
      ;-----------------------------------
      RANGE_X = 255 ; SET NEW HISTOGRAM RANGE  
      RANGE_DATA = (MAX(DATA, /NAN) - MIN(DATA, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
      SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
      INTERCEPT = (SLOPE * MIN(DATA, /NAN)) ; CALCULATE INTERCEPT
      DATA = FIX((SLOPE*DATA)-INTERCEPT) ; APPLY STRETCH
      DATA_PNG = BYTE(TEMPORARY(DATA)) ; CONVERT DATATYPE TO BYTE
      ;-----------------------------------------------------------------------------------------
      ; WRITE DATA:
      ;-----------------------------------
      ; UPDATE COLOR TABLE TO SHOW NODATA AS YELLOW
      IF COUNT_NODATA GT 0 THEN CT_RED[0]=255
      IF COUNT_NODATA GT 0 THEN CT_GREEN[0]=255 
      ;--------------
      OUTNAME = OUT_DIRECTORY + FNS_IN + '.png' ; BUILD OUTNAME
      WRITE_PNG, OUTNAME, DATA_PNG, CT_RED, CT_GREEN, CT_BLUE, /ORDER ; SAVE PNG
      ;-----------------------------------------------------------------------------------------     
    ENDELSE
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
      STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Create_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END   