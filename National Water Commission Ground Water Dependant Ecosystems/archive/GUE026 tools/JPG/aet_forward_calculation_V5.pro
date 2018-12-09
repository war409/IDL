
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
      fname_RAIN_output=  STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\RAIN\' + $
                STRING(year) + $
                month_app + STRING(month) + $
                '_rain.flt', /REMOVE_ALL )

      return,   fname_RAIN_output
end

function SILO_PET_monthly_fname, month, year
      if month le 9 then month_app='0' else  month_app=''
      fname_PET_output=   STRCOMPRESS('\\file-wron\Working\work\Juan_Pablo\AET_C5\SILO\EVAP\' + $
                STRING(year) + $
                month_app + STRING(month) + $
                '_evappt.flt', /REMOVE_ALL )

       return,   fname_PET_output
end



; this function returns the filename (including path) for the output (monthly) synthetic NBAR composite.
function MCD43A4_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\MCD43A4_monthly\'

  if month le 9 then app_month = '0' else app_month = ' '
;  if day le 9 then app_day = '0' else app_day = ' '
;
;  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
;  if doy le 9 then app_doy = '00'
;  if doy gt 9 and doy le 99 then app_doy = '0'
;  if doy gt 99 then app_doy = ' '


  fname = strarr(7)


  for i=0, 6 do begin

    Case i of
      0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.img'
      1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.img'
      2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.img'
      3: Band_text= 'aust.005.b04.500m_0545_0565nm_nbar.img'
      4: Band_text= 'aust.005.b05.500m_1230_1250nm_nbar.img'
      5: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.img'
      6: Band_text= 'aust.005.b07.500m_2105_2155nm_nbar.img'

    EndCase

    fname_i = strcompress( $
      path + $
;      String (year) + '.' + $
;      app_month + String(month) +  '.' + $
;      app_day + String(day) +  $
;      '\' + $
      'MCD43A4.' + $
      String (year) + '.' + $
;      app_doy + String(doy) + '.' + $
      app_month + String(month) +  '.' + $
      Band_text , $
      /REMOVE_ALL )

    fname[i] = fname_i
  EndFor

  return, fname
end

function AET_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\AET\'

  if month le 9 then app_month = '0' else app_month = ' '
;  if day le 9 then app_day = '0' else app_day = ' '
;
;  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
;  if doy le 9 then app_doy = '00'
;  if doy gt 9 and doy le 99 then app_doy = '0'
;  if doy gt 99 then app_doy = ' '

    Band_text= 'AET.img'



    fname = strcompress( $
      path + $
;      String (year) + '.' + $
;      app_month + String(month) +  '.' + $
;      app_day + String(day) +  $
;      '\' + $
      'MCD43A4.' + $
      String (year) + '.' + $
;      app_doy + String(doy) + '.' + $
      app_month + String(month) +  '.' + $
      Band_text , $
      /REMOVE_ALL )

  return, fname
end

function eff_kc_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\eff_kc\'

  if month le 9 then app_month = '0' else app_month = ' '
;  if day le 9 then app_day = '0' else app_day = ' '
;
;  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
;  if doy le 9 then app_doy = '00'
;  if doy gt 9 and doy le 99 then app_doy = '0'
;  if doy gt 99 then app_doy = ' '

    Band_text= 'eff_kc.img'

    fname = strcompress( $
      path + $
;      String (year) + '.' + $
;      app_month + String(month) +  '.' + $
;      app_day + String(day) +  $
;      '\' + $
      'MCD43A4.' + $
      String (year) + '.' + $
;      app_doy + String(doy) + '.' + $
      app_month + String(month) +  '.' + $
      Band_text , $
      /REMOVE_ALL )

  return, fname
end

function RAIN_AET_monthly_fname, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\AET_C5\RAIN_AET\'

  if month le 9 then app_month = '0' else app_month = ' '
