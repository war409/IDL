; ##############################################################################################
; NAME: Time_Series_DOIT_Map_Contiguous_Using_Relational_Operators.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 23/09/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool identifies cells that conform to the user selected relational statement 
;              for a selected length of time. Where time is the count of inputs. For example, 
;              say each individual input raster contains values from 0.0 to 1.0, and each input 
;              is a daily snapshot of the phenomena of interest. Say the user is only interested 
;              in values that are greater than 0.5. The user also wants to identify cells that have 
;              had a value of more than 0.5 for at least 7 days in a row. By defining the relational 
;              statement as ‘Event GT 0.5’ and the length of the contiguous period as ‘7’ the tool 
;              will identify those cells where the criterion is satisfied in the input time series. 
;          
;              The output grid contains values of 0 and 1, where a value of 1 indicates that the 
;              criteria was satisfied at least once during the time-series and a value of 0 indicates 
;              that the criteria was not satisfied.
;          
; INPUT:       One or more single band raster files.
;
; OUTPUT:      One output flat binary file (.img) of the user selected datatype per time-series. 
;              (See description for more details)
;               
; PARAMETERS:  Via IDL widgets, set:
; 

;              
;              6.  SET THE LENGTH OF THE CONTIGUOUS PERIOD: see DESCRIPTION
;              
;              7.  SELECT THE OUTPUT DATATYPE: The datatype of the output raster.
;              
;              8.  DEFINE THE OUTPUT FILE: The output raster name and location. 
;              
; NOTES:       The input data must have identical dimensions.
; 
;              Per cell; if a single date within a contiguous period has a no-data value, but the 
;              selected criteria was satisfied on the previous and subsequent dates, the no-data 
;              date is recorded as satisfying the criteria for the purpose of identifying
;              contiguous periods.
;
;              The input data are sorted by date (in ascending order). Lines 166 and 169 
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
;              
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


FUNCTION SEGMENT_FUNCTION, IN_ELEMENTS, SEGMENT
  ; USING THE SEGMENT VALUE GET THE SEGMENT LENGTH
  SEGMENT_LENGTH = ROUND((IN_ELEMENTS)*SEGMENT)
  ; GET THE COUNT OF SEGMENTS WITHIN THE CURRENT IMAGE
  COUNT_S_TMP = CEIL((FLOAT(IN_ELEMENTS)) / FLOAT(SEGMENT_LENGTH))
  COUNT_S = COUNT_S_TMP[0]
  ; SET THE INITIAL SEGMENT START-POSITION AND END-POSITION
  SEGMENT_START = 0
  SEGMENT_END = FLOAT(SEGMENT_LENGTH)
  ; RETURN VALUES:
  RETURN, [SEGMENT, COUNT_S, SEGMENT_START, SEGMENT_END, SEGMENT_LENGTH]
END

