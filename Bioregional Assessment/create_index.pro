

PRO centre_widget, parent
  ; Centre the widget.
  DEVICE, GET_SCREEN_SIZE=screensize
  x = screensize(0) / 2
  y = screensize(1) / 2
  geometry =  WIDGET_INFO(parent, /GEOMETRY)
  WIDGET_CONTROL, parent, XOFFSET=(x - (geometry.SCR_XSIZE / 2)), YOFFSET=(y - (geometry.SCR_YSIZE / 2))
END

PRO cancel, event
  WIDGET_CONTROL, event.top, /DESTROY
END

PRO ok, event
  WIDGET_CONTROL, event.top, /DESTROY
END

PRO list, event
  WIDGET_CONTROL, event.top, /DESTROY
END


function strconcat, array
  format = string('(', n_elements(array), '(I0,', '" "))')
  str = string(array, format=format)
  return, strmid(str, 0, strlen(str) - 1)
end



PRO delete, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information
  WIDGET_CONTROL, event.id, GET_UVALUE=uvalue
  
  substrings = STRSPLIT(uvalue, '_', /EXTRACT)
  
  x = (*information.PTR).x
  y = (*information.PTR).y
  
  subx = STRSPLIT(x, ' ', /EXTRACT)
  suby = STRSPLIT(y, ' ', /EXTRACT)
  
  wherex = WHERE(STRMATCH(subx, substrings[2]))
  wherey = WHERE(STRMATCH(suby, substrings[3]))
  length = N_ELEMENTS(subx)-1
  
  IF (N_ELEMENTS(wherex) EQ 1) THEN BEGIN
    IF (wherex EQ 0) THEN BEGIN
      subx[wherex] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, '[!0-9]*^0 ', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(subx) EQ 1) THEN subx = subx[0] ELSE subx = strconcat(subx)
      suby[wherey] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, '[!0-9]*^0 ', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(suby) EQ 1) THEN suby = suby[0] ELSE suby = strconcat(suby)
    ENDIF
    IF (wherex EQ length) THEN BEGIN
      subx[wherex] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, ' 0', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(subx) EQ 1) THEN subx = subx[0] ELSE subx = strconcat(subx)
      suby[wherey] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, ' 0', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(suby) EQ 1) THEN suby = suby[0] ELSE suby = strconcat(suby)
    ENDIF
    IF (wherex NE 0) AND (wherex NE length) THEN BEGIN
      subx[wherex] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, ' 0 ', /EXTRACT)
      subx = strconcat(subx)
      suby[wherey] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, ' 0 ', /EXTRACT)
      suby = strconcat(suby)
    ENDIF
  ENDIF ELSE BEGIN
    IF (wherex[0] EQ 0) THEN BEGIN
      subx[wherex[0]] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, '[!0-9]*^0 ', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(subx) EQ 1) THEN subx = subx[0] ELSE subx = strconcat(subx)
      suby[wherey[0]] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, '[!0-9]*^0 ', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(suby) EQ 1) THEN suby = suby[0] ELSE suby = strconcat(suby)
    ENDIF
    IF (wherex[0] EQ length) THEN BEGIN
      subx[wherex[0]] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, ' 0', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(subx) EQ 1) THEN subx = subx[0] ELSE subx = strconcat(subx)
      suby[wherey[0]] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, ' 0', /EXTRACT, /REGEX)
      IF (N_ELEMENTS(suby) EQ 1) THEN suby = suby[0] ELSE suby = strconcat(suby)
    ENDIF
    IF (wherex[0] NE 0) AND (wherex[0] NE length) THEN BEGIN
      subx[wherex[0]] = ''
      subx = strconcat(subx)
      subx = STRSPLIT(subx, ' 0 ', /EXTRACT)
      subx = strconcat(subx)
      suby[wherey[0]] = ''
      suby = strconcat(suby)
      suby = STRSPLIT(suby, ' 0 ', /EXTRACT)
      suby = strconcat(suby)
    ENDIF
    
  ENDELSE
  
  (*information.PTR).x = subx
  (*information.PTR).y = suby
  
  WIDGET_CONTROL, event.id, /DESTROY
  WIDGET_CONTROL, LONG(substrings[0]), /DESTROY
  WIDGET_CONTROL, LONG(substrings[1]), /DESTROY
  
END




PRO add, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information
  WIDGET_CONTROL, event.id, GET_UVALUE=events
  
  WIDGET_CONTROL, information.x, GET_VALUE=result_a
  WIDGET_CONTROL, information.y, GET_VALUE=result_b
  
  (*information.PTR).x = (*information.PTR).x + ' ' + result_a
  (*information.PTR).y = (*information.PTR).y + ' ' + result_b

  xlabel = WIDGET_LIST(information.base_d1, $
                       VALUE=STRTRIM(result_a[0], 2), $
                       XSIZE=9, $
                       YSIZE=1, $
                       SENSITIVE=0)
  
  ylabel = WIDGET_LIST(information.base_d2, $
                       VALUE=STRTRIM(result_b[0], 2), $
                       XSIZE=9, $
                       YSIZE=1, $
                       SENSITIVE=0)
  
  rvalue = STRTRIM(xlabel, 2) + '_' + STRTRIM(ylabel, 2) + '_' + result_a + '_' + result_b
  
  rlabel = WIDGET_LIST(information.base_d3, $
                       FRAME=1, $
                       VALUE='delete', $
                       UVALUE=rvalue, $
                       XSIZE=5, $
                       YSIZE=1, $
                       EVENT_PRO='delete')
  
  information.xlabel = xlabel
  information.ylabel = ylabel
  information.rlabel = rlabel
  
  WIDGET_CONTROL, EVENT.top, SET_UVALUE=information, /NO_COPY ; Put the updated info structure back in the storage location.