;  if day le 9 then app_day = '0' else app_day = ' '
;
;  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
;  if doy le 9 then app_doy = '00'
;  if doy gt 9 and doy le 99 then app_doy = '0'
;  if doy gt 99 then app_doy = ' '

    Band_text= 'RAIN_AET.img'

    fname = strcompress( $
      path + $
;      String (year) + '.' + $
;      app_month + String(month) +  '.' + $
;      app_day + String(day) +  $
;      '\' + $
      'MCD43A4.' + $
      String (year) + '.' + $
;      app_doy + String(doy) + '.' + $
      app_month + String(month) +  '.' + $
      Band_text , $
      /REMOVE_ALL )

  return, fname
end


function Resample_SILO_to_MCD43, array
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

  return, new_array_final

end


FUNCTION EVI_MCD43, BLUE_, RED_, NIR_

  BLUE_ *= 0.0001
  RED_  *= 0.0001
  NIR_  *= 0.0001


  RESULT = (2.5* ((NIR_ - RED_) / (NIR_ + 6 * RED_ - 7.5 * BLUE_ + 1) ))

RETURN, RESULT

END

FUNCTION GVMI_MCD43, NIR_, SWIR2_

  NIR_    *= 0.0001
  SWIR2_  *= 0.0001


  RESULT = ((NIR_ + 0.1)-(SWIR2_ + 0.02)) / ((NIR_ + 0.1) + (SWIR2_ + 0.02))

  RETURN, RESULT

END






function AET_model1, EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max, FLUX_SITE
	compile_opt idl2

	t= systime(1)

		; CALCULATES CMI
		k_CMI=	k_CMI
		C_CMI=	C_CMI
		CMI = GVMI - (k_CMI * EVI + C_CMI)						; This is the original CMI calculation invented by Albert and Guillaume

		;CMI = (-k_CMI * EVI + GVMI - C_CMI) / SQRT (k_CMI^2+1)	; This calculates CMI as the perpendicular distance to the "CMI line"
																; and not in the GVMI axis as before.

		; CALCULATES EVI_r

		;EVI_min = 0.1					; from Excel Spreadsheet
		;EVI_max = 0.75					; from Excel Spreadsheet
		EVI_min=  EVI_min
		EVI_max=  EVI_max

		EVI_r = (  ((EVI-EVI_min)/(EVI_max-EVI_min)) > 0) < 1

		; CALCULATES CMI_r
		CMI_min = 0.					; from Excel Spreadsheet
		CMI_max = CMI_max

		CMI_r = (  ((CMI-CMI_min)/(CMI_max-CMI_min)) > 0) < 1

		;CALCULATES kc
		k_max=		k_max
		a=			a
		alpha=		alpha
		b=		    b
		beta=		beta

		kc = k_max * (1-EXP(-a*EVI_r^alpha-b*CMI_r^beta))

		; CALCULATES k_Ei
		k_Ei_max=	k_Ei_max
		k_Ei = k_Ei_max * EVI_r

		;calculates AET_model1
		AET_1 = kc * PET + k_Ei * RAIN

	;print, '******** ', systime(1)-t, 'seconds for function AET_model1 ************** '

	return, AET_1
end

;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------


; ---------------------------------------------------------------------------
; MAIN PROCEDURE

PRO aet_forward_calculation_V5
	compile_opt idl2

