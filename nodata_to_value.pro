

; !VALUES.F_NAN

PRO nodata_to_value
  PRINT, 'Start'
  
  
  directory = '\\osm-05-cdc\OSM_CBR_LW_FAULTS_work\Spatial\Imagery\Richmond\Principal_component_analysis\Convolutions\Roberts\'
  directory = '\\osm-05-cdc\OSM_CBR_LW_FAULTS_work\Spatial\Imagery\Richmond\Principal_component_analysis\Convolutions\Roberts\'
  filename = directory + 'ltm5sr_Richmond_B7_Roberts_0_Area_of_interest_PCA.dat'
  
  out_directory = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\Lineaments\'
  out = out_directory + 'ltm5sr_Richmond_B7_Roberts_0_Area_of_interest_PCA_.dat'
  
  PRINT, filename
  PRINT, ''
  
  
  array = MAKE_ARRAY(1909, 2254, 44, /FLOAT)
  
;  data = READ_TIFF(filename, geotiff=geotiff) 
  data = READ_BINARY(filename, DATA_TYPE=4) 
  help, data
  
  array[*,*,*] = data
  
  data_ = array[*,*,0]
  help, data_
  
  data = data_
  
;  k = WHERE((data GT 1), nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(255)
  
;  k = WHERE(FINITE(data, /NAN), nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
  
  l = WHERE(data LT 249.00, low_count)
  IF (low_count GT 0) THEN data[l] = 0.00
  
  h = WHERE(data GT 2755.00, high_count)
  IF (high_count GT 0) THEN data[h] = 3.00
  
  m = WHERE(data GT 1200.00, m_count)
  IF (m_count GT 0) THEN data[m] = 2.00
  
  m2 = WHERE(data GT 249.00, m2_count)
  IF (m2_count GT 0) THEN data[m2] = 1.00  
  
;  k = WHERE(data EQ -999.00, nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)  
  
;  data = (((1 - 0) / (max(data) - min(data))) * data)
  
;  filtered = CANNY(data, HIGH=0.9, LOW=0.2, SIGMA=0.6)
  
;  k = WHERE(filtered LT 1, nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
;  data = data * 10000.0
  
;  WRITE_TIFF, out, data, geotiff=geotiff, /FLOAT ;, compression=1
  
  OPENW, lun, out, /GET_LUN
  FREE_LUN, lun
  OPENU, lun, out, /APPEND, /GET_LUN
  WRITEU, lun, data
  FREE_LUN, lun
  
  PRINT, 'End'
END