PRO Time_Series_DOIT_Map_Contiguous_Using_Relational_Operators
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Map_Contiguous_Using_Relational_Operators'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;--------------------------------------------------------------------------------------------- 
  ; SELECT THE INPUT DATA:
  PATH='C:\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=FILTER, /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
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
  ;--------------
  ; SET DATE TYPE:
  TYPE_DATE = FUNCTION_WIDGET_Radio_Button('Select the date format:  ', ['YYYY/DOY', 'DD/MM/YYYY'])
  ;--------------
  IF TYPE_DATE EQ 0 THEN BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FNS, 8, 13) 
  ENDIF ELSE BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(FNS, 15, 13, 11)
  ENDELSE
  ;--------------
  ; SORT BY DATE
  IN_FILES = IN_FILES[SORT(DMY)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATATYPE
  DT_VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  DT = FUNCTION_WIDGET_Radio_Button('SELECT THE INPUT DATATYPE ', DT_VALUES)
  ;--------------
  IF DT EQ 0 THEN RETURN
  IF DT EQ 7 THEN RETURN
  IF DT EQ 8 THEN RETURN
  IF DT EQ 10 THEN RETURN
  IF DT EQ 11 THEN RETURN
  ;--------------------------------------------------------------------------------------------- 
  ; SET THE NODATA STATUS
  TYPE_NAN = FUNCTION_WIDGET_Radio_Button('DEFINE AN INPUT NODATA VALUE ', ['YES', 'NO'])
  ;--------------
  ; SET THE NODATA VALUE
  IF TYPE_NAN EQ 0 THEN NAN_VALUE = FUNCTION_WIDGET_Enter_Value('DEFINE THE INPUT NODATA VALUE: ', 255)
  ;--------------
  ; APPLY THE CORRECT DATATYPE:
  IF TYPE_NAN EQ 0 THEN BEGIN
    IF DT EQ 1 THEN NAN_VALUE = BYTE(NAN_VALUE)
    IF DT EQ 2 THEN NAN_VALUE = FIX(NAN_VALUE)
    IF DT EQ 3 THEN NAN_VALUE = LONG(NAN_VALUE)
    IF DT EQ 4 THEN NAN_VALUE = FLOAT(NAN_VALUE)
    IF DT EQ 5 THEN NAN_VALUE = DOUBLE(NAN_VALUE)
    IF DT EQ 6 THEN NAN_VALUE = COMPLEX(NAN_VALUE)
    IF DT EQ 9 THEN NAN_VALUE = DCOMPLEX(NAN_VALUE)
    IF DT EQ 12 THEN NAN_VALUE = UINT(NAN_VALUE)
    IF DT EQ 13 THEN NAN_VALUE = ULONG(NAN_VALUE)
    IF DT EQ 14 THEN NAN_VALUE = LONG64(NAN_VALUE)
    IF DT EQ 15 THEN NAN_VALUE = ULONG64(NAN_VALUE)
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; RELATIONAL OPERATION PARAMETERS:
  ;-------------- 
  ; REPEAT...UNTIL STATEMENT:
  REPEAT BEGIN ; START 'REPEAT'
  ;-----------------------------------
  ; SET PARENT:
  PARENT = WIDGET_BASE(TITLE='SET THE RELATIONAL STATEMENT', TAB_MODE=2, XSIZE=300, /ROW, /GRID_LAYOUT)
    WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
  ;--------------  
  ; SET CHILDREN:
  CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
  CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
  ;--------------
  ; DEFINE CHILDREN:
  ;--------------
  DROPLIST = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT','NE'])
  STATEMENT_1 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
  STATEMENT_FIELD_1 = CW_FIELD(STATEMENT_1, XSIZE=8, VALUE=20, TITLE='', /RETURN_EVENTS)
  ;--------------
  ; REALIZE WIDGETS
  ;--------------
  WIDGET_CONTROL, DROPLIST, /REALIZE
    DROPLIST_RETURN = WIDGET_EVENT(DROPLIST)
    DROPLIST_ARRAY = DROPLIST_RETURN.INDEX
    DROPLIST_VALUE = DROPLIST_ARRAY[0]
  ;--------------
  WIDGET_CONTROL, STATEMENT_1, /REALIZE
    STATEMENT_RETURN_1 = WIDGET_EVENT(STATEMENT_1)
    STATEMENT_ARRAY_1 = STATEMENT_RETURN_1.VALUE
    STATEMENT_VALUE_1 = DOUBLE(STATEMENT_ARRAY_1[0])
  ;--------------
  ; SET OK BUTTON:
  ;--------------
  ; CREATE BUTTON
  BUTTON_1 = WIDGET_BASE(CHILD_1, XPAD=0, YPAD=5, /COLUMN, /ALIGN_LEFT)
    VALUES=['OK']
    BUTTON_FIELD_1 = CW_BGROUP(BUTTON_1, VALUES, /RETURN_NAME)
  ;--------------
  ; REALIZE BUTTON
  BUTTON_RETURN_1 = WIDGET_EVENT(BUTTON_1)
  BUTTON_VALUE_1 = BUTTON_RETURN_1.VALUE
  ;--------------
  ; KILL PARENT
  IF BUTTON_VALUE_1 EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
  ;-----------------------------------
  ; SET VARIABLES
  IF DROPLIST_VALUE EQ 0 THEN OPERATOR = 'EQ'
  IF DROPLIST_VALUE EQ 1 THEN OPERATOR = 'LE'
  IF DROPLIST_VALUE EQ 2 THEN OPERATOR = 'LT' 
  IF DROPLIST_VALUE EQ 3 THEN OPERATOR = 'GE'
  IF DROPLIST_VALUE EQ 4 THEN OPERATOR = 'GT'
  IF DROPLIST_VALUE EQ 5 THEN OPERATOR = 'NE'
  ;-----------------------------------
  ; PRINT THE RELATIONAL STATEMENT:
  ;--------------
  PRINT,'  RELATIONAL STATEMENT:  (', OPERATOR, '  ', STRTRIM(STATEMENT_VALUE_1, 2), ')'
  PRINT,''
  ;-----------------------------------    
  ; PARAMETER CHECK:
  OPERATION_STATUS = FUNCTION_WIDGET_Radio_Button('IS THE STATEMENT CORRECT?  ', ['YES', 'NO'])
  ;--------------
  IF OPERATION_STATUS EQ 0 THEN CHECK_P = 0 ELSE CHECK_P = 1
  ;-----------------------------------
  ; IF CHECK_P2 = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  ; SET THE LENGTH OF THE CONTIGUOUS PERIOD
  LENGTH = FUNCTION_WIDGET_Enter_Value('SET THE LENGTH OF THE CONTIGUOUS PERIOD: ', 3)
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT DATATYPE:
  ODT = FUNCTION_WIDGET_Radio_Button('SELECT THE OUTPUT DATATYPE  ', DT_VALUES)
  ;--------------
  IF ODT EQ 0 THEN RETURN
  IF ODT EQ 7 THEN RETURN
  IF ODT EQ 8 THEN RETURN
  IF ODT EQ 10 THEN RETURN
  IF ODT EQ 11 THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILE:
  OUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE='DEFINE THE OUTPUT FILE', /OVERWRITE_PROMPT, FILE='MOD09A1.005.AUST.OWL.img')
  ;-------------- 
  ; ERROR CHECK
  IF OUT_FILE EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; SEGMENT LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SEGMENT IMAGE:
  ;-----------------------------------
  ; OPEN THE 1ST FILE TO GET THE INPUT DIMENSIONS
  IN_EXAMPLE = READ_BINARY(IN_FILES[0], DATA_TYPE=DT)
  ;--------------
  ; GET THE NUMBER OF ELEMENTS
  IN_ELEMENTS = N_ELEMENTS(IN_EXAMPLE) - 1
  ;--------------
  ; CALL THE SEGMENT FUNCTION
  RESULT = SEGMENT_FUNCTION(IN_ELEMENTS, 0.1000)
  ;--------------
  ; SET PARAMETERS
  SEGMENT = RESULT[0]
  COUNT_S = LONG(RESULT[1])
  SEGMENT_START = LONG(RESULT[2]) 
  SEGMENT_END = LONG(RESULT[3])
  SEGMENT_LENGTH = LONG(RESULT[4])
  SEGMENT_SIZE = SEGMENT_LENGTH
  ;-----------------------------------
  ; START SEGMENT LOOP:    
  ;-----------------------------------    
  FOR s=0, COUNT_S-1 DO BEGIN ; s
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: SEGMENT LOOP
    S_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------  
    ; UPDATE THE SEGMENT PARAMETERS
    IF s GE 1 THEN BEGIN
      ; UPDATE SEGMENT START-POSITION
      SEGMENT_START = SEGMENT_END + 1
      ;--------------
      ; UPDATE SEGMENT END-POSITION
      SEGMENT_END = SEGMENT_START + SEGMENT_SIZE
    ENDIF
    ;-----------------------------------
    ; IN THE FINAL LOOP FIX THE END-POSITION: WHERE SEGMENT LENGTH IS NOT A WHOLE INTEGER
    IF s EQ COUNT_S-1 THEN SEGMENT_END = ((LONG(IN_ELEMENTS) - SEGMENT_START) + SEGMENT_START)
    ;-----------------------------------
    ; GET CURRENT SEGMENT SIZE
    SEGMENT_SIZE = (SEGMENT_END - SEGMENT_START) + 1
    ;-------------------------------------------------------------------------------------------
    ; PRINT INFORMATION
    PRINT,''
    PRINT,'  SEGMENT: ', STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
    PRINT,'  CURRENT SEGMENT STARTING POSITION: ', STRTRIM(SEGMENT_START, 2)
    PRINT,'  CURRENT SEGMENT ENDING POSITION: ', STRTRIM(SEGMENT_END, 2)
    PRINT,'  CURRENT SEGMENT SIZE: ', STRTRIM(SEGMENT_SIZE, 2)    
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; FILE LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; MAKE ARRAYS:
    DURATION = MAKE_ARRAY(SEGMENT_SIZE, VALUE=0, /DOUBLE)
    CONTIGUOUS = MAKE_ARRAY(SEGMENT_SIZE, VALUE=0, /DOUBLE)
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
      ;-----------------------------------------------------------------------------------------
      ; GET START TIME: FILE LOOP
      F_TIME = SYSTIME(1)
      ;----------------------------------------------------------------------------------------- 
      ; GET DATA:
      ;-----------------------------------------------------------------------------------------
      ; SET THE i-TH FILE
      FILE_IN = IN_FILES[i]
      ;--------------
      ; GET DATA   
      DATA_IN = READ_BINARY(FILE_IN, DATA_TYPE=DT)
      ;--------------
      ; GET DATA SEGMENT
      DATA = DATA_IN(SEGMENT_START:SEGMENT_END)
      ;--------------------------------------
      IF i GT 0 THEN BEGIN
        ; SET THE i-TH -1 FILE
        FILE_P = IN_FILES[i-1]
        ;--------------
        ; GET DATA   
        DATA_P_IN = READ_BINARY(FILE_P, DATA_TYPE=DT)
        ;--------------
        ; GET DATA SEGMENT
        DATA_P = DATA_P_IN(SEGMENT_START:SEGMENT_END)
      ENDIF
      ;--------------------------------------
      IF i EQ 0 THEN BEGIN
        ; SET THE i-TH +1 FILE
        FILE_N = IN_FILES[i+1]
        ;--------------
        ; GET DATA   
        DATA_N_IN = READ_BINARY(FILE_N, DATA_TYPE=DT)
        ;--------------
        ; GET DATA SEGMENT
        DATA_N = DATA_N_IN(SEGMENT_START:SEGMENT_END)
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; APPLY RELATIONAL OPERATION:
      ;-----------------------------------------------------------------------------------------      
      IF i GT 0 THEN BEGIN
      IF TYPE_NAN EQ 0 THEN BEGIN  ; IGNORE NODATA VALUE
        ;--------------
        IF DROPLIST_VALUE EQ 0 THEN DURATION += (((DATA EQ STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P EQ STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 1 THEN DURATION += (((DATA LE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P LE STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 2 THEN DURATION += (((DATA LT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P LT STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 3 THEN DURATION += (((DATA GE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P GE STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 4 THEN DURATION += (((DATA GT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P GT STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 5 THEN DURATION += (((DATA NE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_P NE STATEMENT_VALUE_1) AND (DATA_P NE NAN_VALUE)))
        ;--------------
      ENDIF ELSE BEGIN
        ;--------------
        IF DROPLIST_VALUE EQ 0 THEN DURATION += ((DATA EQ STATEMENT_VALUE_1) AND (DATA_P EQ STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 1 THEN DURATION += ((DATA LE STATEMENT_VALUE_1) AND (DATA_P LE STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 2 THEN DURATION += ((DATA LT STATEMENT_VALUE_1) AND (DATA_P LT STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 3 THEN DURATION += ((DATA GE STATEMENT_VALUE_1) AND (DATA_P GE STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 4 THEN DURATION += ((DATA GT STATEMENT_VALUE_1) AND (DATA_P GT STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 5 THEN DURATION += ((DATA NE STATEMENT_VALUE_1) AND (DATA_P NE STATEMENT_VALUE_1))
        ;--------------
      ENDELSE
      ENDIF
      ;-----------------------------------
      IF i EQ 0 THEN BEGIN
      IF TYPE_NAN EQ 0 THEN BEGIN  ; IGNORE NODATA VALUE
        ;--------------
        IF DROPLIST_VALUE EQ 0 THEN DURATION += (((DATA EQ STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N EQ STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 1 THEN DURATION += (((DATA LE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N LE STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 2 THEN DURATION += (((DATA LT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N LT STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 3 THEN DURATION += (((DATA GE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N GE STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 4 THEN DURATION += (((DATA GT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N GT STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        IF DROPLIST_VALUE EQ 5 THEN DURATION += (((DATA NE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE)) $
          AND ((DATA_N NE STATEMENT_VALUE_1) AND (DATA_N NE NAN_VALUE)))
        ;--------------
      ENDIF ELSE BEGIN
        ;--------------
        IF DROPLIST_VALUE EQ 0 THEN DURATION += ((DATA EQ STATEMENT_VALUE_1) AND (DATA_N EQ STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 1 THEN DURATION += ((DATA LE STATEMENT_VALUE_1) AND (DATA_N LE STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 2 THEN DURATION += ((DATA LT STATEMENT_VALUE_1) AND (DATA_N LT STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 3 THEN DURATION += ((DATA GE STATEMENT_VALUE_1) AND (DATA_N GE STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 4 THEN DURATION += ((DATA GT STATEMENT_VALUE_1) AND (DATA_N GT STATEMENT_VALUE_1))
        IF DROPLIST_VALUE EQ 5 THEN DURATION += ((DATA NE STATEMENT_VALUE_1) AND (DATA_N NE STATEMENT_VALUE_1))
        ;--------------
      ENDELSE
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; RETURN '1' IF CONTIGUOUS PERIOD IS GE THE SELECTED THRESHOLD
      CONTIGUOUS = (DURATION GE DOUBLE(LENGTH))
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; WRITE OUTPUT:
    ;-------------------------------------------------------------------------------------------
    ; CONVERT DATA TO OUTPUT DATATYPE:
    IF ODT EQ 1 THEN CONTIGUOUS_OUT = BYTE(CONTIGUOUS)
    IF ODT EQ 2 THEN CONTIGUOUS_OUT = FIX(CONTIGUOUS)
    IF ODT EQ 3 THEN CONTIGUOUS_OUT = LONG(CONTIGUOUS)
    IF ODT EQ 4 THEN CONTIGUOUS_OUT = FLOAT(CONTIGUOUS)
    IF ODT EQ 5 THEN CONTIGUOUS_OUT = DOUBLE(CONTIGUOUS)
    IF ODT EQ 6 THEN CONTIGUOUS_OUT = COMPLEX(CONTIGUOUS)
    IF ODT EQ 9 THEN CONTIGUOUS_OUT = DCOMPLEX(CONTIGUOUS)
    IF ODT EQ 12 THEN CONTIGUOUS_OUT = UINT(CONTIGUOUS)
    IF ODT EQ 13 THEN CONTIGUOUS_OUT = ULONG(CONTIGUOUS)
    IF ODT EQ 14 THEN CONTIGUOUS_OUT = LONG64(CONTIGUOUS)
    IF ODT EQ 15 THEN CONTIGUOUS_OUT = ULONG64(CONTIGUOUS)
    ;-------------------------------------------------------------------------------------------
    ; CREATE THE OUTPUT FILE:
    ;--------------
    IF s EQ 0 THEN OPENW, UNIT_OUT, OUT_FILE, /GET_LUN
    ;--------------
    ; CLOSE THE NEW FILES
    IF s EQ 0 THEN FREE_LUN, UNIT_OUT
    ;-------------------------------------------------------------------------------------------  
    OPENU, UNIT_OUT, OUT_FILE, /GET_LUN, /APPEND ; OPEN THE OUTPUT FILE 
    WRITEU, UNIT_OUT, CONTIGUOUS_OUT ; APPEND DATA TO THE OUTPUT FILES
    FREE_LUN, UNIT_OUT ; CLOSE THE OUTPUT FILES 
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    SECONDS = (SYSTIME(1)-S_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', STRTRIM(s+1, 2), $
      ' OF ', STRTRIM(FIX(COUNT_S), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR ; FOR s
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
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Map_Contiguous_Using_Relational_Operators'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  