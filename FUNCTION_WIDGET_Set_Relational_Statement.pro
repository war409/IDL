; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Relational_Statement.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 07/04/2011
; DLM: 08/04/2011
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of  
;               3 dropdown widgets, 2 text box entry fields, and Accept and Cancel buttons.
;               
;               The third dropdown widget and the second text box entry field will appear and
;               disappear depending on the value selected in the second dropdown widget. 
;               
;               The widget was created for Time_Series_Map_Proportion_By_Relational_Operators.pro
;
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;               
;               DEFAULT: A scalar string containing the default no data value. The value is 
;               converted to a numeric format before it is returned to the user.
;
; OUTPUT:       A five element integer array containing:
; 
;               Output[0]:  The index of the first dropdown widget (['EQ','LE','LT','GE','GT','NE']).
;               
;               Output[1]:  The value entered in the first text box.
;               
;               Output[2]:  The index of the second dropdown widget (['---','AND','OR']).
;               
;               Output[3]:  The index of the third dropdown widget (['EQ','LE','LT','GE','GT','NE']).
;               
;               Output[4]:  The value entered in the second text box.
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
PRO FSC_DROPLIST_A, EVENT ; This event handler responds to the Cancel button event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  PRINT, ''
  PRINT, ' Selection A: ', *EVENT.SELECTION
  PRINT, ' Index Number A: ', EVENT.INDEX
  (*info.PTR).INDEX_A = EVENT.INDEX
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FSC_DROPLIST_B, EVENT ; This event handler responds to the Cancel button event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info, /NO_COPY
  PRINT, ''
  PRINT, ' Selection B: ', *EVENT.SELECTION
  PRINT, ' Index Number B: ', EVENT.INDEX
  ;--------------
  IF EVENT.INDEX EQ 0 THEN BEGIN ; '---'
    IF (*info.PTR).INDEX_B NE -1 THEN BEGIN
      WIDGET_CONTROL, info.TEXT_B, /DESTROY ; Kill widget
      WIDGET_CONTROL, info.BASE_X, /DESTROY ; Kill widget
      info.WIDT_C = info.WIDT_B ; Reset info structure element back to its defualt
      info.TEXT_B = -1 ; Reset info structure element back to its defualt  
      info.BASE_X = -1
      (*info.PTR).INDEX_B = -1
      (*info.PTR).INDEX_C = -1
    ENDIF
  ENDIF
  ;-------------- 
  IF (EVENT.INDEX EQ 1) OR (EVENT.INDEX EQ 2)  THEN BEGIN ; 'AND' or 'OR'
    IF (*info.PTR).INDEX_B NE -1 THEN BEGIN
      WIDGET_CONTROL, info.TEXT_B, /DESTROY ; Kill widget
      WIDGET_CONTROL, info.BASE_X, /DESTROY ; Kill widget
      info.WIDT_C = info.WIDT_B ; Reset info structure element back to its defualt
      info.TEXT_B = -1 ; Reset info structure element back to its defualt  
      info.BASE_X = -1
      (*info.PTR).INDEX_B = -1
      (*info.PTR).INDEX_C = -1
    ENDIF
    BASE_X = WIDGET_BASE(info.BASE_B, /ROW) ; Droplist base 
    WIDT_C = FSC_DROPLIST(BASE_X, TITLE='',XSIZE=80, VALUE=['EQ','LE','LT','GE','GT','NE'], EVENT_PRO='FSC_DROPLIST_C')
    TEXT_B = WIDGET_TEXT(BASE_X, XSIZE=8, VALUE=((*info.PTR).DEFAULT_B), /EDITABLE)
    info.BASE_X = BASE_X
    info.WIDT_C = WIDT_C
    info.TEXT_B = TEXT_B
    (*info.PTR).INDEX_B = EVENT.INDEX
  ENDIF 
  ;--------------
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=info, /NO_COPY
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FSC_DROPLIST_C, EVENT ; This event handler responds to the Cancel button event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info
  PRINT, ''
  PRINT, ' Selection C: ', *EVENT.SELECTION
  PRINT, ' Index Number C: ', EVENT.INDEX
  (*info.PTR).INDEX_C = EVENT.INDEX
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Set_Relational_Statement_Event, EVENT ; This event handler responds to button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=info ; Get the info structure from the storage location
  thisEvent = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  CASE thisEvent OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*info.PTR).CANCEL = 0
      WIDGET_CONTROL, info.TEXT_A, GET_VALUE=STRING_A  ; Get the text box string
      (*info.PTR).VALUE_A = STRING_A[0] ; Update pointer with the text box string
      IF info.TEXT_B NE -1 THEN BEGIN
        WIDGET_CONTROL, info.TEXT_B, GET_VALUE=STRING_B  ; Get the text box string
        (*info.PTR).VALUE_B = STRING_B[0] ; Update pointer with the text box string
      ENDIF ELSE (*info.PTR).VALUE_B = -1
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
  ENDCASE   
