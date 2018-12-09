; ##############################################################################################
; NAME: MODIS_Time_Series_DOIT_Map_Open_Water_Proportion_By_Threshold.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 03/12/2009
; DLM: 31/05/2010
; 
; DESCRIPTION: This tool creates an inundation accumulation (proportion of) grid for the combined-
;              input based on the user-selected parameter. Inundation Proportion is mapped by-time-
;              series. A cell is classified as being inundated if the OWL (cell) value is EQ, GT, 
;              GE, LT or LE a user-selected 'OWL' threshold. The output (by cell) is the proportion 
;              of time inundated, that is, the percentage of, inundation count divided by total 
;              count (not including cloud dates).
;              
; INPUT:       One or more single band grids. The grids can be either 
;              continuous (0.0 to 1.0) or discrete (0 to 100).
;             
; OUTPUT:      One grid. The output shows inundation accumulation based on
;              the user defined expression (see description).
;         
; PARAMETERS:  Set output filename prefix (see line 54).
; 
;              Via IDL widgets, set:
; 
;              'SELECT THE INPUT DATA'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE INPUT DATA TYPE'
;              'SELECT THE INPUT DATA RANGE'             
;              'SELECT THE RELATIONAL OPERATOR'
;              'SET THE THRESHOLD PARAMETER'
;              'IS THIS CORRECT?' (PARAMETER CHECK)
; 
; NOTES:
; 
; ##############################################################################################


