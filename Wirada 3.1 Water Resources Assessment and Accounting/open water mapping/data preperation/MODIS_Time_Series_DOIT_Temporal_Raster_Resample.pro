; ##############################################################################################
; NAME: MODIS_Time_Series_DOIT_Temporal_Raster_Resample.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 02/06/2010
; DLM: 07/06/2010
; 
; DESCRIPTION: This tool alters the temporal proportions of raster data by combining multiple
;              files into new merged (or composite) files. That is to say, the mean, median,
;              minimum or maximum of the input files (by-cell) is calculated and returned as a
;              single new output. The user can select whether to resample daily files to 8-day or
;              16-day composites by mean, median, minimum or maximum.
;              
; INPUT:       Multiple single band grids (see NOTES).
; 
; OUTPUT:      One new grid (.img) per input period (8-day or 16-day).
; 
; PARAMETERS:  Via widgets.  
;      
;              'SELECT THE INPUT FILES' 
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE RESAMPLE TYPE'
;              'SELECT THE RESAMPLE METHOD'
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE RESIZE VALUE (0.0 - 1.0)'
;              
; NOTES:       The input data must have identical dimensions. The input data must have date (YYYY, 
;              MM AND DD) inculded in the file name (see lines 175 - 177 for the code that extracts
;              date from file name).
;                    
; ##############################################################################################






;***********************************************************************************************
FUNCTION RADIO_BUTTON_WIDGET, TITLE, VALUES
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;-----------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP=TITLE, /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT_TMP = WIDGET_EVENT(BASE)
  RESULT = RESULT_TMP.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
END
;***********************************************************************************************
;***********************************************************************************************
FUNCTION ENTER_VALUE_WIDGET, TITLE, DEFAULT_VALUE
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;-----------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=DEFAULT_VALUE, TITLE=TITLE, /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESULT_TMP = RESULT.VALUE
  RESULT = FLOAT(RESULT_TMP[0])
  WIDGET_CONTROL, BASE, /DESTROY
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
END
;***********************************************************************************************
;***********************************************************************************************
FUNCTION SEGMENT_FUNCTION, IN_ELEMENTS, SEGMENT
  ;----------------------------------- 
  ; USING ON THE SEGMENT VALUE GET THE SEGMENT LENGTH
  SEGMENT_LENGTH = ROUND((IN_ELEMENTS)*SEGMENT)
  ; GET THE COUNT OF SEGMENTS WITHIN THE CURRENT IMAGE
  COUNT_S_TMP = CEIL((IN_ELEMENTS) / SEGMENT_LENGTH)
  COUNT_S = COUNT_S_TMP[0]
  ; SET THE INITIAL SEGMENT START-POSITION AND END-POSITION
  SEGMENT_START = 0
  SEGMENT_END = FLOAT(SEGMENT_LENGTH)
  ;-----------------------------------
  ; RETURN VALUES:
  RETURN, [SEGMENT, COUNT_S, SEGMENT_START, SEGMENT_END, SEGMENT_LENGTH]
END
;***********************************************************************************************
;***********************************************************************************************
FUNCTION GET_FNAME_DATE_DMY, FNAME_SHORT, YEAR_START, YEAR_LENGTH, MONTH_START, MONTH_LENGTH, DAY_START, DAY_LENGTH
  ;-----------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FNAME_SHORT, YEAR_START, YEAR_LENGTH)
  MMM = STRMID(FNAME_SHORT, MONTH_START, MONTH_LENGTH)
  DDD = STRMID(FNAME_SHORT, DAY_START, DAY_LENGTH)
  DMY = JULDAY(MMM, DDD, YYY)
  ;-----------------------------------
  ; RETURN VALUES:
  RETURN, DMY
END
;***********************************************************************************************
;***********************************************************************************************
FUNCTION GET_FNAME_DATE_YDOY, FNAME_SHORT, YEAR_START, YEAR_LENGTH, DOY_START, DOY_LENGTH
  ;-----------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FNAME_SHORT, YEAR_START, YEAR_LENGTH)
  DOY = STRMID(FNAME_SHORT, DOY_START, DOY_LENGTH)
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY, YYY), MONTH, DAY
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MONTH, DAY, YYY)
  ;-----------------------------------
  ; RETURN VALUES:
  RETURN, DMY
