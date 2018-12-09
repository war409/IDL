; ##############################################################################################
; NAME: BATCH_DOIT_Apply_Threshold_tmp.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 09/07/2010
; DLM: 28/07/2010
;
; DESCRIPTION: This tool applies a threshold to the input data via a user defined relational 
;              statement. Cell values that conform to the statement are given a value of 1; 
;              values that do not conform to the statement are given a value of 0.
;
;              For example, say the input data contains values from 0.0 – 1.0 however the user 
;              is only interested in values (or spatial location) that are greater than 0.5. By 
;              defining the relational statement as ‘Event GT 0.5’ the tool will identify those 
;              values that meet the criteria and give them a value of 1 in the output, while a 
;              value of 0 is applied to those cells that do not meet the criteria.
;
;              The statement may contain up to two user-selected operators; e.g. the relational 
;              statement ‘Event GT 0.5’ AND ‘Event LE 0.75’ will identify those values in the 
;              input that have a cell value of more than 0.5 but less than or equal to 0.75.
;
;              Similarly, ‘Event GT 0.5’ OR ‘Event LE 0.25’ identifies values greater than 50 
;              and values less than or equal to 0.25.
;
; INPUT:       One or more single-band datafiles.  
;
; OUTPUT:      One output file per input file. The output filename is the same as the input 
;              filename with an added string descriping the relational statement. 
;              (See description for more details)
;               
; PARAMETERS:  1.    'SELECT THE INPUT DATA'
;              2.    'SELECT THE INPUT DATATYPE'
;              3.    'SET A VALUE AS NODATA'
;              3.1     'SET THE NODATA VALUE' (optional)
;              4.    'SET THE RELATIONAL STATEMENT'
;              5.    'SELECT THE OUTPUT DIRECTORY'
;              
; NOTES:       The input data must have an identical datatype.
;
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: START
;************************************************************************************************

; ##############################################################################################
FUNCTION RADIO_BUTTON_WIDGET, TITLE, VALUES
  ;-----------------------------------
  ; SET XSIZE
  VL = MAKE_ARRAY(1, N_ELEMENTS(VALUES)+1, /STRING)
  FOR v=0, N_ELEMENTS(VALUES) DO BEGIN
    IF v LT N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(VALUES[v])
    IF v EQ N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(TITLE[0])
  ENDFOR
  XSIZE = MAX(VL)*8
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE, /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP=TITLE, /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT_TMP = WIDGET_EVENT(BASE)
  RESULT = RESULT_TMP.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;--------------
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
  ;-----------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION ENTER_VALUE_WIDGET, TITLE, DEFAULT_VALUE
  XSIZE = STRLEN(TITLE[0])*10
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE)
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=DEFAULT_VALUE, TITLE=TITLE, /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESULT_TMP = RESULT.VALUE
  RESULT = FLOAT(RESULT_TMP[0])
  WIDGET_CONTROL, BASE, /DESTROY
  ;--------------  
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
  ;-----------------------------------
END
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: END
;************************************************************************************************