PRO MODIS_Time_Series_DOIT_Map_Open_Water_Proportion_By_Threshold
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_Time_Series_DOIT_Map_Open_Water_Proportion_By_Threshold'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; SET INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SET FILE PREFIX
  FNAME_P = '\MYD09Q1A1.005.OWL.5VariableModel'
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water', $
    TITLE='SELECT THE INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin'], /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------------------------------
  ; ERROR CHECK
  IF N_ELEMENTS(IN_X) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: INPUT DATA'
    RETURN
  ENDIF
  ;--------------------------------------
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;--------------------------------------
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(IN_X)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water', $
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;--------------------------------------  
  ; ERROR CHECK
  IF OUTFOLDER EQ '' THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: OUTPUT DIRECTORY'
    RETURN
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT NODATA STATUS', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  STATUS = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF STATUS EQ 0 THEN BEGIN
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=255.00, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA_TMP = RESULT.VALUE
    NODATA = FLOAT(NODATA_TMP[0])
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SELECT INPUT DATATYPE
  VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT THE INPUT DATA TYPE', $
    /COLUMN, /EXCLUSIVE, /NO_RELEASE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  DATATYPE = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA RANGE
  VALUES = ['0.00 - 1.00', '0 - 100']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT THE INPUT DATA RANGE', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  DATARANGE = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;---------------------------------------------------------------------------------------------
  ; SET THE RELATIONAL OPERATION:
  ;--------------------------------------------------------------------------------------------- 
  ; SET 'REPEAT CHECK' STARTING VALUE
  CHECK_P = 1
  ;-------------------------------------- 
  ; REPEAT...UNTIL STATEMENT: 
  REPEAT BEGIN ; START 'REPEAT'
    ;--------------------------------------
    ; SELECT THE RELATIONAL OPERATOR:
    VALUES = ['EQ','LE','LT','GE','GT']
    BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
    BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT THE RELATIONAL OPERATOR', $
      /COLUMN, /EXCLUSIVE)
    WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    OPERATOR_POS = RESULT.VALUE
    WIDGET_CONTROL, BASE, /DESTROY
    ;--------------------------------------    
    ; ASSIGN STRING TO OPERATOR_POS
    IF OPERATOR_POS EQ 0 THEN OPERATOR = 'EQ'  
    IF OPERATOR_POS EQ 1 THEN OPERATOR = 'LE'  
    IF OPERATOR_POS EQ 2 THEN OPERATOR = 'LT'
    IF OPERATOR_POS EQ 3 THEN OPERATOR = 'GE'
    IF OPERATOR_POS EQ 4 THEN OPERATOR = 'GT'       
    ;--------------------------------------
    ; SET THE THRESHOLD PARAMETER:
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=0.5000, TITLE='SET THE THRESHOLD PARAMETER (0.0 - 1.0) ', $
      /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    THRESHOLD_TMP = RESULT.VALUE
    THRESHOLD = FLOAT(THRESHOLD_TMP[0])
    WIDGET_CONTROL, BASE, /DESTROY
    ; ERROR CHECK
    IF (THRESHOLD LT 0.0) OR (THRESHOLD GT 1.0) THEN BEGIN
      PRINT, ''
      PRINT, 'THE INPUT IS NOT VALID: ENTER A VALUE BETWEEN 0.0000 AND 1.0000'
      RETURN
    ENDIF
    ;--------------------------------------
    ; PRINT OPERATION
    PRINT,''
    PRINT, '  OPERATION:  OWL ', OPERATOR, ' ', STRTRIM(THRESHOLD, 2)
    PRINT,''
    ;--------------------------------------
    ; PARAMETER CHECK: IS THIS CORRECT?
    VALUES = ['YES', 'NO']
    BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=200, /ROW)
    BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='IS THIS CORRECT?', $
      /COLUMN, /EXCLUSIVE)
    WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    CHECK_P = RESULT.VALUE
    WIDGET_CONTROL, BASE, /DESTROY
    ;--------------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------  
  ; OPEN THE 1ST FILE TO GET THE DIMENSIONS
  X_EXAMPLE = READ_BINARY(IN_X[0], DATA_TYPE=DATATYPE)
  ;--------------------------------------
  ; GET NUMBER OF ELEMENTS IN THE ith FILES
  IN_ELEMENTS = (N_ELEMENTS(X_EXAMPLE))
  ;--------------------------------------
  ; CREATE AN EMPTY VECTOR TO HOLD THE OUTPUT DATA
  MATRIX_X = MAKE_ARRAY(IN_ELEMENTS, /INTEGER)
  ; CREATE AN EMPTY VECTOR TO HOLD THE FILE COUNT
  IF STATUS EQ 0 THEN MATRIX_C = MAKE_ARRAY(IN_ELEMENTS, /INTEGER)
  IF STATUS EQ 1 THEN MATRIX_C = MAKE_ARRAY(IN_ELEMENTS, VALUE=COUNT_F, /INTEGER)
  ;--------------------------------------------------------------------------------------------- 
  ; FILE LOOP:
  ;--------------------------------------------------------------------------------------------- 
  FOR i=0, COUNT_F-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; GET LOOP START TIME
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; OPEN THE ith FILE
    X_IN = READ_BINARY(IN_X[i], DATA_TYPE=DATATYPE)
    ;-------------------------------------------------------------------------------------------
    ; ADD DATA TO MATRIX_X: APPLY RELATIONAL OPERATION
    ;-------------------------------------------------------------------------------------------
    ; DATA TYPE CHECK
    IF DATATYPE LT 4 THEN X_IN = FLOAT(X_IN)
    ;-------------------------------------------------------------------------------------------
    ; DATA FORMAT CHECK:
    IF DATARANGE EQ 0 THEN BEGIN
      ;--------------------------------------
      IF STATUS EQ 0 THEN BEGIN
        ;--------------------------------------
        ; APPLY OPERATION
        IF OPERATOR_POS EQ 0 THEN MATRIX_X += ((X_IN EQ THRESHOLD) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 1 THEN MATRIX_X += ((X_IN LE THRESHOLD) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 2 THEN MATRIX_X += ((X_IN LT THRESHOLD) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 3 THEN MATRIX_X += ((X_IN GE THRESHOLD) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 4 THEN MATRIX_X += ((X_IN GT THRESHOLD) AND (X_IN NE NODATA))
        ;--------------------------------------
        ; IDENTIFY VALUES NOT EQUAL TO NODATA
        MATRIX_C += (X_IN NE NODATA)
        ;--------------------------------------        
      ENDIF ELSE BEGIN
        ;--------------------------------------
        ; APPLY OPERATION
        IF OPERATOR_POS EQ 0 THEN MATRIX_X += (X_IN EQ THRESHOLD)
        IF OPERATOR_POS EQ 1 THEN MATRIX_X += (X_IN LE THRESHOLD) 
        IF OPERATOR_POS EQ 2 THEN MATRIX_X += (X_IN LT THRESHOLD)
        IF OPERATOR_POS EQ 3 THEN MATRIX_X += (X_IN GE THRESHOLD)
        IF OPERATOR_POS EQ 4 THEN MATRIX_X += (X_IN GT THRESHOLD)
        ;--------------------------------------
      ENDELSE
      ;--------------------------------------
    ENDIF ELSE BEGIN
      ;-------------------------------------- 
      IF STATUS EQ 0 THEN BEGIN
        ;--------------------------------------
        ; APPLY OPERATION
        IF OPERATOR_POS EQ 0 THEN MATRIX_X += ((X_IN EQ ((THRESHOLD)*100)) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 1 THEN MATRIX_X += ((X_IN LE ((THRESHOLD)*100)) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 2 THEN MATRIX_X += ((X_IN LT ((THRESHOLD)*100)) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 3 THEN MATRIX_X += ((X_IN GE ((THRESHOLD)*100)) AND (X_IN NE NODATA))
        IF OPERATOR_POS EQ 4 THEN MATRIX_X += ((X_IN GT ((THRESHOLD)*100)) AND (X_IN NE NODATA))
        ;--------------------------------------
        ; IDENTIFY VALUES NOT EQUAL TO NODATA
        MATRIX_C += (X_IN NE NODATA)
        ;--------------------------------------        
      ENDIF ELSE BEGIN
        ;--------------------------------------
        ; APPLY OPERATION
        IF OPERATOR_POS EQ 0 THEN MATRIX_X += (X_IN EQ ((THRESHOLD)*100))
        IF OPERATOR_POS EQ 1 THEN MATRIX_X += (X_IN LE ((THRESHOLD)*100))
        IF OPERATOR_POS EQ 2 THEN MATRIX_X += (X_IN LT ((THRESHOLD)*100))
        IF OPERATOR_POS EQ 3 THEN MATRIX_X += (X_IN GE ((THRESHOLD)*100))
        IF OPERATOR_POS EQ 4 THEN MATRIX_X += (X_IN GT ((THRESHOLD)*100))
        ;--------------------------------------
      ENDELSE
      ;--------------------------------------    
    ENDELSE
    ;-------------------------------------------------------------------------------------------
    ; GET LOOP END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
      STRTRIM(COUNT_F, 2)
    ;-------------------------------------------------------------------------------------------  
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------------------------------
  ; CALCULATE THE ACCUMULATED PROPORTION (PERCENTAGE):
  ;--------------------------------------
  ; GET PROPORTION
  MATRIX_OUT = (FLOAT(MATRIX_X) / FLOAT(MATRIX_C))*100
  ;---------------------------------------------------------------------------------------------
  ; WRITE OUTPUT:
  ;--------------------------------------
  ; CONVERT OUTPUT TO INTEGER
  MATRIX_OUT = FIX(MATRIX_OUT)
  ;--------------------------------------
  ; BUILD THE OUTPUT NAME  
  THRESHOLD_P = STRTRIM(FIX((THRESHOLD*100)), 2)
  FNAME_OUT = OUTFOLDER + FNAME_P + '.Inundation.Proportion.' + OPERATOR + '.' + THRESHOLD_P + '.img'
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
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: MODIS_Time_Series_DOIT_Map_Open_Water_Proportion_By_Threshold'
  PRINT,'' 
END  