END






PRO create_index_Event, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information, /NO_COPY ; Get the info structure from the storage location.
  thisevent = TAG_NAMES(event, /STRUCTURE_NAME) ; Get the event name.
END










FUNCTION create_index
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ; Set a groupleader (top level bases must have a group leader)
  groupleader = WIDGET_BASE(MAP = 0)
  WIDGET_CONTROL, groupleader, /REALIZE
  destroy_groupleader = 1
  
  ; Set the parent widget.
  ;parent = WIDGET_BASE(TITLE='Index Tool...', TAB_MODE=2, XSIZE=(STRLEN('Index Tool...') * 15), XPAD=1, YPAD=1, GROUP_LEADER=groupleader, COLUMN=1, /MODAL, /BASE_ALIGN_CENTER)
  
  ; Find the parent widget offset using the screen size:
  DEVICE, GET_SCREEN_SIZE=size
  IF size[0] GT 2000 THEN size[0] = size[0]/2
  xcentre = FIX(size[0] / 2.0)
  ycentre = FIX(size[1] / 2.0)
  xoffset = xcentre - 150
  yoffset = ycentre - 200
  
  ; Create parent widget:
  parent = WIDGET_BASE(TITLE='Index Tool...', GROUP_LEADER=groupleader, COLUMN=1, TAB_MODE=1, $ ;SPACE=5, $
                       TLB_FRAME_ATTR=1, XOFFSET=xoffset, YOFFSET=yoffset, /MODAL, /BASE_ALIGN_CENTER)
  
  centre_widget, parent ; Centre the widget on the users display.
  
  ; Set the child widget.
  child_a = WIDGET_BASE(parent, TAB_MODE=1, XPAD=0, YPAD=0, /ROW)
  
  ; Set the first (left) text box widget.
  base_a = WIDGET_BASE(child_a, YSIZE=25, /COLUMN)
  x = CW_FIELD(base_a, XSIZE=6, VALUE=1, TITLE='X:', /RETURN_EVENTS)
  
  ; Set the second (right) text box widget.
  base_b = WIDGET_BASE(child_a, YSIZE=25, /COLUMN)
  y = CW_FIELD(base_b, XSIZE=6, VALUE=1, TITLE='Y:', /RETURN_EVENTS)
  
  ; Create button widget.
  base_c = WIDGET_BASE(parent, YOFFSET=0, YSIZE=25)
  add_button = WIDGET_BUTTON(base_c, VALUE='ADD', UVALUE='add', EVENT_PRO='add')
  
  
  base_d0 = WIDGET_BASE(parent, FRAME=1, XSIZE=215, /ROW, /BASE_ALIGN_CENTER)
  labelx = WIDGET_LABEL(base_d0, VALUE='  X Index: ', /ALIGN_CENTER)
  labely = WIDGET_LABEL(base_d0, VALUE='Y Index: ', /ALIGN_CENTER, XSIZE=100)
  
  base_d = WIDGET_BASE(parent, FRAME=1, XSIZE=215, COLUMN=3, Y_SCROLL_SIZE=165, /BASE_ALIGN_CENTER, /SCROLL)
  base_d1 = WIDGET_BASE(base_d, /COLUMN)
  base_d2 = WIDGET_BASE(base_d, /COLUMN)
  base_d3 = WIDGET_BASE(base_d, /COLUMN)
  
  ; Create button widget.
  base_e = WIDGET_BASE(parent, /ROW)
  ok_button = WIDGET_BUTTON(base_e, VALUE='OK', EVENT_PRO='ok')
  cancel_button = WIDGET_BUTTON(base_e, VALUE='Cancel', UVALUE='cancel', EVENT_PRO='cancel')
  
  ; Activate the widgets.
  WIDGET_CONTROL, parent, /REALIZE
  PTR = PTR_NEW({index:'', x:'', y:''}) ; Create a pointer to store user information.
  information = {PTR:PTR, $
                 base_a:base_a, $
                 base_b:base_b, $
                 base_c:base_c, $
                 base_d:base_d, $
                 base_d1:base_d1, $
                 base_d2:base_d2, $
                 base_d3:base_d3, $
                 base_e:base_e, $
                 x:x, $
                 y:y, $
                 add_button:'', $
                 xlabel:'', $
                 ylabel:'', $
                 rlabel:''} 
  WIDGET_CONTROL, parent, SET_UVALUE=information, /NO_COPY
  XMANAGER, 'create_index', parent 
  
  ; Get information from the pointer:
  x = (*PTR).x
  y = (*PTR).y
  
  result = x + '_' + y
  
  PTR_FREE, PTR ; Kill the pointer.
  IF destroy_groupleader THEN WIDGET_CONTROL, groupleader, /DESTROY ; Kill the parent widget.
  
  ; Return the information.
  IF (x[0] EQ 0) OR (y[0] EQ 0) THEN return, [-1, -1] ELSE BEGIN
    return, result
  ENDELSE
  
END

