; ##############################################################################################
; NAME: FUNCTION_WIDGET_Checklist.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 08/03/2011
; DLM: 18/03/2011
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of a 
;               title, label, and a check list.
;
; INPUT:        
;
; OUTPUT:       
;               
; NOTES:        For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


;-----------------------------------------------------------------------------------------------
PRO CENTRE_WIDGET, PARENT ; Centre the parent widget:
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
PRO EVENT_CANCEL, EVENT ; This event handler responds to the Cancel button event:
  WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill The parent widget
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
FUNCTION CHECKBOX_EVENT, EVENT ; This event handler responds to radio button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, EVENT.id, GET_UVALUE=EVENTS ; Get the list of possible events
  EVENTVALUE = EVENT.VALUE ; Set the current event
  CASE EVENTVALUE OF
    0: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_0 = 1 ELSE (*INFO.PTR).Index_0 = 0
    ENDCASE
    1: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_1 = 1 ELSE (*INFO.PTR).Index_1 = 0
    ENDCASE
    2: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_2 = 1 ELSE (*INFO.PTR).Index_2 = 0
    ENDCASE    
    3: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_3 = 1 ELSE (*INFO.PTR).Index_3 = 0
    ENDCASE
    4: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_4 = 1 ELSE (*INFO.PTR).Index_4 = 0
    ENDCASE 
    5: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_5 = 1 ELSE (*INFO.PTR).Index_5 = 0
    ENDCASE 
    6: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_6 = 1 ELSE (*INFO.PTR).Index_6 = 0
    ENDCASE
    7: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_7 = 1 ELSE (*INFO.PTR).Index_7 = 0
    ENDCASE
    8: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_8 = 1 ELSE (*INFO.PTR).Index_8 = 0
    ENDCASE
    9: BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).Index_9 = 1 ELSE (*INFO.PTR).Index_9 = 0
    ENDCASE
  ENDCASE
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Checklist_Event, EVENT ; This event handler responds to button and droplist events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  EVENTCASE = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  CASE EVENTCASE OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*INFO.PTR).CANCEL = 0 ; Set the cancel value to 0    
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE  
  ENDCASE
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Checklist, TITLE=TITLE, VALUE=VALUE, LABEL=LABEL
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1  
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_Elements(LABEL) EQ 0 THEN LABEL = ""
  IF N_ELEMENTS(VALUE) EQ 0 THEN RETURN, -1
  ;--------------
  ; Set widget size:
  VLENGTH = MAKE_ARRAY(N_ELEMENTS(VALUE), /INTEGER)
  FOR a=0, N_ELEMENTS(VALUE)-1 DO BEGIN
    VLENGTH[a] += STRLEN(VALUE[a]) ; Get the a-th value length
  ENDFOR
  VMAX = MAX(VLENGTH) ; Set the length of the longest value string
  TLENGTH = STRLEN(TITLE) ; Set the length of the title string
  LLENGTH = STRLEN(LABEL) ; Set the length of the label string
  SMAX = MAX([VMAX,TLENGTH,LLENGTH]) ; Set the length of the longest input string
  XSIZE = SMAX*7 ; Set the default widget size
  IF (SMAX*7 LT 100) THEN XSIZE = 125 ; Set conditional widget size
  IF (SMAX*7 GT 200) THEN XSIZE = 150 ; Set conditional widget size
  IF (SMAX*7 GT 250) THEN XSIZE = 200 ; Set conditional widget size
  IF (SMAX*7 GT 350) THEN XSIZE = 275  ; Set conditional widget size 
  ;---------------------------------------------------------------------------------------------
  ; Create GROUPLEADER (top level - MODAL - bases must have a group leader):
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1
  ;--------------
  ; Create parent widget:
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, SPACE=5, /MODAL, /BASE_ALIGN_RIGHT)
  ;--------------
  ; Create child widget:
  LABEL_STRING_gap = WIDGET_LABEL(PARENT, VALUE=' ', YSIZE=3)
  LABEL_STRING = WIDGET_LABEL(PARENT, VALUE=' ' + LABEL, YSIZE=13, /ALIGN_LEFT)
  BASE_A = WIDGET_BASE(PARENT, ROW=1)
  ; Checkbox widget
  CHECKBOX = CW_BGROUP(BASE_A, VALUE, XSIZE=XSIZE, UVALUE=VALUE, FRAME=1, EVENT_FUNCT='CHECKBOX_EVENT', /NONEXCLUSIVE)
  ;--------------
  ; Create button widget:
  BASE_B = WIDGET_BASE(PARENT, ROW=1) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_B, VALUE='Accept')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_B, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({Index_0:"", $ ; Checkbox index
    Index_1:"", $ ; Checkbox index
    Index_2:"", $ ; Checkbox index
    Index_3:"", $ ; Checkbox index
    Index_4:"", $ ; Checkbox index
    Index_5:"", $ ; Checkbox index
    Index_6:"", $ ; Checkbox index
    Index_7:"", $ ; Checkbox index
    Index_8:"", $ ; Checkbox index    
    Index_9:"", $ ; Checkbox index
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure
    CHECKBOX:CHECKBOX} ; Checkbox ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Checklist', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------  
  ; Get the user information from the pointer:
  Index_0 = (*PTR).Index_0
  Index_1 = (*PTR).Index_1
  Index_2 = (*PTR).Index_2
  Index_3 = (*PTR).Index_3
  Index_4 = (*PTR).Index_4
  Index_5 = (*PTR).Index_5
  Index_6 = (*PTR).Index_6
  Index_7 = (*PTR).Index_7
  Index_8 = (*PTR).Index_8
  Index_9 = (*PTR).Index_9
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget  
  ;---------------------------------------------------------------------------------------------
  ; Return information:
  IF (LONG(CANCEL) EQ 1) THEN RETURN, -1
  RETURN, [LONG(Index_0), LONG(Index_1), LONG(Index_2), LONG(Index_3), LONG(Index_4), LONG(Index_5), $
    LONG(Index_6), LONG(Index_7), LONG(Index_8), LONG(Index_9)] ; Return index
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

