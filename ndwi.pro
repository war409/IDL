


PRO ndwi
  PRINT, 'Start'
 
  filename_B4 = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\ltm5sr_Richmond_B4_CloudFree.dat'
  filename_B5 = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\ltm5sr_Richmond_B5_CloudFree.dat'
  outfn = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\Projects\Fault_related_lineaments\Data\Richmond\ltm5sr_Richmond_NDWI.dat'
  
  PRINT, filename_B4
  PRINT, filename_B5
  
  PRINT, ''
  
;  nir = READ_TIFF(filename_B4, geotiff=geotiff)
;  swir = READ_TIFF(filename_B5, geotiff=geotiff)
  
  nir = READ_BINARY(filename_B4, DATA_TYPE=4)
  swir = READ_BINARY(filename_B5, DATA_TYPE=4)
  
  HELP, nir
  HELP, swir
  
  ndwi = (nir - swir) / (nir + swir)
  
;  WRITE_TIFF, outfn, ndwi, geotiff=geotiff, /FLOAT
  
  OPENW, lun, outfn, /GET_LUN
  FREE_LUN, lun
  OPENU, lun, outfn, /APPEND, /GET_LUN
  WRITEU, lun, ndwi
  FREE_LUN, lun
  
  PRINT, 'End'
END









