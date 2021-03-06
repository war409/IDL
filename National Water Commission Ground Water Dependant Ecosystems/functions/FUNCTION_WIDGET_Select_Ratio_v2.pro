; ##############################################################################################
; NAME: FUNCTION_WIDGET_Select_Ratio_v2.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 13/12/2010
; DLM: 05/09/2010
;
; DESCRIPTION:  This function creates a dynamic pop-up dialog widget. The widget consists of a 
;               checkbox widget, and Select All, Accept, and Cancel buttons.
;               
;               The widget has been created to allow the user to select what Remote Sensing Indices
;               to calculate in their main procedure.
;               
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;
; OUTPUT:       An eight element Long integer array containing the index status of NDVI, NDWI 1 
;               (SWIR 1), NDWI 1 (SWIR 2), NDWI 1 (SWIR 3), NDWI 2, mNDWI (SWIR 1), mNDWI (SWIR 2),
;               and mNDWI (SWIR 3) respectively.
;               
;               For each index a returned value of 1 indicates that the index was selected, a value 
;               of 0 indicates that the index was not selected.
;               
;               If the Cancel or quit buttons are selected the function will return -1.
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
PRO EVENT_ALL, EVENT ; This event handler responds to the Select All button event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  IF INFO.ALL EQ 0 THEN BEGIN ; Select All:
    WIDGET_CONTROL, INFO.CHECKBOX, /DESTROY ; Kill widget
  CHECKBOX = CW_BGROUP(INFO.BASE_B, ['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], EVENT_FUNCT='CHECKBOX_EVENT', UVALUE=['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], SET_VALUE=[1,1,1,1,1,1,1,1], /COLUMN, /NONEXCLUSIVE) ; Checkbox widget
    INFO.CHECKBOX = CHECKBOX ; Update the info structure element - Checkbox widget ID
    INFO.ALL = 1 ; Update the info structure element - Select All status (1 = On)
    (*INFO.PTR).NDVI = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).NDWI1_SWIR1 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).NDWI1_SWIR2 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).NDWI1_SWIR3 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).NDWI2 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).mNDWI_SWIR1 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).mNDWI_SWIR2 = 1 ; Update the info structure element - Index status (1 = On)
    (*INFO.PTR).mNDWI_SWIR3 = 1 ; Update the info structure element - Index status (1 = On)
  ENDIF ELSE BEGIN ; De-select All:
    WIDGET_CONTROL, INFO.CHECKBOX, /DESTROY ; Kill widget
  CHECKBOX = CW_BGROUP(INFO.BASE_B, ['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], EVENT_FUNCT='CHECKBOX_EVENT', UVALUE=['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], SET_VALUE=[0,0,0,0,0,0,0,0], /COLUMN, /NONEXCLUSIVE) ; Checkbox widget
    INFO.CHECKBOX = CHECKBOX ; Update the info structure element - Checkbox widget ID
    INFO.ALL = 0 ; Update the info structure element - Select All status (0 = Off)
    (*INFO.PTR).NDVI = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).NDWI1_SWIR1 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).NDWI1_SWIR2 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).NDWI1_SWIR3 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).NDWI2 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).mNDWI_SWIR1 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).mNDWI_SWIR2 = 0 ; Update the info structure element - Index status (0 = Off)
    (*INFO.PTR).mNDWI_SWIR3 = 0 ; Update the info structure element - Index status (0 = Off)
  ENDELSE
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Select_Ratio_v2_Event, EVENT ; This event handler responds to button events:
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

;-----------------------------------------------------------------------------------------------
FUNCTION CHECKBOX_EVENT, EVENT ; This event handler responds to radio button events:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, EVENT.id, GET_UVALUE=EVENTS ; Get the list of possible events
  EVENTNAME = EVENTS[EVENT.VALUE] ; Set the current event
  CASE EVENTNAME OF
    'NDVI': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).NDVI = 1 ELSE (*INFO.PTR).NDVI = 0
    ENDCASE
    'NDWI 1 (SWIR1)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).NDWI1_SWIR1 = 1 ELSE (*INFO.PTR).NDWI1_SWIR1 = 0
    ENDCASE
    'NDWI 1 (SWIR2)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).NDWI1_SWIR2 = 1 ELSE (*INFO.PTR).NDWI1_SWIR2 = 0
    ENDCASE 
    'NDWI 1 (SWIR3)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).NDWI1_SWIR3 = 1 ELSE (*INFO.PTR).NDWI1_SWIR3 = 0
    ENDCASE 
    'NDWI 2': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).NDWI2 = 1 ELSE (*INFO.PTR).NDWI2 = 0
    ENDCASE
    'mNDWI (SWIR1)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).mNDWI_SWIR1 = 1 ELSE (*INFO.PTR).mNDWI_SWIR1 = 0
    ENDCASE
    'mNDWI (SWIR2)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).mNDWI_SWIR2 = 1 ELSE (*INFO.PTR).mNDWI_SWIR2 = 0
    ENDCASE
    'mNDWI (SWIR3)': BEGIN
      IF EVENT.SELECT EQ 1 THEN (*INFO.PTR).mNDWI_SWIR3 = 1 ELSE (*INFO.PTR).mNDWI_SWIR3 = 0
    ENDCASE
  ENDCASE
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------

