; ##########################################################################
; NAME: Time_Series_Analysis_GET_Spearman_Rank_Correlation.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 10/02/2010
; DLM: 12/03/2010
;
; DESCRIPTION: This tool calculates the spearman's rank correlation coefficient
;              for the two input variables, in this instance, the modelled
;              time-series (M) and the observed time-series (O). Data is
;              calculated on a cell-by-cell basis.
;
;              In the current example 'model estimates' refers to the AWRA
;              model, developed for WIRADA the AWRA model models the dry
;              land water balance (at 5kn) across Australia. It also
;              simulates properties of land surface and vegetation cover,
;              including but not limited to, leaf area index (LAI), greeness
;              (EVI) and fractional cover. The 'observations' refer to various
;              'direct' measures of the corresponding value for example, mean
;              water level and remotely sensed radiances.
;
; INPUT:       The modelled time-series (M) and the the observed time-series
;              (O).
;
; OUTPUT:      Spearman's rank correlation coefficient.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              'SELECT THE OBSERVED TIME-SERIES (O)'
;              'SELECT THE MODELLED TIME-SERIES (M)'
;              'DEFINE THE OUTPUT FILE: SPEARMANS RANK'
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
PRO Time_Series_Analysis_GET_Spearman_Rank_Correlation
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_GET_Spearman_Rank_Correlation'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE OBSERVED TIME-SERIES
  IN_O = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed', $
    TITLE='SELECT THE OBSERVED TIME-SERIES (O)', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  IN_O = IN_O[SORT(IN_O)]
  ;-------------------------------------------------------------------------
  ; SELECT THE MODELLED TIME-SERIES
  IN_M = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Modelled', $
    TITLE='SELECT THE MODELLED TIME-SERIES (M)', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  IN_M = IN_M[SORT(IN_M)]
  ;-------------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILE: SPEARMANS RANK
  OUTFILE = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Statistics\Bivariate', $
    TITLE='DEFINE THE OUTPUT FILE: SPEARMANS RANK', /OVERWRITE_PROMPT)
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
  ; CREATE THE EMPTY OUTPUT FILE
  OPENW, UNIT, OUTFILE, /GET_LUN
  ; CLOSE THE FILE
  FREE_LUN, UNIT
  ;-------------------------------------------------------------------------
  ; GET BAND INFORMATION:
  ;-------------------------------------------------------------------------
  ; SET BAND COUNT
  COUNT_B = N_ELEMENTS(IN_O)
  COUNT_B2 = N_ELEMENTS(IN_M)
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
  IN_EXAMPLE = READ_BINARY(IN_O[0], DATA_TYPE=DATATYPE)
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
    MATRIX_O = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    MATRIX_M = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    RANK_O = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    RANK_M = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    CP = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    MD = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    OD = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
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
      ; OPEN THE ith FILES
      O_IN = READ_BINARY(IN_O[b], DATA_TYPE=DATATYPE)
      M_IN = READ_BINARY(IN_M[b], DATA_TYPE=DATATYPE)
      ;---------------------------------------------------------------------
      ; GET DATA SEGMENT
      O = O_IN(SEGMENT_START:SEGMENT_END)
      M = M_IN(SEGMENT_START:SEGMENT_END)
      ;---------------------------------------------------------------------
      ; FILL THE 2D ARRAYS
      MATRIX_O[b,*] = O
      MATRIX_M[b,*] = M
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ; SET NAN
    IF STATUS EQ 0 THEN BEGIN
      k1 = WHERE(MATRIX_O EQ FLOAT(NODATA), COUNT_k1)
      IF (COUNT_k1 GT 0) THEN MATRIX_O[k1] = !VALUES.F_NAN
      k2 = WHERE(MATRIX_M EQ FLOAT(NODATA), COUNT_k2)
      IF (COUNT_k2 GT 0) THEN MATRIX_M[k2] = !VALUES.F_NAN
    ENDIF
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; BAND LOOP: GET RANKINGS
    ;***********************************************************************
    FOR b=0, COUNT_B-1 DO BEGIN ; START 'FOR b'
      ;---------------------------------------------------------------------
      ; GET THE ith MAXIMUM VALUE
      IF b EQ 0 THEN BEGIN
	  	  ;-------------------------------------------------------------------
        MX_O = MAX(MATRIX_O, DIMENSION=1, LOCATION_O, /NAN)
        MX_M = MAX(MATRIX_M, DIMENSION=1, LOCATION_M, /NAN)
        ;-------------------------------------------------------------------
        ; SET THE ith MAXIMUM VALUE LOCATION
        RANK_O[LOCATION_O]=(b+1) ; DECENDING ORDER
        RANK_M[LOCATION_M]=(b+1) ; DECENDING ORDER
        ;-------------------------------------------------------------------
      ENDIF
      ;---------------------------------------------------------------------
      IF b GT 0 THEN BEGIN
	  	  ;-------------------------------------------------------------------
        MX_O = MAX(MATRIX_O - RANK_O, DIMENSION=1, LOCATION_O, /NAN)
        MX_M = MAX(MATRIX_M - RANK_M, DIMENSION=1, LOCATION_M, /NAN)
        ;-------------------------------------------------------------------
      	; SET THE ith MAXIMUM VALUE LOCATION
      	RANK_O[LOCATION_O]=(b+1) ; DECENDING ORDER
      	RANK_M[LOCATION_M]=(b+1) ; DECENDING ORDER
        ;-------------------------------------------------------------------
	    ENDIF
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ; CALCULATE THE MEAN OF RANK_O AND RANK_M
    RANK_OBAR = (TRANSPOSE(TOTAL(RANK_O, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(RANK_O), 1)))
    RANK_MBAR = (TRANSPOSE(TOTAL(RANK_M, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(RANK_M), 1)))
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; BAND LOOP: GET SPEARMANS SUMS
    ;***********************************************************************
    FOR b=0, COUNT_B-1 DO BEGIN ; START 'FOR b'
      ;---------------------------------------------------------------------
      ; GET THE CROSS-PRODUCT TERM
      CP += ((TRANSPOSE(TOTAL(RANK_M[b,*], 1, /NAN)) - RANK_MBAR) * (TRANSPOSE(TOTAL(RANK_O[b,*], 1, /NAN)) - RANK_OBAR))
      ; GET THE M DEVIATION
      MD += ((TRANSPOSE(TOTAL(RANK_M[b,*], 1, /NAN)) - RANK_MBAR)^2)
      ; GET THE O DEVIATION
      OD += ((TRANSPOSE(TOTAL(RANK_O[b,*], 1, /NAN)) - RANK_OBAR)^2)
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; CALCULATE SPEARMANS COEFFICIENT
    ;***********************************************************************
    ; GET THE SPEARMANS RANK CORRELATION COEFFICIENT (rs)
    rs = CP / SQRT(MD * OD)
    ;-----------------------------------------------------------------------
    ; APPEND DATA:
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILE
    OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
    ; APPEND DATA TO THE OUTPUT FILE
    WRITEU, UNIT, rs
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, UNIT
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
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_GET_Spearman_Rank_Correlation'
  PRINT,''
  ;-------------------------------------------------------------------------
END