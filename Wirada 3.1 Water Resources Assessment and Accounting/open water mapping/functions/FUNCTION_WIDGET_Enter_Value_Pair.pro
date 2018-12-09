; ##############################################################################################
; NAME: FUNCTION_WIDGET_Enter_Value_Pair.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 18/10/2010
; DLM: 20/10/2010
;
; DESCRIPTION:  This function opens an IDL data entry widget. The widget consists of a label (title
;               main), two sub-labels (title a & title b), two data entry fields (one per label),  
;               and an OK button.
;
; INPUT:        TITLE_MAIN: A scalar string containing the widget title.
; 
;               TITLE_A: A scalar string containing the title for the first data entry field.
;               
;               TITLE_B: A scalar string containing the title for the second data entry field.
; 
;               DEFAULT_A: An integer, float, or double precision float containing the default
;               value for data entry field A.
;               
;               DEFAULT_B: An integer, float, or double precision float containing the default
;               value for data entry field B.           
;
; OUTPUT:       A double precision floating point array that contains the user defined values 
;               is returned to the program that called the function. Pos 0 contains the value
;               entered into field A; Pos 1 contains the value entered into field B.
;               
; NOTES:        The user must hit return (the 'Enter' key) in each data entry field to 'register'
;               the entered values. After which the user may hit the OK button to close the widget 
;               and return the entered values to the main program. 
;               
;               After hitting the 'Enter' key the current value is registered and cannot be 
;               changed; if the user enters a new value and again hits return IDL will use the 
;               original.
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Enter_Value_Pair, TITLE_MAIN, TITLE_A, TITLE_B, DEFAULT_A, DEFAULT_B
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;--------------------------------------------------------------------------------------------
  ; SET WIDGET XSIZE
  LIST = [STRLEN(TITLE_MAIN[0]),STRLEN(TITLE_A[0]),STRLEN(TITLE_B[0])]
  ORDER = LIST[SORT(LIST)]
  XSIZE = ORDER[2]*10
  ;---------------------------------------------------------------------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; REPEAT STATEMENT
  ;------------------------------------
  ; SET PARENT:
  PARENT = WIDGET_BASE(TITLE=TITLE_MAIN, TAB_MODE=2, XSIZE=XSIZE, /COLUMN, /GRID_LAYOUT)
  WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
  ;--------------  
  ; SET CHILD:
  CHILD = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)  
  ;--------------  
  BASE_A = WIDGET_BASE(CHILD, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
    FIELD_A = CW_FIELD(BASE_A, XSIZE=10, VALUE=DOUBLE(DEFAULT_A),   TITLE=TITLE_A, /RETURN_EVENTS)  
  BASE_B = WIDGET_BASE(CHILD, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
    FIELD_B = CW_FIELD(BASE_B, XSIZE=10, VALUE=DOUBLE(DEFAULT_B), TITLE=TITLE_B, /RETURN_EVENTS)
  ;--------------
  BUTTON_BASE = WIDGET_BASE(CHILD, XPAD=1, YPAD=2, /COLUMN, /ALIGN_LEFT)
    OK = CW_BGROUP(BUTTON_BASE, ['OK'], /RETURN_NAME)
  ;--------------  
  ; REALIZE WIDGET
  WIDGET_CONTROL, BASE_A, /REALIZE
    RESULT_A = WIDGET_EVENT(BASE_A)
    VALUE_A = RESULT_A.VALUE
    A = VALUE_A[0]
  WIDGET_CONTROL, BASE_B, /REALIZE
    RESULT_B = WIDGET_EVENT(BASE_B)
    VALUE_B = RESULT_B.VALUE
    B = VALUE_B[0]
  ;--------------  
  ; REALIZE BUTTON    
  BUTTON_RESULT = WIDGET_EVENT(BUTTON_BASE)
  BUTTON_VALUE = BUTTON_RESULT.VALUE
  IF BUTTON_VALUE EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
  ;--------------
  ; ERROR CHECK:
  IF (A EQ '') OR (B EQ '') THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF ELSE CHECK_P = 0
  ;-----------------------------------  
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [DOUBLE(A), DOUBLE(B)]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