;***********************************************************************************************
FUNCTION FUNCTION_WIDGET_Select_Ratio_v2, TITLE=TITLE
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Select Indices'
  ;---------------------------------------------------------------------------------------------
  ; Create GROUPLEADER (top level - MODAL - bases must have a group leader):
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1
  ;-------------- ; Create parent widget:
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, SPACE=1, XSIZE=325, $
    TLB_FRAME_ATTR=1, /MODAL, /BASE_ALIGN_CENTER)
  ;-------------- ; Create selection widget:
  BASE_A = WIDGET_BASE(PARENT, COLUMN=2, XSIZE=315, FRAME=1) ; Selection base
  BASE_B = WIDGET_BASE(BASE_A, XSIZE=140) ; Checkbox base
  CHECKBOX = CW_BGROUP(BASE_B, ['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], EVENT_FUNCT='CHECKBOX_EVENT', UVALUE=['NDVI', $
                                'NDWI 1 (SWIR1)', $
                                'NDWI 1 (SWIR2)', $
                                'NDWI 1 (SWIR3)', $
                                'NDWI 2', $
                                'mNDWI (SWIR1)', $
                                'mNDWI (SWIR2)', $
                                'mNDWI (SWIR3)'], /COLUMN, /NONEXCLUSIVE) ; Checkbox widget
  BASE_C = WIDGET_BASE(BASE_A) ; Formula base
  NDVI = WIDGET_LABEL(BASE_C, VALUE='(NIR - R) / (NIR + R)', YOFFSET=10) ; NDVI label
  NDWI1_SWIR1 = WIDGET_LABEL(BASE_C, VALUE='(NIR - SWIR1) / (NIR + SWIR1)', YOFFSET=37) ; NDWI 1 label
  NDWI1_SWIR2 = WIDGET_LABEL(BASE_C, VALUE='(NIR - SWIR2) / (NIR + SWIR2)', YOFFSET=64) ; NDWI 1 label
  NDWI1_SWIR3 = WIDGET_LABEL(BASE_C, VALUE='(NIR - SWIR3) / (NIR + SWIR3)', YOFFSET=91) ; NDWI 1 label
  NDWI2 = WIDGET_LABEL(BASE_C, VALUE='(G - NIR) / (G + NIR)', YOFFSET=118) ; NDWI 2 label
  mNDWI_SWIR1 = WIDGET_LABEL(BASE_C, VALUE='(G - SWIR1) / (G + SWIR1)', YOFFSET=145) ; mNDWI label
  mNDWI_SWIR2 = WIDGET_LABEL(BASE_C, VALUE='(G - SWIR2) / (G + SWIR2)', YOFFSET=172) ; mNDWI label
  mNDWI_SWIR3 = WIDGET_LABEL(BASE_C, VALUE='(G - SWIR3) / (G + SWIR3)', YOFFSET=199) ; mNDWI label
  ;-------------- ; Create button widget:
  BASE_D = WIDGET_BASE(PARENT, ROW=1) ; Button base
  BUTTON_ALL = WIDGET_BUTTON(BASE_D, VALUE='Select All', EVENT_PRO='EVENT_ALL')  
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_D, VALUE='Accept')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_D, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({NDVI:0, $ ; Index status, 0 = No, 1 = Yes
    NDWI1_SWIR1:0, $ ; Index status, 0 = No, 1 = Yes
    NDWI1_SWIR2:0, $ ; Index status, 0 = No, 1 = Yes
    NDWI1_SWIR3:0, $ ; Index status, 0 = No, 1 = Yes
    NDWI2:0, $ ; Index status, 0 = No, 1 = Yes
    mNDWI_SWIR1:0, $ ; Index status, 0 = No, 1 = Yes
    mNDWI_SWIR2:0, $ ; Index status, 0 = No, 1 = Yes
    mNDWI_SWIR3:0, $ ; Index status, 0 = No, 1 = Yes
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons   
  ;-------------- ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure
    BASE_A:BASE_A, $ ; The selection base ID
    BASE_B:BASE_B, $ ; The checkbox base ID
    BASE_C:BASE_C, $ ; The formula labels base ID
    BASE_D:BASE_D, $ ; The button widget base ID
    CHECKBOX:CHECKBOX, $ ; Checkbox ID
    ALL:0} ; Select All status
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Select_Ratio_v2', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------  
  ; Return the user defined information to the main level program:
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  NDVI = (*PTR).NDVI
  NDWI1_SWIR1 = (*PTR).NDWI1_SWIR1
  NDWI1_SWIR2 = (*PTR).NDWI1_SWIR2
  NDWI1_SWIR3 = (*PTR).NDWI1_SWIR3
  NDWI2 = (*PTR).NDWI2
  mNDWI_SWIR1 = (*PTR).mNDWI_SWIR1
  mNDWI_SWIR2 = (*PTR).mNDWI_SWIR2
  mNDWI_SWIR3 = (*PTR).mNDWI_SWIR3
  CANCEL = (*PTR).CANCEL
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;-------------- ; Return information:
  IF (LONG(CANCEL) EQ 1) THEN RETURN, -1 ; If the widget was canceled return -1
  RETURN, [LONG(NDVI), $
          LONG(NDWI1_SWIR1), $
          LONG(NDWI1_SWIR2), $
          LONG(NDWI1_SWIR3), $
          LONG(NDWI2), $
          LONG(mNDWI_SWIR1), $
          LONG(mNDWI_SWIR2), $
          LONG(mNDWI_SWIR3)] ; Return information to the main program level
  ;---------------------------------------------------------------------------------------------
END
;***********************************************************************************************

