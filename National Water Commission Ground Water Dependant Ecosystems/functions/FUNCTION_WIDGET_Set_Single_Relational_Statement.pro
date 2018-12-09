; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Single_Relational_Statement.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 21/05/2011
; DLM: 21/05/2011
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of  
;               1 dropdown widget, 1 text box entry field, and Accept and Cancel buttons.
;               
;               The widget was created for Time_Series_Map_Proportion_By_Relational_Operators_Contiguous.pro
;
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;               
;               DEFAULT: A scalar string containing the default no data value. The value is 
;               converted to a numeric format before it is returned to the user.
;
; OUTPUT:       A two element integer array containing:
; 
;               Output[0]:  The index of the dropdown widget (['EQ','LE','LT','GE','GT','NE']).
;               
;               Output[1]:  The value entered in the text box.
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
PRO FSC_DROPLIST_A, EVENT 
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  PRINT, ''
  PRINT, ' Selection A: ', *EVENT.SELECTION
  PRINT, ' Index Number A: ', EVENT.INDEX
  (*info.PTR).INDEX_A = EVENT.INDEX
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Set_Single_Relational_Statement_Event, EVENT ; This event handler responds to button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info ; Get the info structure from the storage location
  thisEvent = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  CASE thisEvent OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*info.PTR).CANCEL = 0
      WIDGET_CONTROL, info.TEXT_A, GET_VALUE=STRING_A  ; Get the text box string
      (*info.PTR).VALUE_A = STRING_A[0] ; Update pointer with the text box string
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
  ENDCASE   
END
;-----------------------------------------------------------------------------------------------

 
;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Single_Relational_Statement, TITLE=TITLE, DEFAULT=DEFAULT
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
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, ROW=2, TAB_MODE=1, SPACE=2, $
    TLB_FRAME_ATTR=1, /MODAL, /BASE_ALIGN_CENTER, /GRID_LAYOUT)
  ;--------------
  ; Create droplist widget:
  BASE_A = WIDGET_BASE(PARENT, XPAD=25, FRAME=1, XSIZE=180, /ROW) ; Droplist base A
  WIDT_A = FSC_DROPLIST(BASE_A, TITLE='', XSIZE=80, VALUE=['EQ','LE','LT','GE','GT','NE'], EVENT_PRO='FSC_DROPLIST_A', UValue=info)
  ;--------------
  TEXT_A = WIDGET_TEXT(BASE_A, XSIZE=8, VALUE=DEFAULT, /EDITABLE)
  ;--------------
  ; Create button widget:
  BASE_B = WIDGET_BASE(PARENT, XPAD=45, /ROW) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_B, VALUE='Accept', UVALUE='WIDGET_BUTTON')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_B, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX_A:0, $ ; Droplist index
    VALUE_A:DEFAULT, $ ; Text field value
    DEFAULT:DEFAULT, $ ; Default value A
    CANCEL:-1}) ; If CANCEL EQ -1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  info = {PTR:PTR, $ ; Output structure
    BASE_A:BASE_A, $ ; The droplist and text base ID
    BASE_B:BASE_B, $ ; The droplist and text base ID
    WIDT_A:WIDT_A, $ ; Droplist ID A
    TEXT_A:TEXT_A} ; Text A ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Set_Single_Relational_Statement', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX_A = (*PTR).INDEX_A
  VALUE_A = (*PTR).VALUE_A
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------  
  ; Return information to the main program level:
  IF FIX(CANCEL) EQ -1 THEN RETURN, -1 ; If the widget was canceled
  RETURN, [FIX(INDEX_A), FIX(VALUE_A)]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

