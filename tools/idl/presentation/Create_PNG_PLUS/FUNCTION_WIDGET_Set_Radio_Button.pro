; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Radio_Button.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/10/2010
; DLM: 18/11/2010
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
;               VALUE: A vector containing the values to be printed next to each radio button. The
;               function will create one radio button per input in the variable VALUES.
;
; OUTPUT:       An integer containing the position of the selected value is returned to the
;               program that called the function.
;               
; NOTES:        
;
; ##############################################################################################

;-----------------------------------------------------------------------------------------------
PRO CENTRE_WIDGET, PARENT
  ; CENTRE THE PARENT WIDGET ON THE USERS DISPLAY
  DEVICE, GET_SCREEN_SIZE=SSIZE
  XCENTRE = SSIZE(0)/2
  YCENTRE = SSIZE(1)/2
  GEOM =  WIDGET_INFO(PARENT, /GEOMETRY)
  XHALF = GEOM.SCR_XSIZE/2
  YHALF = GEOM.SCR_YSIZE/2
  WIDGET_CONTROL, PARENT, XOFFSET=(XCENTRE-XHALF), YOFFSET=(YCENTRE-YHALF)
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Radio_Button, TITLE=TITLE, LABEL=LABEL, VALUE=VALUE
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK PARAMETERS:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Radio Button Widget'
  IF N_ELEMENTS(LABEL) EQ 0 THEN LABEL = ""  
  IF N_ELEMENTS(VALUE) EQ 0 THEN BEGIN 
    PRINT, 'You Must Set The Value Parameter' 
    RETURN, !VALUES.F_NAN
  ENDIF
  ;--------------
  ; SET WIDGET SIZE:
  VLENGTH = MAKE_ARRAY(N_ELEMENTS(VALUE), /INTEGER)
  FOR a=0, N_ELEMENTS(VALUE)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    VLENGTH[a] += STRLEN(VALUE[a])
  ENDFOR
  VMAX = MAX(VLENGTH) ; LENGTH OF THE LONGEST VALUE STRING
  TLENGTH = STRLEN(TITLE) ; LENGTH OF THE TITLE STRING
  LLENGTH = STRLEN(LABEL) ; LENGTH OF THE LABEL STRING
  SMAX = MAX([VMAX,TLENGTH,LLENGTH]) ; LENGTH OF THE LONGEST INPUT STRING
  IF (SMAX*8 LT 150) OR (SMAX*8 GT 300) THEN XSIZE = 175  ELSE XSIZE = SMAX*8
  ;---------------------------------------------------------------------------------------------
  ; CREATE GROUPLEADER (TOP LEVEL -MODAL- BASES MUST HAVE A GROUP LEADER)
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1  
  ;--------------
  ; CREATE PARENT WIDGET:
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, /MODAL, /BASE_ALIGN_LEFT, /ALIGN_LEFT)
  CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
  ;--------------
  ; CREATE CHILD WIDGET
  CHILD = WIDGET_BASE(PARENT, ROW=1)
  IF LABEL NE "" THEN LABEL = WIDGET_LABEL(CHILD, VALUE=LABEL+'  ', /DYNAMIC_RESIZE)
  RADIO = CW_BGROUP(CHILD, VALUE, /ROW, /EXCLUSIVE, /FRAME)
  WIDGET_CONTROL, CHILD, /REALIZE ; ACTIVATE WIDGET SET
  RESULT = WIDGET_EVENT(PARENT)
  RESULT = RESULT.VALUE
  WIDGET_CONTROL, PARENT, /DESTROY
  ;--------------------------------------------------------------------------------------------- 
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, RESULT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

