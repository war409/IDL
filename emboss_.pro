



; !VALUES.F_NAN

PRO emboss_
  
  directory = '\\osm-05-cdc\OSM_CBR_LW_FAULTS_work\Spatial\Imagery\Gloucester\Time_series\'
  filename = directory + 'ltm5sr_Gloucester_B1_19940117.dat'
  
  out_directory = '\\osm-05-cdc\OSM_CBR_LW_FAULTS_work\Spatial\Imagery\Gloucester\Convolutions\Emboss\'
  out = out_directory + 'ltm5sr_Gloucester_B1_19940117_emboss.dat'
  
  PRINT, filename
  PRINT, ''
  
  data = READ_BINARY(filename, DATA_TYPE=4) 
  help, data
  
  array = MAKE_ARRAY(1909, 2254, /FLOAT) 
  data = READ_BINARY(filename, DATA_TYPE=4) 
  array[*,*] = data
  
  k = WHERE(FINITE(array, /NAN), nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
;  l = WHERE(data LT 249.00, low_count)
;  IF (low_count GT 0) THEN data[l] = 0.00
  
  ; Emboss
;  data_ = EMBOSS(array, /ADD_BACK, AZIMUTH=225, /NAN)
  
  
  ; Create a binary disc of given radius.
  r = 7
  disc = SHIFT(DIST(2*r+1), r, r) LE r
  
;  data_ = MORPH_TOPHAT(array, disc)
  data_ = MORPH_GRADIENT(array, disc)
  
  
  OPENW, lun, out, /GET_LUN
  FREE_LUN, lun
  OPENU, lun, out, /APPEND, /GET_LUN
  WRITEU, lun, data_
  FREE_LUN, lun
  
  PRINT, 'End'
END













