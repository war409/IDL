; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_A.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 22/02/2010
; DLM: 23/06/2010
; 
; DESCRIPTION: This tool alters the temporal proportions of a raster data set 
;              by combining multiple files into new merged (or composite) files. 
;              That is to say, the mean, median, minimum or maximum of the input 
;              files (by-cell) is calculated and returned as a single new output.  
;              The user can select whether to resample daily files to 8-day or 16-
;              day composites by mean, median, minimum or maximum.     
;              
; INPUT:       Multiple single-band files.
; 
; OUTPUT:      One new file per input period (8-day or 16-day).
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
; NOTES:       The input data must have identical dimensions. The input data
;              must have date (YYYY, MM AND DD) inculded in the file name (see 
;              lines 175 - 177 for the code that extracts date from file name).
;                    
; ##########################################################################
; 
PRO Time_Series_Analysis_DOIT_Temporal_Raster_Resample_A
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_A'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT TIME-SERIES
  INPUT = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water', $
    TITLE='SELECT THE INPUT TIME-SERIES', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  INPUT = INPUT[SORT(INPUT)] 
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(INPUT)
  ; ERROR CHECK
  IF COUNT_F EQ 0 THEN RETURN
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled Open Water', $
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT NODATA STATUS', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  STATUS = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF STATUS EQ 0 THEN BEGIN
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=-999, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA1 = RESULT.VALUE
    NODATA = NODATA1[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;-------------------------------------------------------------------------
  ; SELECT THE TEMPORAL RESAMPLE TYPE
  VALUES = ['RESAMPLE DAILY TO 8 DAY', 'RESAMPLE DAILY TO 16 DAY']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE RESAMPLE TYPE')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  RESAMPLE_TYPE = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD
  VALUES = ['MEAN OF PERIOD', 'MEDIAN OF PERIOD', 'MINIMUM OF PERIOD', 'MAXIMUM OF PERIOD']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE RESAMPLE METHOD')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  RESAMPLE_METHOD = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; RESIZE:
  ;*************************************************************************
  ;-------------------------------------------------------------------------  
  ; GET FILE DIMENSIONS:
  ;-------------------------------------------------------------------------
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
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  DATATYPE = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; OPEN THE FIRST FILE IN THE LIST
  IN_EXAMPLE = READ_BINARY(INPUT[0], DATA_TYPE=DATATYPE)
  ;-------------------------------------------------------------------------  
  ; GET NUMBER OF ELEMENTS
  IN_ELEMENTS = (N_ELEMENTS(IN_EXAMPLE))-1
  ;-------------------------------------------------------------------------
  ; SET THE RESIZE VALUE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=0.1000, TITLE='SET THE RESIZE VALUE (0.0 - 1.0) ', $
    /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESIZE = FLOAT(RESULT.VALUE)
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; ERROR CHECK
  IF (RESIZE LT 0.0) OR (RESIZE GT 1.0) THEN BEGIN
    PRINT, 'THE SELECTED PARAMETER IS NOT VALID: ENTER A VALUE BETWEEN 0.0000 AND 1.0000'
    RETURN
  ENDIF
  ;-------------------------------------------------------------------------
  ; BASED ON THE RESIZE VALUE GET THE SEGMENT LENGTH
  SEGMENT_LENGTH = ROUND((IN_ELEMENTS)*RESIZE)
  ; GET THE COUNT OF SEGMENTS WITHIN THE CURRENT IMAGE
  COUNT_S1 = CEIL((IN_ELEMENTS) / SEGMENT_LENGTH)
  COUNT_S = COUNT_S1[0]
  ; SET THE INITIAL SEGMENT START-POSITION AND END-POSITION
  SEGMENT_START = 0
  SEGMENT_END = SEGMENT_LENGTH
  ;-------------------------------------------------------------------------
  ; PRINT INFORMATION
  IF STATUS EQ 0 THEN PRINT,'NO-DATA VALUE: ', STRTRIM(NODATA, 2)
  PRINT,'DATA TYPE: ', STRTRIM(DATATYPE, 2)
  PRINT,'RE-SIZE VALUE: ', STRTRIM(RESIZE, 2)
  PRINT,'FILE COUNT: ', STRTRIM(COUNT_F, 2)
  PRINT,'ELEMENT COUNT, PER-FILE: ', STRTRIM(IN_ELEMENTS, 2)
  PRINT,'SEGMENT COUNT: ', STRTRIM(COUNT_S, 2)
  PRINT,'STANDARD SEGMENT SIZE: ', STRTRIM(SEGMENT_LENGTH, 2)
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; GET DATES:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT 
  FNAME_START = STRPOS(INPUT, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(INPUT)-FNAME_START)-4
  FNAME_SHORT = STRMID(INPUT, FNAME_START[0], FNAME_LENGTH[0])
  ;-------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           ** DEFINE **
  YYY = STRMID(FNAME_SHORT, 31, 4)
  MMM = STRMID(FNAME_SHORT, 35, 2)
  DDD = STRMID(FNAME_SHORT, 37, 2)
  DMY = JULDAY(MMM, DDD, YYY)
  ;-------------------------------------------------------------------------
  ; SETUP DATE PERIODS:
  ;-------------------------------------------------------------------------
  ; RESAMPLE DAILY TO 8 DAY
  IF RESAMPLE_TYPE EQ 0 THEN BEGIN
    ; SET DATE LOOP VARIABLES: 
    ;   LEAP YEAR: (1, 1, YYYY) TO (1, 3, YYYY+1)
    ;   NON-LEAP YEAR: (1, 1, YYYY) TO (1, 4, YYYY+1)
    S_DATE = JULDAY(1, 1, 2004) ; (M,D,YYYY)
    P_DATE = 8
    E_DATE = JULDAY(1, 4, 2005) ; (M,D,YYYY)
    L_DATE = S_DATE
  ENDIF
  ;-------------------------------------------------------------------------
  ; RESAMPLE DAILY TO 16 DAY
  IF RESAMPLE_TYPE EQ 1 THEN BEGIN
    ; SET DATE LOOP VARIABLES
    ;   LEAP YEAR: (1, 1, YYYY) TO (1, 2, YYYY+1)
    ;   NON-LEAP YEAR: (1, 1, YYYY) TO (1, 3, YYYY+1)
    S_DATE = JULDAY(1, 1, 2008) ; (M,D,YYYY)
    P_DATE = 16
    E_DATE = JULDAY(1, 8, 2009) ; (M,D,YYYY)
    L_DATE = S_DATE
  ENDIF
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; DATE LOOP:
  ;*************************************************************************
  WHILE (L_DATE = L_DATE + P_DATE) LE E_DATE DO BEGIN ; START 'WHILE DATE (8DAY & 16DAY)'
    ;-----------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    D_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; UPDATE DATE PERIOD
    DATE_PERIOD = (L_DATE - P_DATE)
    ;-----------------------------------------------------------------------
    ; GET FILES IN DATE PERIOD
    INDEX = WHERE(((DMY LT L_DATE) AND (DMY GE DATE_PERIOD)), COUNT)
    ; SET FILE COUNT
    COUNT_P = COUNT
    ; FILE CHECK - IF THERE ARE NO FILES IN THE CURRENT PERIOD CONTUNUE TO THE NEXT PERIOD 
    IF COUNT_P EQ 0 THEN CONTINUE
    ; GET FILES IN DATE RANGE
    IN_FILES = INPUT[INDEX]
    ;-----------------------------------------------------------------------
    ; BUILD OUTPUT FILE NAME:
    ;-----------------------------------------------------------------------    
    ; GET PERIOD START AND END DATES   
    OUTNAME_PS = STRTRIM(DATE_PERIOD, 2)
    OUTNAME_PE = STRTRIM((L_DATE-1), 2)
    ; CONVERT JULDAY TO CALDAY
    CALDAT, OUTNAME_PS, MONTH_PS, DAY_PS, YEAR_PS
    CALDAT, OUTNAME_PE, MONTH_PE, DAY_PE, YEAR_PE
    ; GET DAY OF YEAR AND JULIAN DATE 
    SDOY = JULDAY(MONTH_PS, DAY_PS, YEAR_PS) - JULDAY(1, 0, YEAR_PS)
    ;----------------------------------------------------------------------- 
    ; ZERO CHECK 1
    IF SDOY LE 9 THEN SDOY = '00' + STRING(STRTRIM(SDOY,2))
    IF (SDOY LE 99) AND (SDOY GT 9) THEN SDOY = '0' + STRING(STRTRIM(SDOY,2))
    ; ZERO CHECK 2
    IF DAY_PS LE 9 THEN DAY_PS = (STRING(0) + STRING(STRTRIM(DAY_PS, 2)))
    IF MONTH_PS LE 9 THEN MONTH_PS = (STRING(0) + STRING(STRTRIM(MONTH_PS, 2)))
    ; ZERO CHECK 3
    IF DAY_PE LE 9 THEN DAY_PE = (STRING(0) + STRING(STRTRIM(DAY_PE, 2)))
    IF MONTH_PE LE 9 THEN MONTH_PE = (STRING(0) + STRING(STRTRIM(MONTH_PE, 2)))
    ;----------------------------------------------------------------------- 
    ; BUILD NEW NAME
    OUT_NAME = STRTRIM(YEAR_PS, 2) + STRTRIM(SDOY, 2) + '.img'
    ; SET OUTPUT FILE NAME AND PATH
    OUT_FILE = OUTFOLDER + OUT_NAME
    ;----------------------------------------------------------------------- 
    ; CREATE THE OUTPUT FILE
    OPENW, UNIT_OUT, OUT_FILE, /GET_LUN
    ; CLOSE THE NEW OUTPUT FILE
    FREE_LUN, UNIT_OUT
    ;-----------------------------------------------------------------------
    ; PRINT INFORMATION
    PRINT, '  FILES: ', STRTRIM(DAY_PS, 2), STRTRIM(MONTH_PS, 2), STRTRIM(YEAR_PS, 2), $
      ' TO ', STRTRIM(DAY_PE, 2), STRTRIM(MONTH_PE, 2), STRTRIM(YEAR_PE, 2)
    PRINT,''
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; SEGMENT LOOP:
    ;***********************************************************************
    ; RESET SEGMENT PARAMETERS
    SEGMENT_END_L = SEGMENT_END
    SEGMENT_START_L = SEGMENT_START    
    ;-----------------------------------------------------------------------    
    FOR s=0, COUNT_S-1 DO BEGIN ; START 'FOR s'
      ;---------------------------------------------------------------------
      ; GET START TIME: SEGMENT LOOP
      L_TIME = SYSTIME(1)
      ;---------------------------------------------------------------------
      IF s GE 1 THEN BEGIN
        ; UPDATE SEGMENT START-POSITION
        IF s EQ 1 THEN SEGMENT_START_L = LONG(SEGMENT_START_L + SEGMENT_LENGTH)+1
        IF s GT 1 THEN SEGMENT_START_L = LONG(SEGMENT_START_L + SEGMENT_LENGTH)
        ; UPDATE SEGMENT END-POSITION
        SEGMENT_END_L = LONG((s+1)*SEGMENT_LENGTH)
      ENDIF
      ; IN THE FINAL LOOP FIX THE END-POSITION, THAT IS, WHERE SEGMENT LENGTH IS NOT INTEGER
      IF s EQ COUNT_S-1 THEN BEGIN
        ; UPDATE SEGMENT END-POSITION
        SEGMENT_END_L = LONG((IN_ELEMENTS - SEGMENT_START_L) + SEGMENT_START_L)
      ENDIF
      ; GET CURRENT SEGMENT SIZE
      SEGMENT_SIZE = LONG(SEGMENT_END_L - SEGMENT_START_L)+1
      ;---------------------------------------------------------------------
      ; CREATE THE DATA ARRAY
      MATRIX_S = MAKE_ARRAY(COUNT_P, SEGMENT_SIZE, /FLOAT)
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; FILE LOOP: 
      ;*********************************************************************
      FOR i=0, COUNT_P-1 DO BEGIN ; START 'FOR b'
        ;-------------------------------------------------------------------
        ; GET INPUT DATA (CURRENT FILE):
        ;-------------------------------------------------------------------
        ; OPEN THE ith FILE
        FILE_IN = READ_BINARY(IN_FILES[i], DATA_TYPE=DATATYPE)
        ;-------------------------------------------------------------------
        ; GET DATA SEGMENT
        IN_DATA = FILE_IN(SEGMENT_START_L:SEGMENT_END_L)
        ;-------------------------------------------------------------------
        ; FILL THE 2D ARRAY
        MATRIX_S[i,*] = IN_DATA
        ;-------------------------------------------------------------------
      ENDFOR
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; CALCULATE STATISTICS
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; SET NAN
      IF STATUS EQ 0 THEN BEGIN
        k = WHERE(MATRIX_S EQ FLOAT(NODATA), COUNT_k)
        IF (COUNT_k GT 0) THEN MATRIX_S[k] = !VALUES.F_NAN
      ENDIF     
      ;---------------------------------------------------------------------  
      ; GET STATISTIC:
      ;--------------------------------------------------------------------- 
      IF COUNT_P GE 2 THEN BEGIN
        ; GET MEAN
        IF RESAMPLE_METHOD EQ 0 THEN OUTDATA = (TRANSPOSE(TOTAL(MATRIX_S, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_S), 1)))
        ; GET MEDIAN
        IF RESAMPLE_METHOD EQ 1 THEN OUTDATA = MEDIAN(MATRIX_S, DIMENSION=1, /EVEN) 
        ; GET MINIMUM
        IF RESAMPLE_METHOD EQ 2 THEN OUTDATA = MIN(MATRIX_S, DIMENSION=1, /NAN)
        ; GET MAXIMUM
        IF RESAMPLE_METHOD EQ 3 THEN OUTDATA = MAX(MATRIX_S, DIMENSION=1, /NAN)
      ENDIF ELSE BEGIN
        ; GET OUTDATA
        OUTDATA = MATRIX_S
      ENDELSE
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; APPEND DATA:
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, OUT_FILE, /APPEND, /GET_LUN
      ;-----------------------------------------------------------------------
      ; APPEND DATA TO THE OUTPUT FILE
      WRITEU, UNIT_OUT, OUTDATA
      ;-----------------------------------------------------------------------
      ; CLOSE THE OUTPUT FILE
      FREE_LUN, UNIT_OUT 
      ;---------------------------------------------------------------------
      ; GET END TIME
      SECONDS = (SYSTIME(1)-L_TIME)
      ; PRINT LOOP INFORMATION
      PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', $
        STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR s'
    ;-----------------------------------------------------------------------
    ; GET END TIME
    MINUTES = (SYSTIME(1)-D_TIME)/60
    ; PRINT LOOP INFORMATION
    PRINT,''
    PRINT,'  PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR FILE ', OUT_NAME
    PRINT,''
    ;-----------------------------------------------------------------------
  ENDWHILE ; END 'WHILE DATE (8DAY & 16DAY)'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_A'
  PRINT,''
  ;-------------------------------------------------------------------------
END