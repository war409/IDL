function MCD43A4_fname, day, month, year
	compile_opt idl2

	path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43A4.005\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(7)


	for i=0, 6 do begin

		Case i of
			0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.hdf.gz'
			1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.hdf.gz'
			2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.hdf.gz'
			3: Band_text= 'aust.005.b04.500m_0545_0565nm_nbar.hdf.gz'
			4: Band_text= 'aust.005.b05.500m_1230_1250nm_nbar.hdf.gz'
			5: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.hdf.gz'
			6: Band_text= 'aust.005.b07.500m_2105_2155nm_nbar.hdf.gz'

		EndCase

		fname_i = strcompress( $
			path + $
			String (year) + '.' +	$
			app_month + String(month) +  '.' + $
			app_day + String(day) +  '\' + $
			'MCD43A4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname[i] = fname_i

	EndFor

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end

function MCD43A4_005_ENVI_fname, day, month, year
	compile_opt idl2

	path = '\\file-wron\Working\work\Juan_Pablo\MCD43A4.005\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


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
		;	String (year) + '.' +	$
		;	app_month + String(month) +  '.' + $
		;	app_day + String(day) +  '\' + $
			'MCD43A4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname[i] = fname_i

	EndFor

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end


function UNMIX_OUTPUT_FNAME, day, month, year
	compile_opt idl2

	path = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v2.1\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(4)


	for i=0, 3 do begin

		Case i of
			0: Band_text= 'aust.005.PV.img'
			1: Band_text= 'aust.005.NPV.img'
			2: Band_text= 'aust.005.BS.img'
			3: band_text= 'aust.005.FLAG.img'
		EndCase

		fname_i = strcompress( $
			path + $
			String (year) + '\' +	$
		;	app_month + String(month) +  '.' + $
		;	app_day + String(day) +  '\' + $
			'FractCover.V2_1.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname[i] = fname_i

	EndFor

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end



function MCD43B4_fname_output_png, day, month, year
	compile_opt idl2

	path = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v2.1\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '

	;fname = strarr(1)

		fname = strcompress( $
			path + $
			String (year) + '\' +	$
			;app_month + String(month) +  '.' + $
			;app_day + String(day) +  '\' + $
			'FractCover.V2_1.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			'aust.005.quicklook.' + $
			'png' , $
			/REMOVE_ALL )

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

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


Function Correct_unmixing, PV, NPV, BS, Threshold

;		; ---------------------------------------------------
;		; ANALYSE AND CHANGE PIXELS OUTSIDE TRIANGLE
;		where_analisys = where (finite(PV) eq 1)
;		PV_a = PV [where_analisys]
;		NPV_a = NPV [where_analisys]
;		BS_a = BS [where_analisys]

		PV_output    = PV
		NPV_output   = NPV
		BS_output    = BS
 		mask_output = Byte (PV) & mask_output [*] = 0


		;check where algorithm fails (at least 1 band lower than -0.25 or higher than 1.25)
        fail =  (PV  lt  -Threshold)  OR  $
        		(PV  gt 1+Threshold)  OR  $
				(NPV lt  -Threshold)  OR  $
				(NPV gt 1+Threshold)  OR  $
				(BS  lt  -Threshold)  OR  $
				(BS  gt 1+Threshold)
		where_fail = Where(fail eq 1, count)
		IF count gt 0 then PV_Output [where_fail] = 2.54    ; Previous version: 'then PV_Output [where_fail] = 0'
		IF count gt 0 then NPV_Output[where_fail] = 2.54    ; Previous version: 'then NPV_Output [where_fail] = 0'
		IF count gt 0 then BS_Output [where_fail] = 2.54    ; Previous version: 'then BS_Output [where_fail] = 0'
		IF count gt 0 then mask_output [where_fail]= 2
		undefine, fail, where_fail



		; only 1 band is negative (correct others)

		; 1: PV LT 0
		PV_LT_0 = (PV LT 0 AND PV ge -Threshold AND NPV GE 0 and BS GE 0 AND mask_output ne 2)
		where_PV_LT_0 = Where (PV_LT_0 eq 1, count)
		if count ge 1 then begin
			PV_output [where_PV_LT_0] = 0
			sum = NPV [where_PV_LT_0] + BS[where_PV_LT_0]
			NPV_output[where_PV_LT_0] /= sum
			BS_output [where_PV_LT_0] /= sum
			undefine, sum
			mask_output [where_PV_LT_0] = 1
		endif
		undefine, PV_LT_0, where_PV_LT_0


		; 2: NPV LT 0
		NPV_LT_0 = (NPV LT 0 AND NPV ge -Threshold AND PV GE 0 and BS GE 0 AND mask_output ne 2)
		where_NPV_LT_0 = where (NPV_LT_0 eq 1 , count)
		if count ge 1 then begin
			NPV_output [where_NPV_LT_0] = 0
			sum = PV [where_NPV_LT_0] + BS[where_NPV_LT_0]
			PV_output[where_NPV_LT_0] /= sum
			BS_output[where_NPV_LT_0] /= sum
			undefine, sum
			mask_output [where_NPV_LT_0] = 1
		endif
		undefine, NPV_LT_0


		; 3: BS LT 0
		BS_LT_0 = (BS LT 0 AND BS ge - Threshold AND PV GE 0 and NPV GE 0 AND mask_output ne 2)
		where_BS_LT_0 = where (BS_LT_0 eq 1, count)
		if count ge 1 then begin
			BS_output [where_BS_LT_0] = 0
			sum = PV[where_BS_LT_0] + NPV[where_BS_LT_0]
			PV_output[where_BS_LT_0] /= sum
			NPV_output[where_BS_LT_0] /= sum
			undefine, sum
			mask_output [where_BS_LT_0] = 1
		endif
		undefine, BS_LT_0, where_BS_LT_0



		; 2 or 3 bands are negative - replace by Nans
		PV_LT_0_AND_NPV_LT_0 = ((PV LT 0) AND (NPV LT 0) AND mask_output ne 2)
		where_PV_LT_0_AND_NPV_LT_0 = where (PV_LT_0_AND_NPV_LT_0 eq 1, count)
		if count ge 1 then begin
			PV_output [where_PV_LT_0_AND_NPV_LT_0] = 0
			NPV_output [where_PV_LT_0_AND_NPV_LT_0] = 0
			BS_output [where_PV_LT_0_AND_NPV_LT_0] = 1
			mask_output[where_PV_LT_0_AND_NPV_LT_0] = 1
		endif
		undefine, PV_LT_0_AND_NPV_LT_0, where_PV_LT_0_AND_NPV_LT_0

		; 2 or 3 bands are negative - replace by Nans
		PV_LT_0_AND_BS_LT_0 = ((PV LT 0) AND (BS LT 0) AND mask_output ne 2)
		where_PV_LT_0_AND_BS_LT_0 = where (PV_LT_0_AND_BS_LT_0 eq 1, count)
		if count ge 1 then begin
			PV_output [where_PV_LT_0_AND_BS_LT_0] = 0
			NPV_output [where_PV_LT_0_AND_BS_LT_0] = 1
			BS_output [where_PV_LT_0_AND_BS_LT_0] = 0
			mask_output[where_PV_LT_0_AND_BS_LT_0] = 1
		endif
		undefine, PV_LT_0_AND_BS_LT_0, where_PV_LT_0_AND_BS_LT_0

		; 2 or 3 bands are negative - replace by Nans
		NPV_LT_0_AND_BS_LT_0 = ((NPV LT 0) AND (BS LT 0) AND mask_output ne 2)
		where_NPV_LT_0_AND_BS_LT_0 = where (NPV_LT_0_AND_BS_LT_0 eq 1, count)
		if count ge 1 then begin
			PV_output [where_NPV_LT_0_AND_BS_LT_0] = 1
			NPV_output [where_NPV_LT_0_AND_BS_LT_0] = 0
			BS_output [where_NPV_LT_0_AND_BS_LT_0] = 0
			mask_output[where_NPV_LT_0_AND_BS_LT_0] = 1
		endif
		undefine, NPV_LT_0_AND_BS_LT_0, where_NPV_LT_0_AND_BS_LT_0


		return , [[[PV_output]],[[NPV_output]],[[BS_output]],[[mask_output]]]

end





pro Create_PV_NPV_BS_from_MCD43B4_006
	compile_opt idl2

	t_elapsed = SysTime (1)

  ;open the following image and extract header info (particularly MAP_INFO)
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


	Dates = MODIS_8d_dates()
	For dates_n = 0, n_elements(Dates)-1 do begin
	;For dates_n = 466, 466 do begin

		tt= SysTime(1)
		Print, 'memory (in Mbytes) currently in use - BEGGINNING OF LOOP ', (Memory())[0] / 1000000

		CALDAT, Dates[dates_n], Month, Day, Year

		Input_file = MCD43A4_fname(day, month, year)
		Temp_file  = 'c:\Temp\temp.hdf'
		Output_file = UNMIX_OUTPUT_FNAME(day, month, year)


    ; check if output exists. If it does, skip all
    FileInfo = File_Info(Output_file[0]+'.gz')
    If FileInfo.Exists ne 1 then begin

        ; get RED band
        fname = Input_file[0]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        RED = Get_Zipped_Hdf(fname, Temp_file)

        ; get NIR band
        fname = Input_file[1]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        NIR = Get_Zipped_Hdf(fname, Temp_file)

        ; get SWIR2 band
        fname = Input_file[5]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        SWIR2 = Get_Zipped_Hdf(fname, Temp_file)

        ; get SWIR3 band
        fname = Input_file[6]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        SWIR3 = Get_Zipped_Hdf(fname, Temp_file)


        SIZE_DATA = Size(RED)

        ; Check if any of the bands returned -1
        If  RED[0] eq -1 or $
          NIR[0] eq -1 or $
          SWIR2[0] eq -1 or $
          SWIR3[0] eq -1 $
        then corrupted = 1 else corrupted = 0



  ;			;Read Envi File
  ;			T= SysTime (1)
  ;			ENVI_OPEN_DATA_FILE , Input_file[band] , R_FID = FID
  ;			ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=NB
  ;			DIMS = [-1, 0, ns-1, 0, nl-1]
  ;
  ;			MAP_INFO = ENVI_GET_MAP_INFO  (FID=FID)
  ;
  ;			DATA = ENVI_GET_DATA (DIMS=DIMS, FID=FID, POS=0 )
  ;
  ;			ENVI_FILE_MNG , ID=FID , /REMOVE

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

      			; calculates NDVI
      			NDVI =  (float(NIR[where_all_bands_ok]) - RED[where_all_bands_ok]) / (NIR[where_all_bands_ok] + RED[where_all_bands_ok])
      			; calculate simple ratio SWIR3/SWIR2
      			SWIR3_SWIR2 =  float(SWIR3[where_all_bands_ok]) / SWIR2[where_all_bands_ok]

      		EndIf Else Begin

      			NDVI = 0.
      			SWIR3_SWIR2 = 0.

      			where_all_bands_ok[0] = 0

      		EndElse


      		; Get rid of RED and NIR (no longer needed in memory)
      		undefine, RED, NIR


      		; Get rid of SWIR3 and and SWIR2 (no longer needed in memory). I don't know how to do it better
      		undefine, SWIR3, SWIR2

      		;-------------------------------------------------------
      		; Perform linear unmixing
      		t= Systime (1)
      		PV_NPV_BS = unmix_nbar (NDVI, SWIR3_SWIR2)
      		print, SysTime(1) - t, ' seconds for unmixing'
      		PV =  REFORM (PV_NPV_BS [0,*])
      		NPV = REFORM (PV_NPV_BS [1,*])
      		BS =  REFORM (PV_NPV_BS [2,*])
      		undefine, PV_NPV_BS, NDVI, SWIR3_SWIR2
      		;-------------------------------------------------------


      		;-------------------------------------------------------
      		; corrects unmixing
      		t= Systime (1)
      		Threshold = 0.20
      		PV_NPV_BS = correct_unmixing (PV, NPV, BS, Threshold)
      		PV =  REFORM (PV_NPV_BS [*,*,0])
      		NPV = REFORM (PV_NPV_BS [*,*,1])
      		BS =  REFORM (PV_NPV_BS [*,*,2])
      		FLAG = BYTE(REFORM (PV_NPV_BS [*,*,3]))
      		undefine, PV_NPV_BS
      		print, SysTime(1) - t, '  Seconds for correcting'
      		;-------------------------------------------------------



      		;-------------------------------------------------------
      		; rescales and convert vectors to byte AND set extreme values to 0
      		t= Systime (1)
      		PV += 0.005
      		PV *=  100
      		PV =   Byte(Temporary(PV))

          NPV += 0.005
      		NPV *=  100
       		NPV =   Byte(Temporary(NPV))

          BS += 0.005
      		BS *=  100
       		BS =   Byte(Temporary(BS))
       		print, SysTime(1) - t, '  Seconds for rescaling'
      		;-------------------------------------------------------




      		;-------------------------------------------------------
      		;reconstruct arrays
      		t= Systime (1)
      		PV_output =  BytArr (SIZE_DATA[1], SIZE_DATA[2])  & PV_output [*] =  255
      		PV_output  [where_all_bands_ok] = PV

      		NPV_output =  BytArr (SIZE_DATA[1], SIZE_DATA[2]) & NPV_output [*] =  255
      		NPV_output  [where_all_bands_ok] = NPV


      		BS_output =  BytArr (SIZE_DATA[1], SIZE_DATA[2]) & BS_output [*] =  255
      		BS_output  [where_all_bands_ok] = BS


      		FLAG_output =  BytArr (SIZE_DATA[1], SIZE_DATA[2])  & FLAG_output [*] =  255
      		FLAG_output  [where_all_bands_ok] = FLAG
       		print, SysTime(1) - t, '  Seconds for reconstructing arrays'
      		;-------------------------------------------------------



      		;-------------------------------------------------------
      		;save png
      		t= Systime (1)

      		reduction_factor = 8
      		IMG_for_PNG =  BytArr (3, SIZE_DATA[1]/reduction_factor, SIZE_DATA[2]/reduction_factor)
      		IMG_for_PNG [1, *, *] = CONGRID ( PV_output, SIZE_DATA[1]/reduction_factor, SIZE_DATA[2]/reduction_factor)
      		IMG_for_PNG [0, *, *] = CONGRID (NPV_output, SIZE_DATA[1]/reduction_factor, SIZE_DATA[2]/reduction_factor)
      		IMG_for_PNG [2, *, *] = CONGRID ( BS_output, SIZE_DATA[1]/reduction_factor, SIZE_DATA[2]/reduction_factor)
      		WHERE_255 = where (IMG_for_PNG EQ 255)
          WHERE_254 = where (IMG_for_PNG EQ 254)

      		IMG_for_PNG *= 2.55
      		IMG_for_PNG[WHERE_255] = 255
          IMG_for_PNG[WHERE_254] = 0

      		WRITE_PNG, MCD43B4_fname_output_png(day, month, year), IMG_for_PNG, green,red,blue, /order
      		undefine, IMG_for_PNG, WHERE_255, WHERE_254
      		PRINT, sYStIME(1) - T, '  SECONDS for png  '
      		;-------------------------------------------------------



      		;-------------------------------------------------------
      		;save ENVI files
      		t=Systime(1)
      		ENVI_WRITE_ENVI_FILE, PV_output, OUT_NAME = Output_file[0], MAP_INFO = MAP_INFO   , /No_Open
      		undefine, PV
      		undefine, PV_output


      		ENVI_WRITE_ENVI_FILE, NPV_output, OUT_NAME = Output_file[1], MAP_INFO = MAP_INFO   , /No_Open
      		undefine, NPV
      		undefine, NPV_Output


      		ENVI_WRITE_ENVI_FILE, BS_output, OUT_NAME = Output_file[2], MAP_INFO = MAP_INFO   , /No_Open
      		undefine, BS
      		undefine, BS_output


      		ENVI_WRITE_ENVI_FILE, FLAG_output, OUT_NAME = Output_file[3], MAP_INFO = MAP_INFO   , /No_Open
      		undefine, FLAG
      		undefine, FLAG_output
       		print, SysTime(1) - t, '  Seconds for saving ENVI files'
      		;-------------------------------------------------------


          ;-------------------------------------------------------
          ;zip files
          t= SysTime (1)
             for i=0,3 do SPAWN, 'gzip ' + Output_file[i] , Result, ErrResult, /HIDE    ; zip File
          Print, SysTime (1) - t, ' Seconds for unzipping file'


          ;-------------------------------------------------------



      		; GETS RID OF THE REST OF THE VARS NO LONGER NEEDED
      		undefine, where_all_bands_ok

      		Print, 'memory (in Mbytes) currently in use - END OF LOOP ', (Memory())[0] / 1000000
      		Print, Systime(1) - tt, '   seconds for processing all loop'

      Endif ELSE Begin
        Print, 'at least one on the input files does not exist. Skip to next.', Input_file
      EndElse

    Endif ELSE Begin
       Print, 'File ', Output_file, ' already exists. Skip to next'
    EndElse

	ENDFOR



end

