




PRO centre_widget, parent
  ; Centre the widget.
  DEVICE, GET_SCREEN_SIZE=screensize
  x = screensize(0) / 2
  y = screensize(1) / 2
  geometry =  WIDGET_INFO(parent, /GEOMETRY)
  WIDGET_CONTROL, parent, XOFFSET=(x - (geometry.SCR_XSIZE / 2)), YOFFSET=(y - (geometry.SCR_YSIZE / 2))
END

PRO loadevent, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information, /NO_COPY
  WIDGET_CONTROL, information.load, GET_VALUE=value 
  WIDGET_CONTROL, event.top, /DESTROY
  ; Load an exiting index.
  filename = DIALOG_PICKFILE(TITLE='Enter The Index File Name', PATH='C:\', FILTER=['*.txt','*.csv'], /MUST_EXIST)
  (*information.PTR).load = filename
END


PRO createevent, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information, /NO_COPY
  WIDGET_CONTROL, information.create, GET_VALUE=value 
  WIDGET_CONTROL, event.top, /DESTROY
  ; Call the index editor.
  index = create_index()
  (*information.PTR).create = index
END


PRO grid_index_Event, event
  WIDGET_CONTROL, event.top, GET_UVALUE=information, /NO_COPY ; Get the info structure from the storage location.
  thisevent = TAG_NAMES(event, /STRUCTURE_NAME) ; Get the event name.
END





FUNCTION grid_index, title
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ; Set a groupleader (top level bases must have a group leader)
  groupleader = WIDGET_BASE(MAP = 0)
  WIDGET_CONTROL, groupleader, /REALIZE
  destroy_groupleader = 1
  ; Set the parent widget.
  parent = WIDGET_BASE(TITLE=title, TAB_MODE=2, XSIZE=(STRLEN(title[0]) * 10), GROUP_LEADER=groupleader, COLUMN=1, /MODAL, /BASE_ALIGN_CENTER)
  centre_widget, parent ; Centre the widget on the users display.
  
  ; Set the child widget.
  child = WIDGET_BASE(parent, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
  
  ; Set the button widget.
  loadbase = WIDGET_BASE(child, ROW=1, /ALIGN_CENTER)
  load = WIDGET_BUTTON(loadbase, VALUE='load', UVALUE='load', EVENT_PRO='loadevent')
  
  ; Set the button widget.
  createbase = WIDGET_BASE(child, ROW=1, /ALIGN_CENTER)
  create = WIDGET_BUTTON(createbase, VALUE='create', UVALUE='create', EVENT_PRO='createevent')
  
  ; Activate the widgets.
  WIDGET_CONTROL, parent, /REALIZE
  
  PTR = PTR_NEW({index:'', load:'', create:''}) ; Create a pointer to store user information.
  information = {PTR:PTR, load:load, create:create} ; Create a structure to store the pointer and other user information.
  WIDGET_CONTROL, parent, SET_UVALUE=information, /NO_COPY
  
  XMANAGER, 'grid_index', parent 
  
  IF (*PTR).load EQ '' THEN BEGIN
    split = STRSPLIT((*PTR).create, '_', /EXTRACT)
    x = STRSPLIT(split[0], ' ', /EXTRACT)
    y = STRSPLIT(split[1], ' ', /EXTRACT)
    x = LONG(x)
    y = LONG(y)
    result = LONARR(2, N_ELEMENTS(x))
    result[0, *] = x
    result[1, *] = y
  ENDIF ELSE BEGIN
    result = (*PTR).load
  ENDELSE
  
  PTR_FREE, PTR ; Destroy the pointer.
  IF destroy_groupleader THEN WIDGET_CONTROL, groupleader, /DESTROY
    
  return, result
END



