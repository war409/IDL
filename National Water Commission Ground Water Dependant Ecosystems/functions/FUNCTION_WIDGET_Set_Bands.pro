; ##############################################################################################
; NAME: FUNCTION_WIDGET_Set_Bands.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 14/12/2010
; DLM: 15/12/2010
;
; DESCRIPTION:  This function includes a multi-part dynamic pop-up dialog widget. The aim of this
;               function is to get the position and length of the string component in the selected
;               filename that describes the selected band. For example,
;                   
;               The input file 'L5105069_06920060730_B30' contains landsat 5 reflectance data for 
;               band 3, which is the Red band. Select 'Red Band' from the bandlist. Change the 'Length: 
;               Red' slider to 3, and move the 'Position: Red' to 21. The red string displayed at the 
;               bottom of the widget should display 'B30'. With this information the program can search 
;               and extract all of the red band data files from the input file list.
;
; INPUT:        TITLE: A scalar string containing the widget title. The default title is 'Provide
;               Input'.
;               
;               IN_FILES: An array containing the input file names.
; 
; OUTPUT:       A 15 element long integer array that contains the file index, string length and string
;               starting position of each selected band. See the structure below, B = Blue, G = Green 
;               etc.
; 
;               [LONG(INDEX_B),LONG(LENGTH_B),LONG(FILE_B_INDEX),LONG(INDEX_G),LONG(LENGTH_G),LONG(FILE_G_INDEX), $
;               LONG(INDEX_R),LONG(LENGTH_R),LONG(FILE_R_INDEX),LONG(INDEX_NIR),LONG(LENGTH_NIR),LONG(FILE_NIR_INDEX), $
;               LONG(INDEX_MIR),LONG(LENGTH_MIR),LONG(FILE_MIR_INDEX)] 
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
PRO EVENT_LIST, EVENT 
  ; This event handler responds to a filename list selection event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, INFO.FILE_LABEL, SET_VALUE=INFO.IN_FILES[EVENT.INDEX] ; Update the selected filename label
  INFO.FILE_IN = INFO.IN_FILES[EVENT.INDEX] ; Update the selected filename widget ID
  INFO.FILE_INDEX = EVENT.INDEX
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO BAND_LIST, EVENT 
  ; This event handler responds to a bandname list selection event:
  WIDGET_CONTROL, EVENT.top, GET_UVALUE=INFO, /NO_COPY ; Get the info structure from the storage location
  WIDGET_CONTROL, INFO.BAND_LABEL, SET_VALUE=INFO.IN_BANDS[EVENT.INDEX] ; Update the selected bandname label
  INFO.BAND_IN = INFO.IN_BANDS[EVENT.INDEX] ; Update the selected bandname widget ID
  ;--------------
  IF INFO.BAND_IN EQ 'Blue Band' THEN BEGIN
    IF INFO.iLABELa_B EQ '' THEN BEGIN
      iLABELa_B = WIDGET_LABEL(INFO.BASE_F, VALUE='Position: BLUE', XSIZE=140, /ALIGN_LEFT, YOFFSET=5)
      iPOS_B = WIDGET_SLIDER(INFO.BASE_F, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=140, UNAME='SLIDER_BLUE', YOFFSET=20, /DRAG)
      iLABELb_B = WIDGET_LABEL(INFO.BASE_G, VALUE='Length: BLUE', /ALIGN_LEFT, YOFFSET=5)
      iLENGTH_B = WIDGET_SLIDER(INFO.BASE_G, MINIMUM=0, MAXIMUM=10, UNAME='SLIDER_BLUE', YOFFSET=20, VALUE=2, XSIZE=95, /DRAG) 
      B_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' BLUE =  '+ "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=7)
      INFO.iLABELa_B = iLABELa_B ; Reset
      INFO.iPOS_B = iPOS_B ; Reset
      INFO.iLABELb_B = iLABELb_B ; Reset
      INFO.iLENGTH_B = iLENGTH_B ; Reset
      INFO.B_STRING = B_STRING ; Reset
    ENDIF ELSE BEGIN
      WIDGET_CONTROL, INFO.iLABELa_B, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iPOS_B, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLABELb_B, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLENGTH_B, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.B_STRING, /DESTROY ; Kill
      INFO.iLABELa_B = '' ; Reset
      INFO.iPOS_B = '' ; Reset
      INFO.iLABELb_B = '' ; Reset
      INFO.iLENGTH_B = '' ; Reset
      INFO.B_STRING = '' ; Reset                  
    ENDELSE
  ENDIF  
  ;--------------
  IF INFO.BAND_IN EQ 'Green Band' THEN BEGIN
    IF INFO.iLABELa_G EQ '' THEN BEGIN
      iLABELa_G = WIDGET_LABEL(INFO.BASE_F, VALUE='Position: GREEN', XSIZE=140, /ALIGN_LEFT, YOFFSET=75)
      iPOS_G = WIDGET_SLIDER(INFO.BASE_F, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=140, UNAME='SLIDER_GREEN', YOFFSET=90, /DRAG)
      iLABELb_G = WIDGET_LABEL(INFO.BASE_G, VALUE='Length: GREEN', /ALIGN_LEFT, YOFFSET=75)
      iLENGTH_G = WIDGET_SLIDER(INFO.BASE_G, MINIMUM=0, MAXIMUM=10, UNAME='SLIDER_GREEN', YOFFSET=90, VALUE=2, XSIZE=95, /DRAG)
      G_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' GREEN =  '+ "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=36)
      INFO.iLABELa_G = iLABELa_G ; Reset
      INFO.iPOS_G = iPOS_G ; Reset
      INFO.iLABELb_G = iLABELb_G ; Reset
      INFO.iLENGTH_G = iLENGTH_G ; Reset
      INFO.G_STRING = G_STRING ; Reset
    ENDIF ELSE BEGIN
      WIDGET_CONTROL, INFO.iLABELa_G, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iPOS_G, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLABELb_G, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLENGTH_G, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.G_STRING, /DESTROY ; Kill
      INFO.iLABELa_G = '' ; Reset
      INFO.iPOS_G = '' ; Reset
      INFO.iLABELb_G = '' ; Reset
      INFO.iLENGTH_G = '' ; Reset
      INFO.G_STRING = '' ; Reset 
    ENDELSE
  ENDIF  
  ;--------------
  IF INFO.BAND_IN EQ 'Red Band' THEN BEGIN
    IF INFO.iLABELa_R EQ '' THEN BEGIN
      iLABELa_R = WIDGET_LABEL(INFO.BASE_F, VALUE='Position: RED', XSIZE=140, /ALIGN_LEFT, YOFFSET=145)
      iPOS_R = WIDGET_SLIDER(INFO.BASE_F, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=140, UNAME='SLIDER_RED', YOFFSET=160, /DRAG)  
      iLABELb_R = WIDGET_LABEL(INFO.BASE_G, VALUE='Length: RED', /ALIGN_LEFT, YOFFSET=145)
      iLENGTH_R = WIDGET_SLIDER(INFO.BASE_G, MINIMUM=0, MAXIMUM=10, UNAME='SLIDER_RED', YOFFSET=160, VALUE=2, XSIZE=95, /DRAG)
      R_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' RED =  '+ "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=65)
      INFO.iLABELa_R = iLABELa_R ; Reset
      INFO.iPOS_R = iPOS_R ; Reset
      INFO.iLABELb_R = iLABELb_R ; Reset
      INFO.iLENGTH_R = iLENGTH_R ; Reset
      INFO.R_STRING = R_STRING ; Reset
    ENDIF ELSE BEGIN
      WIDGET_CONTROL, INFO.iLABELa_R, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iPOS_R, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLABELb_R, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLENGTH_R, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.R_STRING, /DESTROY ; Kill
      INFO.iLABELa_R = '' ; Reset
      INFO.iPOS_R = '' ; Reset
      INFO.iLABELb_R = '' ; Reset
      INFO.iLENGTH_R = '' ; Reset
      INFO.R_STRING = '' ; Reset 
    ENDELSE
  ENDIF  
  ;-------------- 
  IF INFO.BAND_IN EQ 'NIR Band' THEN BEGIN
    IF INFO.iLABELa_NIR EQ '' THEN BEGIN
      iLABELa_NIR = WIDGET_LABEL(INFO.BASE_F, VALUE='Position: NIR', XSIZE=140, /ALIGN_LEFT, YOFFSET=215)
      iPOS_NIR = WIDGET_SLIDER(INFO.BASE_F, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=140, UNAME='SLIDER_NIR', YOFFSET=230, /DRAG)
      iLABELb_NIR = WIDGET_LABEL(INFO.BASE_G, VALUE='Length: NIR', /ALIGN_LEFT, YOFFSET=215)
      iLENGTH_NIR = WIDGET_SLIDER(INFO.BASE_G, MINIMUM=0, MAXIMUM=10, UNAME='SLIDER_NIR', YOFFSET=230, VALUE=2, XSIZE=95, /DRAG)
      NIR_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' NIR =  ' + "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=94) 
      INFO.iLABELa_NIR = iLABELa_NIR ; Reset
      INFO.iPOS_NIR = iPOS_NIR ; Reset
      INFO.iLABELb_NIR = iLABELb_NIR ; Reset
      INFO.iLENGTH_NIR = iLENGTH_NIR ; Reset
      INFO.NIR_STRING = NIR_STRING ; Reset
    ENDIF ELSE BEGIN
      WIDGET_CONTROL, INFO.iLABELa_NIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iPOS_NIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLABELb_NIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLENGTH_NIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.NIR_STRING, /DESTROY ; Kill
      INFO.iLABELa_NIR = '' ; Reset
      INFO.iPOS_NIR = '' ; Reset
      INFO.iLABELb_NIR = '' ; Reset
      INFO.iLENGTH_NIR = '' ; Reset
      INFO.NIR_STRING = '' ; Reset 
    ENDELSE
  ENDIF  
  ;-------------- 
  IF INFO.BAND_IN EQ 'MIR Band' THEN BEGIN
    IF INFO.iLABELa_MIR EQ '' THEN BEGIN
      iLABELa_MIR = WIDGET_LABEL(INFO.BASE_F, VALUE='Position: MIR', XSIZE=140, /ALIGN_LEFT, YOFFSET=285)
      iPOS_MIR = WIDGET_SLIDER(INFO.BASE_F, MINIMUM=0, MAXIMUM=STRLEN(INFO.FILE_IN), XSIZE=140, UNAME='SLIDER_MIR', YOFFSET=310, /DRAG)  
      iLABELb_MIR = WIDGET_LABEL(INFO.BASE_G, VALUE='Length: MIR', /ALIGN_LEFT, YOFFSET=285)
      iLENGTH_MIR = WIDGET_SLIDER(INFO.BASE_G, MINIMUM=0, MAXIMUM=10, UNAME='SLIDER_MIR', YOFFSET=310, VALUE=2, XSIZE=95, /DRAG)
      MIR_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' MIR =  '+ "'" + STRMID(INFO.FILE_IN, 0, 2) + "'" , XSIZE=250, YOFFSET=122)
      INFO.iLABELa_MIR = iLABELa_MIR ; Reset
      INFO.iPOS_MIR = iPOS_MIR ; Reset
      INFO.iLABELb_MIR = iLABELb_MIR ; Reset
      INFO.iLENGTH_MIR = iLENGTH_MIR ; Reset
      INFO.MIR_STRING = MIR_STRING ; Reset
    ENDIF ELSE BEGIN
      WIDGET_CONTROL, INFO.iLABELa_MIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iPOS_MIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLABELb_MIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.iLENGTH_MIR, /DESTROY ; Kill
      WIDGET_CONTROL, INFO.MIR_STRING, /DESTROY ; Kill
      INFO.iLABELa_MIR = '' ; Reset
      INFO.iPOS_MIR = '' ; Reset
      INFO.iLABELb_MIR = '' ; Reset
      INFO.iLENGTH_MIR = '' ; Reset
      INFO.MIR_STRING = '' ; Reset 
    ENDELSE
  ENDIF
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
END
;-----------------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------------
PRO FUNCTION_WIDGET_Set_Bands_Event, EVENT ; This event handler responds to events:
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
      NAME = WIDGET_INFO(EVENT.ID, /UNAME)
      IF NAME EQ 'SLIDER_BLUE' THEN BEGIN
        WIDGET_CONTROL, INFO.iPOS_B, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.iLENGTH_B, GET_VALUE=LENGTH ; Get the slider position
        WIDGET_CONTROL, INFO.B_STRING, /DESTROY ; Kill the current printed DOY string      
        ; Create a new string
        B_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' BLUE =  ' + "'" + STRMID(INFO.FILE_IN, POS, LENGTH) + "'" , XSIZE=250, YOFFSET=7)
        (*INFO.PTR).INDEX_B=POS ; Reset the index
        (*INFO.PTR).LENGTH_B=LENGTH
        (*INFO.PTR).FILE_B_INDEX=INFO.FILE_INDEX
        INFO.B_STRING = B_STRING ; Reset the printed string ID
      ENDIF
      ;--------------
      IF NAME EQ 'SLIDER_GREEN' THEN BEGIN
        WIDGET_CONTROL, INFO.iPOS_G, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.iLENGTH_G, GET_VALUE=LENGTH ; Get the slider position
        WIDGET_CONTROL, INFO.G_STRING, /DESTROY ; Kill the current printed DOY string  
        ; Create a new string
        G_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' GREEN =  '+ "'" + STRMID(INFO.FILE_IN, POS, LENGTH) + "'" , XSIZE=250, YOFFSET=36)
        (*INFO.PTR).INDEX_G=POS ; Reset the index
        (*INFO.PTR).LENGTH_G=LENGTH
        (*INFO.PTR).FILE_G_INDEX=INFO.FILE_INDEX
        INFO.G_STRING = G_STRING ; Reset the printed string ID
      ENDIF
      ;--------------
      IF NAME EQ 'SLIDER_RED' THEN BEGIN      
        WIDGET_CONTROL, INFO.iPOS_R, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.iLENGTH_R, GET_VALUE=LENGTH ; Get the slider position
        WIDGET_CONTROL, INFO.R_STRING, /DESTROY ; Kill the current printed DOY string  
        ; Create a new string
        R_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' RED =  '+ "'" + STRMID(INFO.FILE_IN, POS, LENGTH) + "'" , XSIZE=250, YOFFSET=65)
        (*INFO.PTR).INDEX_R=POS ; Reset the index
        (*INFO.PTR).LENGTH_R=LENGTH
        (*INFO.PTR).FILE_R_INDEX=INFO.FILE_INDEX
        INFO.R_STRING = R_STRING ; Reset the printed string ID
      ENDIF 
      ;--------------
      IF NAME EQ 'SLIDER_NIR' THEN BEGIN 
        WIDGET_CONTROL, INFO.iPOS_NIR, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.iLENGTH_NIR, GET_VALUE=LENGTH ; Get the slider position
        WIDGET_CONTROL, INFO.NIR_STRING, /DESTROY ; Kill the current printed DOY string  
        ; Create a new string
        NIR_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' NIR =  ' + "'" + STRMID(INFO.FILE_IN, POS, LENGTH) + "'" , XSIZE=250, YOFFSET=94)
        (*INFO.PTR).INDEX_NIR=POS ; Reset the index
        (*INFO.PTR).LENGTH_NIR=LENGTH
        (*INFO.PTR).FILE_NIR_INDEX=INFO.FILE_INDEX
        INFO.NIR_STRING = NIR_STRING ; Reset the printed string ID
      ENDIF 
      ;--------------
      IF NAME EQ 'SLIDER_MIR' THEN BEGIN 
        WIDGET_CONTROL, INFO.iPOS_MIR, GET_VALUE=POS ; Get the slider position
        WIDGET_CONTROL, INFO.iLENGTH_MIR, GET_VALUE=LENGTH ; Get the slider position
        WIDGET_CONTROL, INFO.MIR_STRING, /DESTROY ; Kill the current printed DOY string  
        ; Create a new string
        MIR_STRING = WIDGET_LABEL(INFO.BASE_H, VALUE=' MIR =  '+ "'" + STRMID(INFO.FILE_IN, POS, LENGTH) + "'" , XSIZE=250, YOFFSET=122)
        (*INFO.PTR).INDEX_MIR=POS ; Reset the index
        (*INFO.PTR).LENGTH_MIR=LENGTH
        (*INFO.PTR).FILE_MIR_INDEX=INFO.FILE_INDEX
        INFO.MIR_STRING = MIR_STRING ; Reset the printed string ID
      ENDIF 
      ;--------------
      WIDGET_CONTROL, EVENT.top, SET_UVALUE=INFO, /NO_COPY ; Put the updated info structure back in the storage location
    ENDCASE
  ENDCASE
