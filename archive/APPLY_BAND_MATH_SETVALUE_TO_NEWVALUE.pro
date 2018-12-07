; ######################################################################
; NAME: APPLY_BAND_MATH_SETVALUE_TO_NEWVALUE.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 18/08/2009
; DLM: 02/10/2009
; DESCRIPTION: This tool applies an envi band math expression to raster
;              image data (single or multi-band). In this example the band
;              math expression sets all cells of the user-defined vaule to a
;              new user-defined value in the output raster.
; INPUT: Single or multi-band raster (see NOTES)
; OUTPUT: One re-defined raster for each band of a multi-band raster, or
;         a single re-defined raster if the input is a single band raster.
; SET PARAMETERS: Set the output file path; set the values in the BAND 
;                 MATH EXPRESSION.
; NOTES: Load the raster file of interest in ENVI prior to running the 
;        tool.
; ######################################################################
;
PRO APPLY_BAND_MATH_SETVALUE_TO_NEWVALUE
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
        PRINT, 'FID = ' + STRTRIM(FID[i],2) + STRING(9b) + FNAME
        ; SET BAND MATH EXPRESSION ; WHERE VALUE EQ 0.00 SET NEWVALUE -9999.00
        EXP = '((B1 EQ -32768)*(0) + (B1 NE -32768)*B1)'
        ; SET THE OUTPUT RASTER PATH AND NAME
        OUT = FNAME + '_new_.img'
        POS = [0]
        PRINT, OUT
        ; APPLY BAND MATH AND WRITE OUTPUT
        ENVI_DOIT, 'MATH_DOIT', $ 
          FID=FID[i], POS=POS, DIMS=DIMS, $ 
            EXP=EXP, OUT_NAME=OUT, R_FID=R_FID
      ENDFOR
      ; LOOP BACK TO THE NEXT FILE/BAND
    ENDELSE
END