PRO BATCH_DOIT_Apply_Threshold_tmp
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Apply_Threshold_tmp'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA:
  PATH='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  TITLE='SELECT THE INPUT DATA'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
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
  ; SELECT THE INPUT DATATYPE
  TITLE='SELECT THE INPUT DATATYPE'
  VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  DT = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------------------------------------------------------------------------------------- 
  ; SET THE NODATA STATUS
  VALUES = ['YES', 'NO']
  TYPE_NAN = RADIO_BUTTON_WIDGET('SET A VALUE AS NODATA', VALUES)
  ;--------------
  ; SET THE NODATA VALUE
  IF TYPE_NAN EQ 0 THEN NAN_VALUE = ENTER_VALUE_WIDGET('SET THE NODATA VALUE', 255.00)
  ;---------------------------------------------------------------------------------------------
  ; RELATIONAL OPERATION PARAMETERS:
  ;-------------- 
  ; REPEAT...UNTIL STATEMENT:
  ;REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------  
  ; SET PARENT:
  ;PARENT = WIDGET_BASE(TITLE='SET THE RELATIONAL STATEMENT', TAB_MODE=2, XSIZE=310, /ROW, /GRID_LAYOUT)
  ;  WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400  
  ;--------------  
  ; SET CHILDREN:
  ;CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
  ;CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
  ;CHILD_3 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
  ;--------------
  ; DEFINE CHILDREN:
  ;--------------
  ;DL1 = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT'])
  ;SV1 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
  ;SV1_FIELD = CW_FIELD(SV1, XSIZE=8, VALUE=DOUBLE(0.5000), TITLE='', /RETURN_EVENTS)
  ;DL2 = WIDGET_DROPLIST(CHILD_3, SCR_XSIZE=75, YSIZE=25, TITLE='', VALUE=['---','AND','OR'])
  ;-------------- 
  ; REALIZE WIDGETS:
  ;--------------  
  ;WIDGET_CONTROL, DL1, /REALIZE
  ;  DL1_R = WIDGET_EVENT(DL1)
  ;  DL1_VALUE = DL1_R.INDEX
  ;  DL1V = DL1_VALUE[0]
  ;--------------
  ;WIDGET_CONTROL, SV1, /REALIZE
  ;  SV1_R = WIDGET_EVENT(SV1)
  ;  SV1_VALUE = SV1_R.VALUE
  ;  SV1V = SV1_VALUE[0]
  ;--------------
  ;WIDGET_CONTROL, DL2, /REALIZE
  ;  DL2_R = WIDGET_EVENT(DL2)
  ;  DL2_VALUE = DL2_R.INDEX
  ;  DL2V = DL2_VALUE[0]
  ;-----------------------------------  
  ; SECOND OPERATOR:
  ;IF (DL2V GT 0) THEN BEGIN
  ;  ;-----------------------------------
  ;  ; DEFINE CHILDREN:
  ;  ;--------------
  ;  DL3 = WIDGET_DROPLIST(CHILD_1, XSIZE=75, YSIZE=25, TITLE='', VALUE=['EQ','LE','LT','GE','GT'])
  ;  SV2 = WIDGET_BASE(CHILD_2, YSIZE=25, /COLUMN, /ALIGN_LEFT)
  ;  SV2_FIELD = CW_FIELD(SV2, XSIZE=8, VALUE=DOUBLE(0.75000), TITLE='', /RETURN_EVENTS)
  ;  ;--------------
  ;  ; REALIZE WIDGETS
  ;  ;--------------
  ;  WIDGET_CONTROL, DL3, /REALIZE
  ;    DL3_R = WIDGET_EVENT(DL3)
  ;    DL3_VALUE = DL3_R.INDEX
  ;    DL3V = DL3_VALUE[0]
  ;  ;--------------
  ;  WIDGET_CONTROL, SV2, /REALIZE
  ;    SV2_R = WIDGET_EVENT(SV2)
  ;    SV2_VALUE = SV2_R.VALUE
  ;    SV2V = SV2_VALUE[0]
  ;    ;-----------------------------------
  ;    ; SET VARIABLES
  ;    IF DL3V EQ 0 THEN OPERATOR_3 = 'EQ'
  ;    IF DL3V EQ 1 THEN OPERATOR_3 = 'LE'
  ;    IF DL3V EQ 2 THEN OPERATOR_3 = 'LT' 
  ;    IF DL3V EQ 3 THEN OPERATOR_3 = 'GE'
  ;    IF DL3V EQ 4 THEN OPERATOR_3 = 'GT'
  ;ENDIF
  ;-----------------------------------
  ; SET OK BUTTON:
  ;--------------
  ; CREATE BUTTON
  ;B1 = WIDGET_BASE(CHILD_1, XPAD=0, YPAD=5, /COLUMN, /ALIGN_LEFT)
  ;  VALUES=['OK']
  ;  BOK = CW_BGROUP(B1, VALUES, /RETURN_NAME)
  ;--------------
  ; REALIZE BUTTON
  ;BOK_R = WIDGET_EVENT(B1)
  ;BOKV = BOK_R.VALUE
  ;--------------
  ; KILL PARENT
  ;IF BOKV EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
  ;-----------------------------------
  ; SET VARIABLES
  ;IF DL1V EQ 0 THEN OPERATOR_1 = 'EQ'
  ;IF DL1V EQ 1 THEN OPERATOR_1 = 'LE'
  ;IF DL1V EQ 2 THEN OPERATOR_1 = 'LT' 
  ;IF DL1V EQ 3 THEN OPERATOR_1 = 'GE'
  ;IF DL1V EQ 4 THEN OPERATOR_1 = 'GT'
  ;--------------
  ;IF DL2V EQ 0 THEN OPERATOR_2 = '---'
  ;IF DL2V EQ 1 THEN OPERATOR_2 = 'AND'
  ;IF DL2V EQ 2 THEN OPERATOR_2 = 'OR' 
  ;-----------------------------------
  ; PRINT THE RELATIONAL STATEMENT
  ;PRINT,''
  ;IF (DL2V LT 1) THEN PRINT,'  RELATIONAL STATEMENT:  (EVENT  ', OPERATOR_1, '  ', $
  ;  STRTRIM(SV1V, 2),')' ELSE PRINT,'  RELATIONAL STATEMENT:  (EVENT  ', OPERATOR_1, '  ', STRTRIM(SV1V, 2), ')  ', $
  ;  OPERATOR_2, '  (EVENT  ', OPERATOR_3, '  ', STRTRIM(SV2V, 2), ')'
  ;-----------------------------------
  ; PARAMETER CHECK: IS THIS CORRECT?
  ;VALUES = ['YES', 'NO']
  ;TITLE = 'IS THE STATEMENT CORRECT?'
  ;OPERATION_STATUS = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  ;IF OPERATION_STATUS EQ 0 THEN CHECK_P = 0 ELSE CHECK_P = 1
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ;ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
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
    ;-------------------------------------------------------------------------------------------
    ; SET THE i-TH FILE
    FILE_IN = IN_FILES[i]
    ;--------------
    ; SET THE i-TH FILENAME
    FN_IN = FNS[i]
    ;--------------
    ; GET DATA   
    DATA = READ_BINARY(FILE_IN, DATA_TYPE=DT)
    ;-----------------------------------
    ; PREPARE DATA:
    ;-----------------------------------
    ; NODATA
    IF TYPE_NAN EQ 0 THEN BEGIN
      ; DATA TYPE CHECK
      IF (DT LT 4) AND (DT GT 5) THEN DATA = DOUBLE(DATA)
      ;--------------
      ; SET NODATA
      n = WHERE(DATA EQ DOUBLE(NAN_VALUE), COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN DATA[n] = !VALUES.F_NAN
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; APPLY RELATIONAL OPERATION:
    ;******************************************************************************************* 
    ;-------------------------------------------------------------------------------------------
    SVL = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    ;--------------
    FOR j=0, N_ELEMENTS(SVL)-1 DO BEGIN
      ;-----------------------------------------------------------------------------------------
      ; SET
      SV = SVL[j]
      ;--------------
      ; APPLY
      MATRIX_OUT = (DATA GE SV)
      ;-----------------------------------------------------------------------------------------
      ;*****************************************************************************************
      ; WRITE OUTPUT:
      ;***************************************************************************************** 
      ;----------------------------------------------------------------------------------------- 
      ; SET OUTPUT FILENAME
      FNAME_OUT = OUT_DIRECTORY + FN_IN + '.GE.' + STRTRIM(SV,2) + '.img'
      ;--------------------------------------
      ; CONVERT OUTPUT TO INTEGER
      MATRIX_OUT = FIX(MATRIX_OUT)
      ;--------------------------------------
      ; CREATE THE OUTPUT FILE
      OPENW, UNIT_OUT, FNAME_OUT, /GET_LUN
      ;--------------------------------------
      ; CLOSE THE NEW FILES
      FREE_LUN, UNIT_OUT
      ;--------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, FNAME_OUT, /GET_LUN, /APPEND
      ;--------------------------------------
      ; APPEND DATA TO THE OUTPUT FILES
      WRITEU, UNIT_OUT, MATRIX_OUT
      ;--------------------------------------
      ; CLOSE THE OUTPUT FILES
      FREE_LUN, UNIT_OUT   
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Apply_Threshold'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END   
  
  