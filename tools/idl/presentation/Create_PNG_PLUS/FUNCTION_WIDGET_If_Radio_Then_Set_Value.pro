; ##############################################################################################
; NAME: FUNCTION_WIDGET_If_Radio_Then_Set_Value.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 07/11/2010
; DLM: 18/11/2010
;
; DESCRIPTION:  
;
; INPUT:        
;
; OUTPUT:       
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

;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_If_Radio_Then_Set_Value_Event, EVENT
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
FUNCTION FUNCTION_WIDGET_If_Radio_Then_Set_Value, TITLE=TITLE, LABEL_IF=LABEL_IF, LABEL_THEN=LABEL_THEN, $
  VALUE_IF=VALUE_IF, CNT=CNT, VALUE_THEN=VALUE_THEN, FLOATING=FLOATING, DOUBLE=DOUBLE, INTEGER=INTEGER, $
  LONG=LONG, STRING=STRING
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK PARAMETERS:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_ELEMENTS(LABEL_IF) EQ 0 THEN LABEL_IF = ""
  IF N_ELEMENTS(LABEL_THEN) EQ 0 THEN LABEL_THEN = ""  
  IF N_ELEMENTS(VALUE_IF) EQ 0 THEN VALUE_IF = ""
  IF N_ELEMENTS(VALUE_THEN) EQ 0 THEN VALUE_THEN = ""
  IF N_ELEMENTS(CNT) EQ 0 THEN BEGIN 
    PRINT, 'You Must Set The Conditional Continue "CNT" Parameter' 
    RETURN, !VALUES.F_NAN
  ENDIF
  ;--------------
  ; SET WIDGET SIZE:
  VLENGTH = MAKE_ARRAY(N_ELEMENTS(LABEL_THEN), /INTEGER)
  FOR a=0, N_ELEMENTS(VALUE)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    VLENGTH[a] += STRLEN(VALUE[a])
  ENDFOR
  VMAX = MAX(VLENGTH) ; LENGTH OF THE LONGEST VALUE STRING
  TLENGTH = STRLEN(TITLE) ; LENGTH OF THE TITLE STRING
  LLENGTH = STRLEN(VALUE_THEN) ; LENGTH OF THE LABEL STRING
  SMAX = MAX([VMAX,TLENGTH,LLENGTH]) ; LENGTH OF THE LONGEST INPUT STRING
  IF (SMAX*8 LT 150) OR (SMAX*8 GT 300) THEN XSIZE = 175  ELSE XSIZE = SMAX*8
  ;---------------------------------------------------------------------------------------------
  ; IF WIDGET:
  ;--------------  
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
  IF LABEL_IF NE "" THEN LABEL = WIDGET_LABEL(CHILD, VALUE=LABEL_IF+'  ', /DYNAMIC_RESIZE)
  RADIO = CW_BGROUP(CHILD, VALUE_IF, /ROW, /EXCLUSIVE, /FRAME)
  WIDGET_CONTROL, CHILD, /REALIZE ; ACTIVATE WIDGET SET
  RESULT = WIDGET_EVENT(PARENT)
  RESULT = RESULT.VALUE
  WIDGET_CONTROL, PARENT, /DESTROY
  ;---------------------------------------------------------------------------------------------
  ; THEN WIDGET:
  IF RESULT EQ CNT THEN BEGIN
    ; CREATE GROUPLEADER (TOP LEVEL -MODAL- BASES MUST HAVE A GROUP LEADER)
    GROUPLEADER = WIDGET_BASE(MAP=0)
    WIDGET_CONTROL, GROUPLEADER, /REALIZE
    DESTROY_GROUPLEADER = 1  
    ;--------------
    ; CREATE PARENT WIDGET:
    PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, /MODAL, /BASE_ALIGN_RIGHT)
    CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
    ;--------------
    ; CREATE CHILD WIDGET:
    CHILD = WIDGET_BASE(PARENT, ROW=1)
    IF LABEL_THEN NE "" THEN LABEL = WIDGET_LABEL(CHILD, VALUE=LABEL_THEN+'  ', /DYNAMIC_RESIZE)
    WIDT = WIDGET_TEXT(CHILD, SCR_XSIZE=XSIZE, VALUE=STRING(STRTRIM(VALUE_THEN,2)), /EDITABLE)
    ;--------------
    ; CREATE BUTTON WIDGET:
    BASE_BUTTON = WIDGET_BASE(PARENT, ROW=1)
    WID_BUTTON = WIDGET_BUTTON(BASE_BUTTON, VALUE='OK')
    ;--------------
    CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
    WIDGET_CONTROL, PARENT, /REALIZE ; ACTIVATE WIDGET SET
    PTR = PTR_NEW({OUT:'', CANCEL:1}) ; CREATE POINTER FOR THE USER INFORMATION
    info = {PTR:PTR, WIDT:WIDT} ; CREATE STRUCTURE TO STORE USER INFORMATION
    WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY
    XMANAGER, 'FUNCTION_WIDGET_If_Radio_Then_Set_Value', PARENT ; CALL XMANAGER
    ;-------------------------------------------------------------------------------------------
    ; RETURN USER INFORMATION TO THE MAIN LEVEL PROGRAM:
    OUTPUT = (*PTR).OUT ; GET OUTPUT STRING
    CANCEL = (*PTR).CANCEL ; GET DESTROY STATUS
    PTR_FREE, PTR ; DESTROY POINTER
    IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; DESTROY WIDGETS
    ;-------------------------------------------------------------------------------------------
    ; CONVERT OUTPUT:    
    IF N_ELEMENTS(FLOATING) EQ 1 THEN OUTPUT = FLOAT(OUTPUT)
    IF N_ELEMENTS(DOUBLE) EQ 1 THEN OUTPUT = DOUBLE(OUTPUT)
    IF N_ELEMENTS(INTEGER) EQ 1 THEN OUTPUT = ROUND(OUTPUT)
    IF N_ELEMENTS(LONG) EQ 1 THEN OUTPUT = LONG(OUTPUT)
    ;-------------------------------------------------------------------------------------------  
  ENDIF ELSE OUTPUT = !VALUES.F_NAN  
  ;---------------------------------------------------------------------------------------------
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, OUTPUT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

