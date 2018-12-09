; ##########################################################################
; NAME: Time_Series_Analysis_GET_Regression_Coefficents.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 05/02/2010
; DLM: 11/03/2010
;
; DESCRIPTION: This tool calculates the regression coefficients (slope and
;              intercept) of the regression line, which defines the relationship
;              between the two input variables, in this instance, the dependent
;              time-series Y and the independent time-series X. Data is
;              calculated on a cell-by-cell basis.
;
; INPUT:       The dependent time-series (Y) and the independent time-series
;              (X).
;
; OUTPUT:      The slope and the y-intercept of the regression line.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              'SELECT THE DEPENDENT TIME-SERIES (Y)'
;              'SELECT THE INDEPENDENT TIME-SERIES (X)'
;              'DEFINE THE OUTPUT FILE: SLOPE'
;              'DEFINE THE OUTPUT FILE: Y INTERCEPT'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE RESIZE VALUE (0.0 - 1.0)'
;
; NOTES:       The input data must have identical sample, line and band
;              numbers. The input data should have identical cell size,
;              projection and coordinate system, and extents.
;
; ##########################################################################
;
PRO Time_Series_Analysis_GET_Regression_Coefficents
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_GET_Regression_Coefficents'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE RESPONSE TIME-SERIES 'OBSERVED'
  IN_Y = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed', $
    TITLE='SELECT THE DEPENDENT TIME-SERIES (Y)', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;---------------------------------------------------------------------
  ; SORT FILE LIST
  IN_Y = IN_Y[SORT(IN_Y)]
  ;---------------------------------------------------------------------
  ; SELECT THE PREDICTOR TIME-SERIES 'MODELLED'
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Modelled', $
    TITLE='SELECT THE INDEPENDENT TIME-SERIES (X)', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;---------------------------------------------------------------------
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;---------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILE: SLOPE
  OUT_SLOPE = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Statistics\Bivariate', $
    TITLE='DEFINE THE OUTPUT FILE: SLOPE', /OVERWRITE_PROMPT)
  ;---------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILE: Y INTERCEPT
  OUT_INTERCEPT = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Statistics\Bivariate', $
    TITLE='DEFINE THE OUTPUT FILE: Y INTERCEPT', /OVERWRITE_PROMPT)
  ;---------------------------------------------------------------------
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
  ; CREATE THE EMPTY OUTPUT FILES: SLOPE AND Y INTERCEPT
  ;-------------------------------------------------------------------------
  ; CREATE THE FILES
  OPENW, UNIT_SLOPE, OUT_SLOPE, /GET_LUN
  OPENW, UNIT_INTERCEPT, OUT_INTERCEPT, /GET_LUN
  ;-------------------------------------------------------------------------
  ; CLOSE THE NEW FILES
  FREE_LUN, UNIT_SLOPE
  FREE_LUN, UNIT_INTERCEPT
  ;-------------------------------------------------------------------------
  ; GET BAND INFORMATION:
  ;-------------------------------------------------------------------------
  ; SET BAND COUNT
  COUNT_B = N_ELEMENTS(IN_Y)
  COUNT_B2 = N_ELEMENTS(IN_X)
  ; ERROR CHECK
  IF COUNT_B NE COUNT_B2 THEN BEGIN
    PRINT, 'THE SELECTED OBSERVED AND MODELLED TIME-SERIES MUST HAVE AN IDENTICAL BAND COUNT'
    RETURN
  ENDIF
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; RESIZE IMAGE:
  ;*************************************************************************
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
  IN_EXAMPLE = READ_BINARY(IN_Y[0], DATA_TYPE=DATATYPE)
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
  PRINT,'BAND COUNT: ', STRTRIM(COUNT_B, 2)
  PRINT,'ELEMENT COUNT, PER-FILE: ', STRTRIM(IN_ELEMENTS, 2)
  PRINT,'SEGMENT COUNT: ', STRTRIM(COUNT_S, 2)
  PRINT,'STANDARD SEGMENT SIZE: ', STRTRIM(SEGMENT_LENGTH, 2)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; SEGMENT LOOP:
  ;*************************************************************************
  FOR s=0, COUNT_S-1 DO BEGIN ; START 'FOR s'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; UPDATE SEGMENT PARAMETERS
    IF s GE 1 THEN BEGIN
      ; UPDATE SEGMENT START-POSITION
      IF s EQ 1 THEN SEGMENT_START = LONG(SEGMENT_START + SEGMENT_LENGTH)+1
      IF s GT 1 THEN SEGMENT_START = LONG(SEGMENT_START + SEGMENT_LENGTH)
      ; UPDATE SEGMENT END-POSITION
      SEGMENT_END = LONG((s+1)*SEGMENT_LENGTH)
    ENDIF
    ; IN THE FINAL LOOP FIX THE END-POSITION, THAT IS, WHERE SEGMENT LENGTH IS NOT INTEGER
    IF s EQ COUNT_S-1 THEN BEGIN
      ; UPDATE SEGMENT END-POSITION
      SEGMENT_END = LONG((IN_ELEMENTS - SEGMENT_START) + SEGMENT_START)
    ENDIF
    ; GET CURRENT SEGMENT SIZE
    SEGMENT_SIZE = LONG(SEGMENT_END - SEGMENT_START)+1
    ;-----------------------------------------------------------------------
    ; CREATE THE EMPTY 2D DATA ARRAYS
    MATRIX_Y = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    MATRIX_X = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    CP = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    XD = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    ;-----------------------------------------------------------------------
    ; PRINT INFORMATION
    PRINT,''
    PRINT,'  SEGMENT: ', STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
    PRINT,'  CURRENT SEGMENT SIZE: ', STRTRIM(SEGMENT_SIZE, 2)
    PRINT,'  CURRENT SEGMENT STARTING POSITION: ', STRTRIM(SEGMENT_START, 2)
    PRINT,'  CURRENT SEGMENT ENDING POSITION: ', STRTRIM(SEGMENT_END, 2)
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; BAND LOOP: FILL THE 2D ARRAYS
    ;***********************************************************************
    FOR b=0, COUNT_B-1 DO BEGIN ; START 'FOR b'
      ;---------------------------------------------------------------------
      ; GET INPUT DATA (CURRENT BAND):
      ;---------------------------------------------------------------------
      ; OPEN THE ith FILE
      Y_IN = READ_BINARY(IN_Y[b], DATA_TYPE=DATATYPE)
      X_IN = READ_BINARY(IN_X[b], DATA_TYPE=DATATYPE)
      ;---------------------------------------------------------------------
      ; GET DATA SEGMENT
      Y = Y_IN(SEGMENT_START:SEGMENT_END)
      X = X_IN(SEGMENT_START:SEGMENT_END)
      ;---------------------------------------------------------------------
      ; FILL THE 2D ARRAYS
      MATRIX_Y[b,*] = Y
      MATRIX_X[b,*] = X
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ; SET NAN
    IF STATUS EQ 0 THEN BEGIN
      k1 = WHERE(MATRIX_Y EQ FLOAT(NODATA), COUNT_k1)
      IF (COUNT_k1 GT 0) THEN MATRIX_X[k1] = !VALUES.F_NAN
      k2 = WHERE(MATRIX_X EQ FLOAT(NODATA), COUNT_k2)
      IF (COUNT_k2 GT 0) THEN MATRIX_X[k2] = !VALUES.F_NAN
    ENDIF
    ;-----------------------------------------------------------------------
    ; CALCULATE THE MEAN OF Y
    MATRIX_YBAR = (TRANSPOSE(TOTAL(MATRIX_Y, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_Y), 1)))
    ; CALCULATE THE MEAN OF X
    MATRIX_XBAR = (TRANSPOSE(TOTAL(MATRIX_X, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_X), 1)))
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; BAND LOOP: SUMS
    ;***********************************************************************
    FOR b=0, COUNT_B-1 DO BEGIN ; START 'FOR b'
      ;---------------------------------------------------------------------
      ; GET THE CROSS-PRODUCT TERM
      CP += ((TRANSPOSE(TOTAL(MATRIX_X[b,*], 1, /NAN)) - MATRIX_XBAR) * (TRANSPOSE(TOTAL(MATRIX_Y[b,*], 1, /NAN)) - MATRIX_YBAR))
      ; GET THE X DEVIATION
      XD += ((TRANSPOSE(TOTAL(MATRIX_X[b,*], 1, /NAN)) - MATRIX_XBAR)^2)
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; CALCULATE STATISTICS
    ;***********************************************************************
    ; GET THE SLOPE
    SLOPE = CP / XD
    ; GET THE Y INTERCEPT
    INTERCEPT = MATRIX_YBAR - (SLOPE * MATRIX_XBAR)
    ;-----------------------------------------------------------------------
    ; APPEND DATA:
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILES
    OPENU, UNIT_SLOPE, OUT_SLOPE, /APPEND, /GET_LUN
    OPENU, UNIT_INTERCEPT, OUT_INTERCEPT, /APPEND, /GET_LUN
    ;-----------------------------------------------------------------------
    ; APPEND DATA TO THE OUTPUT FILES
    WRITEU, UNIT_SLOPE, SLOPE
    WRITEU, UNIT_INTERCEPT, INTERCEPT
    ;-----------------------------------------------------------------------
    ; CLOSE THE OUTPUT FILES
    FREE_LUN, UNIT_SLOPE
    FREE_LUN, UNIT_INTERCEPT
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SEGMENT ', $
      STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR s'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_GET_Regression_Coefficents'
  PRINT,''
  ;-------------------------------------------------------------------------
END