;	nfile_EVI =   fname_EVI_out ()
;	nfile_GVMI =  fname_GVMI_out ()
;	nfile_PET =   fname_PET_out ()
;	nfile_RAIN =  fname_RAIN_out ()
;
;	nfile_AET = fname_AET_V4_out ()
;	nfile_eff_Kc = fname_eff_Kc_V4_out ()
;	nfile_RAIN_minus_AET = fname_RAIN_AET_V4_out ()

	; ---------------------------------------------------
	; defines model parameters. These come from the paper

	x1=[0.911293,10.221437,2.381496,0,1,0,0.665331,-0.247571,1,0,0.9]
	x2=[0.755762,13.999496,2.457595,0,1,0.207007,0.5,0.05,1,0,0.9]
	x3=[0.868261,14.41953,2.70145,2.086299,0.953363,0,1.777835,-0.35,1,0,0.9]
	x4=[0.679704,14.118289,2.481207,7.991423,0.889975,0.229422,0.774739,-0.075699,1,0,0.9]

	x= x4
	; gets parameters from x
	k_max		= x[0]
	a			= x[1]
	alpha		= x[2]
	b			= x[3]
	beta		= x[4]
	k_Ei_max	= x[5]
	k_CMI		= x[6]
	C_CMI		= x[7]
	CMI_max		= x[8]
	EVI_min		= x[9]
	EVI_max		= x[10]
	; ---------------------------------------------------

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
		tt= systime(1)
		PRINT, 'START MONTH ', month, ' year', year

		dpm = DaysPerMonth(month, year)

		;OPEN and read FILES

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

    ;READS DATA
    t= systime(1)
      RED=  envi_get_data(fid=fid_band1, dims=dims_band1, pos=0)
      NIR=  envi_get_data(fid=fid_band2, dims=dims_band2, pos=0)
      BLUE= envi_get_data(fid=fid_band3, dims=dims_band3, pos=0)
      SWIR2=envi_get_data(fid=fid_band6, dims=dims_band6, pos=0)
      print, systime(1)-t, 'seconds for reading data'


    ;selects pixels with values OK. From now on makes operations with only those pixs and goes faster
    where_OK = where( $
                LAND eq 1 AND $
                RED gt -32000 AND  $
                NIR gt -32000 AND  $
                BLUE gt -32000 AND  $
                SWIR2 gt -32000  , complement=where_NO_OK)

    EVI = EVI_MCD43(BLUE[where_OK], RED[where_OK], NIR[where_OK])
    GVMI = GVMI_MCD43(NIR[where_OK], SWIR2[where_OK])

    undefine, RED, NIR, BLUE, SWIR2    ; don't need these any more

		;reads PET (SILO)
    fname = SILO_PET_monthly_fname(month, year)
    PET= read_binary(fname , DATA_TYPE=4, DATA_DIMS=[841,681])

    ;reads RAIN (SILO)
    fname = SILO_RAIN_monthly_fname(month, year)
    RAIN= read_binary(fname , DATA_TYPE=4, DATA_DIMS=[841,681])

    ;resamples PET and RAIN into MCD43 dimensions and extent
    PET = Resample_SILO_to_MCD43(Temporary(PET))
    RAIN = Resample_SILO_to_MCD43(Temporary(RAIN))

    PET= temporary(PET[where_ok])
    RAIN= temporary(RAIN[where_ok])


		;converts PET and RAIN to mm/day (orig data in mm/month)
		PET /= dpm
		RAIN /= dpm

		;calculates AET_model1
		t= systime(1)
		;CMI = CMI_1 (EVI, GVMI)
		;EVI_r = EVI_r_1 (EVI)
		;CMI_r = CMI_r_1 (CMI)
		;kc = kc_1 (EVI_r, CMI_r)
		;k_Ei = k_Ei_1 (EVI_r)

		;AET_1 = kc * PET + k_Ei * RAIN
		AET_1 = AET_model1 (EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max)
  		print, systime(1)-t, 'seconds for calculating AET model 1'

		effective_Kc = (AET_1 / PET)*100
		RAIN_minus_AET = RAIN - AET_1

		; Converts values back to mm/month (and convert into integer)
		AET_1 *= dpm
		RAIN_minus_AET *= dpm
		AET_1 = FIX(Temporary(AET_1) + 0.5)
    RAIN_minus_AET = FIX(Temporary(RAIN_minus_AET))
    effective_Kc = FIX(Temporary(effective_Kc)+0.5)

		;reconstructs arrays
		t= systime(1)
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
 		print, systime(1)-t, 'seconds for reconstructing arrays'


;		ENVI_enter_DATA, AET
;		ENVI_enter_DATA, eff_Kc
;		ENVI_enter_DATA, RAIN_AET



		; WRITES OUTPUTS
		ENVI_WRITE_ENVI_FILE, AET, out_name=AET_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO
		ENVI_WRITE_ENVI_FILE, eff_Kc,  out_name=eff_Kc_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO
		ENVI_WRITE_ENVI_FILE, RAIN_AET, out_name=RAIN_AET_monthly_fname(month, year), /NO_OPEN, MAP_INFO=MAP_INFO

  		print, systime(1)-tt, 'seconds for processing month ', month, year

	ENDFOR
	endfor

end

