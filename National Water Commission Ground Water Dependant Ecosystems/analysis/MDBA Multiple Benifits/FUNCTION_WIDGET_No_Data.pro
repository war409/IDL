; ##############################################################################################
; NAME: FUNCTION_WIDGET_No_Data.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 13/12/2010
; DLM: 15/12/2010
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of a 
;               radio button widget, a text box entry field, and Accept and Cancel buttons.
;               
;               The widget has been created to get the user defined no data status and if needed 
;               return the user defined no data value to the main level procedure.
;               
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;               
;               DEFAULT: A scalar string containing the default no data value. The value is 
;               converted to a numeric format before it is returned to the user.
;               
;               The user may include one of the following exclusive keywords:
;               
;               /FLOATING
;               /DOUBLE
;               /INTEGER
;               /LONG
;
;               The user defined value is converted to the selected format before it is returned
;               to the user. If a format keyword is not included in the call statement the default
;               format is Long Integer (LONG).
;
; OUTPUT:       A two element array containing the Cancel status and user defined no data value 
;               is returned to the program that called the function.
;               
;               If the Cancel button or the close button is selected, or the radio button option -
;               'Do Not Set a Grid Value to NaN' is selected. The return value is -1.
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
PRO FUNCTION_WIDGET_No_Data_Event, EVENT ; This event handler responds to button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location 
  WIDGET_CONTROL, EVENT.id, GET_UVALUE=EVENTCASE ; Get the event name
  CASE EVENTCASE OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*INFO.PTR).CANCEL = 0 ; Set the cancel value to 0 
      IF INFO.TEXT NE -1 THEN BEGIN
        WIDGET_CONTROL, INFO.TEXT, GET_VALUE=STRING  ; Get the text box string
        (*info.PTR).NAN = STRING[0] ; Update pointer with the text box string
      ENDIF ;ELSE (*info.PTR).VALUE = -1
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
    'RADIO_BUTTON': BEGIN
      WIDGET_CONTROL, EVENT.id, GET_VALUE=buttonvalue
      CASE buttonvalue OF
        0: BEGIN ; If 'Set a Grid Value to NaN' is selected:
          ; Create text widget:
          TEXT_LABEL = WIDGET_LABEL(INFO.BASE_B, VALUE='Set The No Data Value:', /ALIGN_CENTER) 
          BASE_C = WIDGET_BASE(INFO.BASE_B, COLUMN=1, XSIZE=150, /ALIGN_CENTER) ; Text base  
          TEXT = WIDGET_TEXT(BASE_C, VALUE=(*INFO.PTR).DEFAULT, /EDITABLE)
          (*INFO.PTR).INDEX = 0 ; Update the pointer with the new radio index value 
          INFO.TEXT_LABEL = TEXT_LABEL ; Update the info structure element
          INFO.BASE_C = BASE_C ; Update the info structure element
          INFO.TEXT = TEXT ; Update the info structure element
          WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
        END
        1: BEGIN ; If 'Do Not Set a Grid Value to NaN' is selected:
          IF INFO.TEXT_LABEL NE -1 THEN BEGIN ; If text widget exists:
            WIDGET_CONTROL, INFO.TEXT_LABEL, /DESTROY ; Kill widget
            WIDGET_CONTROL, INFO.TEXT, /DESTROY ; Kill widget
            WIDGET_CONTROL, INFO.BASE_C, /DESTROY ; Kill widget
            INFO.TEXT_LABEL = -1 ; Reset info structure element back to its defualt
            INFO.BASE_C = -1 ; Reset info structure element back to its defualt
            INFO.TEXT = -1 ; Reset info structure element back to its defualt
          ENDIF
          (*INFO.PTR).INDEX = 1 ; Update the pointer with the new radio index value
          (*INFO.PTR).NAN = "" ; Reset info structure element back to its defualt
          WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
        END     
      ELSE:RETURN
      ENDCASE
    ENDCASE   
  ENDCASE
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_No_Data, TITLE=TITLE, DEFAULT=DEFAULT, FLOATING=FLOATING, DOUBLE=DOUBLE, INTEGER=INTEGER, LONG=LONG
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Provide Input'
  IF N_ELEMENTS(DEFAULT) EQ 0 THEN DEFAULT = '0'
  IF (N_ELEMENTS(FLOATING) EQ 0) AND (N_ELEMENTS(DOUBLE) EQ 0) AND (N_ELEMENTS(INTEGER) EQ 0) AND (N_ELEMENTS(LONG) EQ 0) THEN LONG = 1
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
  ; Create radio button widget:
  BASE_A = WIDGET_BASE(PARENT, COLUMN=0, FRAME=1, XSIZE=180) ; Radio base
  RADIO = CW_BGROUP(BASE_A, ['Set a Grid Value to NaN','Do Not Set a Grid Value to NaN'],$
    BUTTON_UVALUE=['YES','NO'], UVALUE='RADIO_BUTTON', UNAME='', /NO_RELEASE, /COLUMN, /EXCLUSIVE)
  ;--------------
  BASE_B = WIDGET_BASE(PARENT, COLUMN=1, FRAME=1, YSIZE=50, XSIZE=180) ; Text base main
  ;--------------
  ; Create button widget:
  BASE_D = WIDGET_BASE(PARENT, ROW=1, BASE_ALIGN_RIGHT=1) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_D, VALUE='Accept', UVALUE='WIDGET_BUTTON')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_D, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX:1, $ ; Radio index
    NAN:DEFAULT, $ ; No Data value
    DEFAULT:DEFAULT, $ ; Default No Data value
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons
  ;--------------  
  ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure
    BASE_A:BASE_A, $ ; The radio button base ID
    BASE_B:BASE_B, $ ; The text widget main base ID
    BASE_C:-1, $ ; The text widget sub base ID
    BASE_D:BASE_D, $ ; The button widget base ID
    RADIO:RADIO, $ ; Radio ID
    TEXT_LABEL:-1, $ ; Text label ID
    TEXT:-1} ; Text ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_No_Data', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX = (*PTR).INDEX
  NAN = (*PTR).NAN
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------  
  ; Return information to the main program level:
  IF (LONG(CANCEL) EQ 1) OR (LONG(INDEX) EQ 1) THEN RETURN, -1 ; If the widget was canceled
  IF N_ELEMENTS(FLOATING) EQ 1 THEN RETURN, [FLOAT(CANCEL), FLOAT(NAN)]
  IF N_ELEMENTS(DOUBLE) EQ 1 THEN RETURN, [DOUBLE(CANCEL), DOUBLE(NAN)]
  IF N_ELEMENTS(INTEGER) EQ 1 THEN RETURN, [FIX(CANCEL), FIX(NAN)]
  IF N_ELEMENTS(LONG) EQ 1 THEN RETURN, [LONG(CANCEL), LONG(NAN)]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

