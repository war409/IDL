


PRO difference_between_grids
  time = SYSTIME(1) 
  PRINT,''
  PRINT,'Start Processing: difference_between_grids'
  PRINT,''
  
  prefix = 'tmin.changegrid.'
  directory_out = 'G:\projects\saf\awap\tmin\2000\change_revised\' 
  
  
  directory_one = 'G:\projects\saf\awap\tmin\2000\5km\'
  directory_two = 'C:\saf\anuclim\1990\anuclim_1990_5km_2\subset\'
  
  filenames_one = DIALOG_PICKFILE(PATH=directory_one, TITLE='Select The Input Data', FILTER=['*.img','*.flt','*.bin'], /MUST_EXIST, /MULTIPLE_FILES)
  filenames_two = DIALOG_PICKFILE(PATH=directory_two, TITLE='Select The Input Data', FILTER=['*.img','*.flt','*.bin'], /MUST_EXIST, /MULTIPLE_FILES)
  
  FOR i = 0, N_ELEMENTS(filenames_one)-1 DO BEGIN
    itime = SYSTIME(1) 
    
    file_one = filenames_one[i]
    file_two = filenames_two[i]
    
    PRINT, file_one
    PRINT, file_two
    PRINT, ''
    
    data_one = READ_BINARY(file_one, DATA_TYPE=4) 
    data_two = READ_BINARY(file_two, DATA_TYPE=4) 

    k = WHERE(data_one EQ FLOAT(-9999), nodata_count_1)
    IF (nodata_count_1 GT 0) THEN data_one[k] = !VALUES.F_NAN
    
    m = WHERE(data_two EQ FLOAT(-9999), nodata_count_2)
    IF (nodata_count_2 GT 0) THEN data_two[m] = !VALUES.F_NAN
    
;    data_two = data_two * 31
;    data_two = data_two * 30
;    data_two = data_two * 28.25
    data_out = data_one - data_two
    
    IF (i LE 8) THEN month = '0' + STRTRIM(i+1, 2) ELSE month = STRTRIM(i+1, 2)
;    file_out = directory_out + prefix + '01' + '.flt' 
;    file_out = directory_out + prefix + '02' + '.flt' 
;    file_out = directory_out + prefix + '03' + '.flt' 
;    file_out = directory_out + prefix + '04' + '.flt' 
;    file_out = directory_out + prefix + '05' + '.flt' 
;    file_out = directory_out + prefix + '06' + '.flt' 
;    file_out = directory_out + prefix + '07' + '.flt' 
;    file_out = directory_out + prefix + '08' + '.flt' 
;    file_out = directory_out + prefix + '09' + '.flt' 
;    file_out = directory_out + prefix + '10' + '.flt' 
;    file_out = directory_out + prefix + '11' + '.flt' 
;    file_out = directory_out + prefix + '12' + '.flt' 
    file_out = directory_out + prefix + month + '.flt' 
    
    OPENW, lun, file_out, /GET_LUN 
    FREE_LUN, lun 
    
    OPENU, lun, file_out, /APPEND, /GET_LUN
    WRITEU, lun, data_out 
    FREE_LUN, lun
    
    ;PRINT, '  Processing Time: ', STRTRIM(((SYSTIME(1) - itime) / 60), 2), ' minutes, for segment ', STRTRIM(i + 1, 2), ' of ', STRTRIM(N_ELEMENTS(filenames_one), 2)
  ENDFOR
  
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(((SYSTIME(1) - time) / 60), 2), ' minutes'
END

