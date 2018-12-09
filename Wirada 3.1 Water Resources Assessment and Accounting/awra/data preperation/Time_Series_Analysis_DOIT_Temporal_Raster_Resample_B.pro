; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_B.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 23/02/2010
; DLM: 25/02/2010
; 
; DESCRIPTION: This tool alters the temporal proportions of a raster data set 
;              by combining multiple files into new merged (or composite) files. 
;              That is to say, the mean, median, minimum or maximum of the input 
;              files (by-cell) is calculated and returned as a single new output. 
;              In this instance daily files are resampled to monthly composites. 
;              Where 'monthy' includes all input files of a given month and year (
;              January-December).
;              
; INPUT:       Multiple single-band files.
; 
; OUTPUT:      One new file per input period (per-month).
; 
; PARAMETERS:  Via widgets.  
;      
;              'SELECT THE INPUT FILES' 
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE RESAMPLE METHOD'
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE RESIZE VALUE (0.0 - 1.0)'
;              
; NOTES:       The input data must have identical dimensions. The input data
;              must have date (YYYY, MM AND DD) inculded in the file name (see 
;              lines 163 & 187 for the code that extracts date from file name).
;                    
; ##########################################################################
; 
PRO Time_Series_Analysis_DOIT_Temporal_Raster_Resample_B
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_B'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT TIME-SERIES
  INPUT = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_runs\v05.07.01.2010\output', TITLE='SELECT THE INPUT TIME-SERIES', FILTER='*.img', $
    /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
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
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Modelled', TITLE='SELECT THE OUTPUT DIRECTORY', $
    /DIRECTORY, /OVERWRITE_PROMPT)
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
  ; MANIPULATE FILE NAMES TO GET YEAR                           ** DEFINE **
  YYY = STRMID(FNAME_SHORT, 0, 4)
  ;-------------------------------------------------------------------------
  ; SETUP DATE PERIODS: YEAR
  ;-------------------------------------------------------------------------
  ; GET UNIQUE YEARS
  UYYY = YYY[UNIQ(YYY)]
  ; GET COUNT OF UNIQUE YEARS
  COUNT_Y = N_ELEMENTS(UYYY)
  ;*************************************************************************
  ; YEAR LOOP
  ;*************************************************************************
  FOR y=0, COUNT_Y-1 DO BEGIN ; START 'FOR y'
    ;-----------------------------------------------------------------------
    ; GET CURRENT UNIQUE YEAR INDEX
    YEAR_INDEX = WHERE(YYY EQ UYYY[y], COUNT)
    ; GET FILE LIST FOR THE CURRENT YEAR
    IN_YFILES = INPUT[YEAR_INDEX]
    ;-----------------------------------------------------------------------
    ; MANIPULATE FILENAME TO GET FILENAME SHORT 
    FNAME_START = STRPOS(IN_YFILES, '\', /REVERSE_SEARCH)+1
    FNAME_LENGTH = (STRLEN(IN_YFILES)-FNAME_START)-4
    FNAME_SHORT = STRMID(IN_YFILES, FNAME_START[0], FNAME_LENGTH[0])
    ;-----------------------------------------------------------------------
    ; MANIPULATE FILE NAMES TO GET MONTH                          ** DEFINE **
    MMM = STRMID(FNAME_SHORT, 4, 2)
    ;-----------------------------------------------------------------------
    ; SETUP DATE PERIODS: MONTH
    ;-----------------------------------------------------------------------
    ; GET UNIQUE MONTHS
    UMMM = MMM[UNIQ(MMM)]
    ; GET COUNT OF UNIQUE MONTHS
    COUNT_M = N_ELEMENTS(UMMM)
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; MONTH LOOP
    ;***********************************************************************
    FOR m=0, COUNT_M-1 DO BEGIN ; START 'FOR m'
      ;---------------------------------------------------------------------
      ; GET START TIME: DATE LOOP
      D_TIME = SYSTIME(1)
      ;---------------------------------------------------------------------
      ; GET CURRENT UNIQUE YEAR MONTH
      MONTH_INDEX = WHERE(MMM EQ UMMM[m], COUNT)
      ; GET FILE LIST FOR THE CURRENT MONTH (AND YEAR)
      IN_MFILES = IN_YFILES[MONTH_INDEX]
      ;---------------------------------------------------------------------
      ; SET FILE COUNT
      COUNT_MF = N_ELEMENTS(IN_MFILES)
      ;---------------------------------------------------------------------
      ; BUILD OUTPUT FILE NAME:
      ;---------------------------------------------------------------------
      ; GET DAY OF YEAR AND JULIAN DATE 
      SDOY = JULDAY(UMMM[m], 1, UYYY[y]) - JULDAY(1, 0, UYYY[y])
      ;---------------------------------------------------------------------
      ; SET VARIABLE MONTH_C 
      MONTH_C = UMMM[m]
      ;---------------------------------------------------------------------
      ; BUILD NEW NAME
      OUT_NAME = STRTRIM(UYYY[y], 2) + STRTRIM(MONTH_C, 2) + '.img'
      ; SET OUTPUT FILE NAME AND PATH
      OUT_FILE = OUTFOLDER + OUT_NAME
      ;---------------------------------------------------------------------
      ; CREATE THE OUTPUT FILE
      OPENW, UNIT_OUT, OUT_FILE, /GET_LUN
      ; CLOSE THE NEW OUTPUT FILE
      FREE_LUN, UNIT_OUT
      ;---------------------------------------------------------------------
      ; PRINT INFORMATION
      PRINT, '  FILES: ', 'XX/', STRTRIM(MONTH_C, 2), '/', STRTRIM(UYYY[y], 2)
      PRINT,''
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; SEGMENT LOOP:
      ;*********************************************************************
      ; RESET SEGMENT PARAMETERS
      SEGMENT_END_L = SEGMENT_END
      SEGMENT_START_L = SEGMENT_START  
      ;---------------------------------------------------------------------      
      FOR s=0, COUNT_S-1 DO BEGIN ; START 'FOR s'
        ;-------------------------------------------------------------------
        ; GET START TIME: SEGMENT LOOP
        L_TIME = SYSTIME(1)
        ;-------------------------------------------------------------------
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
        ;-------------------------------------------------------------------
        ; CREATE THE DATA ARRAY
        MATRIX_S = MAKE_ARRAY(COUNT_MF, SEGMENT_SIZE, /FLOAT)
        ;-------------------------------------------------------------------
        ;*******************************************************************
        ; FILE LOOP: 
        ;*******************************************************************
        FOR i=0, COUNT_MF-1 DO BEGIN ; START 'FOR b'
          ;-----------------------------------------------------------------
          ; GET INPUT DATA (CURRENT FILE):
          ;-----------------------------------------------------------------
          ; OPEN THE ith FILE
          MFILE_IN = READ_BINARY(IN_MFILES[i], DATA_TYPE=DATATYPE)
          ;-----------------------------------------------------------------
          ; GET DATA SEGMENT
          IN_DATA = MFILE_IN(SEGMENT_START_L:SEGMENT_END_L)
          ;-----------------------------------------------------------------
          ; FILL THE 2D ARRAY
          MATRIX_S[i,*] = IN_DATA
          ;-----------------------------------------------------------------
        ENDFOR
        ;-------------------------------------------------------------------
        ;*******************************************************************
        ; CALCULATE STATISTICS
        ;*******************************************************************
        ;-------------------------------------------------------------------
        ; SET NAN
        IF STATUS EQ 0 THEN BEGIN
          k = WHERE(MATRIX_S EQ FLOAT(NODATA), COUNT_k)
          IF (COUNT_k GT 0) THEN MATRIX_S[k] = !VALUES.F_NAN
        ENDIF     
        ;-------------------------------------------------------------------  
        ; GET STATISTIC:
        ;------------------------------------------------------------------- 
        IF COUNT_MF GE 2 THEN BEGIN
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
        ;-------------------------------------------------------------------
        ;*******************************************************************
        ; APPEND DATA:
        ;*******************************************************************
        ;-------------------------------------------------------------------
        ; OPEN THE OUTPUT FILE
        OPENU, UNIT_OUT, OUT_FILE, /APPEND, /GET_LUN
        ;-------------------------------------------------------------------
        ; APPEND DATA TO THE OUTPUT FILE
        WRITEU, UNIT_OUT, OUTDATA
        ;-------------------------------------------------------------------
        ; CLOSE THE OUTPUT FILE
        FREE_LUN, UNIT_OUT 
        ;-------------------------------------------------------------------
        ; GET END TIME
        SECONDS = (SYSTIME(1)-L_TIME)
        ; PRINT LOOP INFORMATION
        PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', $
          STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
        ;-------------------------------------------------------------------
      ENDFOR ; END 'FOR s'
      ;---------------------------------------------------------------------
      ; GET END TIME
      MINUTES = (SYSTIME(1)-D_TIME)/60
      ; PRINT LOOP INFORMATION
      PRINT,''
      PRINT,'  PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR FILE ', OUT_NAME
      PRINT,''
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR m'
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR y
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Temporal_Raster_Resample_B'
  PRINT,''
  ;-------------------------------------------------------------------------
END
