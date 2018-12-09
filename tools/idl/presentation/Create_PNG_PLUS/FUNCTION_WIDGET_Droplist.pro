; ##############################################################################################
; NAME: FUNCTION_WIDGET_Droplist.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 12/10/2010
; DLM: 12/11/2010
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of a 
;               title, label, and a drop down list.
;
; INPUT:        A one dimensional scalar string array containing the droplist values. Optionally,
;               the user may include a title string and/or a label string. A default title sting,
;               'Provide Input' will be used if a user title is not provided.
;
; OUTPUT:       A single long integer that describes the index position of the selected droplist
;               value.
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
PRO FUNCTION_WIDGET_Droplist_Event, EVENT ; This event handler responds to button and droplist events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  EVENTCASE = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  CASE EVENTCASE OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*INFO.PTR).CANCEL = 0 ; Set the cancel value to 0    
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
    'FSC_DROPLIST_EVENT': BEGIN ; Droplist event:
      PRINT, ''
      PRINT, ' Selection: ', *EVENT.SELECTION ; Print the current selection
      (*INFO.PTR).INDEX = EVENT.INDEX ; Update the pointer with the new selection
      WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
    ENDCASE
  ENDCASE  
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Droplist, TITLE=TITLE, VALUE=VALUE, LABEL=LABEL
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1  
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_Elements(TITLE) EQ 0 THEN TITLE = 'Provide Input'
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
  XSIZE = SMAX*8 ; Set the default widget size
  IF (SMAX*8 LT 150) THEN XSIZE = 175 ; Set conditional widget size
  IF (SMAX*8 GT 300) THEN XSIZE = 235 ; Set conditional widget size
  IF (SMAX*8 GT 350) THEN XSIZE = 275 ; Set conditional widget size
  IF (SMAX*8 GT 400) THEN XSIZE = 300  ; Set conditional widget size 
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
  BASE_A = WIDGET_BASE(PARENT, ROW=1)
  IF LABEL NE "" THEN LABEL = LABEL+'  '
  DROPLIST = FSC_DROPLIST(BASE_A, SCR_XSIZE=XSIZE, VALUE=VALUE, TITLE=LABEL, UVALUE=INFO, /DYNAMIC_RESIZE)
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
  PTR = PTR_NEW({INDEX:"", $ ; Droplist index
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure
    DROPLIST:DROPLIST} ; Droplist index
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Droplist', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------  
  ; Get the user information from the pointer:
  OUTPUT = (*PTR).INDEX 
  CANCEL = (*PTR).CANCEL 
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget  
  ;---------------------------------------------------------------------------------------------
  ; Return information:
  IF (LONG(CANCEL) EQ 1) THEN RETURN, -1
  RETURN, LONG(OUTPUT) ; Return the droplist index to the main program level  
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

