; ######################################################################
; NAME: OWL_INUNDATION_BY_COUNT_MAPPER.pro
; LANGUAGE: ENVI IDL
; AUTHOR: JUAN PABLO GUERSCHMAN & GARTH WARREN
; DATE: 09/12/2009
; DLM: 11/12/2009
; DESCRIPTION: THIS TOOL CREATES AN INUNDATION IMAGE BASED ON USER- 
;              SELECTED PARAMETERS. INUNDATION BY-COUNT IS MAPPED 
;              BY-TIME-SERIES. A CELL IS CLASSIFIED AS BEING INUNDATED 
;              IF THE OWL VALUE IS EQ, GT, GE, LT OR LE A USER-SELECTED 
;              OWL THRESHOLD AND IS EQ, GT, GE, LT OR LE A USER-SELECTED 
;              COUNT THRESHOLD. IF THE INUNDATION CRITERIA AND THE COUNT 
;              CRITERIA IS SATISFIED A CELL IS IS GIVEN A VALUE OF 1, IF 
;              NOT, THE CELL IS GIVEN A VALUE OF 0.
; INPUT: ONE SINGLE-BAND IMAGE OR ONE MULTI-BAND IMAGE.
; OUTPUT: ONE IMAGE.
; PARAMETERS: INPUT IS VIA WIDGETS.
; NOTES:
; ######################################################################
; 
PRO OWL_INUNDATION_BY_COUNT_MAPPER
  ; GET START TIME
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: OWL_INUNDATION_BY_COUNT_MAPPER'
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
  ; COUNT THE NUMBER OF BANDS IN THE INPUT FILE
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
  ; DEFINE OPERATOR: WIDGET_STRING
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
  ; SET PARAMETER OPERATOR: WIDGET_PARAM
  PA_BASE = WIDGET_AUTO_BASE(TITLE='DEFINE...')
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
  PRINT, '  EXPRESSION:  (OWL ', OPER, ' ', STRTRIM(PARAM, 2),')'
  PRINT,''
  ;--------------------------------------------------------------------- 
  ; CREATE EMPTY ARRAY
  ACUM_OWL = LONARR(NS, NL)
  ;---------------------------------------------------------------------
  ; LOOP THROUGH EACH BAND
  FOR i=0, BCOUNT-1 DO BEGIN ; START 'FOR i'
    ; GET START TIME FOR LOOP
    T_TIME = Systime(1)
    ;-------------------------------------------------------------------
    ; GET BAND DATA
    OWL_IN = ENVI_GET_DATA(FID=FID, POS=i, DIMS=DIMS)
    ;-------------------------------------------------------------------
    ; ADD TO THE ARRAY IF THE CELL MEETS THE EXPRESSION CRITERIA AT THIS 
    ; BAND/DATE COMBINATION. AFTER THE LAST DATE/BAND THE ARRAY ACUM_OWL 
    ; IS MADE-UP OF CELLS THAT HAVE MET THE CRITERIA AT LEAST ONCE DURING 
    ; THE TIME-SERIES.
    IF (OPER EQ 'EQ') AND (PARAM EQ 255) THEN ACUM_OWL += OWL_IN EQ STRTRIM(PARAM, 2)
    IF (OPER EQ 'EQ') AND (PARAM NE 255) THEN ACUM_OWL += ((OWL_IN EQ STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'LE' THEN ACUM_OWL += ((OWL_IN LE STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'LT' THEN ACUM_OWL += ((OWL_IN LT STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'GE' THEN ACUM_OWL += ((OWL_IN GE STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    IF OPER EQ 'GT' THEN ACUM_OWL += ((OWL_IN GT STRTRIM(PARAM, 2)) AND (OWL_IN NE 255))
    ;-------------------------------------------------------------------
    ; PRINT THE LOOP PROCESSING TIME
    SECONDS = (SYSTIME(1)-T_TIME)
    PRINT,''
    PRINT, SECONDS,'  SECONDS FOR BAND ', i+1, ' OF ', BCOUNT
    ;-------------------------------------------------------------------
  ENDFOR ; END 'FOR i' ROI
  ;---------------------------------------------------------------------
  ; RENAME OUTPUT
  OWL_EXP = ACUM_OWL
  ;---------------------------------------------------------------------
  ; CREATE EMPTY ARRAY
  OUT = LONARR(NS, NL)
  COUNT_OWL = LONARR(NS, NL)
  ;---------------------------------------------------------------------
  ; DEFINE OPERATOR 2 (% OF TIME): WIDGET_STRING
  OP_BASE2 = WIDGET_AUTO_BASE(TITLE='DEFINE...')
  LIST=['EQ','LE','LT','GE','GT']
  WO_OP2 = WIDGET_PMENU(OP_BASE2, LIST=LIST, uvalue='OUTOP2', $
    PROMPT='SELECT AN OPERATOR FOR INUNDATION COUNT', XSIZE=20, /AUTO)  
  RESULT_OP2 = AUTO_WID_MNG(OP_BASE2) 
  IF (RESULT_OP2.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OPERATOR IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    OPER2 = LIST(RESULT_OP2.OUTOP2)
    PRINT,''
    PRINT, 'OPERATOR: ', OPER2
  ENDELSE
  ;---------------------------------------------------------------------
  ; SET PARAMETER IN OPERATOR: WIDGET_PARAM
  PA_BASE2 = WIDGET_AUTO_BASE(TITLE='DEFINE...')
  WO_PA2 = WIDGET_PARAM(PA_BASE2, DT=2, UVALUE='PARAM2', $
    PROMPT='ENTER A PARAMETER (INUNDATION COUNT)', XSIZE=18, /AUTO)
  RESULT_PA2 = AUTO_WID_MNG(PA_BASE2)
  IF (RESULT_PA2.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED PARAMETER IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    PARAM2 = FIX(RESULT_PA2.PARAM2)
    PRINT,''
    PRINT, 'PARAMETER VALUE = ', STRTRIM(PARAM2, 2)
  ENDELSE
  ;---------------------------------------------------------------------
  ; PRINT EXPRESSION
  PRINT, '  EXPRESSION:  (OWL ', OPER2, ' ', STRTRIM(PARAM2, 2),')'
  PRINT,''
  ;---------------------------------------------------------------------  
  ; DEFINE OUTPUT FILE
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT OUTPUT FILE')
  WO = WIDGET_OUTFM(BASE, UVALUE='OUTFILE1', /AUTO) 
  RESULT_OUT1 = AUTO_WID_MNG(BASE)
  IF (RESULT_OUT1.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OUTPUT FILE IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  IF ((RESULT_OUT1.OUTFILE1.IN_MEMORY) EQ 1) THEN $
    PRINT, 'OUTPUT TO MEMORY' ELSE PRINT, 'SELECTED OUTPUT FILE: ', RESULT_OUT1.OUTFILE1.NAME
  ;---------------------------------------------------------------------
  ; GET COUNT OF RESULTS
  IF OPER2 EQ 'EQ' THEN COUNT_OWL += (OWL_EXP EQ STRTRIM(PARAM2, 2))
  IF OPER2 EQ 'LE' THEN COUNT_OWL += (OWL_EXP LE STRTRIM(PARAM2, 2))
  IF OPER2 EQ 'LT' THEN COUNT_OWL += (OWL_EXP LT STRTRIM(PARAM2, 2))
  IF OPER2 EQ 'GE' THEN COUNT_OWL += (OWL_EXP GE STRTRIM(PARAM2, 2))
  IF OPER2 EQ 'GT' THEN COUNT_OWL += (OWL_EXP GT STRTRIM(PARAM2, 2))
  ;---------------------------------------------------------------------
  ; GET RESULTS
  OUT += (COUNT_OWL GE 1)
  OWL_EXP_OUT = FIX(OUT)
  ;---------------------------------------------------------------------
  ; SAVE DATA TO OUTPUT
  FNAME = RESULT_OUT1.OUTFILE1.NAME
  ENVI_WRITE_ENVI_FILE, OWL_EXP_OUT, OUT_NAME=FNAME, MAP_INFO=MAP_INFO
  ;---------------------------------------------------------------------
  ; PRINT THE PROCESSING TIME
  PRINT,''
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: OWL_INUNDATION_BY_COUNT_MAPPER'
  PRINT,'' 
END  