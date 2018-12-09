
;+
; This program calculates AET using MODIS, SILO inputs.
; It calculates AET following the updated version of the model and calibration, performed in December 2007
;
; @author Juan Pablo Guerschman
; @Date: 8 January 2008
;-------
; Modified from V4 on Aug 7 2009
; Now the procedure uses data inputs from MCD43A4 collection 5 (500 meters)
; reads bands 1,2,3 and 6 and calculates NDVI and GVMI internally
; also reads SILO rainfall and potential ET in the original dimensions (841 * 681) and resamples that into
; MODIS 500 m size internally.
;-



function SILO_Rain_monthly_fname, month, year
  if month le 9 then month_app='0' else  month_app=''
  fname_RAIN_output = STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\RAIN\' + STRING(year) + month_app + STRING(month) + '_rain.flt', /REMOVE_ALL )
  RETURN, fname_RAIN_output
end



function SILO_PET_monthly_fname, month, year
  if month le 9 then month_app='0' else  month_app=''
  fname_PET_output = STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\EVAP\' + STRING(year) + month_app + STRING(month) + '_evappt.flt', /REMOVE_ALL )
  RETURN, fname_PET_output
end



; this function returns the filename (including path) for the output (monthly) synthetic NBAR composite.
function MCD43A4_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\MCD43A4_monthly\'
  IF month LE 9 THEN app_month = '0' ELSE app_month = ' '
  fname = strarr(7)
  
  FOR i=0, 6 DO BEGIN
    CASE i OF
      0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.img'
      1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.img'
      2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.img'
      3: Band_text= 'aust.005.b04.500m_0545_0565nm_nbar.img'
      4: Band_text= 'aust.005.b05.500m_1230_1250nm_nbar.img'
      5: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.img'
      6: Band_text= 'aust.005.b07.500m_2105_2155nm_nbar.img'
    ENDCASE

    fname_i = strcompress(path + 'MCD43A4.' + String(year) + '.' + app_month + String(month) +  '.' + Band_text , /REMOVE_ALL)
    fname[i] = fname_i
  ENDFOR

  return, fname
END



function AET_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\AET\'
  if month le 9 then app_month = '0' else app_month = ' '
  Band_text= 'AET.img'
  
  fname = strcompress( $
    path + $
    'MCD43A4.' + $
    String (year) + '.' + $
    app_month + String(month) +  '.' + $
    Band_text , $
    /REMOVE_ALL )
  
  return, fname
end


function eff_kc_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\eff_kc\'
  if month le 9 then app_month = '0' else app_month = ' '
  Band_text= 'eff_kc.img'

  fname = strcompress( $
    path + $
    'MCD43A4.' + $
    String (year) + '.' + $
    app_month + String(month) +  '.' + $
    Band_text , $
    /REMOVE_ALL )
  
  return, fname
END



FUNCTION RAIN_AET_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\RAIN_AET\'
  if month le 9 then app_month = '0' else app_month = ' '
  Band_text= 'RAIN_AET.img'

  fname = strcompress($
    path + $
    'MCD43A4.' + $
    String (year) + '.' + $
    app_month + String(month) +  '.' + $
    Band_text , $
    /REMOVE_ALL)

  return, fname
END



FUNCTION Resample_SILO_to_MCD43, array
  size_array = Size(Array)
  
  if size_array[0] ne 2 then begin
    print, 'array must have 2 dimensions'
    return, 0
  endif
  
  if size_array[1] ne 841 or size_array[2] ne 681 then begin
    print, 'array must be of size 841 * 681'
    return, 0
  endif

  ; fills array with 40 columns left, 20 right and 20 bottom
  new_Array = FltArr(901, 701)
  new_Array[40:40+840, 0:680] = Array

  ; resize new array to MODIS 500m dimensions
  new_Array_MCD43_Size = Congrid(new_Array, 9591, 7462)

  ; gets rid of left, top 5 pixels , bottom , right 6 pixels
  new_array_final = new_Array_MCD43_Size[5:9584, 5:7455]

  RETURN, new_array_final
