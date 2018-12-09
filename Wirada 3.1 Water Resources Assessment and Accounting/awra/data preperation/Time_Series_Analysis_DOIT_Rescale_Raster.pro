; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Rescale_Raster.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 09/03/2010
; DLM: 10/03/2010
;
; DESCRIPTION: This tool re-scales the values in the input data by multiplication
;              with the user-selected rescale value. 
;
; INPUT:       Multiple single-band rasters.
;
; OUTPUT:      One rescaled output per input.
;               
; PARAMETERS:  Via ENVI and IDL widgets, set:
; 
;              'SELECT THE INPUT TIME-SERIES'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SET THE RESCALE VALUE'
;              'SELECT NODATA STATUS'
;              'SELECT THE INPUT DATA TYPE'
;
; NOTES:       The input data must have identical dimensions. An interactive 
;              ENVI session is needed to run this tool. The input data must 
;              have an associated ENVI header file.
;
; ##########################################################################
;
PRO Time_Series_Analysis_DOIT_Rescale_Raster
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Rescale_Raster'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT TIME-SERIES
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed', $
    TITLE='SELECT THE INPUT TIME-SERIES', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUT_DIR = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed', $ 
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SET THE RESCALE VALUE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=10, VALUE=0.01, TITLE='SET THE RESCALE VALUE ', $
    /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESCALE_TMP = RESULT.VALUE
  RESCALE = FLOAT(RESCALE_TMP[0])
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------  
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(IN_X)
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
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=255, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA1 = RESULT.VALUE
    NODATA = NODATA1[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
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
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_F-1 DO BEGIN ; START 'FOR i' 
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET INPUT FILE
    INFILE = IN_X[i] 
    ;-----------------------------------------------------------------------   
    ; GET FILENAME AND PATH FROM FULL NAME & PATH
    START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILE)-START)-4
    FNAME = STRMID(INFILE, START, LENGTH)
    INPATH = STRMID(INFILE, 0, START)
    OUTPATH = OUT_DIR
    ;-----------------------------------------------------------------------
    ; BUILD THE OUTPUT FILE NAME
    OUTFILE = OUTPATH + FNAME + '.RESCALE.img'
    ;-----------------------------------------------------------------------
    ; CREATE THE EMPTY OUTPUT FILE
    OPENW, UNIT, OUTFILE, /GET_LUN
    ; CLOSE THE FILE
    FREE_LUN, UNIT
    ;-----------------------------------------------------------------------
    ; GET DATA
    IN_DATA = READ_BINARY(INFILE, DATA_TYPE=DATATYPE)
    ;-----------------------------------------------------------------------  
    ; GET NUMBER OF ELEMENTS
    IN_ELEMENTS = (N_ELEMENTS(IN_DATA))
    ;-----------------------------------------------------------------------
    ; SET NAN
    IF STATUS EQ 0 THEN BEGIN
      ;---------------------------------------------------------------------
      ; DATA TYPE CHECK
      IF DATATYPE LT 4 THEN IN_DATA = FLOAT(IN_DATA)
      ;---------------------------------------------------------------------
      ; SET NAN
      k = WHERE(IN_DATA EQ FLOAT(NODATA), COUNT)
      IF (COUNT GT 0) THEN IN_DATA[k] = !VALUES.F_NAN
      ;---------------------------------------------------------------------
    ENDIF
    ;-----------------------------------------------------------------------
    ; RESCALE DATA
    OUT_DATA = (IN_DATA * RESCALE)
    ;-----------------------------------------------------------------------
    ; WRITE DATA:
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILE
    OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
    ; APPEND DATA TO THE OUTPUT FILE
    WRITEU, UNIT, OUT_DATA
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, UNIT
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', $
      STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_F, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Subset_Extents'
  PRINT,''
  ;-------------------------------------------------------------------------
END  