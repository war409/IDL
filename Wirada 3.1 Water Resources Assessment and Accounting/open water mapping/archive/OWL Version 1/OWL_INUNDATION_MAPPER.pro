; ######################################################################
; NAME: OWL_INUNDATION_MAPPER.pro
; LANGUAGE: ENVI IDL
; AUTHOR: GARTH WARREN
; DATE: 03/12/2009
; DLM: 11/12/2009
; DESCRIPTION: THIS TOOL CREATES AN INUNDATION IMAGE FOR EACH INPUT BASED
;              ON USER SELECTED PARAMETERS. INUNDATION EXTENT IS MAPPED 
;              BY-DATE. A CELL IS CLASSIFIED AS BEING INUNDATED IF THE 
;              OWL VALUE IS EQ, GT, GE, LT OR LE A USER-SELECTED 
;              THRESHOLD. IF FOR A GIVEN DATE AND CELL LOCATION THE OWL
;              VALUE SATISFIES THE USER-SELECTED CRITERIA THAT CELL IS 
;              SAID TO BE INUNDATED AND IS GIVEN A VALUE OF 1. IF THE
;              CRITERIA IS NOT SATISFIED THE CELL IS GIVEN A VALUE OF 0.
; INPUT: ONE SINGLE-BAND IMAGE OR ONE MULTI-BAND IMAGE.
; OUTPUT: ONE IMAGE PER INPUT THAT SHOWS INUNDATION EXTENT BASED ON THE
;         USER-SELECTED EXPRESSION.
; SET PARAMETERS: INPUT IS VIA WIDGETS.
; NOTES:
; ######################################################################
; 
PRO OWL_INUNDATION_MAPPER
  ; GET START TIME
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: OWL_INUNDATION_MAPPER'
  ;---------------------------------------------------------------------
  ; DEFINE THE INPUT IMAGE DATA (SINGLE BAND IMAGE OR MULTIBAND IMAGE)
  ENVI_SELECT, TITLE='SELECT INPUT IMAGE DATA', FID=FID, POS=POS
  ; CHECK WHETHER THE INPUT IMAGE DATA NAME AND PATH IS VALID
  IF (FID EQ -1) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED INPUT FILE IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ;---------------------------------------------------------------------
  ; QUERY INPUT IMAGE: GET BAND COUNT AND MAP INFO
  ENVI_FILE_QUERY, FID, BNAME=BNAME, SNAME=SNAME, NB=NB, NS=NS, NL=NL, DATA_TYPE=DATA_TYPE
  RESULT = WHERE(BNAME, COUNT)
  BCOUNT = COUNT
  PRINT, 'NUMBER OF BANDS: ', BCOUNT
  ; GET DIMENSIONS
  DIMS = [-1, 0, NS-1, 0, NL-1]
  PRINT, 'IMAGE DIMENSIONS: ', DIMS
  ; GET MAP INFO
  MAP_INFO = ENVI_GET_MAP_INFO(FID=FID)
  ;---------------------------------------------------------------------
  ; DEFINE OPERATOR
  OP_BASE = WIDGET_AUTO_BASE(TITLE='DEFINE...')
  LIST=['EQ','LE','LT','GE','GT']
  WO_OP = WIDGET_PMENU(OP_BASE, LIST=LIST, uvalue='OUTOP', $
    PROMPT='SELECT AN OPERATOR', XSIZE=20, /AUTO)  
  RESULT_OP = AUTO_WID_MNG(OP_BASE) 
  IF (RESULT_OP.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OPERATOR IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    OPER = LIST(RESULT_OP.OUTOP)
    PRINT, 'OPERATOR: ', OPER
  ENDELSE
  ;---------------------------------------------------------------------
  ; SET PARAMETER IN OPERATOR
  PA_BASE = WIDGET_AUTO_BASE(TITLE='DEFINE... (0 - 100)')
  WO_PA = WIDGET_PARAM(PA_BASE, DT=2, UVALUE='PARAM', $
    PROMPT='ENTER A PARAMETER', XSIZE=18, /AUTO)
  RESULT_PA = AUTO_WID_MNG(PA_BASE)
  IF (RESULT_PA.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED PARAMETER IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    PARAM = FIX(RESULT_PA.PARAM)
    PRINT, 'PARAMETER VALUE = ', STRTRIM(PARAM, 2)
  ENDELSE
  ;---------------------------------------------------------------------
  ; PRINT EXPRESSION
  PRINT,''
  PRINT, 'EXPRESSION:  (OWL ', OPER, ' ', STRTRIM(PARAM, 2),')'
  PRINT,''
  ;---------------------------------------------------------------------
  ; SET THE OUTPUT DIRECTORY
  OUTPATH = ENVI_PICKFILE(TITLE='SELECT OUTPUT FOLDER', /DIRECTORY)
  PRINT, ''
  PRINT, '  ', OUTPATH
  ;---------------------------------------------------------------------
  ; LOOP THROUGH EACH BAND
  FOR i=0, BCOUNT-1 DO BEGIN ; START 'FOR i'
    ; GET START TIME FOR LOOP
    T_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------
    ; GET BAND NAME
    BNAMEX = BNAME[i]
    ; GET SHORT BAND NAME
    IF (i+1) LT 10 THEN BANDNAME = STRMID(BNAMEX, 15, 28)
    IF (((i+1) GE 10) AND ((i+1) LT 100)) THEN BANDNAME = STRMID(BNAMEX, 16, 28)
    IF (i+1) GE 100 THEN BANDNAME = STRMID(BNAMEX, 17, 28)
    ;-------------------------------------------------------------------
    ; PRINT THE CURRENT IMAGE NAME
    PRINT, ''
    PRINT, 'FILENAME: ', BANDNAME, ' FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(FID), 2)
    ;-------------------------------------------------------------------
    ; SET OUTPUT FILENAME
    ; BUILD EXPRESSION
    PAR =  OPER + STRTRIM(FIX(RESULT_PA.PARAM), 2)
    ; BUILD THE OUTPUT FILENAME
    OUTFILE = OUTPATH + '\' + BANDNAME + '.' + PAR + '.img'
    PRINT, OUTFILE
    ;-------------------------------------------------------------------
    ; GET BAND DATA
    OWL_IN = ENVI_GET_DATA(FID=FID, POS=i, DIMS=DIMS)
    ;-------------------------------------------------------------------    
    ; CREATE EXPRESSION ARRAY
    OWLEXP = LONARR(NS, NL)
    ;-------------------------------------------------------------------
    ; APPLY EXPRESSION
    IF OPER EQ 'EQ' THEN OWLEXP += ((OWL_IN EQ STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'LE' THEN OWLEXP += ((OWL_IN LE STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'LT' THEN OWLEXP += ((OWL_IN LT STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'GE' THEN OWLEXP += ((OWL_IN GE STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'GT' THEN OWLEXP += ((OWL_IN GT STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    ;-------------------------------------------------------------------
    ; MAKE INTEGER OUTPUT WITH OWLEXP
    OWLEXPOUT = FIX(OWLEXP)
    ;-------------------------------------------------------------------
    ; WRITE DATA TO OUTPUT
    ENVI_WRITE_ENVI_FILE, OWLEXPOUT, OUT_NAME=OUTFILE, MAP_INFO=MAP_INFO, /NO_OPEN
    ;-------------------------------------------------------------------
    ; PRINT THE BAND PROCESSING TIME
    SECONDS = (SYSTIME(1)-T_TIME)
    PRINT,''
    PRINT, SECONDS,'  SECONDS FOR BAND ', i+1, ' OF ', BCOUNT
    ;-------------------------------------------------------------------
  ENDFOR ; END 'FOR i' ROI
  ;---------------------------------------------------------------------
  ; PRINT THE PROCESSING TIME
  PRINT,''
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: OWL_INUNDATION_MAPPER'
  PRINT,'' 
END  