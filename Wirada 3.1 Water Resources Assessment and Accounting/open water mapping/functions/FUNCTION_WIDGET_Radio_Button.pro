; ##############################################################################################
; NAME: FUNCTION_WIDGET_Radio_Button.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This function opens an IDL radio button widget.
; 
;               For example, say the input vector is set as ['MEAN', 'MEDIAN', 'MIN', 'MAX', 'SUM'] 
;               if the user selects 'MEAN' the output would be the integer 0, if the user selects
;               'MEDIAN' the output would be 1, if the user selects 'MIN' the output would be 2,
;               and so on.  
;
; INPUT:        TITLE: A scalar string containing the widget title.
; 
;               VALUES: A vector containing the values to be printed next to each radio button. The
;               function will create one radio button per input in the variable VALUES.
;
; OUTPUT:       An integer containing the position of the selected value is returned to the
;               program that called the function.
;               
; NOTES:        
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Radio_Button, TITLE, VALUES
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; SET WIDGET XSIZE
  VL = MAKE_ARRAY(1, N_ELEMENTS(VALUES)+1, /STRING)
  FOR v=0, N_ELEMENTS(VALUES) DO BEGIN
    IF v LT N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(VALUES[v])
    IF v EQ N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(TITLE[0])
  ENDFOR
  XSIZE = MAX(VL)*6
  ;---------------------------------------------------------------------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; REPEAT STATEMENT
  ;-----------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE, /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP=TITLE, /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT_TMP = WIDGET_EVENT(BASE)
  RESULT = RESULT_TMP.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;--------------
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END REPEAT STATEMENT
  ;--------------------------------------------------------------------------------------------- 
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, RESULT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

