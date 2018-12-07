; ##############################################################################################
; NAME: BATCH_DOIT_Temporal_Resample.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 30/06/2010
; DLM: 28/07/2010
; 
; DESCRIPTION: This tool alters the temporal proportions of raster data by combining multiple
;              files into new composite files. The mean, median, minimum or maximum of the input 
;              files (by-cell) is calculated and returned as a  single new output. 
;              
;              The user may select whether to resample the input data to 8-day or 16-day 
;              composites. 
;              
;              Further, the output composite may be built using a single input dataset
;              or using two different input datasets.
;              
;              Before running this script check that the code responsible for extracting the file  
;              dates conforms to the file naming conventions of the selected input data (see NOTES).
;              
; INPUT:       Multiple single band grids (see NOTES). The user may select a single input dataset
;              two datasets.
; 
; OUTPUT:      One new grid (.img) per input period (8-day or 16-day).
; 
; PARAMETERS:  1.    'SELECT THE INPUT TYPE'
;              2.1     'SELECT THE INPUT DATA' (optional)
;              2.1     'SELECT THE FIRST DATASET' (optional)
;              2.2     'SELECT THE SECOND DATASET' (optional)
;              3.    'SELECT THE INPUT DATA TYPE'
;              4.    'SET A VALUE AS NODATA'
;              4.1     'SET THE NODATA VALUE' (optional)
;              5.    'SELECT THE RESAMPLE TYPE'
;              6.    'SELECT THE RESAMPLE METHOD'
;              7.1    'SELECT THE DATE TYPE'
;              7.1    'SELECT THE DATE TYPE OF THE FIRST DATASET'
;              7.2    'SELECT THE DATE TYPE OF THE SECOND DATASET'
;              8.    'SELECT THE OUTPUT DIRECTORY'
;              
; NOTES:       The input data must have identical dimensions. 
; 
;              The input data must have the date included in the file name (see lines 283 - 304). 
;              The date may be in the form of YEAR & DAY-OF-YEAR (DOY), or DAY, MONTH, YEAR. 
;              The order of the date elements is not important however the input datasets must have 
;              the same file naming conventions.  
;                    
; ##############################################################################################


;***********************************************************************************************
; FUNCTIONS: START
;***********************************************************************************************


; ##############################################################################################
FUNCTION RADIO_BUTTON_WIDGET, TITLE, VALUES
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
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
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
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
  ;-----------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION GET_FNAME_DMY_DOYYYYY, FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FILENAME, YEAR_STARTPOS, YEAR_LENGTH)
  DOY = STRMID(FILENAME, DOY_STARTPOS, DOY_LENGTH)
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY, YYY), MONTH, DAY
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MONTH, DAY, YYY)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, DMY
  ;-----------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION GET_FNAME_DMY_DDMMYYYY, FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FILENAME, YEAR_STARTPOS, YEAR_LENGTH)
  MMM = STRMID(FILENAME, MONTH_STARTPOS, MONTH_LENGTH)
  DDD = STRMID(FILENAME, DAY_STARTPOS, DAY_LENGTH)
  DMY = JULDAY(MMM, DDD, YYY)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, DMY
  ;-----------------------------------
END
; ###############################################################################################


;***********************************************************************************************
; FUNCTIONS: END
;***********************************************************************************************


