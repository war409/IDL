

; ##############################################################################################
FUNCTION NORMALISED_RATIO, B1, B2
  ;---------------------------------------------------------------------------------------------
  ; CALCULATE NORMALISED RATIO:
  ;---------------------------------------------------------------------------------------------
  NORM = (B1 - B2) / (B1 + B2 * 1.0)
  RETURN, NORM
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION FIVE_VARIABLE_MODEL, G0, G1, G2, G3, G4, G5, G6, X2, X3, X4, X5, X6
  ;---------------------------------------------------------------------------------------------
  ; SET FUNCTION
  Z = G1 + (G2 * X2) + (G3 * X3) + (G4 * X4) + (G5 * X5) + (G6 * X6)
  ;---------------------------------------------------------------------------------------------
  ; APPLY LOGISTIC MODEL
  OWL_OUT = G0 / (1 + EXP(Z))
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, OWL_OUT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION BITWISE_OPERATOR, DATA, BIN, EQV, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN) EQ EQV)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION BITWISE_OPERATOR_AND, DATA, BIN1, EQV1, BIN2, EQV2, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN1) EQ EQV1) AND ((DATA AND BIN2) EQ EQV2)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION EXTRACT_MODIS, X_ALL
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT FILES (SURFACE REFLECTANCE)
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b01*') EQ 1)]
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b02*') EQ 1)]
  MIR2 = X_ALL[WHERE(STRMATCH(X_ALL, '*b06*') EQ 1)]
  MIR3 = X_ALL[WHERE(STRMATCH(X_ALL, '*b07*') EQ 1)]
  ; EXTRACT FILES (QUALITY STATE)
  STATE = X_ALL[WHERE(STRMATCH(X_ALL, '*state*') EQ 1)]
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [RED, NIR, MIR2, MIR3, STATE]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################



function MOD09A1_fname, day, month, year
  compile_opt idl2

  path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD09A1.005\'

  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '

  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '


  fname = strarr(10)


  for i=0, 9 do begin

    Case i of
      0: Band_text= 'aust.005.b01.500m_0620_0670nm_refl.hdf.gz'
      1: Band_text= 'aust.005.b02.500m_0841_0876nm_refl.hdf.gz'
      2: Band_text= 'aust.005.b03.500m_0459_0479nm_refl.hdf.gz'
      3: Band_text= 'aust.005.b04.500m_0545_0565nm_refl.hdf.gz'
      4: Band_text= 'aust.005.b05.500m_1230_1250nm_refl.hdf.gz'
      5: Band_text= 'aust.005.b06.500m_1628_1652nm_refl.hdf.gz'
      6: Band_text= 'aust.005.b07.500m_2105_2155nm_refl.hdf.gz'
      7: Band_text= 'aust.005.b08.500m_quality.hdf.gz'
      8: Band_text= 'aust.005.b12.500m_state_flags.hdf.gz'
      9: Band_text= 'aust.005.b13.500m_day_of_year.hdf.gz'

    EndCase

    fname_i = strcompress( $
      path + $
      String (year) + '.' + $
      app_month + String(month) +  '.' + $
      app_day + String(day) +  '\' + $
      'MOD09A1.' + $
      String (year) + '.' + $
      app_doy + String(doy) + '.' + $
      Band_text , $
      /REMOVE_ALL )

    fname[i] = fname_i

  EndFor

    ;fname_search = FILE_SEARCH(fname_case)

    ;if n_elements(Fname_search) ne 1 then stop else $
    ; fname[i*2+j] = Fname_case

  return, fname
end






function OWL_OUTPUT_FNAME, day, month, year
	compile_opt idl2

	path = 'H:\war409\Open_Water\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(1)

	    Band_text= 'aust.005.OWL.img'

		fname_i = strcompress( $
			path + $
		;	String (year) + '\' +	$
		;	app_month + String(month) +  '.' + $
		;	app_day + String(day) +  '\' + $
			'MOD09A1..' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname = fname_i

	return, fname
end






function MODIS_8d_dates
	compile_opt idl2

	  dates_2000 = IndGen(46) * 8 +  JULDAY (1,1,2000)
	  dates_2001 = IndGen(46) * 8 +  JULDAY (1,1,2001)
	  dates_2002 = IndGen(46) * 8 +  JULDAY (1,1,2002)
	  dates_2003 = IndGen(46) * 8 +  JULDAY (1,1,2003)
	  dates_2004 = IndGen(46) * 8 +  JULDAY (1,1,2004)
	  dates_2005 = IndGen(46) * 8 +  JULDAY (1,1,2005)
	  dates_2006 = IndGen(46) * 8 +  JULDAY (1,1,2006)
	  dates_2007 = IndGen(46) * 8 +  JULDAY (1,1,2007)
	  dates_2008 = IndGen(46) * 8 +  JULDAY (1,1,2008)
	  dates_2009 = IndGen(46) * 8 +  JULDAY (1,1,2009)
      dates_2010 = IndGen(46) * 8 +  JULDAY (1,1,2010)
      dates_2011 = IndGen(46) * 8 +  JULDAY (1,1,2011)

	dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, dates_2007, dates_2008, dates_2009, dates_2010, dates_2011]

	return, dates