END



FUNCTION EVI_MCD43, BLUE_, RED_, NIR_
  BLUE_ *= 0.0001
  RED_ *= 0.0001
  NIR_ *= 0.0001
  RESULT = (2.5* ((NIR_ - RED_) / (NIR_ + 6 * RED_ - 7.5 * BLUE_ + 1) ))
  RETURN, RESULT
END



FUNCTION GVMI_MCD43, NIR_, SWIR2_
  NIR_ *= 0.0001
  SWIR2_ *= 0.0001
  RESULT = ((NIR_ + 0.1)-(SWIR2_ + 0.02)) / ((NIR_ + 0.1) + (SWIR2_ + 0.02))
  RETURN, RESULT
END



FUNCTION AET_model1, EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max, FLUX_SITE
	COMPILE_OPT idl2
	
	; CALCULATE CMI
	k_CMI=	k_CMI
	C_CMI=	C_CMI
	CMI = GVMI - (k_CMI * EVI + C_CMI)
	
	; CALCULATES EVI_r
	EVI_min=  EVI_min
	EVI_max=  EVI_max
	EVI_r = (((EVI-EVI_min)/(EVI_max-EVI_min)) > 0) < 1

	; CALCULATES CMI_r
	CMI_min = 0.
	CMI_max = CMI_max
	CMI_r = (((CMI-CMI_min)/(CMI_max-CMI_min)) > 0) < 1

	;CALCULATE kc
	k_max = k_max
	a = a
	alpha =	alpha
	b = b
	beta = beta
	kc = k_max * (1-EXP(-a*EVI_r^alpha-b*CMI_r^beta))
	
	; CALCULATE k_Ei
	k_Ei_max=	k_Ei_max
	k_Ei = k_Ei_max * EVI_r
  
	;calculate AET_model1
	AET_1 = kc * PET + k_Ei * RAIN
  
	RETURN, AET_1
END



