






PRO value_to_value
  PRINT, 'Start'
  
  d_in = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\_Archive\NWC_groundwater_dependent_ecosystems\data\cmrset\cmrset.bias'
  d_out = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\CMRSET\Day_fill'
  
  files = DIALOG_PICKFILE(PATH=d_in, TITLE='SELECT THE INPUT DATA', FILTER=['*.img','*.flt','*.bin','*.bsq','*.dat', '*tif'], /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
  
  fstart = STRPOS(files, '\', /REVERSE_SEARCH)+1
  flength = (STRLEN(files)-fstart)
  fout = MAKE_ARRAY(N_ELEMENTS(files), /STRING)
  FOR a=0, N_ELEMENTS(files)-1 DO fout[a] += d_out + '\' + STRMID(files[a], fstart[a], flength[a])
  
  FOR i=0, N_ELEMENTS(files)-1 DO BEGIN
    
    PRINT, ''
    PRINT, files[i]
    PRINT, fout[i]
    
    data = READ_BINARY(files[i], DATA_TYPE=2)
    
    k = WHERE(data EQ -999, count, complement=l, ncomplement=ncount)
    IF (count GT 0) THEN data[k] = 0
    IF (ncount GT 0) THEN data[l] = 1
    
    OPENW, lun, fout[i], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, fout[i], /APPEND, /GET_LUN
    WRITEU, lun, data
    FREE_LUN, lun
  
  ENDFOR
  
  PRINT, ''
  PRINT, 'End'
END