PRO BATCH_DOIT_Temporal_Resample
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Temporal_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT TYPE 
  TITLE ='SELECT THE INPUT TYPE'
  VALUES = ['CREATE A SINGLE DATASET COMPOSITE', 'CREATE A TWO DATASET COMPOSITE']
  TYPE_INPUT = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA
  PATH = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IF TYPE_INPUT EQ 0 THEN TITLE='SELECT THE INPUT DATA' ELSE TITLE='SELECT THE FIRST DATASET'
  ;--------------
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
  IF TYPE_INPUT EQ 1 THEN BEGIN
    ;-----------------------------------
    ; SELECT THE INPUT DATA
    TITLE='SELECT THE SECOND DATASET'
    ;--------------
    IN_FILES2 = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
    ;--------------
    ; ERROR CHECK:
    IF IN_FILES2[0] EQ '' THEN RETURN
    ;--------------
    ; SORT FILE LIST
    IN_FILES2 = IN_FILES2[SORT(IN_FILES2)]
    ;--------------
    ; GET FILENAME SHORT
    FNAME_START = STRPOS(IN_FILES2, '\', /REVERSE_SEARCH)+1
    FNAME_LENGTH = (STRLEN(IN_FILES2)-FNAME_START)-4
    ;--------------
    ; GET FILENAME ARRAY
    FNS2 = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES2), /STRING)
    FOR a=0, N_ELEMENTS(IN_FILES2)-1 DO BEGIN
      ; GET THE a-TH FILE NAME 
      FNS2[*,a] += STRMID(IN_FILES2[a], FNAME_START[a], FNAME_LENGTH[a])
    ENDFOR
    ;-----------------------------------
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA TYPE
  TITLE='SELECT THE INPUT DATA TYPE'
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
  ; SELECT THE TEMPORAL RESAMPLE TYPE
  VALUES = ['RESAMPLE DAILY TO 8 DAY', 'RESAMPLE DAILY TO 16 DAY']
  TYPE_RESAMPLE = RADIO_BUTTON_WIDGET('SELECT THE RESAMPLE TYPE', VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD  
  VALUES = ['MEAN OF PERIOD', 'MEDIAN OF PERIOD', 'MINIMUM OF PERIOD', 'MAXIMUM OF PERIOD']
  METHOD_RESAMPLE = RADIO_BUTTON_WIDGET('SELECT THE RESAMPLE METHOD', VALUES)
  ;--------------
  ; SET RESAMPLE METHOD STRING
  IF METHOD_RESAMPLE EQ 0 THEN METHOD = 'MEAN'
  IF METHOD_RESAMPLE EQ 1 THEN METHOD = 'MEDIAN'
  IF METHOD_RESAMPLE EQ 2 THEN METHOD = 'MINIMUM'
  IF METHOD_RESAMPLE EQ 3 THEN METHOD = 'MAXIMUM'
  ;---------------------------------------------------------------------------------------------
  ; SET DATE TYPE:
  VALUES = ['DOY/YEAR', 'DD/MM/YYYY']
  IF TYPE_INPUT EQ 0 THEN TITLE='SELECT THE DATE TYPE' ELSE TITLE='SELECT THE DATE TYPE OF THE FIRST DATASET'
  TYPE_DATE = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  IF TYPE_DATE EQ 0 THEN BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY = GET_FNAME_DMY_DOYYYYY(FNS, 33, 4, 37, 3) 
  ENDIF ELSE BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY = GET_FNAME_DMY_DDMMYYYY(FNS, 15, 4, 13, 2, 11, 2) 
  ENDELSE 
  ;---------------------------------------------------------------------------------------------   
  IF TYPE_INPUT EQ 1 THEN BEGIN
    ;-----------------------------------
    ; SET DATE TYPE:
    VALUES = ['DOY/YEAR', 'DD/MM/YYYY']
    TITLE='SELECT THE DATE TYPE OF THE SECOND DATASET'
    TYPE_DATE = RADIO_BUTTON_WIDGET(TITLE, VALUES)
    ;--------------
    IF TYPE_DATE EQ 0 THEN BEGIN
      ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
      DMY2 = GET_FNAME_DMY_DOYYYYY(FNS2, 31, 4, 35, 3) 
    ENDIF ELSE BEGIN
      ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
      DMY2 = GET_FNAME_DMY_DDMMYYYY(FNS2, 15, 4, 13, 2, 11, 2) 
    ENDELSE 
    ;-----------------------------------
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  OUT_DIRECTORY = DIALOG_PICKFILE(DIALOG_PARENT=BASE, PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SET DATE LOOP PARAMETERS:
  ;-----------------------------------
  DSTART = JULDAY(1, 1, 2004) ; (M,D,YYYY)
  IF TYPE_RESAMPLE EQ 0 THEN DLENGTH = 8
  IF TYPE_RESAMPLE EQ 1 THEN DLENGTH = 16 
  DSTOP = JULDAY(1, 8, 2005) ; (M,D,YYYY)
  ;-----------------------------------
  ; START DATE LOOP:
  ;-----------------------------------
  WHILE (DEND = DSTART + DLENGTH) LE DSTOP DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    D_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET FILES:
    ;-------------------------------------------------------------------------------------------
    ; CONVERT JULDAY TO CALDAY
    CALDAT, DSTART, SM, SD, SY
    CALDAT, DEND-1, EM, ED, EY
    ;--------------------------------------
    ; GET FILES THAT FALL WITHIN THE DATE PERIOD
    INDEX = WHERE(((DMY GE DSTART) AND (DMY LT DEND)), COUNT1)
    ;--------------
    IF TYPE_INPUT EQ 1 THEN INDEX2 = WHERE(((DMY2 GE DSTART) AND (DMY2 LT DEND)), COUNT2) ELSE COUNT2 = 0
    ;--------------------------------------
    ; UPDATE START DATE 
    DSTART = DEND    
    ;--------------------------------------
    ; FILE CHECK: IF THERE ARE NO FILES IN THE CURRENT PERIOD CONTUNUE TO THE NEXT PERIOD 
    IF (COUNT1 EQ 0) AND (COUNT2 EQ 0) THEN CONTINUE
    ;--------------------------------------
    ; GET DAY OF YEAR AND JULIAN DATE
    SDOY = JULDAY(SM, SD, SY) - JULDAY(1, 0, SY)    
    ;--------------------------------------
    ; GET FILES
    FILES_IN = IN_FILES[INDEX]
    ;--------------
    IF TYPE_INPUT EQ 1 THEN FILES_IN2 = IN_FILES2[INDEX2]
    ;--------------------------------------
    ; COMBINE FILE LISTS
    IF TYPE_INPUT EQ 1 THEN BEGIN
      FILES = [[FILES_IN], [FILES_IN2]]
      FILES = FILES[SORT(FILES)]
    ENDIF ELSE FILES = FILES_IN
    ;-------------------------------------------------------------------------------------------
    ; SET OUTPUT:
    ;-------------------------------------------------------------------------------------------
    ; DOY ZERO CHECK
    IF SDOY LE 9 THEN SDOY = '00' + STRING(STRTRIM(SDOY,2))
    IF (SDOY LE 99) AND (SDOY GT 9) THEN SDOY = '0' + STRING(STRTRIM(SDOY,2))
    ;--------------------------------------
    ; SET DATE STRING
    OUT_FNAME_DATE = STRTRIM(SY, 2) + STRTRIM(SDOY, 2)
    ;--------------------------------------
    ; GET PREFIX
    PREFIX = STRMID(FNS[0], 0, 7)
    IF TYPE_INPUT EQ 1 THEN PREFIX2 = STRMID(FNS2[0], 0, 7)
    ;--------------------------------------
    ; GET SUFFIX
    SUFFIX = ''
    IF STRMATCH(FNS[0], '*3VariableModel*') EQ 1 THEN SUFFIX = '3VariableModel.'
    IF STRMATCH(FNS[0], '*5VariableModel*') EQ 1 THEN SUFFIX = '5VariableModel.'
    ;--------------------------------------
    ; SET OUTPUT FILENAME AND PATH
    IF TYPE_INPUT EQ 1 THEN BEGIN
      OUT_FNAME = OUT_DIRECTORY + PREFIX + '.' + PREFIX2 + '.005.' + STRTRIM(DLENGTH, 2) + 'DAY.' + METHOD + '.' + SUFFIX + OUT_FNAME_DATE + '.img'
    ENDIF ELSE BEGIN
      OUT_FNAME = OUT_DIRECTORY + PREFIX + '.005.' + STRTRIM(DLENGTH, 2) + 'DAY.' + METHOD + '.' + SUFFIX + OUT_FNAME_DATE + '.img'
    ENDELSE
    ;--------------------------------------
    ; CREATE THE OUTPUT FILE
    OPENW, UNIT_OUT, OUT_FNAME, /GET_LUN
    ;--------------
    ; CLOSE THE NEW OUTPUT FILE
    FREE_LUN, UNIT_OUT
    ;--------------------------------------
    ; PRINT INFORMATION
    PRINT,'' 
    PRINT,'    FILES: ', STRTRIM(SD, 2), STRTRIM(SM, 2), STRTRIM(SY, 2),' TO ', STRTRIM(ED, 2), STRTRIM(EM, 2), STRTRIM(EY, 2)
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; SEGMENT LOOP:
    ;*******************************************************************************************  
    ;------------------------------------------------------------------------------------------- 
    ; SEGMENT IMAGE:
    ;--------------------------------------
    ; OPEN THE FIRST INPUT FILE
    IN_EXAMPLE = READ_BINARY(FILES[0], DATA_TYPE=DT)
    ;--------------
    ; GET THE NUMBER OF ELEMENTS
    IN_ELEMENTS = N_ELEMENTS(IN_EXAMPLE)-1
    ;--------------
    ; CALL THE SEGMENT FUNCTION
    RESULT = SEGMENT_FUNCTION(IN_ELEMENTS, 0.1000) 
    ;--------------
    ; SET PARAMETERS
    SEGMENT = RESULT[0]
    COUNT_S = RESULT[1]
    SEGMENT_START = RESULT[2] 
    SEGMENT_END = RESULT[3]
    SEGMENT_LENGTH = RESULT[4]
    ;--------------------------------------
    ; SAVE SEGMENT PARAMETERS
    SEGMENT_END_TMP = SEGMENT_END
    SEGMENT_START_TMP = SEGMENT_START 
    ;--------------------------------------
    ; START SEGMENT LOOP:    
    ;--------------------------------------    
    FOR s=0, COUNT_S-1 DO BEGIN ; s
      ;-----------------------------------------------------------------------------------------
      ; GET START TIME: SEGMENT LOOP
      L_TIME = SYSTIME(1)
      ;-----------------------------------------------------------------------------------------
      ; UPDATE THE SEGMENT PARAMETERS
      IF s GE 1 THEN BEGIN
        ; UPDATE SEGMENT START-POSITION
        IF s EQ 1 THEN SEGMENT_START_TMP = LONG(SEGMENT_START_TMP + SEGMENT_LENGTH)+1
        IF s GT 1 THEN SEGMENT_START_TMP = LONG(SEGMENT_START_TMP + SEGMENT_LENGTH)
        ;--------------
        ; UPDATE SEGMENT END-POSITION
        SEGMENT_END_TMP = LONG((s+1)*SEGMENT_LENGTH)
      ENDIF
      ;--------------------------------------
      ; IN THE FINAL LOOP FIX THE END-POSITION: WHERE SEGMENT LENGTH IS NOT INTEGER
      IF s EQ COUNT_S-1 THEN BEGIN
        ; UPDATE SEGMENT END-POSITION
        SEGMENT_END_TMP = LONG((IN_ELEMENTS - SEGMENT_START_TMP) + SEGMENT_START_TMP)
      ENDIF
      ;--------------------------------------
      ; GET CURRENT SEGMENT SIZE
      SEGMENT_SIZE = LONG(SEGMENT_END_TMP - SEGMENT_START_TMP)+1
      ;-----------------------------------------------------------------------------------------       
      ;*****************************************************************************************
      ; FILE LOOP:
      ;*****************************************************************************************
      ;-----------------------------------------------------------------------------------------
      ; CREATE AN ARRAY TO HOLD THE GRID DATA
      MATRIX_X = MAKE_ARRAY(N_ELEMENTS(FILES), SEGMENT_SIZE, /DOUBLE)
      ;--------------------------------------
      ; START FILE LOOP:    
      ;-------------------------------------- 
      FOR i=0, N_ELEMENTS(FILES)-1 DO BEGIN ; i
        ;--------------------------------------
        ; GET INPUT DATA:
        ;--------------------------------------
        ; OPEN THE ith FILE
        DATA = READ_BINARY(FILES[i], DATA_TYPE=DT)
        ;--------------
        ; GET DATA SEGMENT
        DATA_IN = DATA(SEGMENT_START_TMP:SEGMENT_END_TMP)
        ;--------------
        ; FILL MATRIX_X
        MATRIX_X[i,*] = DATA_IN  
        ;--------------------------------------
      ENDFOR ; i
      ;-----------------------------------------------------------------------------------------
      ;*****************************************************************************************
      ; CALCULATE COMPOSITE:
      ;*****************************************************************************************
      ;-----------------------------------------------------------------------------------------
      IF TYPE_NAN EQ 0 THEN BEGIN ; SET NAN
        k = WHERE(MATRIX_X EQ FLOAT(NAN_VALUE), COUNT_k)
        IF (COUNT_k GT 0) THEN MATRIX_X[k] = !VALUES.F_NAN
      ENDIF   
      ;--------------------------------------
      ; GET COMPOSITE DATA:
      ;--------------------------------------
      IF N_ELEMENTS(FILES) GE 2 THEN BEGIN
        ;--------------------------------------
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
        ;--------------------------------------
      ENDIF ELSE BEGIN
        ;--------------------------------------
        ; GET OUTDATA
        DATA_OUT = MATRIX_X
        ;--------------------------------------
      ENDELSE
      ;-----------------------------------------------------------------------------------------
      ;*****************************************************************************************
      ; APPEND DATA:
      ;*****************************************************************************************
      ;-----------------------------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, OUT_FNAME, /APPEND, /GET_LUN
      ;--------------
      ; APPEND DATA TO THE OUTPUT FILE
      WRITEU, UNIT_OUT, DATA_OUT
      ;--------------
      ; CLOSE THE OUTPUT FILE
      FREE_LUN, UNIT_OUT
      ;-----------------------------------------------------------------------------------------
      ; PRINT LOOP INFORMATION:
      ;----------------------------------- 
      ; GET END TIME
      SECONDS = (SYSTIME(1)-L_TIME)
      ;--------------
      ; PRINT   
      PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', STRTRIM(s+1, 2), ' OF ', STRTRIM(FIX(COUNT_S), 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    MINUTES = (SYSTIME(1)-D_TIME)/60
    ;--------------
    ; PRINT
    PRINT,'    PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR FILES ', STRTRIM(SD, 2), '/', $
      STRTRIM(SM, 2), '/', STRTRIM(SY, 2), ' TO ', STRTRIM(ED, 2), '/', STRTRIM(EM, 2), '/', STRTRIM(EY, 2)
    ;-------------------------------------------------------------------------------------------
  ENDWHILE
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Temporal_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END