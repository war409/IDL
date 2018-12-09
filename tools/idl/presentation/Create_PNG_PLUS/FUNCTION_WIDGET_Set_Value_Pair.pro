; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Value_Pair.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 18/11/2010
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
PRO FUNCTION_WIDGET_Set_Value_Pair_Event, EVENT
  ; THE EVENT HANDLER RESPONDS TO ALL WIDGET EVENTS: 
    ; TEXT IS RECORDED IF THE USER HITS 'OK', RETURN, OR CLOSES THE WIDGET WINDOW
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  ; GET THE USER STRING AND STORE IN THE POINTER:
  WIDGET_CONTROL, info.WIDT_A, GET_VALUE=OUTPUT
    (*info.PTR).OUT_A = OUTPUT[0]
    (*info.PTR).CANCEL = 0
  WIDGET_CONTROL, info.WIDT_B, GET_VALUE=OUTPUT
    (*info.PTR).OUT_B = OUTPUT[0]
    (*info.PTR).CANCEL = 0 
  WIDGET_CONTROL, EVENT.top, /DESTROY
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Value_Pair, TITLE=TITLE, VALUE_A=VALUE_A, VALUE_B=VALUE_B, LABEL_A=LABEL_A, $
  LABEL_B=LABEL_B, FLOATING=FLOATING, DOUBLE=DOUBLE, INTEGER=INTEGER, LONG=LONG, STRING=STRING 
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK PARAMETERS:
  IF N_Elements(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_Elements(LABEL_A) EQ 0 THEN LABEL_A = ""
  IF N_Elements(LABEL_B) EQ 0 THEN LABEL_B = ""
  IF N_Elements(VALUE_A) EQ 0 THEN VALUE_A = ""
  IF N_Elements(VALUE_B) EQ 0 THEN VALUE_B = ""
  VALUE_A = STRING(STRTRIM(VALUE_A,2))
  VALUE_B = STRING(STRTRIM(VALUE_B,2))
  ;--------------
  ; SET WIDGET SIZE:
  TLENGTH = STRLEN(TITLE) ; LENGTH OF THE TITLE STRING
  VALENGTH = STRLEN(VALUE_A) ; LENGTH OF THE LONGEST VALUE STRING
  VBLENGTH = STRLEN(VALUE_B) ; LENGTH OF THE LONGEST VALUE STRING
  LALENGTH = STRLEN(LABEL_A) ; LENGTH OF THE LABEL STRING
  LBLENGTH = STRLEN(LABEL_B) ; LENGTH OF THE LABEL STRING
  SMAX = MAX([TLENGTH,VALENGTH,VBLENGTH,LALENGTH,LBLENGTH]) ; LENGTH OF THE LONGEST INPUT STRING
  IF N_ELEMENTS(STRING) EQ 1 THEN BEGIN 
    IF (SMAX*8 LT 150) OR (SMAX*8 GT 300) THEN XSIZE = 175  ELSE XSIZE = SMAX*8
  ENDIF ELSE XSIZE = 60+TLENGTH*2
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
  CHILD_A = WIDGET_BASE(PARENT, ROW=1)
  CHILD_B = WIDGET_BASE(PARENT, ROW=1)
  IF LABEL_A NE "" THEN LABEL = WIDGET_LABEL(CHILD_A, VALUE=LABEL_A+'  ', /DYNAMIC_RESIZE)
  IF LABEL_B NE "" THEN LABEL = WIDGET_LABEL(CHILD_B, VALUE=LABEL_B+'  ', /DYNAMIC_RESIZE)
  WIDT_A = WIDGET_TEXT(CHILD_A, SCR_XSIZE=XSIZE, VALUE=VALUE_A, /EDITABLE)
  WIDT_B = WIDGET_TEXT(CHILD_B, SCR_XSIZE=XSIZE, VALUE=VALUE_B, /EDITABLE)
  ;--------------
  ; CREATE BUTTON WIDGET:
  BASE_BUTTON = WIDGET_BASE(PARENT, ROW=1)
  WID_BUTTON = WIDGET_BUTTON(BASE_BUTTON, VALUE='OK')
  ;--------------
  CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
  WIDGET_CONTROL, PARENT, /REALIZE ; ACTIVATE WIDGET SET
  PTR = PTR_NEW({OUT_A:"",OUT_B:"",CANCEL:1}) ; CREATE POINTER FOR THE USER INFORMATION
  info = {PTR:PTR, WIDT_A:WIDT_A,WIDT_B:WIDT_B} ; CREATE STRUCTURE TO STORE USER INFORMATION
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY
  XMANAGER, 'FUNCTION_WIDGET_Set_Value_Pair', PARENT ; CALL XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ; RETURN USER INFORMATION TO THE MAIN LEVEL PROGRAM:
  OUTPUT_A = (*PTR).OUT_A ; GET OUTPUT STRING
  OUTPUT_B = (*PTR).OUT_B ; GET OUTPUT STRING
  CANCEL = (*PTR).CANCEL ; GET DESTROY STATUS
  PTR_FREE, PTR ; DESTROY POINTER
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; DESTROY WIDGETS
  ;---------------------------------------------------------------------------------------------
  ; CONVERT OUTPUT:
  IF N_ELEMENTS(FLOATING) EQ 1 THEN OUTPUT_A = FLOAT(OUTPUT_A)
  IF N_ELEMENTS(DOUBLE) EQ 1 THEN OUTPUT_A = DOUBLE(OUTPUT_A)
  IF N_ELEMENTS(INTEGER) EQ 1 THEN OUTPUT_A = ROUND(OUTPUT_A)
  IF N_ELEMENTS(LONG) EQ 1 THEN OUTPUT_A = LONG(OUTPUT_A)
  IF N_ELEMENTS(FLOATING) EQ 1 THEN OUTPUT_B = FLOAT(OUTPUT_B)
  IF N_ELEMENTS(DOUBLE) EQ 1 THEN OUTPUT_B = DOUBLE(OUTPUT_B)
  IF N_ELEMENTS(INTEGER) EQ 1 THEN OUTPUT_B = ROUND(OUTPUT_B)
  IF N_ELEMENTS(LONG) EQ 1 THEN OUTPUT_B = LONG(OUTPUT_B)
  ;---------------------------------------------------------------------------------------------  
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, [OUTPUT_A, OUTPUT_B] 
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

