; ##############################################################################################
; NAME: FUNCTION_WIDGET_Map_By_Frequency.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 07/04/2011
; DLM: 07/04/2011
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of a 
;               dropdown widget, a text box entry field, and Accept and Cancel buttons.
;               
;               The widget was created for Time_Series_Map_Proportion_By_Relational_Operators.pro
;
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;               
;               DEFAULT: A scalar string containing the default no data value. The value is 
;               converted to a numeric format before it is returned to the user.
;
; OUTPUT:       A two element integer array containing the dropdown index [0] and the user defined 
;               integer [1].
;               
;               If the Cancel button or the close button is selected the return value is -1.
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
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  (*INFO.PTR).CANCEL = -1
  WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill The parent widget
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Map_By_Frequency_Event, EVENT ; This event handler responds to button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info ; Get the info structure from the storage location 
  ;WIDGET_CONTROL, EVENT.id, GET_UVALUE=EVENTCASE ; Get the event name
  thisEvent = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  CASE thisEvent OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*info.PTR).CANCEL = 0
      WIDGET_CONTROL, INFO.TEXT, GET_VALUE=STRING  ; Get the text box string
      (*info.PTR).VALUE = STRING[0] ; Update pointer with the text box string
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
    'FSC_DROPLIST_EVENT': BEGIN
      PRINT, ''
      PRINT, ' Selection: ', *EVENT.SELECTION
      PRINT, ' Index Number: ', EVENT.INDEX
      (*info.PTR).INDEX = EVENT.INDEX
    ENDCASE
  ENDCASE   
END
;-----------------------------------------------------------------------------------------------
  

  
;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Map_By_Frequency, TITLE=TITLE, DEFAULT=DEFAULT
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input:'
  IF N_ELEMENTS(DEFAULT) EQ 0 THEN DEFAULT = '0'
  ;---------------------------------------------------------------------------------------------
  ; Create GROUPLEADER (top level - MODAL - bases must have a group leader):
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1
  ;--------------
  ; Create parent widget:
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, SPACE=5, $
    TLB_FRAME_ATTR=1, /MODAL, /BASE_ALIGN_CENTER)
  ;--------------
  ; Create droplist widget:
  BASE_A = WIDGET_BASE(PARENT, FRAME=1, XSIZE=175, ROW=1) ; Droplist base 
  WIDT = FSC_DROPLIST(BASE_A, TITLE='', SCR_XSIZE=80, VALUE=['EQ','LE','LT','GE','GT','NE'], UValue=info)
  ;--------------
  TEXT = WIDGET_TEXT(BASE_A, XSIZE=13, VALUE=DEFAULT, /EDITABLE)
  ;--------------
  ; Create button widget:
  BASE_B = WIDGET_BASE(PARENT, ROW=1, BASE_ALIGN_RIGHT=1) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_B, VALUE='Accept', UVALUE='WIDGET_BUTTON')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_B, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX:'', $ ; Droplist index
    VALUE:DEFAULT, $ ; No Data value
    DEFAULT:DEFAULT, $ ; Default No Data value
    CANCEL:-1}) ; If CANCEL EQ -1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  info = {PTR:PTR, $ ; Output structure
    BASE_A:BASE_A, $ ; The droplist and text base ID
    BASE_B:BASE_B, $ ; The button widget base ID
    WIDT:WIDT, $ ; Droplist ID
    TEXT:TEXT} ; Text ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Map_By_Frequency', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX = (*PTR).INDEX
  VALUE = (*PTR).VALUE
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------  
  ; Return information to the main program level:
  IF FIX(CANCEL) EQ -1 THEN RETURN, -1 ; If the widget was canceled
  RETURN, [FIX(INDEX), FIX(VALUE)]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************
  
  