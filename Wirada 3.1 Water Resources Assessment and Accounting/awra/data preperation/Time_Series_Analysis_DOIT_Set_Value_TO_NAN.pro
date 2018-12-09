; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Set_Value_TO_NAN.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 26/03/2010
; DLM: 26/03/2010
; 
; DESCRIPTION: This tool sets the user-selected value to NAN.
;              
; INPUT:       One or more single-band or multi-band image files. 
; 
; OUTPUT:      One new file per input.
;     
; PARAMETERS:  Via widgets. The user may choose whether to use the cell
;              size of an existing file, or enter the new cell size
;              manually. If the user opts to use the cell size of an 
;              existing file the user may also select whether or not to
;              align (snap cells) the output with the existing file.   
;      
;              'SELECT THE INPUT FILES' 
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT THE INPUT DATA TYPE'
;              'SET ONE OR TWO VALUES AS NAN'
;              'SET THE NODATA VALUE'               
;              'SET THE SECOND NODATA VALUE' (Optional)             
; NOTES:       
;                    
; ##########################################################################
; 
PRO Time_Series_Analysis_DOIT_Set_Value_TO_NAN
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Set_Value_TO_NAN'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT TIME-SERIES
  INPUT = DIALOG_PICKFILE(PATH='\\wron\Working\work\war409\work\imagery\globcover\workspace\subset\img', $ 
    TITLE='SELECT THE INPUT TIME-SERIES', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  INPUT = INPUT[SORT(INPUT)]
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  FCOUNT = N_ELEMENTS(INPUT) 
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\wron\Working\work\war409\work\imagery\globcover\workspace\subset\nan', $
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
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
  ; SELECT NODATA COUNT
  VALUES = ['SET ONE VALUE TO NAN','SET TWO VALUES TO NAN']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SET ONE OR TWO VALUES AS NAN', $
    /COLUMN, /EXCLUSIVE, /NO_RELEASE)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  NANCOUNT = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=128.00, TITLE='SET THE NODATA VALUE ', /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  NODATA = RESULT.VALUE
  NODATA1 = NODATA[0]
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  IF NANCOUNT EQ 1 THEN BEGIN
    ; SET THE NODATA VALUE
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=0.00, TITLE='SET THE SECOND NODATA VALUE ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA = RESULT.VALUE
    NODATA2 = NODATA[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR i=0, FCOUNT-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; GET DATA:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; GET THE CURRENT INPUT FILE
    INFILE = INPUT[i]
    ;-----------------------------------------------------------------------
    ; GET FILENAME FROM NAME & PATH
    START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILE)-START)-4
    FNAME = STRMID(INFILE, START, LENGTH)
    INPATH = STRMID(INFILE, 0, START)
    OUTPATH = OUTFOLDER
    ;-----------------------------------------------------------------------
    ; BUILD THE OUTPUT FILE NAME
    OUTFILE = OUTPATH + FNAME + '.img'
    ;-----------------------------------------------------------------------
    ; CREATE THE EMPTY OUTPUT FILE
    OPENW, UNIT, OUTFILE, /GET_LUN
    ; CLOSE THE FILE
    FREE_LUN, UNIT
    ;-----------------------------------------------------------------------
    ; GET DATA
    IN_DATA = READ_BINARY(INFILE, DATA_TYPE=DATATYPE)
    ;-----------------------------------------------------------------------  
    ;***********************************************************************
    ; SET NAN:
    ;***********************************************************************
    ;-----------------------------------------------------------------------    
    ; DATA TYPE CHECK
    IF DATATYPE NE (4 OR 5) THEN IN_DATA = FLOAT(IN_DATA)
    ; SET NAN
    IF NANCOUNT EQ 0 THEN BEGIN
      ;---------------------------------------------------------------------
      k = WHERE(IN_DATA EQ FLOAT(NODATA1), COUNT)
      IF (COUNT GT 0) THEN IN_DATA[k] = !VALUES.F_NAN
      ;---------------------------------------------------------------------
    ENDIF ELSE BEGIN
      k = WHERE(IN_DATA EQ FLOAT(NODATA1), COUNT)
      IF (COUNT GT 0) THEN IN_DATA[k] = !VALUES.F_NAN
      ;---------------------------------------------------------------------
      k = WHERE(IN_DATA EQ FLOAT(NODATA2), COUNT)
      IF (COUNT GT 0) THEN IN_DATA[k] = !VALUES.F_NAN
    ENDELSE  
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; WRITE DATA:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; OPEN THE OUTPUT FILE
    OPENU, UNIT, OUTFILE, /APPEND, /GET_LUN
    ; APPEND DATA TO THE OUTPUT FILE
    WRITEU, UNIT, IN_DATA
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, UNIT
    ;-----------------------------------------------------------------------
    ; PRINT END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT, ''
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2),'  SECONDS, FOR FILE: ', STRTRIM(i+1, 2), ' OF ', STRTRIM(FCOUNT, 2)
    ;-----------------------------------------------------------------------   
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Spatial_Raster_Resample'
  PRINT,''
  ;-------------------------------------------------------------------------
END