end





pro create_OWL_from_MOD09A1
	compile_opt idl2

	t_elapsed = SysTime (1)

  ;open the following image and extract header info (particularly MAP_INFO )
  fname = '\\wron\Working\work\Juan_Pablo\MOD09A1.005\header_issue\MOD09A1.2009.001.aust.005.b01.500m_0620_0670nm_refl.img'
  ENVI_OPEN_FILE , fname , R_FID = FID_dummy, /NO_REALIZE
  ENVI_FILE_QUERY, FID_dummy, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE, XSTART=XSTART, YSTART=YSTART, DEF_STRETCH=DEF_STRETCH, ns=ns, nl=nl
  projection = ENVI_GET_PROJECTION (FID= FID_dummy)
  MAP_INFO = ENVI_GET_MAP_INFO  (FID=FID_dummy)

  ; open land mask
  fname = '\\wron\Working\work\Juan_Pablo\auxiliary\land_mask_australia_MCD43'
  ENVI_OPEN_FILE , fname , R_FID = FID_land_mask, /NO_REALIZE
  ENVI_FILE_QUERY, FID_land_mask, DIMS=DIMS_land_mask
  Land = ENVI_GET_DATA(fid=FID_land_mask, dims=DIMS_land_mask, pos=0)
  Where_land = Where(Land eq 1, count_land)

  ; open MrVBF
  fname = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MrVBF\SRTM.DEM.3s.01.MrVBF.Aust.500m.img'
  ENVI_OPEN_FILE , fname , R_FID = FID_MrVBF, /NO_REALIZE
  ENVI_FILE_QUERY, FID_MrVBF, DIMS=DIMS_MrVBF
  MrVBF = ENVI_GET_DATA(fid=FID_MrVBF, dims=DIMS_MrVBF, pos=0)


	Dates = MODIS_8d_dates()

    date_begin = JULDAY(1,1,2011)
