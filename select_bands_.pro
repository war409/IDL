











PRO select_bands_
  PRINT, 'Start'
  
  ; Richmond:
  
  filename = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\ltm5sr_Richmond_B7.tif'
  outname = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\ltm5sr_Richmond_B7_cloudfree.tif'
  
  index = [61,60,59,56,55,54,53,52,51,50, $
    49,48,47,46,45,43,42,41,40,39,37,36, $
    35,33,32,29,28,27,24,23,21,20,17,14, $
    13,8,7,6,5,4,3,2,1,0]
  
  PRINT, filename
  PRINT, ''
  
  data = READ_TIFF(filename, geotiff=geotiff)
  
  HELP, data
  data = data[index,*,*]
  HELP, data
  
;  k = WHERE(FINITE(data, /NAN), nodata_count)
;  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
  WRITE_TIFF, outname, data, geotiff=geotiff, compression=1, /FLOAT
  
  PRINT, 'End'
END











