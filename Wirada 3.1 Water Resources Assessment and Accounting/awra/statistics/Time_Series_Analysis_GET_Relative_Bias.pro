;  ##########################################################################
; NAME: Time_Series_Analysis_GET_Relative_Bias.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 23/03/2010
; DLM: 23/03/2010
;
; DESCRIPTION: This tool calculates the relative bias between the model 
;              estimate and the observation. Data is calculated on a cell-
;              by-cell basis.
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
;              'SET THE SEGMENT VALUE (0.0 - 1.0)'
;
; NOTES:       The input data must have identical sample, line and band
;              numbers. The input data should have identical cell size,
;              projection and coordinate system, and extents.
;              
;              No data values are treated as missing data and are not included
;              in the calculation.
;
; ##########################################################################
;
PRO Time_Series_Analysis_GET_Relative_Bias
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_GET_Relative_Bias'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------  
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
  ; SET BAND COUNT
  COUNT_B = N_ELEMENTS(IN_O)
  COUNT_B2 = N_ELEMENTS(IN_M)
  ; ERROR CHECK
  IF COUNT_B NE COUNT_B2 THEN BEGIN
    PRINT, 'THE SELECTED OBSERVED AND MODELLED TIME-SERIES MUST HAVE AN IDENTICAL BAND COUNT'
    RETURN
  ENDIF
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
  ; SET THE SEGMENT VALUE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=0.1000, TITLE='SET THE SEGMENT VALUE (0.0 - 1.0) ', $
    /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  SEGMENT = FLOAT(RESULT.VALUE)
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; ERROR CHECK
  IF (SEGMENT LT 0.0) OR (SEGMENT GT 1.0) THEN BEGIN
    PRINT, 'THE SELECTED PARAMETER IS NOT VALID: ENTER A VALUE BETWEEN 0.0000 AND 1.0000'
    RETURN
  ENDIF
  ;-------------------------------------------------------------------------
  ; CREATE THE EMPTY OUTPUT FILE:
  ;-------------------------------------------------------------------------
  ; BUILD THE OUTPUT NAME
  OUT_RBIAS = OUTFOLDER + 'Relative.Bias' + '.img'
  ;-------------------------------------------------------------------------
  ; CREATE THE FILES
  OPENW, UNIT_RBIAS, OUT_RBIAS, /GET_LUN
  ;-------------------------------------------------------------------------
  ; CLOSE THE NEW FILES
  FREE_LUN, UNIT_RBIAS
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; SEGMENT IMAGE:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; OPEN THE FIRST FILE IN THE LIST
  IN_EXAMPLE = READ_BINARY(IN_O[0], DATA_TYPE=DATATYPE)
  ; GET NUMBER OF ELEMENTS
  IN_ELEMENTS = (N_ELEMENTS(IN_EXAMPLE))-1
  ;-------------------------------------------------------------------------
  ; BASED ON THE SEGMENT VALUE GET THE SEGMENT LENGTH
  SEGMENT_LENGTH = ROUND((IN_ELEMENTS)*SEGMENT)
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
  PRINT,'SEGMENT VALUE: ', STRTRIM(SEGMENT, 2)
  PRINT,'BAND COUNT: ', STRTRIM(COUNT_B, 2)
  PRINT,'ELEMENT COUNT, PER-FILE: ', STRTRIM(IN_ELEMENTS, 2)
  PRINT,'SEGMENT COUNT: ', STRTRIM(COUNT_S, 2)
  PRINT,'STANDARD SEGMENT SIZE: ', STRTRIM(SEGMENT_LENGTH, 2)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; SEGMENT LOOP:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
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
    ;-----------------------------------------------------------------------
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
    ; CALCULATE STATISTICS:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; GET THE RELATIVE BIAS
    RBIAS = ((MATRIX_MBAR - MATRIX_OBAR) / MATRIX_OBAR)
    ;-----------------------------------------------------------------------
    ;***********************************************************************  
    ; APPEND DATA:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILES
    OPENU, UNIT_RBIAS, OUT_RBIAS, /GET_LUN, /APPEND
    ;-----------------------------------------------------------------------
    ; APPEND DATA TO THE OUTPUT FILES
    WRITEU, UNIT_RBIAS, RBIAS
    ;-----------------------------------------------------------------------
    ; CLOSE THE OUTPUT FILES
    FREE_LUN, UNIT_RBIAS
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS FOR SEGMENT ', STRTRIM(s+1, 2), ' OF ', STRTRIM(COUNT_S, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR s'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_GET_Relative_Bias'
  PRINT,''
  ;-------------------------------------------------------------------------
END  