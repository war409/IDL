; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Value.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 07/11/2010
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

;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Set_Value_Event, EVENT
  ; THE EVENT HANDLER RESPONDS TO ALL WIDGET EVENTS: 
    ; TEXT IS RECORDED IF THE USER HITS 'OK', RETURN, OR CLOSES THE WIDGET WINDOW
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  ; GET THE USER STRING AND STORE IN THE POINTER:
  WIDGET_CONTROL, info.WIDT, GET_VALUE=OUTPUT
    (*info.PTR).OUT = OUTPUT[0]
    (*info.PTR).CANCEL = 0
  WIDGET_CONTROL, EVENT.top, /DESTROY
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Value, TITLE=TITLE, VALUE=VALUE, LABEL=LABEL, FLOATING=FLOATING, $
  DOUBLE=DOUBLE, INTEGER=INTEGER, LONG=LONG, STRING=STRING 
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK PARAMETERS:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_ELEMENTS(LABEL) EQ 0 THEN LABEL = ""
  IF N_ELEMENTS(VALUE) EQ 0 THEN VALUE = ""
  VALUE = STRING(STRTRIM(VALUE,2))
  IF N_ELEMENTS(STRING) EQ 1 THEN XSIZE = 150 ELSE XSIZE = 110
  ;---------------------------------------------------------------------------------------------
  ; CREATE GROUPLEADER (TOP LEVEL -MODAL- BASES MUST HAVE A GROUP LEADER)
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1  
  ;--------------
  ; CREATE PARENT WIDGET
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, /MODAL, /BASE_ALIGN_RIGHT)
  ;--------------
  ; CREATE CHILD WIDGET
  CHILD = WIDGET_BASE(PARENT, ROW=1)
  IF LABEL NE "" THEN LABEL = WIDGET_LABEL(CHILD, VALUE=LABEL+'  ', /DYNAMIC_RESIZE)
  WIDT = WIDGET_TEXT(CHILD, SCR_XSIZE=XSIZE, VALUE=VALUE, /EDITABLE)
  ;--------------
  ; CREATE BUTTON WIDGET:
  BASE_BUTTON = WIDGET_BASE(PARENT, ROW=1)
  WID_BUTTON = WIDGET_BUTTON(BASE_BUTTON, VALUE='OK')
  ;--------------
  CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
  WIDGET_CONTROL, PARENT, /REALIZE ; ACTIVATE WIDGET SET
  PTR = PTR_NEW({OUT:"", CANCEL:1}) ; CREATE POINTER FOR THE USER INFORMATION
  info = {PTR:PTR, WIDT:WIDT} ; CREATE STRUCTURE TO STORE USER INFORMATION
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY
  XMANAGER, 'FUNCTION_WIDGET_Set_Value', PARENT ; CALL XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ; RETURN USER INFORMATION TO THE MAIN LEVEL PROGRAM:
  OUTPUT = (*PTR).OUT ; GET OUTPUT STRING
  CANCEL = (*PTR).CANCEL ; GET DESTROY STATUS
  PTR_FREE, PTR ; DESTROY POINTER
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; DESTROY WIDGETS
  ;---------------------------------------------------------------------------------------------
  ; CONVERT OUTPUT:
  IF N_ELEMENTS(FLOATING) EQ 1 THEN OUTPUT = FLOAT(OUTPUT)
  IF N_ELEMENTS(DOUBLE) EQ 1 THEN OUTPUT = DOUBLE(OUTPUT)
  IF N_ELEMENTS(INTEGER) EQ 1 THEN OUTPUT = ROUND(OUTPUT)
  IF N_ELEMENTS(LONG) EQ 1 THEN OUTPUT = LONG(OUTPUT)
  ;---------------------------------------------------------------------------------------------  
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, OUTPUT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

