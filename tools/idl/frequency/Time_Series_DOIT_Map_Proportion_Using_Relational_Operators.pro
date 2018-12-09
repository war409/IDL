; ##############################################################################################
; NAME: Time_Series_DOIT_Map_Proportion_Using_Relational_Operators.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 22/09/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool produces three types of output:
; 
;              MAP THE PERCENTAGE OF...
; 
;              The per-cell proportion of the input time-series that conforms   
;              to the user defined relational statement. Cell values that: DO and DO NOT, conform  
;              to the user statement are identified in each input. The per-cell percentage of 
;              inputs in the time-series that DO conform to the selected statement is calculated  
;              and returned.
;              
;              For example, say each individual input contains values from 0.0 to 1.0 however the  
;              user is only interested in values (or spatial location) that are greater than 0.5.  
;              By defining the relational statement as ‘Event GT 0.5’ the tool will identify those 
;              cells that satisfy the criteria in each input grid. The output grid can contain 
;              values from 0 to 100. Where a cell value of 100 indicates that for each input that 
;              cell location has a value greater than 0.5.
;              
;              The statement may contain up to two user-selected operators; e.g. the relational 
;              statement ‘Event GT 0.5’ AND ‘Event LE 0.75’ will identify those values in the 
;              input that have a cell value of more than 0.5 but less than or equal to 0.75.
;
;              Similarly, ‘Event GT 0.5’ OR ‘Event LE 0.25’ identifies values greater than 50 
;              and values less than or equal to 0.25.
;              
;              MAP THE COUNT OF...
;              
;              Similar to above. Rather than the output containing the proportion of the time-series
;              that conforms to the selected statement it contains the per cell count of times the 
;              statement was satisfied.
;              
;              MAP BY FREQUENCY OF...
;              
;              This output type identifies cells that have meet the selected statement EQ, NE, 
;              LT, LE, GE, GT a user selected proportion of time.
;              
;              For example, this option could identify cells that have had a cell value GE 0.95 for
;              95% of the time-series. Cells that satisfy the criteria are given a value of 1 in the
;              output, cells that do not satisfy the criteria are given a value of 0.
;          
; INPUT:       One or more single band raster files.
;
; OUTPUT:      One output flat binary file (.img) of the user selected datatype per time-series. 
;             (See description for more details)
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT THE OUTPUT TYPE: choose from 'MAP THE PERCENTAGE OF...', 'MAP THE COUNT OF...',
;                  or 'MAP BY FREQUENCY OF...' see DESCRIPTION
;              
;              2.  SELECT THE INPUT DATA: see INPUT
;              
;              3.  Select the date format: Select whether the input filenames include the year, day,
;                  and month as YYYY MM DD (e.g. 2010 13 10), or year and day-of-year (e.g. 2010 049). 
;                  The date elements can be in any order. See NOTES for more information.
;              
;              4.  SELECT THE INPUT DATATYPE: The datatype of the input rasters e.g. byte, integer, 
;                  float etc.
;              
;              5.  DEFINE A NODATA VALUE: If the input data contains a 'fill' or 'nodata' value that 
;                  you want to exclude from the processing select YES.
;              
;              5.1   DEFINE THE INPUT NODATA VALUE (optional; if YES in 3.): The input nodata value.
;              
;              6.  SET THE RELATIONAL STATEMENT: see DESCRIPTION
;              
;              7.  SET THE OUTPUT NODATA VALUE' (no-data cells in the output will have this value)*
;              
;              8.  SELECT THE OUTPUT DATATYPE: The datatype of the output raster.
;              
;              9.  DEFINE THE OUTPUT FILE: The output raster name and location.     
;              
; NOTES:       The input data must have identical dimensions.
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

