; ######################################################################
; NAME: BATCH_APPLY_MASK.pro
; LANGUAGE: IDL
; AUTHOR: GARTH WARREN
; DATE: 10/11/2009
; DLM: 16/11/2009
; DESCRIPTION: THIS TOOL APPLIES A MASK TO ALL OPEN IMAGES.
; INPUT: ONE OR MORE IMAGE FILES.
; OUTPUT: ONE MASKED IMAGE FOR EACH INPUT
; SET PARAMETERS: VIA ENVI WIDGETS.
; NOTES: THE INPUT MASK AND IMAGE DATA MUST HAVE IDENTICAL EXTENTS.
; ######################################################################
; 
PRO BATCH_APPLY_MASK
  ; GET START TIME FOR WHOLE
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_APPLY_MASK'
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
    ; OPEN AND SET MASK
    MASKFILE = ENVI_PICKFILE(TITLE='SELECT MASK', /NO_CHANGE) 
    ENVI_OPEN_FILE, MASKFILE, R_FID=M_FID
    IF (M_FID EQ -1) THEN BEGIN
      PRINT, ''
      PRINT, '  A VAID MASK WAS NOT SELECTED'
      PRINT, ''
      RETURN   
    ENDIF ELSE BEGIN
      ; GET MASK DIMS
      ENVI_FILE_QUERY, M_FID, DIMS=MASKDIMS
      ; SET THE OUTPUT DIRECTORY
      OUTPATH = ENVI_PICKFILE(TITLE='SELECT OUTPUT FOLDER', /DIRECTORY)
      PRINT, ''
      PRINT, '  ', OUTPATH
      ;-------------------------------------------------------------------
      ; FILE LOOP
      FOR i=0, N_ELEMENTS(FID)-1 DO BEGIN ; FOR 'i' START
        ; QUERY THE CURRENT FILE BY FID
        ENVI_FILE_QUERY, FID[i], SNAME=SNAME, DIMS=DIMS
        ; PRINT THE CURRENT FILE FID AND NAME
        PRINT, ''
        PRINT, 'FILENAME: ', SNAME, ' FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(FID), 2)
        ;-----------------------------------------------------------------      
        ; BUILD THE OUTPUT FILENAME
        OUTFILE = OUTPATH + '\' + SNAME + '_MASK' ;+ '_EXPAND'
        ; WRITE THE OUTPUT FILE AND APPLY MASK
        ENVI_MASK_APPLY_DOIT, FID=FID[i], POS=0, DIMS=DIMS, $ 
          M_FID=M_FID, M_POS=0, VALUE=0, OUT_NAME=OUTFILE, R_FID=R_FID
        ;--------------------------------------------------------------- 
      ENDFOR ; FOR 'i' END
    ENDELSE
  ENDELSE
  ;-----------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_APPLY_MASK'
  PRINT,'' 
END  