PRO aet_forward_calculation_V5
  compile_opt idl2
	
	; Define model parameters.
	
	k_max = 0.679704
	a  = 14.118289
	alpha  = 2.481207
	b  = 7.991423
	beta = 0.889975
	k_Ei_max = 0.229422
	k_CMI = 0.774739
	C_CMI  = -0.075699
	CMI_max  = 1
	EVI_min  = 0
	EVI_max  = 0.9
	
	FNAME = '\\file-wron\Working\work\Juan_Pablo\auxiliary\land_mask_australia_MCD43'
	envi_open_file, FNAME, r_fid=fid_LAND, /No_Realize
	if (fid_LAND eq -1) then return
	envi_file_query, fid_LAND, ns=ns, nl=nl, nb=nb
	MAP_INFO = ENVI_GET_MAP_INFO  (FID=fid_LAND)
	dims_LAND = [-1, 0, ns-1, 0, nl-1]
	LAND= envi_get_data(fid=fid_LAND, dims=DIMS_LAND, pos=0)
	
  FOR year=2000, 2009 DO BEGIN
    if year eq 2000 then init_month=2 ELSE init_month=1
    
    for month=init_month, 12 do begin
     
      dpm = DaysPerMonth(month, year)
      
      ; reads MCD43A4 band1
      envi_open_file, (MCD43A4_monthly_fname(month, year))[0], r_fid=fid_band1, /No_Realize
      envi_file_query, fid_band1, ns=ns, nl=nl, nb=nb
      dims_band1 = [-1, 0, ns-1, 0, nl-1]
  
      ; reads MCD43A4 band2
      envi_open_file, (MCD43A4_monthly_fname(month, year))[1], r_fid=fid_band2, /No_Realize
      envi_file_query, fid_band2, ns=ns, nl=nl, nb=nb
      dims_band2 = [-1, 0, ns-1, 0, nl-1]
  
      ; reads MCD43A4 band3
      envi_open_file, (MCD43A4_monthly_fname(month, year))[2], r_fid=fid_band3, /No_Realize
      envi_file_query, fid_band3, ns=ns, nl=nl, nb=nb
      dims_band3 = [-1, 0, ns-1, 0, nl-1]
  
       ; reads MCD43A4 band6
      envi_open_file, (MCD43A4_monthly_fname(month, year))[5], r_fid=fid_band6, /No_Realize
      envi_file_query, fid_band1, ns=ns, nl=nl, nb=nb
      dims_band6 = [-1, 0, ns-1, 0, nl-1]
      
      RED = envi_get_data(fid=fid_band1, dims=dims_band1, pos=0)
      NIR = envi_get_data(fid=fid_band2, dims=dims_band2, pos=0)
      BLUE = envi_get_data(fid=fid_band3, dims=dims_band3, pos=0)
      SWIR2 = envi_get_data(fid=fid_band6, dims=dims_band6, pos=0)
    
      ; Selects pixels with values OK. From now on makes operations with only those pixs and goes faster
      where_OK = where(LAND eq 1 AND RED gt -32000 AND NIR gt -32000 AND BLUE gt -32000 AND SWIR2 gt -32000, complement=where_NO_OK)
    
      EVI = EVI_MCD43(BLUE[where_OK], RED[where_OK], NIR[where_OK])
      GVMI = GVMI_MCD43(NIR[where_OK], SWIR2[where_OK])
      
      fname = SILO_PET_monthly_fname(month, year)
      PET= read_binary(fname , DATA_TYPE=4, DATA_DIMS=[841,681])
  
      fname = SILO_RAIN_monthly_fname(month, year)
      RAIN= read_binary(fname , DATA_TYPE=4, DATA_DIMS=[841,681])
      
      PET = Resample_SILO_to_MCD43(Temporary(PET))
      RAIN = Resample_SILO_to_MCD43(Temporary(RAIN))
      
      PET= temporary(PET[where_ok])
      RAIN= temporary(RAIN[where_ok])
      
  		; Converts PET and RAIN to mm/day (orig data in mm/month)
  		PET /= dpm
  		RAIN /= dpm
  
  		; calculate AET_model1
  		AET_1 = AET_model1(EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max)
  		effective_Kc = (AET_1 / PET) * 100
  		RAIN_minus_AET = RAIN - AET_1
  
  		; Converts values back to mm/month (and convert into integer)
  		AET_1 *= dpm
  		RAIN_minus_AET *= dpm
  		AET_1 = FIX(Temporary(AET_1) + 0.5)
      RAIN_minus_AET = FIX(Temporary(RAIN_minus_AET))
      effective_Kc = FIX(Temporary(effective_Kc)+0.5)
  
  		; Reconstructs arrays
  		AET = FIX(LAND) & AET[*] = 0
  		AET[where_ok] = AET_1
  		AET[where_no_ok] = -999
  		undefine, AET_1
  
  		eff_Kc = FIX(LAND) & eff_Kc[*] = 0
  		eff_Kc[where_ok] = effective_Kc
  		eff_Kc[where_no_ok] = -999
  		undefine, effective_Kc
  
  		RAIN_AET = FIX(LAND) & RAIN_AET[*] = 0
  
  		RAIN_AET[where_ok] = RAIN_minus_AET
  		RAIN_AET[where_no_ok] = -999
  		undefine, RAIN_minus_AET
  		
  		; WRITES OUTPUTS
  		ENVI_WRITE_ENVI_FILE, AET, out_name=AET_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO
  		ENVI_WRITE_ENVI_FILE, eff_Kc,  out_name=eff_Kc_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO
  		ENVI_WRITE_ENVI_FILE, RAIN_AET, out_name=RAIN_AET_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO
    ENDFOR
  ENDFOR
END










