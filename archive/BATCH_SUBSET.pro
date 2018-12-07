; ######################################################################
; NAME: BATCH_SUBSET.pro
; LANGUAGE: IDL
; AUTHOR: GARTH WARREN
; DATE: 09/11/2009
; DLM: 10/12/2009
; DESCRIPTION: THIS TOOL APPLIES A SPATIAL SUBSET TO EACH OPEN FILE.
; INPUT: ONE OR MORE IMAGE FILES.
; OUTPUT: ONE NEW IMAGE FOR EACH INPUT.
; SET PARAMETERS: INPUT SUBSET INFORMATION VIA WIDGET.
; NOTES:
; ######################################################################
; 
PRO BATCH_SUBSET
  ; GET START TIME FOR WHOLE
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_SUBSET'
  ;---------------------------------------------------------------------
  ; GET OPEN FILE FID
  FID = ENVI_GET_FILE_IDS()
  ; ERROR CHECK
  IF (FID[0] EQ -1) THEN BEGIN
    PRINT, ''
    PRINT, 'NO FILES CURRENTLY OPEN IN ENVI'
    PRINT, ''
    RETURN
  ENDIF ELSE BEGIN
    ;-------------------------------------------------------------------
    ; GET OPEN FILE INFORMATION
    ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=DIMS
    ; SUBSET WIDGET
    BASE = WIDGET_AUTO_BASE(TITLE='SELECT SUBSET')
    WS = WIDGET_SUBSET(BASE, UVALUE='SUBSET', FID=FID[0], DIMS=DIMS, /AUTO)
    RESULT = AUTO_WID_MNG(BASE) 
    IF (RESULT.ACCEPT EQ 0) THEN BEGIN
        PRINT, ''
        PRINT, 'THE SELECTED SUBSET IS NOT VALID'
        PRINT, ''
        RETURN
    ENDIF
    NEWDIMS = RESULT.SUBSET
    PRINT, ''
    PRINT, 'NEWDIMS: ', NEWDIMS
    ;-------------------------------------------------------------------
    ; SET THE OUTPUT DIRECTORY
    OUTPATH = ENVI_PICKFILE(TITLE='SELECT OUTPUT FOLDER', /DIRECTORY)
    PRINT, ''
    PRINT, '  ', OUTPATH 
    ;-------------------------------------------------------------------
    ; FILE LOOP
    FOR i=0, N_ELEMENTS(FID)-1 DO BEGIN ; FOR 'i' START
      ; QUERY THE CURRENT FILE BY FID
      ENVI_FILE_QUERY, FID[i], SNAME=SNAME
      ; PRINT THE CURRENT FILE FID AND NAME
      PRINT, ''
      PRINT, 'FILENAME: ', SNAME, ' FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(FID), 2)
      ;-----------------------------------------------------------------  
      ; BUILD THE OUTPUT FILENAME
      OUTFILE = OUTPATH + '\' + SNAME + '.SUBSET.img'
      ; WRITE DATA
      INFILE = ENVI_GET_DATA(FID=FID[i], DIMS=NEWDIMS, POS=0)
      ENVI_WRITE_ENVI_FILE, INFILE, OUT_NAME=OUTFILE, /NO_OPEN
      ;-----------------------------------------------------------------  
    ENDFOR ; FOR 'i' END
  ENDELSE
  ;---------------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_SUBSET'
  PRINT,'' 
END  