END
;-----------------------------------------------------------------------------------------------


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_WIDGET_Set_Bands, TITLE=TITLE, IN_FILES=IN_FILES
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  CATCH, ERROR
  IF ERROR NE 0 THEN RETURN, -1
  ;---------------------------------------------------------------------------------------------
  ; Check parameters:
  IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = 'Define Bands'
  IF N_ELEMENTS(IN_FILES) EQ 0 THEN RETURN, -1
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
  PARENT = WIDGET_BASE(TITLE=TITLE, GROUP_LEADER=GROUPLEADER, COLUMN=1, TAB_MODE=1, SPACE=5, $
    TLB_FRAME_ATTR=1, XOFFSET=XOFFSET, YOFFSET=YOFFSET, /MODAL, /BASE_ALIGN_CENTER)
  ;--------------
  ; Create file list widget:
  BASE_A = WIDGET_BASE(PARENT) ; File list base
  FILE_LIST = WIDGET_LIST(BASE_A, VALUE=IN_FILES, YSIZE=8, SCR_XSIZE=260, EVENT_PRO='EVENT_LIST')
  ;--------------
  ; Create selected filename widget: 
  BASE_B = WIDGET_BASE(PARENT, ROW=1) ; Selected filename base 
  FILE_LABEL = WIDGET_LABEL(BASE_B, VALUE=IN_FILES[0], XSIZE=259, /SUNKEN_FRAME, /ALIGN_LEFT)
  ;--------------
  ; Create index list:
  IN_BANDS = ['Blue Band','Green Band', 'Red Band', 'NIR Band', 'MIR Band']
  ; Create index list widget:
  BASE_C = WIDGET_BASE(PARENT) ; Index list base
  BAND_LIST = WIDGET_LIST(BASE_C, VALUE=IN_BANDS, YSIZE=5, SCR_XSIZE=260, EVENT_PRO='BAND_LIST')
  ;--------------
  ; Create selected filename widget: 
  BASE_D = WIDGET_BASE(PARENT, ROW=1) ; Selected filename base 
  BAND_LABEL = WIDGET_LABEL(BASE_D, VALUE='', XSIZE=259, /SUNKEN_FRAME, /ALIGN_LEFT)
  ;---------------------------------------------------------------------------------------------
  BASE_E = WIDGET_BASE(PARENT, COLUMN=2, FRAME=1, XSIZE=260, YSIZE=355) ; Selection base
  ;--------------  
  BASE_F = WIDGET_BASE(BASE_E, XSIZE=155) ; Position base
  BASE_G = WIDGET_BASE(BASE_E, XSIZE=105) ; Length base
  BASE_H = WIDGET_BASE(PARENT, FRAME=1, XSIZE=260, YSIZE=142) ; Slider output base
  ;---------------------------------------------------------------------------------------------
  ; Create button widget:
  BASE_I = WIDGET_BASE(PARENT, ROW=1, BASE_ALIGN_CENTER=1) ; Button base
  BUTTON_ACCEPT = WIDGET_BUTTON(BASE_I, VALUE='Accept')
  BUTTON_CANCEL = WIDGET_BUTTON(BASE_I, VALUE='Cancel', EVENT_PRO='EVENT_CANCEL', UVALUE='CANCEL')
  ;---------------------------------------------------------------------------------------------
  CENTRE_WIDGET, PARENT ; Centre the parent widget
  WIDGET_CONTROL, PARENT, /REALIZE ; Activate widget set
  ;---------------------------------------------------------------------------------------------
  ; Create structure to store the output information:
  PTR = PTR_NEW({INDEX_B:0, $ ; The position of the first B character in the selected input filename
    INDEX_G:0, $ ; The position of the first G character in the selected input filename
    INDEX_R:0, $ ; The position of the first R character in the selected input filename
    INDEX_NIR:0, $ ; The position of the first NIR character in the selected input filename
    INDEX_MIR:0, $ ; The position of the first MIR character in the selected input filename 
    LENGTH_B:0, $ ; The length of the B string
    LENGTH_G:0, $ ; The length of the G string
    LENGTH_R:0, $ ; The length of the R string
    LENGTH_NIR:0, $ ; The length of the NIR string
    LENGTH_MIR:0, $ ; The length of the MIR string
    FILE_B_INDEX:0, $
    FILE_G_INDEX:0, $
    FILE_R_INDEX:0, $
    FILE_NIR_INDEX:0, $
    FILE_MIR_INDEX:0, $
    CANCEL:1}) ; If CANCEL EQ 1 then the widget was canceled via the cancel or quit buttons
  ;--------------
  ; Create structure to store widget and event information
  INFO = {PTR:PTR, $ ; Output structure     
    IN_FILES:IN_FILES, $ ; The input filename array
    FILE_IN:IN_FILES[0], $ ; The selected filename string (The default value is the first filename in the filename array)    
    IN_BANDS:IN_BANDS, $
    BAND_IN:'', $
    BAND_LABEL:BAND_LABEL, $
    FILE_LIST:FILE_LIST, $ ; The file list widget ID
    FILE_LABEL:FILE_LABEL, $ ; The selected filename label widget ID
    FILE_INDEX:'', $    
    BASE_A:BASE_A, $ ; The file list base ID
    BASE_B:BASE_B, $ ; The selected filename base ID
    BASE_C:BASE_C, $ 
    BASE_D:BASE_D, $ 
    BASE_E:BASE_E, $ 
    BASE_F:BASE_F, $    
    BASE_G:BASE_G, $    
    BASE_H:BASE_H, $    
    BASE_I:BASE_I, $ 
    iLABELa_B:'', $
    iPOS_B:'', $
    iLABELb_B:'', $
    iLENGTH_B:'', $
    iLABELa_G:'', $
    iPOS_G:'', $
    iLABELb_G:'', $
    iLENGTH_G:'', $     
    iLABELa_R:'', $
    iPOS_R:'', $
    iLABELb_R:'', $
    iLENGTH_R:'', $ 
    iLABELa_NIR:'', $
    iPOS_NIR:'', $
    iLABELb_NIR:'', $
    iLENGTH_NIR:'', $
    iLABELa_MIR:'', $
    iPOS_MIR:'', $
    iLABELb_MIR:'', $
    iLENGTH_MIR:'', $
    B_STRING:'', $
    G_STRING:'', $
    R_STRING:'', $
    NIR_STRING:'', $
    MIR_STRING:''}
  ;---------------------------------------------------------------------------------------------
  WIDGET_CONTROL, PARENT, SET_UVALUE=INFO, /NO_COPY ; Set (assign) the info structure to the parent widget
  XMANAGER, 'FUNCTION_WIDGET_Set_Bands', PARENT ; Start XMANAGER
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************  
  ; Return the user defined information to the main level program:
  ;*********************************************************************************************  
  ;---------------------------------------------------------------------------------------------
  ; Get the user information from the pointer:
  INDEX_B = (*PTR).INDEX_B
  LENGTH_B = (*PTR).LENGTH_B
  FILE_B_INDEX = (*PTR).FILE_B_INDEX
  INDEX_G = (*PTR).INDEX_G  
  LENGTH_G = (*PTR).LENGTH_G  
  FILE_G_INDEX = (*PTR).FILE_G_INDEX  
  INDEX_R = (*PTR).INDEX_R 
  LENGTH_R = (*PTR).LENGTH_R
  FILE_R_INDEX = (*PTR).FILE_R_INDEX
  INDEX_NIR = (*PTR).INDEX_NIR
  LENGTH_NIR = (*PTR).LENGTH_NIR
  FILE_NIR_INDEX = (*PTR).FILE_NIR_INDEX
  INDEX_MIR = (*PTR).INDEX_MIR
  LENGTH_MIR = (*PTR).LENGTH_MIR
  FILE_MIR_INDEX = (*PTR).FILE_MIR_INDEX
  CANCEL = (*PTR).CANCEL
  ;--------------
  PTR_FREE, PTR ; Kill the pointer
  IF DESTROY_GROUPLEADER THEN WIDGET_CONTROL, GROUPLEADER, /DESTROY ; Kill the parent widget
  ;---------------------------------------------------------------------------------------------
  ; Return information:
  IF (LONG(CANCEL) EQ 1) THEN RETURN, -1 ; If the widget was canceled return -1
  RETURN, [LONG(INDEX_B),LONG(LENGTH_B),LONG(FILE_B_INDEX),LONG(INDEX_G),LONG(LENGTH_G),LONG(FILE_G_INDEX), $
    LONG(INDEX_R),LONG(LENGTH_R),LONG(FILE_R_INDEX),LONG(INDEX_NIR),LONG(LENGTH_NIR),LONG(FILE_NIR_INDEX), $
    LONG(INDEX_MIR),LONG(LENGTH_MIR),LONG(FILE_MIR_INDEX)] ; Return information to the main program level
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

