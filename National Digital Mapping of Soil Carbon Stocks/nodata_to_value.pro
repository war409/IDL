


PRO nodata_to_value
  time = SYSTIME(1) 
  PRINT,''
  PRINT,'Start'
  PRINT,''
  
  filename = 'C:\Workspace\GoogleEarthEngine\tiff\Darwin_Wildman_River_LTM5SR_NDVI_03.tif'
  out = 'C:\Workspace\GoogleEarthEngine\tiff\Darwin_Wildman_River_LTM5SR_NDVI_03_.tif'
  
  PRINT, filename
  PRINT, ''
  
  data = READ_BINARY(filename, DATA_TYPE=4)
  
  k = WHERE(FINITE(data, /NAN), nodata_count)
  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
  
  
  
  
  
  
  
  OPENW, lun, out, /GET_LUN
  FREE_LUN, lun
  
  OPENU, lun, out, /APPEND, /GET_LUN
  WRITEU, lun, data
  FREE_LUN, lun
  
  PRINT,'End'
END

