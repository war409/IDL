; ##############################################################################################
; NAME: FUNCTION_WIDGET_Enter_String.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This function opens an IDL data entry widget. The widget consists of a label (title)
;               and a text field.
;
; INPUT:        TITLE: A scalar string containing the widget title.
; 
;               DEFAULT_VALUE: A scalar string containing the default string.
;
; OUTPUT:       A scalar string variable containing the user defined string is returned to the
;               program that called the function.
;               
; NOTES:        The user must hit return (the 'Enter' key) to close the widget and return the
;               value to the main program.
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Enter_String, TITLE, DEFAULT_VALUE
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; SET WIDGET XSIZE
  XSIZE = STRLEN(TITLE[0])*9
  ;---------------------------------------------------------------------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; REPEAT STATEMENT
  ;-----------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE)
  FIELD = CW_FIELD(BASE, XSIZE=23, VALUE=DEFAULT_VALUE, TITLE=TITLE, /RETURN_EVENTS, /STRING)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESULT_TMP = RESULT.VALUE
  RESULT = RESULT_TMP[0]
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