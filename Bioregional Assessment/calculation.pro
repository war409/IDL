


PRO calculation
  start_time = SYSTIME(1) 
  PRINT,''
  PRINT,'Begin Processing'
  PRINT,''

  rain_filename = 'C:\Users\war409\ba\' + 'rain.s1102.2001.2010.long.term.mean.monthly.rain.img'
  mssr_filename = 'C:\Users\war409\ba\' + 'MOD09Q1.MOD09A1.CMRSET.2001.2010.MMSR.img'
  cmrset_filename = 'C:\Users\war409\ba\' + 'CMRSET.021.2001.2010.Bias.Correct.long.term.mean.monthly.AET.img'
  rain_output = 'C:\Users\war409\ba\' + 'rain.s1102.2001.2010.mean.monthly.total.img'
  output_filename = 'C:\Users\war409\ba\' + 'p.minus.et.minus.mssr.img'
  
  rain = READ_BINARY(rain_filename, DATA_TYPE=2) 
  mssr = READ_BINARY(mssr_filename, DATA_TYPE=4) 
  cmrset = READ_BINARY(cmrset_filename, DATA_TYPE=4) 
  
  
  rain_mod = rain * 0.1
  
  OPENW, lun, rain_output, /GET_LUN 
  FREE_LUN, lun 
  OPENU, lun, rain_output, /APPEND, /GET_LUN
  WRITEU, lun, rain_mod 
  FREE_LUN, lun
  
  

;  output = (rain_mod - (cmrset - mssr))
;  
;  OPENW, lun, output_filename, /GET_LUN 
;  FREE_LUN, lun 
;  OPENU, lun, output_filename, /APPEND, /GET_LUN
;  WRITEU, lun, output 
;  FREE_LUN, lun

    
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours).'
END



