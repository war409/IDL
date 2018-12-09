;+
; This procedure reads daily SILO data and calculates monthly sums.
; It works with rainfall and evappt data
;
; @ author: Juan Pablo Guerschman
; Modified from calculate_monthly_means_SILO_v3
; 6 Aug 2009
;-
;
; This program reads daily SILO (PET and RAIN in this version) and


Function SILO_Rain_fname, day, month, year
  if month le 9 then month_app='0' else  month_app=''
  if day le 9 then day_app='0' else  day_app=''

      folder = STRCOMPRESS('\\file-wron\TimeSeries\Climate\usilo\rain\'+STRING(Year)+'\' , /REMOVE_ALL)  
      
      file_name_starts_with = STRCOMPRESS( $
                STRING(year) + $
                month_app + STRING(month) + $
                day_app + STRING(day) + $
                '_rain_', /REMOVE_ALL)  
                
   if year EQ 2000 then $
      last_bit = 's0504.flt'
   if year EQ 2001 then $
      last_bit = 's0701.flt'
   if year GE 2002 AND year LE 2003 then $
      last_bit = 's0504.flt'
   if year EQ 2004 then $
      last_bit = 's0602.flt'
   if year GE 2005 AND year LE 2006 then $
      last_bit = 's0708.flt'
   if year GE 2007  then $
      last_bit = 's0905.flt'
    
   result = folder + file_name_starts_with + last_bit  
   return, result
end

Function SILO_evap_fname, day, month, year
  if month le 9 then month_app='0' else  month_app=''
  if day le 9 then day_app='0' else  day_app=''

  if year LT 2005 then $
      folder_evap = STRCOMPRESS('\\file-wron\TimeSeries\Climate\usilo\evap\'+STRING(Year)+'\' , /REMOVE_ALL)  $
  else $
      folder_evap = STRCOMPRESS('\\file-wron\TimeSeries\Climate\usilo\evappt\'+STRING(Year)+'\' , /REMOVE_ALL)  
      
   if year LT 2005 then $
      file_name_starts_with = STRCOMPRESS( $
                STRING(year) + $
                month_app + STRING(month) + $
                day_app + STRING(day) + $
                '_evap_', /REMOVE_ALL)  $
   else $
       file_name_starts_with = STRCOMPRESS( $
                STRING(year) + $
                month_app + STRING(month) + $
                day_app + STRING(day) + $
                '_evappt_', /REMOVE_ALL)  
                
   if year LE 2003 then $
      last_bit = 's0504.flt'
   if year EQ 2004 then $
      last_bit = 's0602.flt'
   if year GE 2005 then $
      last_bit = 's0905.flt'
    
   result = folder_evap + file_name_starts_with + last_bit

  return, result 
end




pro calculate_monthly_means_SILO_v4
	compile_opt idl2

	;fname_input = filenames_SILO_rain_daily ()
	;fname_output = filenames_SILO_rain_monthly ()


	; START PROCESSING
	t= systime(1)
	for year=2000,2009 do begin
		for month=1,12 do begin
			print, year, month


			RAIN_data= fltarr( 841,681, 31) & RAIN_data[*]= !VALUES.F_NAN
			PET_data=  fltarr( 841,681, 31) & PET_data[*]= !VALUES.F_NAN

			; START READING DAILY DATA FOR YEAR-YEAR, MONTH=MONTH

			for day=1,DaysPerMonth(month, year) do begin
				;print, year, month, day


				fname_RAIN= SILO_Rain_fname(day, month, year)
				fname_RAIN_info =  FILE_INFO(fname_RAIN)

				fname_PET= 	SILO_Evap_fname(day, month, year)
				fname_PET_info =  FILE_INFO(fname_PET)


 				if fname_RAIN_info.Exists eq 1 then $
   					RAIN_data [*,*,day-1]= read_binary(fname_RAIN , DATA_TYPE=4, DATA_DIMS=[841,681]) $
   					else $
   					print, fname_RAIN, ' does not exist'

 				if fname_PET_info.Exists eq 1 then $
   					PET_data [*,*,day-1]= read_binary(fname_PET , DATA_TYPE=4, DATA_DIMS=[841,681])   $
            else $
            print, fname_PET, ' does not exist'


			endfor

			;gets rid of -999s
			RAIN_data[where(RAIN_data eq -999)] = !VALUES.F_NAN
			PET_data[where(PET_data eq -999)] = !VALUES.F_NAN

			RAIN_monthly = TOTAL(RAIN_data, 3, /NAN)    ; CALCULATES MONTHLY TOTAL
			PET_monthly = TOTAL(PET_data, 3, /NAN)    ; CALCULATES MONTHLY TOTAL

      if month le 9 then month_app='0' else  month_app=''
			fname_RAIN_output= 	STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\RAIN\' + $
								STRING(year) + $
								month_app + STRING(month) + $
								'_rain.flt', /REMOVE_ALL )
   			OPENW, 1, fname_RAIN_output
   			WRITEU, 1, RAIN_monthly
   			CLOSE, 1

			fname_PET_output= 	STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\EVAP\' + $
								STRING(year) + $
								month_app + STRING(month) + $
								'_evappt.flt', /REMOVE_ALL )
   			OPENW, 1, fname_PET_output
   			WRITEU, 1, PET_monthly
   			CLOSE, 1


	print, systime(1)-t, ' seconds for processing year', year, ' month', month

	endfor & endfor

end