END
;***********************************************************************************************
;***********************************************************************************************
FUNCTION EXTRACT_MODIS, INPUT
  ;-----------------------------------
  ; EXTRACT FILES (SURFACE REFLECTANCE)
  RED = INPUT[WHERE(STRMATCH(INPUT, '*b01*') EQ 1)]
  NIR = INPUT[WHERE(STRMATCH(INPUT, '*b02*') EQ 1)]
  BLUE = INPUT[WHERE(STRMATCH(INPUT, '*b03*') EQ 1)]
  GREEN = INPUT[WHERE(STRMATCH(INPUT, '*b04*') EQ 1)]    
  MIR1 = INPUT[WHERE(STRMATCH(INPUT, '*b05*') EQ 1)]  
  MIR2 = INPUT[WHERE(STRMATCH(INPUT, '*b06*') EQ 1)]
  MIR3 = INPUT[WHERE(STRMATCH(INPUT, '*b07*') EQ 1)]
  ; EXTRACT FILES (QUALITY STATE) 
  STATE = INPUT[WHERE(STRMATCH(INPUT, '*state*') EQ 1)]
  ;-----------------------------------
  ; RETURN VALUES:
  RETURN, [RED, NIR, BLUE, GREEN, MIR1, MIR2, MIR3, STATE]
  ;RETURN, [RED, NIR]
END
;***********************************************************************************************