END
;-----------------------------------------------------------------------------------------------

 
;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Relational_Statement, TITLE=TITLE, DEFAULT_A=DEFAULT_A, DEFAULT_B=DEFAULT_B 
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input:'
  IF N_ELEMENTS(DEFAULT_A) EQ 0 THEN DEFAULT_A = '0'
  IF N_ELEMENTS(DEFAULT_B) EQ 0 THEN DEFAULT_B = '0'
  ;---------------------------------------------------------------------------------------------
  ; Create GROUPLEADER (top level - MODAL - bases must have a group leader):
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1
  ;--------------
  ; Create parent widget:
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, ROW=3, TAB_MODE=1, SPACE=2, $
    TLB_FRAME_ATTR=1, /MODAL, /BASE_ALIGN_CENTER, /GRID_LAYOUT)
  ;--------------
  ; Create droplist widget:
  BASE_A = WIDGET_BASE(PARENT, FRAME=1, XSIZE=205, /ROW) ; Droplist base A
  WIDT_A = FSC_DROPLIST(BASE_A, TITLE='', XSIZE=80, VALUE=['EQ','LE','LT','GE','GT','NE'], EVENT_PRO='FSC_DROPLIST_A', UValue=info)
  ;--------------
  TEXT_A = WIDGET_TEXT(BASE_A, XSIZE=8, VALUE=DEFAULT_A, /EDITABLE)
  WIDT_B = FSC_DROPLIST(BASE_A, TITLE='', XSIZE=57, VALUE=['---','AND','OR'], EVENT_PRO='FSC_DROPLIST_B', UValue=info)
  ;--------------
  BASE_B = WIDGET_BASE(PARENT, FRAME=1, XPAD=25, XSIZE=205, YSIZE=33, /ROW) ; Droplist base B
  ;--------------
  ; Create button widget:
  BASE_C = WIDGET_BASE(PARENT, XPAD=45, /ROW) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_C, VALUE='Accept', UVALUE='WIDGET_BUTTON')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_C, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX_A:0, $ ; Droplist index
    INDEX_B:-1, $ ; Droplist index
    INDEX_C:0, $ ; Droplist index
    VALUE_A:DEFAULT_A, $ ; Text field value
    VALUE_B:DEFAULT_B, $ ; Text field value    
    DEFAULT_A:DEFAULT_A, $ ; Default value A
    DEFAULT_B:DEFAULT_B, $ ; Default value B
    CANCEL:-1}) ; If CANCEL EQ -1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  info = {PTR:PTR, $ ; Output structure
    BASE_A:BASE_A, $ ; The droplist and text base ID
    BASE_B:BASE_B, $ ; The droplist and text base ID
    BASE_C:BASE_C, $ ; The button widget base ID
    BASE_X:"", $
    WIDT_A:WIDT_A, $ ; Droplist ID A
    WIDT_B:WIDT_B, $ ; Droplist ID B
    WIDT_C:WIDT_B, $ ; Droplist ID C
    TEXT_A:TEXT_A, $ ; Text A ID
    TEXT_B:TEXT_A}   ; Text B ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=info, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Set_Relational_Statement', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX_A = (*PTR).INDEX_A
  INDEX_B = (*PTR).INDEX_B
  INDEX_C = (*PTR).INDEX_C
  VALUE_A = (*PTR).VALUE_A
  VALUE_B = (*PTR).VALUE_B
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------  
  ; Return information to the main program level:
  IF FIX(CANCEL) EQ -1 THEN RETURN, -1 ; If the widget was canceled
  RETURN, [FIX(INDEX_A), FIX(VALUE_A), FIX(INDEX_B), FIX(INDEX_C), FIX(VALUE_B)]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************
  
