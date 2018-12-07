; ##############################################################################################
; NAME: spatial_subset_.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 09/03/2010
; DLM: 17/05/2017

; ##############################################################################################


PRO spatial_subset_
  time = SYSTIME(1) 
  
  ; Select the input data...
  
  filenames = DIALOG_PICKFILE(PATH='\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\', TITLE='Select The Input Data', FILTER=['*.img','*.flt','*.bin','*.dat'], /MUST_EXIST, /MULTIPLE_FILES)
  IF filenames[0] EQ '' THEN RETURN 
  filenames = filenames[SORT(filenames)] 
  
  ; Remove the file path from the input filenames...
  
  start = STRPOS(filenames, '\', /REVERSE_SEARCH)+1 
  length = (STRLEN(filenames)-start)-4 
  names = MAKE_ARRAY(N_ELEMENTS(filenames), /STRING) 
  
  FOR k=0, N_ELEMENTS(filenames)-1 DO BEGIN 
    names[k] += STRMID(filenames[k], start[k], length[k]) 
  ENDFOR
  
  ; Define the spatial subset...
  
  first = filenames[0] 
  ENVI_OPEN_FILE, first, R_FID=FID_first, /NO_REALIZE 
  ENVI_FILE_QUERY, FID_first, DIMS=DIMS_first, FILE_TYPE=type_first, NS=NS_first, NL=NL_first 
  
  ; Get map information...
  
  mapinfo = ENVI_GET_MAP_INFO(FID=FID_first)
  projection = mapinfo.PROJ
  datum = mapinfo.PROJ.DATUM
  projectionname = mapinfo.PROJ.NAME
  units = mapinfo.PROJ.UNITS
  xsize = FLOAT(mapinfo.PS[0])
  ysize = FLOAT(mapinfo.PS[1])
  cxul = FLOAT(mapinfo.MC[2])
  cyul = FLOAT(mapinfo.MC[3])
  cxlo = FLOAT(mapinfo.MC[0])
  cylo = FLOAT(mapinfo.MC[1])
  
  ; Set the spatial subset...
  
  base = WIDGET_AUTO_BASE(TITLE='Define The Spatial Subset')
  subsetwidget = WIDGET_SUBSET(base, UVALUE='SUBSET', FID=FID_first, DIMS=DIMS_first, /AUTO)
  subset = AUTO_WID_MNG(base) 
  
  IF (subset.ACCEPT EQ 0) THEN BEGIN
    PRINT,'** Invalid Subset **' 
    RETURN 
  ENDIF
  
  dims_subset = subset.SUBSET 
  IF dims_subset[1] EQ 0 THEN ns_subset = (dims_subset[2] + 1) ELSE ns_subset = (dims_subset[2] - dims_subset[1]) + 1 
  IF dims_subset[3] EQ 0 THEN nl_subset = (dims_subset[4] + 1) ELSE nl_subset = (dims_subset[4] - dims_subset[3]) + 1 
  
  FOR i=0, N_ELEMENTS(filenames)-1 DO BEGIN 
    itime = SYSTIME(1) 
    
    filename = filenames[i] 
    name = names[i] 
    output_filename = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Out\' + name + '_Area_of_interest.dat' 
    
    ENVI_RESTORE_ROIS, '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\SP_Area_of_interest_May2017.roi' 
    roi_ids = ENVI_GET_ROI_IDS() 
    data = FLTARR([3179,3803]) ; Dimensions of the original data.
    addr = ENVI_GET_ROI(roi_ids[0]) 
    data[addr] = 1     
    index = WHERE(data EQ 0) 
    
    ENVI_OPEN_FILE, filename, R_FID=FID_In, /NO_REALIZE 
    ENVI_FILE_QUERY, FID_In, DATA_TYPE=output_type, NB=Band_count, DIMS=dims_in
    
    data_ = FLTARR([1909,2254,44]) ; Dimensions of the subset - area of interest
;    data_ = FLTARR([1873,2254,44]) ; Dimensions of the subset. - area of interest non-alluvium
;    data_ = FLTARR([1873,2190,44]) ; Dimensions of the subset. - alluvium
    
    FOR j=0, Band_count-1 DO BEGIN 
      data = ENVI_GET_DATA(FID=FID_In, DIMS=dims_in, POS=j) 
      data[index] = 0.00 
      data_[*,*,j] = data[(dims_subset[1]):(dims_subset[2]),(dims_subset[3]):(dims_subset[4])]
    ENDFOR
    
    mapinfo_subset = ENVI_MAP_INFO_CREATE(DATUM=datum, NAME=projectionname, PROJ=projection, PS=[xsize, ysize], $ 
                                            MC=[cxlo, cylo, cxul + (DCOMPLEX(dims_subset[1]) * DCOMPLEX(xsize)), $ 
                                            cyul - (DCOMPLEX(dims_subset[3]) * DCOMPLEX(ysize))], UNITS=units) 
    
    ENVI_WRITE_ENVI_FILE, data_, OUT_NAME=output_filename, MAP_INFO=mapinfo_subset, PIXEL_SIZE=[xsize, ysize], NB=Band_count, $ 
                             OUT_DT=output_type, NS=ns_subset, NL=nl_subset, FILE_TYPE=type_first, UNITS=units, /NO_OPEN 
    
    PRINT, '  Processing Time: ', STRTRIM(((SYSTIME(1)-itime) / 60), 2), ' minutes, for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(filenames), 2) 
  ENDFOR
  
  minutes = (SYSTIME(1) - time) / 60 
  hours = minutes / 60 
  PRINT,''
  PRINT,'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT,''
END