PRO MODIS_Time_Series_DOIT_Temporal_Raster_Resample
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_Time_Series_DOIT_Temporal_Raster_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  PATH = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics'
  TITLE='SELECT THE INPUT DATA'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  ;-----------------------------------
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
  ; ERROR CHECK
  IF IN_FILES[0] EQ '' THEN RETURN
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  ;-----------------------------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(DIALOG_PARENT=BASE, PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  TITLE ='SELECT NODATA STATUS'
  NAN_STATUS = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF NAN_STATUS EQ 0 THEN BEGIN
    TITLE = 'SET THE NODATA VALUE (SURFACE REFLECTANCE)  '
    DEFAULT_VALUE = -28672
    NAN_VALUE = ENTER_VALUE_WIDGET(TITLE, DEFAULT_VALUE)
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE TEMPORAL RESAMPLE TYPE
  VALUES = ['RESAMPLE DAILY TO 8 DAY', 'RESAMPLE DAILY TO 16 DAY']
  TITLE = 'SELECT THE RESAMPLE TYPE'
  RESAMPLE_TYPE = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD  
  VALUES = ['MEAN OF PERIOD', 'MEDIAN OF PERIOD', 'MINIMUM OF PERIOD', 'MAXIMUM OF PERIOD']
  TITLE = 'SELECT THE RESAMPLE METHOD'
  RESAMPLE_METHOD = RADIO_BUTTON_WIDGET(TITLE, VALUES)  
  ; SET STRING 'METHOD' FOR OUTPUT NAME
  IF RESAMPLE_METHOD EQ 0 THEN METHOD = 'MEAN'
  IF RESAMPLE_METHOD EQ 1 THEN METHOD = 'MEDIAN'
  IF RESAMPLE_METHOD EQ 2 THEN METHOD = 'MINIMUM'
  IF RESAMPLE_METHOD EQ 3 THEN METHOD = 'MAXIMUM'      
  ;---------------------------------------------------------------------------------------------  
  ; SET THE SEGMENT VALUE
  TITLE = 'SET THE SEGMENT VALUE: 0.00 - 1.00  '
  DEFAULT_VALUE = 0.1000
  SEGMENT = ENTER_VALUE_WIDGET(TITLE, DEFAULT_VALUE)
  ; ERROR CHECK
  IF (SEGMENT LT 0.0) OR (SEGMENT GT 1.0) THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ENTER A VALUE BETWEEN 0.00 AND 1.00'
    RETURN
  ENDIF
  ;---------------------------------------------------------------------------------------------   
  ; GET DATES:
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT
  ;-----------------------------------
  ; SET EXTENSION LENGTH (i.e. '.img' is 4 characters long) 
  EXTENSION_LENGTH = 4
  ; GET FNAME_SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-EXTENSION_LENGTH
  FNAME_SHORT = STRARR(N_ELEMENTS(IN_FILES))
  FOR f=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    FNAME_SHORT[f] = STRMID(IN_FILES[f], FNAME_START[f], FNAME_LENGTH[f])   
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; CALL THE GET_FNAME_DATE FUNCTION
  ;-----------------------------------
  ; METHOD 1: DDMMYYYY
  ;YEAR_START = 9
  ;YEAR_LENGTH = 4  
  ;MONTH_START = 4
  ;MONTH_LENGTH = 2  
  ;DAY_START = 6
  ;DAY_LENGTH = 2
  ;DMY = GET_FNAME_DATE_DMY(FNAME_SHORT, YEAR_START, YEAR_LENGTH, MONTH_START, MONTH_LENGTH, DAY_START, DAY_LENGTH)
  ;-----------------------------------
  ; METHOD 2: YYYYDOY
  YEAR_START = 9
  YEAR_LENGTH = 4  
  DOY_START = 13
  DOY_LENGTH = 3
  DMY = GET_FNAME_DATE_YDOY(FNAME_SHORT, YEAR_START, YEAR_LENGTH, DOY_START, DOY_LENGTH)  
  ;---------------------------------------------------------------------------------------------
  ; SET DATE LOOP PARAMETERS:
  DSTART = JULDAY(1, 1, 2004) ; (M,D,YYYY)
  IF RESAMPLE_TYPE EQ 0 THEN DLENGTH = 8
  IF RESAMPLE_TYPE EQ 1 THEN DLENGTH = 16 
  DSTOP = JULDAY(1, 8, 2005) ; (M,D,YYYY)
  ;---------------------------------------------------------------------------------------------
  ; DATE LOOP:
  ;---------------------------------------------------------------------------------------------  
  WHILE (DEND = DSTART + DLENGTH) LE DSTOP DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    D_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ; CONVERT JULDAY TO CALDAY    
    CALDAT, DSTART, SM, SD, SY
    CALDAT, DEND-1, EM, ED, EY
    ;--------------------------------------
    ; TESTING: PRINT INFORMATION
    ;PRINT, 'START: ', JULDAY(SM, SD, SY) - JULDAY(1, 0, SY)
    ;PRINT, 'END: ', JULDAY(EM, ED, EY) - JULDAY(1, 0, EY)
    ;PRINT, ''
    ;-------------------------------------------------------------------------------------------
    ; GET DAY OF YEAR AND JULIAN DATE 
    SDOY = JULDAY(SM, SD, SY) - JULDAY(1, 0, SY)   
    ;-------------------------------------------------------------------------------------------
    ; GET FILES THAT FALL WITHIN THE DATE PERIOD
    INDEX = WHERE(((DMY GE DSTART) AND (DMY LT DEND)), COUNT)
    ;--------------------------------------
    ; UPDATE START DATE 
    DSTART = DEND    
    ;--------------------------------------
    ; FILE CHECK: IF THERE ARE NO FILES IN THE CURRENT PERIOD CONTUNUE TO THE NEXT PERIOD 
    IF COUNT EQ 0 THEN CONTINUE
    ;-------------------------------------------------------------------------------------------    
    ; GET FILES IN DATE RANGE:
    ;--------------------------------------
    ; GET FILES
    FILES_IN = IN_FILES[INDEX]
    ; EXTRACT FILES: CALL FUNCTION EXTRACT_MODIS
    X_BANDS = EXTRACT_MODIS(FILES_IN)
    ;--------------------------------------
    ; SET CONSTANT COUNT_B: NUMBER OF FILES PER DATE
    COUNT_B = (N_ELEMENTS(X_BANDS)/8)
    ;COUNT_B = (N_ELEMENTS(X_BANDS)/2)
    ; SET FILES BY BAND
    X_RED = X_BANDS[0:(COUNT_B-1)]
    X_NIR = X_BANDS[COUNT_B:(COUNT_B*2)-1]
    X_BLUE = X_BANDS[(COUNT_B*2):(COUNT_B*3)-1] 
    X_GREEN = X_BANDS[(COUNT_B*3):(COUNT_B*4)-1]    
    X_MIR1 = X_BANDS[(COUNT_B*4):(COUNT_B*5)-1]    
    X_MIR2 = X_BANDS[(COUNT_B*5):(COUNT_B*6)-1]
    X_MIR3 = X_BANDS[(COUNT_B*6):(COUNT_B*7)-1]
    X_STATE = X_BANDS[(COUNT_B*7):(COUNT_B*8)-1]
    ;-------------------------------------------------------------------------------------------
    ; BAND LOOP:
    ;-------------------------------------------------------------------------------------------
    SEVEN = 7
    ;TWO = 2
    FOR b=0, SEVEN-1 DO BEGIN ; b
      ;-----------------------------------------------------------------------------------------
      ; SET INPUT
      IF b EQ 0 THEN INPUT = X_RED & IF b EQ 0 THEN BNAME = 'RED'
      IF b EQ 1 THEN INPUT = X_NIR & IF b EQ 1 THEN BNAME = 'NIR'
      IF b EQ 2 THEN INPUT = X_BLUE & IF b EQ 2 THEN BNAME = 'BLUE'
      IF b EQ 3 THEN INPUT = X_GREEN & IF b EQ 3 THEN BNAME = 'GREEN'
      IF b EQ 4 THEN INPUT = X_MIR1 & IF b EQ 4 THEN BNAME = 'MIR1'
      IF b EQ 5 THEN INPUT = X_MIR2 & IF b EQ 5 THEN BNAME = 'MIR2'
      IF b EQ 6 THEN INPUT = X_MIR3 & IF b EQ 6 THEN BNAME = 'MIR3'      
      STATE = X_STATE
      ;-----------------------------------------------------------------------------------------
      ; BUILD OUTPUT FILENAME:
      ;-----------------------------------
      ; ZERO CHECK
      IF b EQ 0 THEN BEGIN
        IF SDOY LE 9 THEN SDOY = '00' + STRING(STRTRIM(SDOY,2))
        IF (SDOY LE 99) AND (SDOY GT 9) THEN SDOY = '0' + STRING(STRTRIM(SDOY,2))
        IF SD LE 9 THEN SD = (STRING(0) + STRING(STRTRIM(SD, 2)))
        IF SM LE 9 THEN SM = (STRING(0) + STRING(STRTRIM(SM, 2)))
        IF ED LE 9 THEN ED = (STRING(0) + STRING(STRTRIM(ED, 2)))
        IF EM LE 9 THEN EM = (STRING(0) + STRING(STRTRIM(EM, 2)))
      ENDIF
      ;-----------------------------------
      ; BUILD NAME
      OUT_FNAME_DATE = STRTRIM(SY, 2) + STRTRIM(SDOY, 2) 
      ; GET FILENAME
      NAME_START = STRPOS(INPUT[0], '\', /REVERSE_SEARCH)+1
      NAME_LENGTH = (STRLEN(INPUT[0])-NAME_START)-EXTENSION_LENGTH
      NAME_SHORT = STRMID(INPUT[0], NAME_START, NAME_LENGTH)
      ; GET PREFIX
      IF b EQ 0 THEN PREFIX = STRMID(NAME_SHORT, 0, 7)
      ; GET SUFFIX
      SUFFIX_START = STRPOS(NAME_SHORT, '.', /REVERSE_SEARCH)+1
      SUFFIX_LENGTH = (STRLEN(NAME_SHORT)-SUFFIX_START)
      SUFFIX = STRMID(NAME_SHORT, SUFFIX_START, SUFFIX_LENGTH)
      ; SET OUTPUT FILENAME AND PATH
      OUT_FNAME = OUT_DIRECTORY + PREFIX + '.' + STRTRIM(DLENGTH, $
        2) + 'DAY.' + METHOD + '.' + OUT_FNAME_DATE + '.' + SUFFIX + '.img'
      ;-----------------------------------
      ; CREATE THE OUTPUT FILE
      OPENW, UNIT_OUT, OUT_FNAME, /GET_LUN
      ; CLOSE THE NEW OUTPUT FILE
      FREE_LUN, UNIT_OUT
      ;-----------------------------------------------------------------------------------------
      ; SEGMENT IMAGE:
      ;-----------------------------------      
      IF b EQ 0 THEN BEGIN
        ; OPEN THE FIRST INPUT FILE
        IN_EXAMPLE = READ_BINARY(INPUT[0], DATA_TYPE=2)
        ; GET THE NUMBER OF ELEMENTS
        IN_ELEMENTS = N_ELEMENTS(IN_EXAMPLE)-1
        ; CALL THE SEGMENT FUNCTION
        RESULT = SEGMENT_FUNCTION(IN_ELEMENTS, SEGMENT) 
        ; SET RESULTS
        SEGMENT = RESULT[0]
        COUNT_S = RESULT[1]
        SEGMENT_START = RESULT[2] 
        SEGMENT_END = RESULT[3]
        SEGMENT_LENGTH = RESULT[4]
      ENDIF
      ;-----------------------------------------------------------------------------------------
      ; PRINT INFORMATION
      PRINT,  ''
      PRINT, ' PROCESSING -', BNAME, '- FILES: ', STRTRIM(SD, 2), '/', STRTRIM(SM, 2), '/', STRTRIM(SY, 2), $
        ' TO ', STRTRIM(ED, 2), '/', STRTRIM(EM, 2), '/', STRTRIM(EY, 2)
      PRINT,  ''        
      ;-----------------------------------------------------------------------------------------
      ; SEGMENT LOOP:
      ;-----------------------------------------------------------------------------------------
      ; RESET SEGMENT PARAMETERS
      SEGMENT_END_L = SEGMENT_END
      SEGMENT_START_L = SEGMENT_START 
      ;-----------------------------------------------------------------------------------------
      FOR s=0, COUNT_S-1 DO BEGIN ; s
        ;---------------------------------------------------------------------------------------
        ; GET START TIME: SEGMENT LOOP
        L_TIME = SYSTIME(1)
        ;---------------------------------------------------------------------------------------
        ; UPDATE THE SEGMENT PARAMETERS
        IF s GE 1 THEN BEGIN
          ; UPDATE SEGMENT START-POSITION
          IF s EQ 1 THEN SEGMENT_START_L = LONG(SEGMENT_START_L + SEGMENT_LENGTH)+1
          IF s GT 1 THEN SEGMENT_START_L = LONG(SEGMENT_START_L + SEGMENT_LENGTH)
          ;-----------------------------------
          ; UPDATE SEGMENT END-POSITION
          SEGMENT_END_L = LONG((s+1)*SEGMENT_LENGTH)
        ENDIF
        ;-----------------------------------
        ; IN THE FINAL LOOP FIX THE END-POSITION: WHERE SEGMENT LENGTH IS NOT INTEGER
        IF s EQ COUNT_S-1 THEN BEGIN
          ; UPDATE SEGMENT END-POSITION
          SEGMENT_END_L = LONG((IN_ELEMENTS - SEGMENT_START_L) + SEGMENT_START_L)
        ENDIF
        ;-----------------------------------
        ; GET CURRENT SEGMENT SIZE
        SEGMENT_SIZE = LONG(SEGMENT_END_L - SEGMENT_START_L)+1
        ;---------------------------------------------------------------------------------------
        ; CREATE AN ARRAY TO HOLD THE GRID DATA
        MATRIX_X = MAKE_ARRAY(N_ELEMENTS(INPUT), SEGMENT_SIZE, /FLOAT)
        ;---------------------------------------------------------------------------------------
        ; FILE LOOP:
        ;---------------------------------------------------------------------------------------
        FOR i=0, N_ELEMENTS(INPUT)-1 DO BEGIN ; i
          ;-------------------------------------------------------------------------------------
          ; GET INPUT DATA:
          ;-----------------------------------
          ; OPEN THE ith FILES
          FILE_IN = READ_BINARY(INPUT[i], DATA_TYPE=2)
          STATE_IN = READ_BINARY(STATE[i], DATA_TYPE=12)
          ;-----------------------------------
          ; GET DATA SEGMENTS
          IN_DATA = FILE_IN(SEGMENT_START_L:SEGMENT_END_L)
          IN_DATA_STATE = STATE_IN(SEGMENT_START_L:SEGMENT_END_L)
          ;-----------------------------------
          ; APPLY MODIS CLOUD MASK:
          ;-----------------------------------
          ; USE BITWISE OPERATORS TO "MASK-OUT" CLOUD PIXELS 
          ; -  SEE 'NOTES' IN THE HEADER FOR MORE INFORMATION  
          MASK_OK = ((IN_DATA_STATE AND 1) EQ 0)
          ; APPLY MASK TO 'IN_DATA'
          ; -  WHERE THE CELL IS CLEAR (MASK_OK = 1) MULTIPLY OWL_OUT BY 1
          ; -  WHERE THE CELL IS NOT CLEAR (MASK_OK = 0) REPLACE OWL_OUT BY THE USER SELECTED (NAN)
          IF NAN_STATUS EQ 0 THEN BEGIN
            IN_DATA = IN_DATA * (MASK_OK EQ 1) + NAN_VALUE * (MASK_OK EQ 0)
          ENDIF ELSE IN_DATA = IN_DATA * (MASK_OK EQ 1) + 255 * (MASK_OK EQ 0)
          ;-----------------------------------     
          ; FILL MATRIX_X
          MATRIX_X[i,*] = IN_DATA  
          ;-------------------------------------------------------------------------------------
        ENDFOR ; i
        ;---------------------------------------------------------------------------------------
        ; CALCULATE COMPOSITE VALUES:
        ;---------------------------------------------------------------------------------------  
        ; SET NAN:
        ;-----------------------------------
        IF NAN_STATUS EQ 0 THEN BEGIN
          k = WHERE(MATRIX_X EQ FLOAT(NAN_VALUE), COUNT_k)
          IF (COUNT_k GT 0) THEN MATRIX_X[k] = !VALUES.F_NAN
        ENDIF
        ;---------------------------------------------------------------------------------------      
        ; GET COMPOSITE DATA:
        ;-----------------------------------
        IF N_ELEMENTS(INPUT) GE 2 THEN BEGIN
          ; GET MEAN
          IF RESAMPLE_METHOD EQ 0 THEN OUT_DATA = (TRANSPOSE(TOTAL(MATRIX_X, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_X), 1)))
          ; GET MEDIAN
          IF RESAMPLE_METHOD EQ 1 THEN OUT_DATA = MEDIAN(MATRIX_X, DIMENSION=1, /EVEN) 
          ; GET MINIMUM
          IF RESAMPLE_METHOD EQ 2 THEN OUT_DATA = MIN(MATRIX_X, DIMENSION=1, /NAN)
          ; GET MAXIMUM
          IF RESAMPLE_METHOD EQ 3 THEN OUT_DATA = MAX(MATRIX_X, DIMENSION=1, /NAN)
        ENDIF ELSE BEGIN
          ; GET OUTDATA
          OUT_DATA = MATRIX_X
        ENDELSE
        ;---------------------------------------------------------------------------------------
        ; APPEND DATA:
        ;---------------------------------------------------------------------------------------
        ; OPEN THE OUTPUT FILE
        OPENU, UNIT_OUT, OUT_FNAME, /APPEND, /GET_LUN
        ;-----------------------------------
        ; APPEND DATA TO THE OUTPUT FILE
        WRITEU, UNIT_OUT, OUT_DATA
        ;-----------------------------------
        ; CLOSE THE OUTPUT FILE
        FREE_LUN, UNIT_OUT
        ;---------------------------------------------------------------------------------------
        ; GET END TIME
        SECONDS = (SYSTIME(1)-L_TIME)
        ; PRINT LOOP INFORMATION      
        PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', $
          STRTRIM(s+1, 2), ' OF ', STRTRIM(FIX(COUNT_S), 2)
        ;---------------------------------------------------------------------------------------
      ENDFOR ; s
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; b
    ;-------------------------------------------------------------------------------------------
    ; GET END TIME
    MINUTES = (SYSTIME(1)-D_TIME)/60
    ; PRINT LOOP INFORMATION
    PRINT,''
    PRINT,'  PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR FILES ', STRTRIM(SD, 2), '/', $
      STRTRIM(SM, 2), '/', STRTRIM(SY, 2), ' TO ', STRTRIM(ED, 2), '/', STRTRIM(EM, 2), '/', STRTRIM(EY, 2)
    ;-------------------------------------------------------------------------------------------
  ENDWHILE
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: MODIS_Time_Series_DOIT_Temporal_Raster_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END