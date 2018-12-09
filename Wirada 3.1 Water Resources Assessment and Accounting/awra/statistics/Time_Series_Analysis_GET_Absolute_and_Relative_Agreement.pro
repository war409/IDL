; ######################################################################
; NAME: Time_Series_Analysis_GET_Absolute_and_Relative_Agreement.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 10/02/2010
; DLM: 17/02/2010
;
; DESCRIPTION: This tool calculates a set of metrics chosen to express
;              the absolute agreement (or difference) and the relative
;              agreement (or difference) between the model estimates and
;              the observations. Data is calculated on a cell-by-cell basis.
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
;              The measures of absolute agreement include... the standard
;              difference (SD) expressed as the square root of the
;              residual variance; bias expressed as the difference between
;              the observed and predicted means; and the Nash-Sutcliffe model
;              efficiency (NSME) expressed as the fraction of total variance
;              in the observations accurately reproduced by the model.
;
;              The measures of relative agreement include... the coefficient
;              of determination (R^2); the pearson's product-moment
;              correlation coefficient; and the correlated residual variation
;              expressed as the difference between R^2 and NSME indicating
;              the fraction of the observed variance that is correlated to
;              the model estimates but not explained by them.
;
; INPUT:       The modelled time-series (M) and the the observed time-series
;              (O).
;
; OUTPUT:      See DESCRIPTION.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              'SELECT THE OBSERVED TIME-SERIES (O)'
;              'SELECT THE MODELLED TIME-SERIES (M)'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE RESIZE VALUE (0.0 - 1.0)'
;
; NOTES:       The input data must have identical sample, line and band
;              numbers. The input data should have identical cell size,
;              projection and coordinate system, and extents.
;
; ######################################################################
;
PRO Time_Series_Analysis_GET_Absolute_and_Relative_Agreement
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_GET_Absolute_and_Relative_Agreement'
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
  ; SELECT THE OUTPUT DIRECTORY:
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Statistics\Bivariate', $
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
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=255, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA1 = RESULT.VALUE
    NODATA = NODATA1[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;-------------------------------------------------------------------------
  ; CREATE THE EMPTY OUTPUT FILES:
  ;-------------------------------------------------------------------------
  ; BUILD THE OUTPUT NAMES: ABSOLUTE AGREEMENT
  OUT_SD = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.STANDARD.DIFFERENCE' + '.img'
  OUT_BIAS = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.BIAS' + '.img'
  OUT_NSME = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.NSME' + '.img'
  OUT_COD = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.COEFFICIENT.OF.DETERMINATION' + '.img'
  OUT_COC = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.COEFFICIENT.OF.CORRELATION' + '.img'
  OUT_PPM = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.PEARSONS.PRODUCT.MOMENT' + '.img'
  OUT_CRV1 = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.CORRELATION.RESIDUAL.VARIATION.R2' + '.img'
  OUT_CRV2 = OUTFOLDER + 'MCD43A4.005.aet.vs.AWRA.etot.200001.200904.8day.aust.5000m.CORRELATION.RESIDUAL.VARIATION.r12' + '.img'
  ;-------------------------------------------------------------------------
  ; CREATE THE FILES
  OPENW, UNIT_SD, OUT_SD, /GET_LUN
  OPENW, UNIT_BIAS, OUT_BIAS, /GET_LUN
  OPENW, UNIT_NSME, OUT_NSME, /GET_LUN
  OPENW, UNIT_COD, OUT_COD, /GET_LUN
  OPENW, UNIT_COC, OUT_COC, /GET_LUN
  OPENW, UNIT_PPM, OUT_PPM, /GET_LUN
  OPENW, UNIT_CRV1, OUT_CRV1, /GET_LUN
  OPENW, UNIT_CRV2, OUT_CRV2, /GET_LUN
  ;-------------------------------------------------------------------------
  ; CLOSE THE NEW FILES
  FREE_LUN, UNIT_SD
  FREE_LUN, UNIT_BIAS
  FREE_LUN, UNIT_NSME
  FREE_LUN, UNIT_COD
  FREE_LUN, UNIT_COC
  FREE_LUN, UNIT_PPM
  FREE_LUN, UNIT_CRV1
  FREE_LUN, UNIT_CRV2
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
    ; CREATE THE EMPTY 2D DATA ARRAYS
    MATRIX_O = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    MATRIX_M = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    SSTO = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    SSR = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
    SSE = MAKE_ARRAY(COUNT_B, SEGMENT_SIZE, /FLOAT)
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
    ; CALCULATE THE MEAN OF O
    MATRIX_OBAR = (TRANSPOSE(TOTAL(MATRIX_O, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_O), 1)))
    ; CALCULATE THE MEAN OF M
    MATRIX_MBAR = (TRANSPOSE(TOTAL(MATRIX_M, 1, /NAN)) / TRANSPOSE(TOTAL(FINITE(MATRIX_M), 1)))
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; BAND LOOP: SUMS
    ;***********************************************************************
    FOR b=0, COUNT_B-1 DO BEGIN ; START 'FOR b'
      ;---------------------------------------------------------------------
      ; GET THE TOTAL SUM OF SQUARES (SSTO)
      SSTO += ((TRANSPOSE(TOTAL(MATRIX_O[b,*], 1, /NAN)) - MATRIX_OBAR)^2)
      ; GET THE REGRESSION SUM OF SQUARES (SSR)
      SSR += ((TRANSPOSE(TOTAL(MATRIX_M[b,*], 1, /NAN)) - MATRIX_OBAR)^2)
      ; GET THE RESIDUAL SUM OF SQUARES (SSE)
      SSE += ((TRANSPOSE(TOTAL(MATRIX_O[b,*], 1, /NAN)) - TRANSPOSE(TOTAL(MATRIX_M[b,*], 1, /NAN)))^2)
      ;-------------------------------------------------------------------
      ; GET THE CROSS-PRODUCT TERM
      CP += ((TRANSPOSE(TOTAL(MATRIX_M[b,*], 1, /NAN)) - MATRIX_MBAR) * (TRANSPOSE(TOTAL(MATRIX_O[b,*], 1, /NAN)) - MATRIX_OBAR))
      ; GET THE M DEVIATION
      MD += ((TRANSPOSE(TOTAL(MATRIX_M[b,*], 1, /NAN)) - MATRIX_MBAR)^2)
      ; GET THE O DEVIATION
      OD += ((TRANSPOSE(TOTAL(MATRIX_O[b,*], 1, /NAN)) - MATRIX_OBAR)^2)
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; CALCULATE STATISTICS
    ;***********************************************************************
    ; MEASURES OF ABSOLUTE AGREEMENT:
    ;-----------------------------------------------------------------------
    ; GET THE STANDARD DIFFERENCE (SD)
    SD = SQRT((FLOAT(1) / TRANSPOSE(TOTAL(FINITE(MATRIX_O), 1))) * SSE)
    ; GET THE BIAS
    BIAS = MATRIX_MBAR - MATRIX_OBAR
    ; GET THE NASH-SUTCLIFFE MODEL EFFICIENCY
    NSME = FLOAT(1) - (SSE / SSTO)
    ;-----------------------------------------------------------------------
    ; MEASURES OF RELATIVE AGREEMENT:
    ;-----------------------------------------------------------------------
    ; GET THE COEFFICIENT OF DETERMINATION (R^2)
    COD = SSR / SSTO
    ; GET THE COEFFICIENT OF CORRELATION (r)
    COC = SQRT(COD)
    ; GET THE PEARSONS PRODUCT MOMENT CORRELATION COEFFICIENT (r12)
    PPM = CP / (SQRT(MD) * SQRT(OD))
    ; GET THE CORRELATION RESIDUAL VARIATION 1 (FOR THE COEFFICIENT OF DETERMINATION)
    CRV1 = COD - NSME
    ; GET THE CORRELATION RESIDUAL VARIATION 1 (FOR THE PEARSONS PRODUCT MOMENT)
    CRV2 = PPM - NSME
    ;-----------------------------------------------------------------------
    ; APPEND DATA:
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILES
    OPENU, UNIT_SD, OUT_SD, /GET_LUN, /APPEND
    OPENU, UNIT_BIAS, OUT_BIAS, /GET_LUN, /APPEND
    OPENU, UNIT_NSME, OUT_NSME, /GET_LUN, /APPEND
    OPENU, UNIT_COD, OUT_COD, /GET_LUN, /APPEND
    OPENU, UNIT_COC, OUT_COC, /GET_LUN, /APPEND
    OPENU, UNIT_PPM, OUT_PPM, /GET_LUN, /APPEND
    OPENU, UNIT_CRV1, OUT_CRV1, /GET_LUN, /APPEND
    OPENU, UNIT_CRV2, OUT_CRV2, /GET_LUN, /APPEND
    ;-----------------------------------------------------------------------
    ; APPEND DATA TO THE OUTPUT FILES
    WRITEU, UNIT_SD, SD
    WRITEU, UNIT_BIAS, BIAS
    WRITEU, UNIT_NSME, NSME
    WRITEU, UNIT_COD, COD
    WRITEU, UNIT_COC, COC
    WRITEU, UNIT_PPM, PPM
    WRITEU, UNIT_CRV1, CRV1
    WRITEU, UNIT_CRV2, CRV2
    ;-----------------------------------------------------------------------
    ; CLOSE THE OUTPUT FILES
    FREE_LUN, UNIT_SD
    FREE_LUN, UNIT_BIAS
    FREE_LUN, UNIT_NSME
    FREE_LUN, UNIT_COD
    FREE_LUN, UNIT_COC
    FREE_LUN, UNIT_PPM
    FREE_LUN, UNIT_CRV1
    FREE_LUN, UNIT_CRV2
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
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_GET_Absolute_and_Relative_Agreement'
  PRINT,''
  ;-------------------------------------------------------------------------
END