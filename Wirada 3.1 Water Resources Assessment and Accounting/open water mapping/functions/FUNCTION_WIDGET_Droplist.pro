; ##############################################################################################
; NAME: FUNCTION_WIDGET_Droplist.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 31/10/2010
; DLM: 08/11/2010
;
; DESCRIPTION:  This function opens an IDL data entry widget. The widget consists of a label (title)
;               and a drop down list.
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
PRO FUNCTION_WIDGET_Set_Value_Event, EVENT
  ; THE EVENT HANDLER RESPONDS TO ALL WIDGET EVENTS: 
    ; TEXT IS RECORDED IF THE USER HITS 'OK', RETURN, OR CLOSES THE WIDGET WINDOW
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  thisEvent = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; GET EVENT
  CASE thisEvent OF
    'FSC_DROPLIST_EVENT': BEGIN
      PRINT, ''
      PRINT, ' Selection: ', *EVENT.SELECTION
      PRINT, ' Index Number: ', EVENT.INDEX
      (*info.PTR).INDEX = EVENT.INDEX
      (*info.PTR).CANCEL = 0
    ENDCASE
    'WIDGET_BUTTON': BEGIN
      WIDGET_CONTROL, EVENT.top, /DESTROY    
    ENDCASE
  ENDCASE  
END
;-----------------------------------------------------------------------------------------------

;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Value, TITLE=TITLE, VALUE=VALUE, LABEL=LABEL
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; CHECK PARAMETERS:
  IF N_Elements(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_Elements(LABEL) EQ 0 THEN LABEL = ""
  IF N_Elements(VALUE) EQ 0 THEN VALUE = ""
  XSIZE = STRLEN(TITLE[0])*10
  ;---------------------------------------------------------------------------------------------
  ; CREATE GROUPLEADER (TOP LEVEL -MODAL- BASES MUST HAVE A GROUP LEADER)
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1  
  ;--------------
  ; CREATE PARENT WIDGET
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, /MODAL, /BASE_ALIGN_RIGHT)
  ;--------------
  ; CREATE CHILD WIDGET
  CHILD = WIDGET_BASE(PARENT, ROW=1)
  IF LABEL NE "" THEN LABEL = LABEL+'  '
  WIDT = FSC_DROPLIST(CHILD, SCR_XSIZE=(XSIZE+STRLEN(LABEL[0])), VALUE=VALUE, TITLE=LABEL, UValue=info)
  ;--------------
  ; CREATE BUTTON WIDGET:
  BASE_BUTTON = WIDGET_BASE(PARENT, ROW=1)
  WID_BUTTON = WIDGET_BUTTON(BASE_BUTTON, VALUE='OK')
  ;--------------
  CENTRE_WIDGET, PARENT ; CENTRE THE PARENT WIDGET
  WIDGET_CONTROL, PARENT, /REALIZE ; ACTIVATE WIDGET SET
  PTR = PTR_NEW({INDEX:"", CANCEL:1}) ; CREATE POINTER FOR THE USER INFORMATION
  info = {PTR:PTR, WIDT:WIDT} ; CREATE STRUCTURE TO STORE USER INFORMATION
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY
  XMANAGER, 'FUNCTION_WIDGET_Set_Value', PARENT ; CALL XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ; RETURN USER INFORMATION TO THE MAIN LEVEL PROGRAM:
  OUTPUT = (*PTR).INDEX ; GET OUTPUT STRING
  CANCEL = (*PTR).CANCEL ; GET DESTROY STATUS
  PTR_FREE, PTR ; DESTROY POINTER
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; DESTROY WIDGETS
  ;---------------------------------------------------------------------------------------------
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, LONG(OUTPUT)
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

