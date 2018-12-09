

PRO netcdf_to_bin_ozclim
  time = SYSTIME(1) 
  PRINT,''
  PRINT,'Start Processing: netCDF_to_bin'
  PRINT,''
  
  filename_short = 'tasmin_Amon_GFDL-ESM2M_rcp85_r1i1p1_seasave_2080-2099-clim-abs-change-wrt-1986-2005_native'
  
  filename = 'C:\saf\change\tmin\GFDL_ESM2M\' + filename_short + '.nc' 
  output_folder = 'C:\saf\change\tmin\GFDL_ESM2M\flt\' 
  
;  variable_name = ['pr_annual', 'pr_january', 'pr_february', 'pr_march', 'pr_april', $
;                   'pr_may', 'pr_june', 'pr_july', 'pr_august', 'pr_september', $
;                   'pr_october', 'pr_november', 'pr_december']  
  
;  variable_name = ['tasmax_annual', 'tasmax_january', 'tasmax_february', 'tasmax_march', 'tasmax_april', $
;                   'tasmax_may', 'tasmax_june', 'tasmax_july', 'tasmax_august', 'tasmax_september', $
;                   'tasmax_october', 'tasmax_november', 'tasmax_december']

  variable_name = ['tasmin_annual', 'tasmin_january', 'tasmin_february', 'tasmin_march', 'tasmin_april', $
                   'tasmin_may', 'tasmin_june', 'tasmin_july', 'tasmin_august', 'tasmin_september', $
                   'tasmin_october', 'tasmin_november', 'tasmin_december']
  
  FOR i=0, N_ELEMENTS(variable_name)-1 DO BEGIN ; File loop.
    itime = SYSTIME(1) ; Get the loop start time.
    
    variable = variable_name[i] ; Get the current variable.
    
    nc = NCDF_OPEN(filename ,/NOWRITE) ; Open netCDF.
    variableID = NCDF_VARID(nc, variable) ; Get the variable ID.
    NCDF_VARGET, nc, variableID, data ; Get data.
    NCDF_CLOSE, nc ; Close the netCDF.
    
    data = REVERSE(data)
    data = ROTATE(data, 2) 
    
    output_filename = output_folder + filename_short + '_' + variable + '.flt'
    OPENW, UNIT_Out, output_filename, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Out ; Close the output file.
    
    OPENU, UNIT_Out, output_filename, /APPEND, /GET_LUN
    WRITEU, UNIT_Out, data
    FREE_LUN, UNIT_Out
    
    PRINT, '  Processing Time: ', STRTRIM((SYSTIME(1)-itime), 2), ' seconds, for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(variable_name), 2) 
  ENDFOR    
  
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)' 
  PRINT, ''
END

