; ######################################################################
; NAME: EXPORT_RASTER_AS_ASCII.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 18/08/2009
; DLM: 02/10/2009
; DESCRIPTION: 
; INPUT: NA
; OUTPUT: NA 
; SET PARAMETERS: NA
; NOTES: Load the raster file of interest in ENVI prior to running the 
;        tool.
; ######################################################################
;
PRO EXPORT_RASTER_AS_ASCII
  ;
  ; GET OPEN FILE FID
  FID = ENVI_GET_FILE_IDS()
  ; ERROR CHECK
  IF (FID[0] EQ -1) THEN $
    PRINT, 'NO FILES CURRENTLY OPEN IN ENVI' $
    ELSE BEGIN
      ;
      ; FILE LOOP 
      FOR i=0, N_ELEMENTS(FID)-1 DO BEGIN
        ; QUERY THE CURRENT FILE BY FID
        ENVI_FILE_QUERY, FID[i], FNAME=FNAME, BNAMES=BNAMES, DIMS=DIMS
        ; PRINT THE CURRENT FILE FID AND NAME
        PRINT, 'FID = ' + STRTRIM(FID[i],2) + STRING(9b) + FNAME
        ; SET THE OUTPUT ASCII PATH AND NAME
        OUT = 'C:/WorkSpace/war409/amsr-e database/data/A_Time/ENVI/Temp/Test_r02b_' + BNAMES
        POS = [0]
        ; SET THE FIELD LENGTH AND FIELD PRECISION OF THE OUTPUT ASCII
        FIELD = [17,6]
        ; PRINT THE OUTPUT ASCII PATH AND NAME
        PRINT, OUT
        ; WRITE THE OUTPUT ASCII
        ENVI_OUTPUT_TO_EXTERNAL_FORMAT, /ASCII, DIMS=DIMS, FID=FID[i], FIELD=FIELD, OUT_NAME=OUT, POS=POS
      ENDFOR
      ; LOOP BACK TO THE NEXT FILE/BAND
    ENDELSE
END



