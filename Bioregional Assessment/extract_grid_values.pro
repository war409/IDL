; ##############################################################################################
; NAME: extract_grid_values.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 14/01/2014
; DLM: 17/01/2014
;
; DESCRIPTION:  
;               
;               The extracted values are written to a user defined comma-delimited text file. 
;               The file name, and the coordinate index are included in the output.
;
; INPUT:        
;
; OUTPUT:       One comma-delimited text file. The output file (inc. hearder information) is 
;               formatted dynamically depending on the selected coordinates.
;               
; PARAMETERS:   Via pop-up dialog widgets:
;               
;               Functions used in this program include:
;               
;               
;
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################

FUNCTION filenames, path, filter
  names = DIALOG_PICKFILE(TITLE='Select The Input Data', PATH=path, FILTER=filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF names[0] EQ '' THEN RETURN, '-1' ELSE BEGIN 
    names = names[SORT(names)] ; Sort the input file list.
    start = STRPOS(names, '\', /REVERSE_SEARCH)+1 ; Get the position of the first filename character (after the file path).
    length = (STRLEN(names)-start)-4 ; Get the length of the filename, not including the file path.
    shortnames = MAKE_ARRAY(N_ELEMENTS(names), /STRING) ; Create an array to store the input filenames.
    FOR i=0, N_ELEMENTS(names)-1 DO BEGIN 
      shortnames[i] += STRMID(names[i], start[i], length[i]) ; Remove the file path from the file names.
    ENDFOR
    results = MAKE_ARRAY(2, N_ELEMENTS(shortnames), /STRING)
    results[0,*] = names
    results[1,*] = shortnames
    RETURN, results
  ENDELSE
END

FUNCTION strconcat, array
  format = string('(', n_elements(array), '(I0,', '" "))')
  str = string(array, format=format)
  return, strmid(str, 0, strlen(str) - 1)
END

PRO extract_grid_values
  starttime = systime(1) 
  print, ''
  print, 'begin processing: extract_grid_values'
  print, ''
  
  ;---------------------------------------------------------------------------------------------
  ; input / output
  ;---------------------------------------------------------------------------------------------
  
  ; Define the input files.
  files = filenames('G:\projects\NWC_Groundwater_Dependent_Ecosystems\data\', ['*.tif','*.img','*.flt','*.bin'])
  IF files[0] EQ '-1' THEN return

  ; Define the output file.
  result = DIALOG_PICKFILE(TITLE='Define The Output File', PATH='C:\', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  IF result EQ '' THEN return

  ; Define the input data type.
  datatype = droplist(TITLE='Select The Input Datatype:', $
                      VALUE=['UNDEFINED : Undefined', $
                      'BYTE : Byte', $
                      'INT : Integer', $
                      'LONG : Longword integer', $
                      'FLOAT : Floating point', $
                      'DOUBLE : Double-precision floating', $
                      'COMPLEX : Complex floating', $
                      'STRING : String', $
                      'STRUCT : Structure', $
                      'DCOMPLEX : Double-precision complex', $
                      'POINTER : Pointer', $
                      'OBJREF : Object reference', $
                      'UINT : Unsigned Integer', $
                      'ULONG : Unsigned Longword Integer', $
                      'LONG64 : 64-bit Integer', $
                      'ULONG64 : Unsigned 64-bit Integer'], LABEL='Datatype:')
  IF (datatype EQ 7) OR (datatype EQ 8) OR (datatype EQ 9) OR (datatype EQ 10) OR (datatype EQ 11) OR (datatype EQ -1) THEN return
  
  ; Get the file dimensions.
  file = READ_BINARY(files[0], DATA_TYPE=datatype) ; Open the first input file.
  count = N_ELEMENTS(file) ; Get the number of grid elements in the input file.
  values = double_text_box('Set The Grid Size...', ['Columns: ', 'Rows: '], [841, 681])
  columns = LONG(values[0])
  rows = LONG(values[1])
  IF (count NE (columns * rows)) THEN BEGIN
    print, 'The selected grid dimensions and the dimensions of the input file do not match'
    return
  ENDIF
  
  ; Define the file index.
  index = grid_index('Define The Grid Index')
  IF (TYPENAME(index) EQ 'STRING') THEN BEGIN
    OPENR, lun, index, /GET_LUN
    line = ''
    x = []
    y = []
    xy = []
    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      line = STRSPLIT(line, ',', /EXTRACT)
      x = [x, line[0]]
      y = [y, line[1]]
      xy = [xy, line[0] + '_' + line[1]]
      line = ''
    ENDWHILE
    FREE_LUN, lun
  ENDIF ELSE BEGIN
    x = index[0,*]
    y = index[1,*]
    xy = []
    FOR i=0, N_ELEMENTS(x)-1 DO BEGIN
      xy = [xy, STRTRIM(index[0,i], 2) + '_' +  STRTRIM(index[1,i], 2)]
    ENDFOR
  ENDELSE
  
  ; Write the output file.
  filehead = MAKE_ARRAY(N_ELEMENTS(x)+2, /STRING)
  filehead[0] = 'fid' 
  filehead[1] = 'filename' 
  FOR i=0, N_ELEMENTS(x)-1 DO BEGIN
    IF i EQ 0 THEN j=2 ELSE j=j+1 
    filehead[j] += xy[i] ; Add the index or region name to the array as a new column.
  ENDFOR
  OPENW, fileid, result, /GET_LUN 
  PRINTF, FORMAT='(10000(A,:,","))', fileid, '"' + filehead + '"' 
  FREE_LUN, fileid 
  
  ;---------------------------------------------------------------------------------------------
  ; extract data
  ;---------------------------------------------------------------------------------------------
  
  ; File loop.
  FOR i=0, N_ELEMENTS(files[0,*])-1 DO BEGIN 
    looptime = SYSTIME(1)
    
    ; Load data.
    data = READ_BINARY(files[0,[i]], DATA_TYPE=datatype)
    
    ; Build arrays to hold the grid data and the extracted grid data.
    IF (datatype EQ 1) THEN array = MAKE_ARRAY(columns, rows, /BYTE) 
    IF (datatype EQ 2) THEN array = MAKE_ARRAY(columns, rows, /INTEGER) 
    IF (datatype EQ 3) THEN array = MAKE_ARRAY(columns, rows, /LONG) 
    IF (datatype EQ 4) THEN array = MAKE_ARRAY(columns, rows, /FLOAT) 
    IF (datatype EQ 5) THEN array = MAKE_ARRAY(columns, rows, /DOUBLE)
    IF (datatype EQ 6) THEN array = MAKE_ARRAY(columns, rows, /COMPLEX) 
    IF (datatype EQ 9) THEN array = MAKE_ARRAY(columns, rows, /DCOMPLEX) 
    IF (datatype EQ 12) THEN array = MAKE_ARRAY(columns, rows, /UINT) 
    IF (datatype EQ 13) THEN array = MAKE_ARRAY(columns, rows, /ULONG) 
    IF (datatype EQ 14) THEN array = MAKE_ARRAY(columns, rows, /L64)
    IF (datatype EQ 15) THEN array = MAKE_ARRAY(columns, rows, /UL64)
    IF (datatype EQ 1) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /BYTE)
    IF (datatype EQ 2) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /INTEGER)
    IF (datatype EQ 3) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /LONG)
    IF (datatype EQ 4) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /FLOAT)
    IF (datatype EQ 5) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /DOUBLE)
    IF (datatype EQ 6) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /COMPLEX)
    IF (datatype EQ 9) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /DCOMPLEX)
    IF (datatype EQ 12) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /UINT)
    IF (datatype EQ 13) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /ULONG)
    IF (datatype EQ 14) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /L64)
    IF (datatype EQ 15) THEN results = MAKE_ARRAY(N_ELEMENTS(x), /UL64)
    array[*] = data
    
    ; Site loop. Extract data at the selected locations.
    FOR j=0, N_ELEMENTS(x)-1 DO BEGIN
      results[j] = array[x[j], y[j]]
    ENDFOR
    
    ; Write the data to the output file.
    OPENU, fileid, result, /APPEND, /GET_LUN
    IF datatype EQ 1 THEN BEGIN
      PRINTF, FORMAT='(10000(A,:,","))', fileid, STRTRIM(i+1, 2), '"' + files[1,[i]] + '"', STRTRIM(FIX(results), 2)
    ENDIF ELSE BEGIN
      PRINTF, FORMAT='(10000(A,:,","))', fileid, STRTRIM(i+1, 2), '"' + files[1,[i]] + '"', STRTRIM(results, 2)
    ENDELSE
    FREE_LUN, fileid 
    
    ; Print loop information.
    minutes = (SYSTIME(1) - looptime) / 60
    print, '  processing time: ', STRTRIM(minutes, 2), ' minutes, for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(files[0,*]), 2) 
  ENDFOR
  
  ; Print script information.
  minutes = (SYSTIME(1) - starttime) / 60
  hours = minutes / 60
  print,''
  print,'total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  print,''  
END  





