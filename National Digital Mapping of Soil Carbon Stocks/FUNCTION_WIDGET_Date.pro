; ##############################################################################################
; NAME: FUNCTION_WIDGET_Date.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 05/12/2010
; DLM: 15/12/2010
;
; DESCRIPTION:  This function included a multi-part dynamic pop-up dialog widget.
;
; INPUT:        An array containing input file names. 
; 
;               The user may include the keyword JULIAN, if so a one dimensional array is returned
;               that contains the Julian day number of each input file name. 
;
; OUTPUT:       A vector containing the droplist index and either: 
; 
;               The Julian day number for each input file name. 
;               
;               OR 
;               
;               The position of the first character in the DOY, and YYYY, or DD, MM, and YYYY, 
;               depending on the droplist date selection.  
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
PRO EVENT_DROPLIST, EVENT ; This event handler responds to a droplist event: 
  ; Depending on the droplist selection the appropriate date sliders and labels are created and/or destroyed
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, EVENT.id, GET_UVALUE=EVENTS ; Get the list of possible events
  EVENTNAME = EVENTS[EVENT.INDEX] ; Set the current event
  CASE EVENTNAME OF
    'NA': BEGIN ; If 'No Date' is selected:
      IF INFO.DOY_LABEL NE '' THEN BEGIN ; If DOY/YYYY sliders and labels exist:
        WIDGET_CONTROL, INFO.DOY_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DOY_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DOY_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_STRING, /DESTROY ; Kill widget
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value
        (*INFO.PTR).INDEX_DOY = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_YYYYa = 0 ; Reset info structure element back to its defualt
        INFO.DOY_LABEL = "" ; Reset info structure element back to its defualt
        INFO.DOY_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_LABEL = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.DOY_STRING = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_STRING = "" ; Reset info structure element back to its defualt
      ENDIF
      ;--------------
      IF INFO.DD_LABEL NE '' THEN BEGIN ; If DD/MM/YYYY sliders and labels exist:
        WIDGET_CONTROL, INFO.DD_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DD_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DD_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_STRING, /DESTROY ; Kill widget
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value
        (*INFO.PTR).INDEX_DD = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_MM = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_YYYYb = 0 ; Reset info structure element back to its defualt
        INFO.DD_LABEL = "" ; Reset info structure element back to its defualt 
        INFO.DD_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.MM_LABEL = "" ; Reset info structure element back to its defualt
        INFO.MM_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_LABEL = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.DD_STRING = "" ; Reset info structure element back to its defualt
        INFO.MM_STRING = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_STRING = "" ; Reset info structure element back to its defualt
      ENDIF
    ENDCASE
    ;--------------------------------------------------------------------------------------------
    'DOY/YYYY': BEGIN ; If 'DOY/YYYY' is selected:
      IF INFO.DD_LABEL NE '' THEN BEGIN ; If DD/MM/YYYY sliders and labels exist:
        WIDGET_CONTROL, INFO.DD_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DD_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DD_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.MM_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYb_STRING, /DESTROY ; Kill widget
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value
        (*INFO.PTR).INDEX_DD = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_MM = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_YYYYb = 0 ; Reset info structure element back to its defualt
        INFO.DD_LABEL = "" ; Reset info structure element back to its defualt
        INFO.DD_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.MM_LABEL = "" ; Reset info structure element back to its defualt
        INFO.MM_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_LABEL = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.DD_STRING = "" ; Reset info structure element back to its defualt
        INFO.MM_STRING = "" ; Reset info structure element back to its defualt
        INFO.YYYYb_STRING = "" ; Reset info structure element back to its defualt        
      ENDIF
      ;--------------
      IF INFO.DOY_LABEL EQ '' THEN BEGIN ; Create DOY/YYYY slider and label widgets:
        DOY_LABEL = WIDGET_LABEL(INFO.BASE_D, VALUE='  Set DOY:', XSIZE=250, /ALIGN_LEFT, YOFFSET=5) 
        DOY_SLIDER = WIDGET_SLIDER(INFO.BASE_D, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=250, UVALUE='WIDGET_SLIDER', YOFFSET=15)
        YYYYa_LABEL = WIDGET_LABEL(INFO.BASE_D, VALUE='  Set YYYY:', XSIZE=250, /ALIGN_LEFT, YOFFSET=60)
        YYYYa_SLIDER = WIDGET_SLIDER(INFO.BASE_D, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=250, UVALUE='WIDGET_SLIDER', YOFFSET=70)    
        DOY_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DOY =  ' + "'" + STRMID(INFO.FILE_IN, 0, 3) + "'" , XSIZE=250, YOFFSET=5)
        YYYYa_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  '+ "'" + STRMID(INFO.FILE_IN, 0, 4) + "'" , XSIZE=250, YOFFSET=25)   
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value 
        INFO.DOY_LABEL = DOY_LABEL ; Update the info structure element with the new widget id
        INFO.DOY_SLIDER = DOY_SLIDER ; Update the info structure element with the new widget id
        INFO.YYYYa_LABEL = YYYYa_LABEL ; Update the info structure element with the new widget id
        INFO.YYYYa_SLIDER = YYYYa_SLIDER ; Update the info structure element with the new widget id
        INFO.DOY_STRING = DOY_STRING ; Update the info structure element with the new widget id
        INFO.YYYYa_STRING = YYYYa_STRING ; Update the info structure element with the new widget id        
      ENDIF
    ENDCASE
    ;--------------------------------------------------------------------------------------------
    'DD/MM/YYYY': BEGIN ; If 'DD/MM/YYYY' is selected:
      IF INFO.DOY_LABEL NE '' THEN BEGIN ; IF DOY/YYYY sliders and labels exist:
        WIDGET_CONTROL, INFO.DOY_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DOY_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_LABEL, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_SLIDER, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.DOY_STRING, /DESTROY ; Kill widget
        WIDGET_CONTROL, INFO.YYYYa_STRING, /DESTROY ; Kill widget
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value
        (*INFO.PTR).INDEX_DOY = 0 ; Reset info structure element back to its defualt
        (*INFO.PTR).INDEX_YYYYa = 0 ; Reset info structure element back to its defualt
        INFO.DOY_LABEL = "" ; Reset info structure element back to its defualt
        INFO.DOY_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_LABEL = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_SLIDER = "" ; Reset info structure element back to its defualt
        INFO.DOY_STRING = "" ; Reset info structure element back to its defualt
        INFO.YYYYa_STRING = "" ; Reset info structure element back to its defualt 
      ENDIF
      ;--------------
      IF INFO.DD_LABEL EQ '' THEN BEGIN ; Create DD/MM/YYYY slider and label widgets:   
        DD_LABEL = WIDGET_LABEL(INFO.BASE_D, VALUE='  Set DD:', XSIZE=250, /ALIGN_LEFT, YOFFSET=5)
        DD_SLIDER = WIDGET_SLIDER(INFO.BASE_D, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=250, UVALUE='WIDGET_SLIDER', YOFFSET=15)
        MM_LABEL = WIDGET_LABEL(INFO.BASE_D, VALUE='  Set MM:', XSIZE=250, /ALIGN_LEFT, YOFFSET=60)
        MM_SLIDER = WIDGET_SLIDER(INFO.BASE_D, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=250, UVALUE='WIDGET_SLIDER', YOFFSET=70)      
        YYYYb_LABEL = WIDGET_LABEL(INFO.BASE_D, VALUE='  Set YYYY:', XSIZE=250, /ALIGN_LEFT, YOFFSET=115)
        YYYYb_SLIDER = WIDGET_SLIDER(INFO.BASE_D, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=250, UVALUE='WIDGET_SLIDER', YOFFSET=125)      
        DD_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DD =  ' + "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=5)
        MM_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  MM =  ' + "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=25)  
        YYYYb_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  ' + "'" + STRMID(INFO.FILE_IN, 0, 4) + "'" , XSIZE=250, YOFFSET=45)  
        (*INFO.PTR).INDEX_DL = EVENT.INDEX ; Update the pointer with the new droplist index value
        INFO.DD_LABEL = DD_LABEL ; Update the info structure element with the new widget id
        INFO.DD_SLIDER = DD_SLIDER ; Update the info structure element with the new widget id
        INFO.MM_LABEL = MM_LABEL ; Update the info structure element with the new widget id
        INFO.MM_SLIDER = MM_SLIDER ; Update the info structure element with the new widget id
        INFO.YYYYb_LABEL = YYYYb_LABEL ; Update the info structure element with the new widget id
        INFO.YYYYb_SLIDER = YYYYb_SLIDER ; Update the info structure element with the new widget id
        INFO.DD_STRING = DD_STRING ; Update the info structure element with the new widget id
        INFO.MM_STRING = MM_STRING ; Update the info structure element with the new widget id
        INFO.YYYYb_STRING = YYYYb_STRING ; Update the info structure element with the new widget id
      ENDIF
    ENDCASE
  ENDCASE
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO EVENT_LIST, EVENT 
  ; This event handler responds to a filename list selection event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, INFO.FILE_LABEL, SET_VALUE=INFO.IN_FILES[EVENT.INDEX] ; Update the selected filename label
  INFO.FILE_IN = INFO.IN_FILES[EVENT.INDEX] ; Update the selected filename widget ID
  ;--------------
  ; Update the printed date strings using the new selected filename:
  IF INFO.DOY_SLIDER NE '' THEN BEGIN
    WIDGET_CONTROL, INFO.DOY_SLIDER, GET_VALUE=POS ; Get the slider position
    WIDGET_CONTROL, INFO.DOY_STRING, /DESTROY ; Kill the current printed DOY string
    ; Create a new DOY string
    DOY_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DOY =  ' + "'" + STRMID(INFO.FILE_IN, POS, 3) + "'" , XSIZE=250, YOFFSET=5)
    (*INFO.PTR).INDEX_DOY=POS ; Reset the DOY index
    INFO.DOY_STRING = DOY_STRING ; Reset the printed DOY string widget ID   
  ENDIF
  IF INFO.YYYYa_SLIDER NE '' THEN BEGIN
    WIDGET_CONTROL, INFO.YYYYa_SLIDER, GET_VALUE=POS ; Get the slider position
    WIDGET_CONTROL, INFO.YYYYa_STRING, /DESTROY ; Kill the current printed YYYY string
    ; Create a new YYYY string
    YYYYa_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  '+ "'" + STRMID(INFO.FILE_IN, POS, 4) + "'" , XSIZE=250, YOFFSET=25)    
    (*INFO.PTR).INDEX_YYYYa=POS ; Reset the YYYY index   
    INFO.YYYYa_STRING = YYYYa_STRING ; Reset the printed YYYY string widget ID
  ENDIF  
  IF INFO.DD_SLIDER NE '' THEN BEGIN
    WIDGET_CONTROL, INFO.DD_SLIDER, GET_VALUE=POS ; Get the slider position
    WIDGET_CONTROL, INFO.DD_STRING, /DESTROY ; Kill the current printed DD string
    ; Create a new DD string
    DD_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DD =  ' + "'" + STRMID(INFO.FILE_IN, POS, 2) + "'" , XSIZE=250, YOFFSET=5)
    (*INFO.PTR).INDEX_DD=POS ; Reset the DD index
    INFO.DD_STRING = DD_STRING ; Reset the printed DD string widget ID     
  ENDIF 
  IF INFO.MM_SLIDER NE '' THEN BEGIN
    WIDGET_CONTROL, INFO.MM_SLIDER, GET_VALUE=POS ; Get the slider position
    WIDGET_CONTROL, INFO.MM_STRING, /DESTROY ; Kill the current printed MM string
    ; Create a new MM string
    MM_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  MM =  ' + "'" + STRMID(INFO.FILE_IN, POS, 2) + "'" , XSIZE=250, YOFFSET=25)
    (*INFO.PTR).INDEX_MM=POS ; Reset the MM index
    INFO.MM_STRING = MM_STRING ; Reset the printed MM string widget ID
  ENDIF       
  IF INFO.YYYYb_SLIDER NE '' THEN BEGIN
    WIDGET_CONTROL, INFO.YYYYb_SLIDER, GET_VALUE=POS ; Get the slider position
    WIDGET_CONTROL, INFO.YYYYb_STRING, /DESTROY ; Kill the current printed YYYY string
    ; Create a new YYYY string
    YYYYb_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  '+ "'" + STRMID(INFO.FILE_IN, POS, 4) + "'" , XSIZE=250, YOFFSET=45)
    (*INFO.PTR).INDEX_YYYYb=POS ; Reset the YYYY index
    INFO.YYYYb_STRING = YYYYb_STRING ; Reset the printed YYYY string widget ID
  ENDIF
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Date_Event, EVENT ; This event handler responds to button and slider events: 
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  EVENTCASE = TAG_NAMES(EVENT, /STRUCTURE_NAME) ; Get the event name
  ;--------------
  CASE EVENTCASE OF
    'WIDGET_BUTTON': BEGIN ; Button event:
      (*INFO.PTR).CANCEL = 0 ; Set the cancel value to 0
      WIDGET_CONTROL, EVENT.top, /DESTROY ; Kill the parent widget
    ENDCASE
    ;--------------
    'WIDGET_SLIDER':BEGIN ; Slider event:
      IF INFO.DOY_SLIDER NE '' THEN BEGIN
        WIDGET_CONTROL, INFO.DOY_SLIDER, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.DOY_STRING, /DESTROY ; Kill the current printed DOY string
        ; Create a new DOY string
        DOY_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DOY =  ' + "'" + STRMID(INFO.FILE_IN, POS, 3) + "'" , XSIZE=250, YOFFSET=5)
        (*INFO.PTR).INDEX_DOY=POS ; Reset the DOY index
        INFO.DOY_STRING = DOY_STRING ; Reset the printed DOY string widget ID   
      ENDIF
      IF INFO.YYYYa_SLIDER NE '' THEN BEGIN
        WIDGET_CONTROL, INFO.YYYYa_SLIDER, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.YYYYa_STRING, /DESTROY ; Kill the current printed YYYY string
        ; Create a new YYYY string
        YYYYa_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  '+ "'" + STRMID(INFO.FILE_IN, POS, 4) + "'" , XSIZE=250, YOFFSET=25)    
        (*INFO.PTR).INDEX_YYYYa=POS ; Reset the YYYY index    
        INFO.YYYYa_STRING = YYYYa_STRING ; Reset the printed YYYY string widget ID
      ENDIF  
      IF INFO.DD_SLIDER NE '' THEN BEGIN
        WIDGET_CONTROL, INFO.DD_SLIDER, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.DD_STRING, /DESTROY ; Kill the current printed DD string
        ; Create a new DD string
        DD_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  DD =  ' + "'" + STRMID(INFO.FILE_IN, POS, 2) + "'" , XSIZE=250, YOFFSET=5)
        (*INFO.PTR).INDEX_DD=POS ; Reset the DD index 
        INFO.DD_STRING = DD_STRING ; Reset the printed DD string widget ID     
      ENDIF 
      IF INFO.MM_SLIDER NE '' THEN BEGIN
        WIDGET_CONTROL, INFO.MM_SLIDER, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.MM_STRING, /DESTROY ; Kill the current printed MM string
        ; Create a new MM string
        MM_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  MM =  ' + "'" + STRMID(INFO.FILE_IN, POS, 2) + "'" , XSIZE=250, YOFFSET=25)
        (*INFO.PTR).INDEX_MM=POS ; Reset the MM index 
        INFO.MM_STRING = MM_STRING ; Reset the printed MM string widget ID 
      ENDIF       
      IF INFO.YYYYb_SLIDER NE '' THEN BEGIN
        WIDGET_CONTROL, INFO.YYYYb_SLIDER, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.YYYYb_STRING, /DESTROY ; Kill the current printed YYYY string
        ; Create a new YYYY string
        YYYYb_STRING = WIDGET_LABEL(INFO.BASE_E, VALUE='  YYYY =  '+ "'" + STRMID(INFO.FILE_IN, POS, 4) + "'" , XSIZE=250, YOFFSET=45)
        (*INFO.PTR).INDEX_YYYYb=POS ; Reset the YYYY index 
        INFO.YYYYb_STRING = YYYYb_STRING ; Reset the printed YYYY string widget ID
      ENDIF      
      WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
    ENDCASE
    ;--------------
  ENDCASE
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Date, IN_FILES=IN_FILES, JULIAN=JULIAN
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(IN_FILES) EQ 0 THEN RETURN, -1
  IF KEYWORD_SET(JULIAN) THEN JULIAN = 1 ELSE JULIAN = 0
  ;---------------------------------------------------------------------------------------------
  ; Create GROUPLEADER (top level - MODAL - bases must have a group leader):
  GROUPLEADER = WIDGET_BASE(MAP=0)
  WIDGET_CONTROL, GROUPLEADER, /REALIZE
  DESTROY_GROUPLEADER = 1
  ;--------------
  ; Find the parent widget offset using the screen size:
  DEVICE, GET_SCREEN_SIZE=SCREENSIZE
  IF SCREENSIZE[0] GT 2000 THEN SCREENSIZE[0] = SCREENSIZE[0]/2
  XCENTRE = FIX(SCREENSIZE[0] / 2.0)
  YCENTRE = FIX(SCREENSIZE[1] / 2.0)
  XOFFSET = XCENTRE - 150
  YOFFSET = YCENTRE - 200
  ;--------------
  ; Create parent widget:
  PARENT = WIDGET_BASE(TITLE='Define Date', GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, SPACE=5, $
    TLB_FRAME_ATTR=1, XOFFSET=XOFFSET, YOFFSET=YOFFSET, /MODAL, /BASE_ALIGN_CENTER)
  ;--------------
  ; Create file list widget:
  BASE_A = WIDGET_BASE(PARENT) ; File list base
  FILE_LIST = WIDGET_LIST(BASE_A, VALUE=IN_FILES, YSIZE=8, SCR_XSIZE=250, EVENT_PRO='EVENT_LIST')
  ;--------------
  ; Create selected filename widget: 
  BASE_B = WIDGET_BASE(PARENT, ROW=1) ; Selected filename base 
  FILE_LABEL = WIDGET_LABEL(BASE_B, VALUE=IN_FILES[0], XSIZE=250, /SUNKEN_FRAME, /ALIGN_LEFT)
  ;--------------
  ; Create droplist widget:
  BASE_C = WIDGET_BASE(PARENT, ROW=1, FRAME=1, XSIZE=250) ; Droplist base
  DROPLIST_DATE = WIDGET_DROPLIST(BASE_C, VALUE=['No Date','DOY/YYYY','DD/MM/YYYY'], TITLE='Filename Date Type:  ', EVENT_PRO='EVENT_DROPLIST', UVALUE=['NA','DOY/YYYY','DD/MM/YYYY'], /DYNAMIC_RESIZE) 
  ;--------------
  BASE_D = WIDGET_BASE(PARENT, FRAME=1, XSIZE=250, YSIZE=165) ; Slider base
  BASE_E = WIDGET_BASE(PARENT, FRAME=1, XSIZE=250, YSIZE=65) ; Slider output base
  ;-------------- 
  ; Create button widget:
  BASE_F = WIDGET_BASE(PARENT, ROW=1, BASE_ALIGN_CENTER=1) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_F, VALUE='Accept')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_F, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------  
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX_DL:0, $ ; Droplist index: 0 EQ 'No Date', 1 EQ 'DOY/YYYY', 2 EQ 'DD/MM/YYYY'
    INDEX_DOY:0, $ ; DOY index: the position of the first DOY character in the selected input filename
    INDEX_YYYYa:0, $ ; YYYY (DOY/YYYY) index: the position of the first YYYY character in the selected input filename
    INDEX_DD:0, $ ; DD index: the position of the first DD character in the selected input filename
    INDEX_MM:0, $ ; MM index: the position of the first MM character in the selected input filename
    INDEX_YYYYb:0, $ ; YYYY (DD/MM/YYYY) index: the position of the first YYYY character in the selected input filename
    IN_FILES:IN_FILES, $ ; An array containing all of the input filenames
    JULIAN:JULIAN, $ ; JULIAN KEYWORD ID: If EQ 1 then the function output is an array containing the julian day number of each file in the filename array
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons
  ;--------------    
  ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure     
    IN_FILES:IN_FILES, $ ; The input filename array
    FILE_IN:IN_FILES[0], $ ; The selected filename string (The default value is the first filename in the filename array)    
    BASE_A:BASE_A, $ ; The file list base ID
    BASE_B:BASE_B, $ ; The selected filename base ID
    BASE_D:BASE_D, $ ; The Slider base ID
    BASE_E:BASE_E, $ ; The Slider output base ID
    FILE_LIST:FILE_LIST, $ ; The file list widget ID
    DROPLIST_DATE:DROPLIST_DATE, $ ; The date type droplist widget ID 
    FILE_LABEL:FILE_LABEL, $ ; The selected filename label widget ID
    DOY_LABEL:"", $ ; The DOY label widget ID
    DOY_SLIDER:"", $ ; The DOY Slider widget ID 
    YYYYa_LABEL:"", $ ; The YYYY (DOY/YYYY) label widget ID
    YYYYa_SLIDER:"", $ ; The YYYY (DOY/YYYY) Slider widget ID
    DOY_STRING:"", $ ; The output DOY label widget ID 
    YYYYa_STRING:"", $ ; The output YYYY (DOY/YYYY) label widget ID
    DD_LABEL:"", $ ; The DD label widget ID
    DD_SLIDER:"", $ ; The DD Slider widget ID 
    MM_LABEL:"", $ ; The MM label widget ID
    MM_SLIDER:"", $ ; The MM Slider widget ID 
    YYYYb_LABEL:"", $ ; The YYYY (DD/MM/YYYY) label widget ID
    YYYYb_SLIDER:"", $ ; The YYYY (DD/MM/YYYY) Slider widget ID
    DD_STRING:"", $ ; The output DD label widget ID
    MM_STRING:"", $ ; The output MM label widget ID
    YYYYb_STRING:""} ; The output YYYY (DD/MM/YYYY) label widget ID
  ;---------------------------------------------------------------------------------------------    
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Date', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX_DL = (*PTR).INDEX_DL
  INDEX_DOY = (*PTR).INDEX_DOY
  INDEX_YYYYa = (*PTR).INDEX_YYYYa
  INDEX_DD = (*PTR).INDEX_DD
  INDEX_MM = (*PTR).INDEX_MM
  INDEX_YYYYb = (*PTR).INDEX_YYYYb
  IN_FILES = (*PTR).IN_FILES
  JULIAN = (*PTR).JULIAN
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------
  ; Return information:
  IF (INDEX_DL EQ 0) OR (LONG(CANCEL) EQ 1) THEN RETURN, -1 ; If 'NO DATE' was selected or the widget was canceled
  IF JULIAN EQ 1 THEN BEGIN ; return the julian day number of each input filename
    IF INDEX_DL EQ 1 THEN BEGIN ; DOY/YYYY
      DOY = STRMID(IN_FILES, LONG(INDEX_DOY), 3) ; Manipulate the filename array to get the DOY
      YEAR = STRMID(IN_FILES, LONG(INDEX_YYYYa), 4) ; Manipulate the filename array to get the YEAR 
      CALDAT, JULDAY(1, DOY, YEAR), MONTH, DAY ; Get 'DAY' and 'MONTH' FROM 'DAY OF YEAR' 
      JULIAN_DATE = JULDAY(MONTH, DAY, YEAR) ; Convert file dates to 'JULDAY' format      
      RETURN, JULIAN_DATE ; Return information to the main program level
    ENDIF ELSE BEGIN ; DD/MM/YYYY    
      DAY = STRMID(IN_FILES, LONG(INDEX_DD), 2) ; Manipulate the filename array to get the DAY
      MONTH = STRMID(IN_FILES, LONG(INDEX_MM), 2) ; Manipulate the filename array to get the MONTH                   
      YEAR = STRMID(IN_FILES, LONG(INDEX_YYYYb), 4) ; Manipulate the filename array to get the YEAR 
      JULIAN_DATE = JULDAY(MONTH, DAY, YEAR) ; Convert file dates to 'JULDAY' format 
      RETURN, JULIAN_DATE ; Return information to the main program level
    ENDELSE
  ENDIF ELSE BEGIN ; Return the droplist, DOY, YYYY (DOY/YYYY), DD, MM, and YYYY (DD/MM/YYYY ) index and the Cancel value
    ; Return information to the main program level  
    RETURN, [LONG(INDEX_DL),LONG(INDEX_DOY),LONG(INDEX_YYYYa),LONG(INDEX_DD),LONG(INDEX_MM),LONG(INDEX_YYYYb),LONG(CANCEL)]
  ENDELSE
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************