;   date_begin = JULDAY(3,14,2009)
    date_end   = JULDAY(8,18,2011)

   where_dates = where(Dates ge date_begin and Dates le date_end, count_dates)

	For dates_i = 0, count_dates - 1 do begin		; update

	  dates_n=where_dates[dates_i]


		tt= SysTime(1)
		Print, 'memory (in Mbytes) currently in use - BEGGINNING OF LOOP ', (Memory())[0] / 1000000

		CALDAT, Dates[dates_n], Month, Day, Year

		Input_file = MOD09A1_fname(day, month, year)
		Temp_file  = 'C:\Users\war409\Temp\temp.hdf'
		Output_file = OWL_OUTPUT_FNAME(day, month, year)

        ; get RED band
        fname = Input_file[0]
        RED = Get_Zipped_Hdf(fname, Temp_file)

        ; get NIR band
        fname = Input_file[1]
        NIR = Get_Zipped_Hdf(fname, Temp_file)

        ; get SWIR2 band
        fname = Input_file[5]
        SWIR2 = Get_Zipped_Hdf(fname, Temp_file)

        ; get SWIR3 band
        fname = Input_file[6]
        SWIR3 = Get_Zipped_Hdf(fname, Temp_file)

        ; get QA band
        fname = Input_file[8]
        STATE = Get_Zipped_Hdf(fname, Temp_file)


        SIZE_DATA = Size(RED)

        ; Check if any of the bands returned -1
        If  n_elements(RED)   eq 1 or $
            n_elements(NIR)   eq 1 or $
            n_elements(SWIR2) eq 1 or $
            n_elements(SWIR3) eq 1 or $
            n_elements(STATE)    eq 1    $
        then corrupted = 1 else corrupted = 0

  			print, SysTime (1) - tt, ' seconds for reading band


      ; SKIP all processing if at least one file does not exist
      If corrupted eq 0 then Begin

      		; find where all bands have data AND is LAND
      		where_all_bands_ok = Where (RED ne -32768 AND $
      		                            NIR ne -32768 AND $
                                      SWIR2 ne -32768 AND $
                                      SWIR3 ne -32768 AND $
                                      Land eq 1, count) ;, complement=where_all_bands_NoOk)


      		if count gt 0 then  begin  ;in case there are no pixels with valid data will make a "fake array"

      			; decrease array size by getting only good data points (frees memory)
				RED=    Temporary(RED[where_all_bands_ok])
				NIR=    Temporary(NIR[where_all_bands_ok])
				SWIR2=  Temporary(SWIR2[where_all_bands_ok])
				SWIR3=  Temporary(SWIR3[where_all_bands_ok])
				STATE=     Temporary(STATE[where_all_bands_ok])
				MrVBF_calc= MrVBF[where_all_bands_ok]


      			; calculates NDVI and NDWI
      	  NDVI = Normalised_Ratio(NIR, RED)
 			    NDWI = NORMALISED_RATIO(NIR, SWIR2)

			    ;-------------------------------------------------------------------------------------------
			    ; CALCULATE OPEN WATER (APPLY MODEL)
			    OWL = FIVE_VARIABLE_MODEL(1.00, -3.4137561, -0.000959735270, 0.00417955330, 14.1927990, $
			      -0.430407140, -0.0961932990, SWIR2, SWIR3, NDVI, NDWI, MrVBF_calc)

        		; Get rid of individual bands and indices (no longer needed in memory)
        		undefine, RED, NIR, SWIR2, SWIR3, NDVI, NDWI, MrVBF_calc

			    ;-------------------------------------------------------------------------------------------
			    ; APPLY MODIS CLOUD MASK:
			    ;--------------
			    ; REPLACE 'FILL' CELLS
			    INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
			    IF (COUNT_FILL GT 0) THEN OWL[INDEX_FILL] = 255.00
			    ;--------------
			    ; REPLACE 'CLOUD CELLS' ["Cloud"= 0000000000000001]
			    INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1)
			    IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN OWL[INDEX_CLOUD] = 255.00
			    ;--------------
			    ; REPLACE 'MIXED CLOUD' CELLS ["MIXED"= 0000000000000010]
			    INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
			    IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN OWL[INDEX_MIXED] = 255.00
			    ;--------------
			    ; REPLACE 'CLOUD SHADOW' CELLS ["Cloud_Shadow"= 0000000000000100]
			    INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
			    IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN OWL[INDEX_SHADOW] = 255.00
			    ;-------------------------------------------------------------------------------------------
			    ; SET NAN TO 255
			    n = WHERE(FINITE(OWL, /NAN), COUNT_NAN)
			    IF (COUNT_NAN GT 0) THEN OWL[n] = 255.00
			    ;-------------------------------------------------------------------------------------------
			    ; CONVERT TO BYTE
			    OWL = BYTE((OWL LT 255) * (OWL+0.005) * 100.00 + (OWL EQ 255) * 255.00)
			    ;-------------------------------------------------------------------------------------------



      		EndIf Else Begin

      			OWL = 255
      			where_all_bands_ok[0] = 0

      		EndElse





      		;-------------------------------------------------------
      		;reconstruct arrays
      		t= Systime (1)
      		OWL_output =  BytArr(SIZE_DATA[1], SIZE_DATA[2]) & OWL_output [*] =  255
      		OWL_output  [where_all_bands_ok] = OWL
       		print, SysTime(1) - t, '  Seconds for reconstructing arrays'
      		;-------------------------------------------------------





      		;-------------------------------------------------------
      		;save ENVI files
      		t=Systime(1)
      		ENVI_WRITE_ENVI_FILE, OWL_output, OUT_NAME = Output_file, MAP_INFO = MAP_INFO   , /No_Open
      		undefine, OWL
      		undefine, OWL_output
       		print, SysTime(1) - t, '  Seconds for saving ENVI files'
      		;-------------------------------------------------------



      		; GETS RID OF THE REST OF THE VARS NO LONGER NEEDED
      		undefine, where_all_bands_ok

      		Print, 'memory (in Mbytes) currently in use - END OF LOOP ', (Memory())[0] / 1000000
      		Print, Systime(1) - tt, '   seconds for processing all loop'

      Endif ELSE Begin
        Print, 'at least one on the input files does not exist. Skip to next.', Input_file
      EndElse


	ENDFOR



end

