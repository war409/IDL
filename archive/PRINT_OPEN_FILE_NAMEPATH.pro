; ######################################################################
; NAME: PRINT_OPEN_FILE_NAMEPATH.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 18/08/2009
; DLM: 02/10/2009
; DESCRIPTION: Print the name and path of all open files (in ENVI) to 
;              the IDL console.
; INPUT: NA
; OUTPUT: NA 
; SET PARAMETERS: NA
; NOTES: 
; ######################################################################
;
PRO PRINT_OPEN_FILE_NAMEPATH
  ;
  ; GET OPEN FILE FID
  FID = ENVI_GET_FILE_IDS()
  ; ERROR CHECK
  IF (FID[0] eq -1) THEN $
  PRINT, 'NO FILES CURRENTLY OPEN IN ENVI' $
    ELSE BEGIN
      PRINT, ''
      ; FILE LOOP
      FOR i=0, N_ELEMENTS(FID)-1 DO BEGIN
        ; QUERY THE CURRENT FILE BY FID
        ENVI_FILE_QUERY, FID[i], FNAME=FNAME
        ; PRINT THE CURRENT FILE FID AND NAME
        PRINT, 'FID = ' + STRTRIM(FID[i],2) + STRING(9b) + '  ' + FNAME
      ENDFOR
    ENDELSE
    PRINT, ''
END