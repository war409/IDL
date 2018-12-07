; ##########################################################################
; NAME: Convert_Grid_To_CSV.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Improving the MODIS open water product (Activity 6, WRAA, WIRADA)
; DATE: 06/05/2010
; DLM: 07/05/2010
;
; DESCRIPTION: This tool extracts the individual cell values of the input data
;              and exports them to a comma delimeted text file.
;
; INPUT:       One or more single-band grids.
;
; OUTPUT:      One comma delimeted text file. One file enrty is recorded for 
;              each pixel in the input grid.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              'SELECT THE INPUT DATA'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE' (Optional)
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE SEGMENT VALUE (0.0 - 1.0)'
;              
; NOTES:       
;
; ##########################################################################
;
PRO Convert_Grid_To_CSV
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Convert_Grid_To_CSV'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  IN_X = DIALOG_PICKFILE(PATH='\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster', $
    TITLE='SELECT THE INPUT DATA', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUTDIR = DIALOG_PICKFILE(PATH='\\File-wron\Working\work\war409\Work\WfHC\wirada\wraa\awra\open_water_mapping\spatial\raster', $
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
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(IN_X)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  FOR f=0, COUNT_F-1 DO BEGIN ; START 'FOR f'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET INPUT DATA (CURRENT FILE):
    ;-----------------------------------------------------------------------
    ; OPEN THE ith FILE
    X_IN = READ_BINARY(IN_X[f], DATA_TYPE=DATATYPE)
    ;-----------------------------------------------------------------------
    ; GET FILE NAME
    FNAME = IN_X[f]
    ; GET FILE NAME SHORT
    SNAME_START = STRPOS(FNAME, '\', /REVERSE_SEARCH)+1
    SNAME_LENGTH = (STRLEN(FNAME)-SNAME_START)-4
    SNAME = STRMID(FNAME, SNAME_START, SNAME_LENGTH)
    ;-----------------------------------------------------------------------  
    ; WRITE THE OUTPUT FILE HEAD:                       
    ;-----------------------------------------------------------------------
    ; BUILD THE OUTPUT FILE NAME
    ONAME = OUTDIR + SNAME + '.csv'
    ; CREATE THE OUTPUT FILE 
    OPENW, OUTLUN, ONAME, /GET_LUN
    ;-----------------------------------------------------------------------
    ; SET THE FILE HEAD
    FHEAD=["CID","Value"]
    ;-----------------------------------------------------------------------
    ; WRITE THE FILE HEAD
    PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FHEAD + '"'   
    ;-----------------------------------------------------------------------
    ; SEGMENT IMAGE:
    ;-----------------------------------------------------------------------
    ; GET NUMBER OF ELEMENTS IN X_IN
    COUNT_ELEMENTS = (N_ELEMENTS(X_IN))-1
    ;-----------------------------------------------------------------------
    ; BASED ON THE SEGMENT VALUE GET THE SEGMENT LENGTH
    SEGMENT_LENGTH = ROUND((COUNT_ELEMENTS)*SEGMENT)
    ; GET THE COUNT OF SEGMENTS WITHIN THE CURRENT IMAGE
    COUNT_S1 = CEIL((COUNT_ELEMENTS) / SEGMENT_LENGTH)
    COUNT_S = COUNT_S1[0]
    ; SET THE INITIAL SEGMENT START-POSITION AND END-POSITION
    SEGMENT_START = 0
    SEGMENT_END = SEGMENT_LENGTH
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; SEGMENT LOOP:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    FOR s=0, COUNT_S-1 DO BEGIN ; START 'FOR s'
      ;---------------------------------------------------------------------
      ; UPDATE SEGMENT PARAMETERS:
      ;---------------------------------------------------------------------      
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
        SEGMENT_END = LONG((COUNT_ELEMENTS - SEGMENT_START) + SEGMENT_START)
      ENDIF
      ; GET CURRENT SEGMENT SIZE
      SEGMENT_SIZE = LONG(SEGMENT_END - SEGMENT_START)+1
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; GET DATA:
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; GET DATA SEGMENT
      X = X_IN(SEGMENT_START:SEGMENT_END)
      ;---------------------------------------------------------------------
      ; SET NAN:
      IF STATUS EQ 0 THEN BEGIN
        ;----------------------------------------
        ; DATA TYPE CHECK
        IF DATATYPE NE (4 OR 5) THEN X = FLOAT(X)
        ;----------------------------------------
        k = WHERE(X EQ FLOAT(NODATA), COUNT_k)
        IF (COUNT_k GT 0) THEN X[k] = !VALUES.F_NAN
        ;----------------------------------------
      ENDIF
      ;---------------------------------------------------------------------
      ; CREATE THE EMPTY 2D DATA ARRAY
      IF STATUS EQ 0 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /FLOAT) ELSE BEGIN
        ;----------------------------------------
        IF DATATYPE EQ 1 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /BYTE)
        IF DATATYPE EQ 2 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /INTEGER)
        IF DATATYPE EQ 3 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /LONG)
        IF DATATYPE EQ 4 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /FLOAT)
        IF DATATYPE EQ 5 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /DOUBLE)
        IF DATATYPE EQ 6 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /COMPLEX)
        IF DATATYPE EQ 7 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /STRING)
        IF DATATYPE EQ 9 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /DCOMPLEX)
        IF DATATYPE EQ 10 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /PTR)
        IF DATATYPE EQ 11 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /OBJ)
        IF DATATYPE EQ 12 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /UINT)
        IF DATATYPE EQ 13 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /ULONG)
        IF DATATYPE EQ 14 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /L64)
        IF DATATYPE EQ 15 THEN MATRIX_X = MAKE_ARRAY(1, SEGMENT_SIZE, /UL64)
        ;----------------------------------------
      ENDELSE
      ;---------------------------------------------------------------------
      ; CREATE THE ID ARRAY
      ID_X = MAKE_ARRAY(1, SEGMENT_SIZE, /LONG)
      ;---------------------------------------------------------------------      
      ; FILL THE GRID VALUE ARRAY
      MATRIX_X[0,*] = X
      ;---------------------------------------------------------------------
      ; ADD ID VALUES
      IF s EQ 0 THEN BEGIN
        ; FILL THE ID VALUE ARRAY
        ID_X[0,*] = LINDGEN(SEGMENT_SIZE)
        ; STORE SEGMENT NUMBER
        SEGMENT_NO = N_ELEMENTS(ID_X[0,*])
      ENDIF
      ;----------------------------------------
      IF s GT 0 THEN BEGIN
        ; FILL THE ID VALUE ARRAY
        ID_X[0,*] = LINDGEN(SEGMENT_SIZE) + SEGMENT_NO
        ; STORE NEW SEGMENT NUMBER
        SEGMENT_NO = N_ELEMENTS(ID_X[0,*]) + SEGMENT_NO
      ENDIF
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; WRITE DATA:
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; DATA TYPE CHECK
      IF DATATYPE EQ 1 THEN MATRIX_X = DOUBLE(MATRIX_X)
      ;---------------------------------------------------------------------            
      ; WRITE DATA LOOP:
      ;---------------------------------------------------------------------
      FOR j=0, N_ELEMENTS(ID_X[0,*])-1 DO BEGIN ; START 'FOR j
        PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, STRTRIM(ID_X[0,j], 2), STRTRIM(MATRIX_X[0,j], 2)
      ENDFOR ; END 'FOR j'
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR s'
    ;-----------------------------------------------------------------------
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, OUTLUN
    ;-----------------------------------------------------------------------    
    ; GET END TIME: LOOP
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,''
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), $
      ' SECONDS, FOR FILE ', STRTRIM(f+1, 2), ' OF ', STRTRIM(COUNT_F, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR f'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Convert_Grid_To_CSV'
  PRINT,''
  ;-------------------------------------------------------------------------
END  
  
  
  