PRO Time_Series_DOIT_Map_Proportion_Using_Relational_Operators
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Map_Proportion_Using_Relational_Operators'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE OUTPUT TYPE
  VALUES = ['1. MAP THE PERCENTAGE OF...','2. MAP THE COUNT OF...','3. MAP BY FREQUENCY OF...']
  TYPE_OUTPUT = FUNCTION_WIDGET_Radio_Button('SELECT THE OUTPUT TYPE', VALUES)
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA:
  PATH='C:\'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin'], $
    /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
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
  TYPE_DATE = FUNCTION_WIDGET_Radio_Button('Select the date format:  ', ['DOY/YEAR', 'DD/MM/YYYY'])
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
  DT = FUNCTION_WIDGET_Radio_Button('SELECT THE INPUT DATATYPE', DT_VALUES)
  ;--------------
  IF DT EQ 0 THEN RETURN
  IF DT EQ 7 THEN RETURN
  IF DT EQ 8 THEN RETURN
  IF DT EQ 10 THEN RETURN
  IF DT EQ 11 THEN RETURN
  ;--------------------------------------------------------------------------------------------- 
  ; SET THE NODATA STATUS
  TYPE_NAN = FUNCTION_WIDGET_Radio_Button('DEFINE AN INPUT NODATA VALUE', ['YES', 'NO'])
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
  ;---------------------------------------------------------------------------------------------
  ; SET PARENT:
  PARENT = WIDGET_BASE(TITLE='SET THE RELATIONAL STATEMENT', TAB_MODE=2, XSIZE=310, /ROW, /GRID_LAYOUT)
    WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
  ;--------------  
  ; SET CHILDREN:
  CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
  CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
  CHILD_3 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
  ;--------------
  ; DEFINE CHILDREN:
  ;--------------
  DROPLIST_1 = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT','NE'])
  STATEMENT_1 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
  STATEMENT_FIELD_1 = CW_FIELD(STATEMENT_1, XSIZE=8, VALUE=20, TITLE='', /RETURN_EVENTS)
  DROPLIST_2 = WIDGET_DROPLIST(CHILD_3, SCR_XSIZE=75, YSIZE=25, TITLE='', VALUE=['---','AND','OR'])
  ;-------------- 
  ; REALIZE WIDGETS:
  ;--------------  
  WIDGET_CONTROL, DROPLIST_1, /REALIZE
    DROPLIST_RETURN_1 = WIDGET_EVENT(DROPLIST_1)
    DROPLIST_ARRAY_1 = DROPLIST_RETURN_1.INDEX
    DROPLIST_VALUE_1 = DROPLIST_ARRAY_1[0]
  ;--------------
  WIDGET_CONTROL, STATEMENT_1, /REALIZE
    STATEMENT_RETURN_1 = WIDGET_EVENT(STATEMENT_1)
    STATEMENT_ARRAY_1 = STATEMENT_RETURN_1.VALUE
    STATEMENT_VALUE_1 = DOUBLE(STATEMENT_ARRAY_1[0])
  ;--------------
  WIDGET_CONTROL, DROPLIST_2, /REALIZE
    DROPLIST_RETURN_2 = WIDGET_EVENT(DROPLIST_2)
    DROPLIST_ARRAY_2 = DROPLIST_RETURN_2.INDEX
    DROPLIST_VALUE_2 = DROPLIST_ARRAY_2[0]
  ;-----------------------------------  
  ; SECOND OPERATOR:
  IF (DROPLIST_VALUE_2 GT 0) THEN BEGIN
    ;-----------------------------------
    ; DEFINE CHILDREN:
    ;--------------
    DROPLIST_3 = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT','NE'])
    STATEMENT_2 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
    STATEMENT_FIELD_2 = CW_FIELD(STATEMENT_2, XSIZE=8, VALUE=75, TITLE='', /RETURN_EVENTS)
    ;--------------
    ; REALIZE WIDGETS
    ;--------------
    WIDGET_CONTROL, DROPLIST_3, /REALIZE
      DROPLIST_RETURN_3 = WIDGET_EVENT(DROPLIST_3)
      DROPLIST_ARRAY_3 = DROPLIST_RETURN_3.INDEX
      DROPLIST_VALUE_3 = DROPLIST_ARRAY_3[0]
    ;--------------
    WIDGET_CONTROL, STATEMENT_2, /REALIZE
      STATEMENT_RETURN_2 = WIDGET_EVENT(STATEMENT_2)
      STATEMENT_ARRAY_2 = STATEMENT_RETURN_2.VALUE
      STATEMENT_VALUE_2 = DOUBLE(STATEMENT_ARRAY_2[0])
    ;-----------------------------------
    ; SET VARIABLES
    IF DROPLIST_VALUE_3 EQ 0 THEN OPERATOR_3 = 'EQ'
    IF DROPLIST_VALUE_3 EQ 1 THEN OPERATOR_3 = 'LE'
    IF DROPLIST_VALUE_3 EQ 2 THEN OPERATOR_3 = 'LT' 
    IF DROPLIST_VALUE_3 EQ 3 THEN OPERATOR_3 = 'GE'
    IF DROPLIST_VALUE_3 EQ 4 THEN OPERATOR_3 = 'GT'
    IF DROPLIST_VALUE_3 EQ 5 THEN OPERATOR_1 = 'NE'
  ENDIF
  ;-----------------------------------
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
  IF DROPLIST_VALUE_1 EQ 0 THEN OPERATOR_1 = 'EQ'
  IF DROPLIST_VALUE_1 EQ 1 THEN OPERATOR_1 = 'LE'
  IF DROPLIST_VALUE_1 EQ 2 THEN OPERATOR_1 = 'LT' 
  IF DROPLIST_VALUE_1 EQ 3 THEN OPERATOR_1 = 'GE'
  IF DROPLIST_VALUE_1 EQ 4 THEN OPERATOR_1 = 'GT'
  IF DROPLIST_VALUE_1 EQ 5 THEN OPERATOR_1 = 'NE'
  ;--------------
  IF DROPLIST_VALUE_2 EQ 0 THEN OPERATOR_2 = '---'
  IF DROPLIST_VALUE_2 EQ 1 THEN OPERATOR_2 = 'AND'
  IF DROPLIST_VALUE_2 EQ 2 THEN OPERATOR_2 = 'OR'
  ;-----------------------------------
  ; PRINT THE RELATIONAL STATEMENT:
  ;--------------
  IF (DROPLIST_VALUE_2 LT 1) THEN PRINT,'  RELATIONAL STATEMENT:  (EVENT  ', OPERATOR_1, '  ', $
    STRTRIM(STATEMENT_VALUE_1, 2),')' ELSE PRINT,'  RELATIONAL STATEMENT:  (EVENT  ', OPERATOR_1, $
    '  ', STRTRIM(STATEMENT_VALUE_1, 2), ')  ', OPERATOR_2, '  (EVENT  ', OPERATOR_3, '  ', $
    STRTRIM(STATEMENT_VALUE_2, 2), ')'
  PRINT,''
  ;-----------------------------------
  ; SET THE STATEMENT VALUE DATATYPE:
  IF DT EQ 1 THEN BEGIN
    STATEMENT_VALUE_1 = BYTE(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = BYTE(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 2 THEN BEGIN
    STATEMENT_VALUE_1 = FIX(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = FIX(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 3 THEN BEGIN
    STATEMENT_VALUE_1 = LONG(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = LONG(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 4 THEN BEGIN
    STATEMENT_VALUE_1 = FLOAT(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = FLOAT(STATEMENT_VALUE_2)
  ENDIF  
  ;--------------
  IF DT EQ 5 THEN BEGIN
    STATEMENT_VALUE_1 = DOUBLE(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = DOUBLE(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 6 THEN BEGIN
    STATEMENT_VALUE_1 = COMPLEX(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = COMPLEX(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 9 THEN BEGIN
    STATEMENT_VALUE_1 = DCOMPLEX(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = DCOMPLEX(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 12 THEN BEGIN
    STATEMENT_VALUE_1 = UINT(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = UINT(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 13 THEN BEGIN
    STATEMENT_VALUE_1 = ULONG(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = ULONG(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 14 THEN BEGIN
    STATEMENT_VALUE_1 = LONG64(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = LONG64(STATEMENT_VALUE_2)
  ENDIF
  ;--------------
  IF DT EQ 15 THEN BEGIN
    STATEMENT_VALUE_1 = ULONG64(STATEMENT_VALUE_1)
    IF (DROPLIST_VALUE_2 GT 0) THEN STATEMENT_VALUE_2 = ULONG64(STATEMENT_VALUE_2)
  ENDIF
  ;-----------------------------------
  ; PARAMETER CHECK:
  OPERATION_STATUS = FUNCTION_WIDGET_Radio_Button('IS THE STATEMENT CORRECT?', ['YES', 'NO'])
  ;--------------
  IF OPERATION_STATUS EQ 0 THEN CHECK_P = 0 ELSE CHECK_P = 1
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  ; SET THE PROPORTION OF TIME:
  ;-----------------------------------
  IF TYPE_OUTPUT EQ 2 THEN BEGIN
    ;--------------  
    ; REPEAT...UNTIL STATEMENT:
    REPEAT BEGIN ; START 'REPEAT'
    ;--------------
    ; ACTIVATE PARENT:
    ;--------------
    PARENT = WIDGET_BASE(TITLE='SET THE RELATIONAL STATEMENT', TAB_MODE=2, XSIZE=275, /ROW, /GRID_LAYOUT)
      WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
    ;--------------
    ; SET CHILDREN:
    CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
    CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
    ;--------------    
    ; DEFINE CHILDREN:
    ;--------------
    DROPLIST_4 = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT','NE'])
    STATEMENT_3 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
    STATEMENT_FIELD_3 = CW_FIELD(STATEMENT_3, XSIZE=8, VALUE=20, TITLE='', /RETURN_EVENTS)
    ;--------------
    ; REALIZE WIDGETS:
    ;--------------  
    WIDGET_CONTROL, DROPLIST_4, /REALIZE
      DROPLIST_RETURN_4 = WIDGET_EVENT(DROPLIST_4)
      DROPLIST_ARRAY_4 = DROPLIST_RETURN_4.INDEX
      DROPLIST_VALUE_4 = DROPLIST_ARRAY_4[0]
    ;--------------
    WIDGET_CONTROL, STATEMENT_3, /REALIZE
      STATEMENT_RETURN_3 = WIDGET_EVENT(STATEMENT_3)
      STATEMENT_ARRAY_3 = STATEMENT_RETURN_3.VALUE
      STATEMENT_VALUE_3 = DOUBLE(STATEMENT_ARRAY_3[0])
    ;--------------  
    ; SET OK BUTTON:
    ;--------------
    ; CREATE BUTTON
    BUTTON_2 = WIDGET_BASE(CHILD_1, XPAD=0, YPAD=5, /COLUMN, /ALIGN_LEFT)
      VALUES=['OK']
      BUTTON_FIELD_2 = CW_BGROUP(BUTTON_2, VALUES, /RETURN_NAME)
    ;--------------
    ; REALIZE BUTTON
    BUTTON_RETURN_2 = WIDGET_EVENT(BUTTON_2)
    BUTTON_VALUE_2 = BUTTON_RETURN_2.VALUE
    ;--------------
    ; KILL PARENT
    IF BUTTON_VALUE_2 EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
    ;-----------------------------------
    ; SET VARIABLES
    IF DROPLIST_VALUE_4 EQ 0 THEN OPERATOR_4 = 'EQ'
    IF DROPLIST_VALUE_4 EQ 1 THEN OPERATOR_4 = 'LE'
    IF DROPLIST_VALUE_4 EQ 2 THEN OPERATOR_4 = 'LT' 
    IF DROPLIST_VALUE_4 EQ 3 THEN OPERATOR_4 = 'GE'
    IF DROPLIST_VALUE_4 EQ 4 THEN OPERATOR_4 = 'GT'
    IF DROPLIST_VALUE_4 EQ 5 THEN OPERATOR_4 = 'NE'
    ;-----------------------------------
    ; PRINT THE RELATIONAL STATEMENT:
    ;--------------
    PRINT,'  RELATIONAL STATEMENT:  (FREQUENCY  ', OPERATOR_4, '  ', STRTRIM(STATEMENT_VALUE_3, 2), '% OF CASES)'
    PRINT,''
    ;-----------------------------------    
    ; PARAMETER CHECK:
    OPERATION_STATUS = FUNCTION_WIDGET_Radio_Button('IS THE STATEMENT CORRECT?', ['YES', 'NO'])
    ;--------------
    IF OPERATION_STATUS EQ 0 THEN CHECK_P2 = 0 ELSE CHECK_P2 = 1
    ;-----------------------------------
    ; IF CHECK_P2 = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
    ENDREP UNTIL (CHECK_P2 EQ 0) ; END 'REPEAT'
    ;--------------  
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; SET THE OUTPUT NODATA VALUE
  NAN_VALUE_OUT = FUNCTION_WIDGET_Enter_Value('SET THE OUTPUT NODATA VALUE: ', 255)
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT DATATYPE:
  ODT = FUNCTION_WIDGET_Radio_Button('SELECT THE OUTPUT DATATYPE', DT_VALUES)
  ;--------------
  IF ODT EQ 0 THEN RETURN
  IF ODT EQ 7 THEN RETURN
  IF ODT EQ 8 THEN RETURN
  IF ODT EQ 10 THEN RETURN
  IF ODT EQ 11 THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILE:
  PATH='C:\'
  OUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE='DEFINE THE OUTPUT FILE', /OVERWRITE_PROMPT)
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
    ; MAKE ARRAY TO HOLD FREQUENCY:
    MATRIX = MAKE_ARRAY(SEGMENT_SIZE, /DOUBLE)
    ;--------------
    ; MAKE ARRAY TO HOLD FILE COUNT:
    IF TYPE_NAN EQ 0 THEN MATRIX_COUNT = MAKE_ARRAY(SEGMENT_SIZE, /DOUBLE) ; NO DATA FREQUENCY 
    IF TYPE_NAN EQ 1 THEN MATRIX_COUNT = MAKE_ARRAY(SEGMENT_SIZE, VALUE=N_ELEMENTS(IN_FILES), /DOUBLE) ; TOTAL COUNT
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
      ;-----------------------------------------------------------------------------------------
      ; APPLY RELATIONAL OPERATION: 
      ;-----------------------------------------------------------------------------------------
      ; ONE OPERATOR STATEMENT:
      ;-----------------------------------
      IF DROPLIST_VALUE_2 EQ 0 THEN BEGIN
        ;--------------
        IF TYPE_NAN EQ 0 THEN BEGIN  ; IGNORE NODATA VALUE
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          IF DROPLIST_VALUE_1 EQ 1 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          IF DROPLIST_VALUE_1 EQ 2 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          IF DROPLIST_VALUE_1 EQ 3 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          IF DROPLIST_VALUE_1 EQ 4 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          IF DROPLIST_VALUE_1 EQ 5 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA NE NAN_VALUE))
          ;--------------
          ; VALUES NOT EQUAL TO THE NODATA VALUE
          MATRIX_COUNT += (DATA NE NAN_VALUE)
          ;--------------        
        ENDIF ELSE BEGIN
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN MATRIX += (DATA EQ STATEMENT_VALUE_1)
          IF DROPLIST_VALUE_1 EQ 1 THEN MATRIX += (DATA LE STATEMENT_VALUE_1) 
          IF DROPLIST_VALUE_1 EQ 2 THEN MATRIX += (DATA LT STATEMENT_VALUE_1)
          IF DROPLIST_VALUE_1 EQ 3 THEN MATRIX += (DATA GE STATEMENT_VALUE_1)
          IF DROPLIST_VALUE_1 EQ 4 THEN MATRIX += (DATA GT STATEMENT_VALUE_1)
          IF DROPLIST_VALUE_1 EQ 5 THEN MATRIX += (DATA NE STATEMENT_VALUE_1)
          ;--------------
        ENDELSE
        ;--------------
      ENDIF
      ;-----------------------------------
      ; TWO OPERATOR STATEMENT: AND
      ;-----------------------------------
      IF DROPLIST_VALUE_2 EQ 1 THEN BEGIN
        ;--------------
        IF TYPE_NAN EQ 0 THEN BEGIN  ; IGNORE NODATA VALUE
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE)) 
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))   
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 1 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 2 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))  
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 3 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 4 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 5 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          ; VALUES NOT EQUAL TO THE NODATA VALUE
          MATRIX_COUNT += (DATA NE NAN_VALUE)
          ;--------------        
        ENDIF ELSE BEGIN
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))   
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 1 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 2 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))  
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 3 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 4 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 5 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) AND (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
        ENDELSE
        ;--------------
      ENDIF
      ;-----------------------------------
      ; TWO OPERATOR STATEMENT: AND
      ;-----------------------------------
      IF DROPLIST_VALUE_2 EQ 2 THEN BEGIN
        ;--------------
        IF TYPE_NAN EQ 0 THEN BEGIN  ; IGNORE NODATA VALUE
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE)) 
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA EQ STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))   
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 1 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 2 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA LT STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))  
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 3 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 4 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA GT STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 5 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += (((DATA NE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2)) AND (DATA NE NAN_VALUE))
          ENDIF
          ;--------------
          ; VALUES NOT EQUAL TO THE NODATA VALUE
          MATRIX_COUNT += (DATA NE NAN_VALUE)
          ;--------------        
        ENDIF ELSE BEGIN
          ;--------------
          IF DROPLIST_VALUE_1 EQ 0 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA EQ STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))   
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 1 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 2 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA LT STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))  
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 3 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 4 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA GT STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
          IF DROPLIST_VALUE_1 EQ 5 THEN BEGIN 
            IF DROPLIST_VALUE_3 EQ 0 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA EQ STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 1 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA LE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 2 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA LT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 3 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA GE STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA GT STATEMENT_VALUE_2))
            IF DROPLIST_VALUE_3 EQ 4 THEN MATRIX += ((DATA NE STATEMENT_VALUE_1) OR (DATA NE STATEMENT_VALUE_2))
          ENDIF
          ;--------------
        ENDELSE
        ;--------------
      ENDIF
      ;-----------------------------------------------------------------------------------------      
      ; PRINT LOOP INFORMATION:
      ;-----------------------------------  
      ; GET END TIME
      SECONDS = (SYSTIME(1)-F_TIME)
      ;--------------
      ; PRINT
      PRINT, '    PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; WRITE OUTPUT:
    ;-------------------------------------------------------------------------------------------
    ; GET PROPORTION OF:
    ;--------------------------------------
    IF TYPE_OUTPUT EQ 0 THEN BEGIN 
      ;--------------
      ; CALCULATE PERCENTAGE
      MATRIX_OUT = ((MATRIX / MATRIX_COUNT) * 100.00)
      ;--------------
      ; SET NAN TO THE OUTPUT NO DATA VALUE
      n = WHERE(FINITE(MATRIX_OUT, /NAN), COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN MATRIX_OUT[n] = DOUBLE(NAN_VALUE_OUT)
      ;--------------
      ; CONVERT DATA TO OUTPUT DATATYPE:
      IF ODT EQ 1 THEN MATRIX_OUT = BYTE(MATRIX_OUT)
      IF ODT EQ 2 THEN MATRIX_OUT = FIX(MATRIX_OUT)
      IF ODT EQ 3 THEN MATRIX_OUT = LONG(MATRIX_OUT)
      IF ODT EQ 4 THEN MATRIX_OUT = FLOAT(MATRIX_OUT)
      IF ODT EQ 5 THEN MATRIX_OUT = DOUBLE(MATRIX_OUT)
      IF ODT EQ 6 THEN MATRIX_OUT = COMPLEX(MATRIX_OUT)
      IF ODT EQ 9 THEN MATRIX_OUT = DCOMPLEX(MATRIX_OUT)
      IF ODT EQ 12 THEN MATRIX_OUT = UINT(MATRIX_OUT)
      IF ODT EQ 13 THEN MATRIX_OUT = ULONG(MATRIX_OUT)
      IF ODT EQ 14 THEN MATRIX_OUT = LONG64(MATRIX_OUT)
      IF ODT EQ 15 THEN MATRIX_OUT = ULONG64(MATRIX_OUT)
      ;--------------
    ENDIF
    ;--------------------------------------
    ; GET COUNT OF:
    ;--------------------------------------
    ; SET NAN TO THE OUTPUT NO DATA VALUE
    n = WHERE(FINITE(MATRIX, /NAN), COUNT_NAN)
    IF (COUNT_NAN GT 0) THEN MATRIX[n] = DOUBLE(NAN_VALUE_OUT)
    ;--------------
    IF TYPE_OUTPUT EQ 1 THEN BEGIN 
      ;--------------
      ; CONVERT DATA TO OUTPUT DATATYPE:
      IF ODT EQ 1 THEN MATRIX_OUT = BYTE(MATRIX)
      IF ODT EQ 2 THEN MATRIX_OUT = FIX(MATRIX)
      IF ODT EQ 3 THEN MATRIX_OUT = LONG(MATRIX)
      IF ODT EQ 4 THEN MATRIX_OUT = FLOAT(MATRIX)
      IF ODT EQ 5 THEN MATRIX_OUT = DOUBLE(MATRIX)
      IF ODT EQ 6 THEN MATRIX_OUT = COMPLEX(MATRIX)
      IF ODT EQ 9 THEN MATRIX_OUT = DCOMPLEX(MATRIX)
      IF ODT EQ 12 THEN MATRIX_OUT = UINT(MATRIX)
      IF ODT EQ 13 THEN MATRIX_OUT = ULONG(MATRIX)
      IF ODT EQ 14 THEN MATRIX_OUT = LONG64(MATRIX)
      IF ODT EQ 15 THEN MATRIX_OUT = ULONG64(MATRIX)
      ;--------------
    ENDIF
    ;--------------------------------------
    ; GET PROPORTION OF TIME:
    ;--------------------------------------
    IF TYPE_OUTPUT EQ 2 THEN BEGIN 
      ;--------------
      ; CALCULATE PERCENTAGE
      MATRIX_OUT_TMP = ((MATRIX / MATRIX_COUNT) * 100.00)
      ;--------------
      ; GET PERCENT OF FREQUENCY RESULTS
      IF OPERATOR_4 EQ 'EQ' THEN MATRIX_OUT = (MATRIX_OUT_TMP EQ STATEMENT_VALUE_3)
      IF OPERATOR_4 EQ 'LE' THEN MATRIX_OUT = (MATRIX_OUT_TMP LE STATEMENT_VALUE_3)
      IF OPERATOR_4 EQ 'LT' THEN MATRIX_OUT = (MATRIX_OUT_TMP LT STATEMENT_VALUE_3)
      IF OPERATOR_4 EQ 'GE' THEN MATRIX_OUT = (MATRIX_OUT_TMP GE STATEMENT_VALUE_3)
      IF OPERATOR_4 EQ 'GT' THEN MATRIX_OUT = (MATRIX_OUT_TMP GT STATEMENT_VALUE_3)
      IF OPERATOR_4 EQ 'NE' THEN MATRIX_OUT = (MATRIX_OUT_TMP NE STATEMENT_VALUE_3)
      ;--------------
      ; SET NAN TO THE OUTPUT NO DATA VALUE
      n = WHERE(FINITE(MATRIX_OUT, /NAN), COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN MATRIX_OUT[n] = DOUBLE(NAN_VALUE_OUT)
      ;--------------
      ; CONVERT DATA TO OUTPUT DATATYPE:
      IF ODT EQ 1 THEN MATRIX_OUT = BYTE(MATRIX_OUT)
      IF ODT EQ 2 THEN MATRIX_OUT = FIX(MATRIX_OUT)
      IF ODT EQ 3 THEN MATRIX_OUT = LONG(MATRIX_OUT)
      IF ODT EQ 4 THEN MATRIX_OUT = FLOAT(MATRIX_OUT)
      IF ODT EQ 5 THEN MATRIX_OUT = DOUBLE(MATRIX_OUT)
      IF ODT EQ 6 THEN MATRIX_OUT = COMPLEX(MATRIX_OUT)
      IF ODT EQ 9 THEN MATRIX_OUT = DCOMPLEX(MATRIX_OUT)
      IF ODT EQ 12 THEN MATRIX_OUT = UINT(MATRIX_OUT)
      IF ODT EQ 13 THEN MATRIX_OUT = ULONG(MATRIX_OUT)
      IF ODT EQ 14 THEN MATRIX_OUT = LONG64(MATRIX_OUT)
      IF ODT EQ 15 THEN MATRIX_OUT = ULONG64(MATRIX_OUT)
      ;--------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; CREATE THE OUTPUT FILE:
    ;--------------------------------------
    IF s EQ 0 THEN OPENW, UNIT_OUT, OUT_FILE, /GET_LUN
    ;--------------
    ; CLOSE THE NEW FILES
    IF s EQ 0 THEN FREE_LUN, UNIT_OUT
    ;--------------
    OPENU, UNIT_OUT, OUT_FILE, /GET_LUN, /APPEND ; OPEN THE OUTPUT FILE
    WRITEU, UNIT_OUT, MATRIX_OUT ; APPEND DATA TO THE OUTPUT FILES
    FREE_LUN, UNIT_OUT ; CLOSE THE OUTPUT FILES    
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    SECONDS = (SYSTIME(1)-S_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', STRTRIM(s+1, 2), ' OF ', STRTRIM(FIX(COUNT_S), 2)
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
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Map_Proportion_Using_Relational_Operators'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END