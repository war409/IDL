; ; NAME:
;   Create_PV_NPV_BS_from_MCD43B4_006_recalibration
;
; PURPOSE:
;   The purpose of this program is to generate the fractional Cover product (v2.2) and save 
;   the outputs in the \\wron server 
;
;
; :History:
;     Change History::
;        Written, around 2011, Juan Pablo Guerschman
;        added save as geoTIFF (for John Leys). 13 March 2013
;-



function MCD43A4_fname, day, month, year
	compile_opt idl2

	;path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43A4.005\'
  path = '\\cmar-04-cdc.it.csiro.au\OSM_CDC_LPDAAC_work\lpdaac-mosaics\c5\v1-hdf4\aust\MCD43A4.005\'
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

	path = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\'

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
			'FractCover.V3_0_1.' + $
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

function UNMIX_OUTPUT_FNAME_TIFF, day, month, year
  compile_opt idl2

  path = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\geoTIFF\'

  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '

  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '


  fname = strarr(4)


  for i=0, 3 do begin

    Case i of
      0: Band_text= 'aust.005.PV.tif'
      1: Band_text= 'aust.005.NPV.tif'
      2: Band_text= 'aust.005.BS.tif'
      3: band_text= 'aust.005.FLAG.tif'
    EndCase

    fname_i = strcompress( $
      path + $
    ; String (year) + '\' + $
    ; app_month + String(month) +  '.' + $
    ; app_day + String(day) +  '\' + $
      'FractCover.V3_0_1.' + $
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


function MCD43A4_fname_output_png, day, month, year
	compile_opt idl2

	path = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\'

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
			'FractCover.V3_0_1.' + $
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



;function MODIS_8d_dates
;	compile_opt idl2
;
;	  dates_2000 = IndGen(46) * 8 +  JULDAY (1,1,2000)
;	  dates_2001 = IndGen(46) * 8 +  JULDAY (1,1,2001)
;	  dates_2002 = IndGen(46) * 8 +  JULDAY (1,1,2002)
;	  dates_2003 = IndGen(46) * 8 +  JULDAY (1,1,2003)
;	  dates_2004 = IndGen(46) * 8 +  JULDAY (1,1,2004)
;	  dates_2005 = IndGen(46) * 8 +  JULDAY (1,1,2005)
;	  dates_2006 = IndGen(46) * 8 +  JULDAY (1,1,2006)
;	  dates_2007 = IndGen(46) * 8 +  JULDAY (1,1,2007)
;	  dates_2008 = IndGen(46) * 8 +  JULDAY (1,1,2008)
;	  dates_2009 = IndGen(46) * 8 +  JULDAY (1,1,2009)
;    dates_2010 = IndGen(46) * 8 +  JULDAY (1,1,2010)
;    dates_2011 = IndGen(46) * 8 +  JULDAY (1,1,2011)
;    dates_2012 = IndGen(46) * 8 +  JULDAY (1,1,2012)
;    dates_2013 = IndGen(46) * 8 +  JULDAY (1,1,2013)
;
;	dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, $
;	         dates_2005, dates_2006, dates_2007, dates_2008, dates_2009, $
;	         dates_2010, dates_2011, dates_2012, dates_2013]
;	
;
;	return, dates
;
;end




pro create_FC_V30
	compile_opt idl2
	

  envi, /restore_base_save_files
  envi_batch_init


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


	Dates = MODIS_8d_dates()
	For dates_n = n_elements(Dates)-1, 0, -1 do begin    ; now starts from the end and go backwards 
	;For dates_n = 466, 466 do begin

		tt= SysTime(1)
		Print, 'memory (in Mbytes) currently in use - BEGGINNING OF LOOP ', (Memory())[0] / 1000000

		CALDAT, Dates[dates_n], Month, Day, Year

		Input_file = MCD43A4_fname(day, month, year)
    t=systime(1, /julian)  
    temp_file=strcompress('c:\temp\'+ $
    		string(t, format='(f15.5)')+'.hdf', /remove_all)
		;Temp_file  = 'c:\Temp\temp.hdf'
		Output_file = UNMIX_OUTPUT_FNAME(day, month, year)
    Output_file_TIFF = UNMIX_OUTPUT_FNAME_TIFF(day, month, year)
    
    dummy_file = Output_file[0]+'.dummy'

    ; check if output (either .img .gz or .dummy) exists. If it does, skip all
    FileInfo1 = File_Info(Output_file[0])
    FileInfo2 = File_Info(Output_file[0]+'.gz')
    FileInfo3 = File_Info(dummy_file)
    If FileInfo1.Exists + FileInfo2.Exists + FileInfo3.Exists eq 0 then begin
         
        ; first creat dummy variable to tell other instances of this program that we are working on this date
        openw, 1, dummy_file ;, /get_lun  
        printf, 1, 'dummy'
        close, 1

        print, 'start processing date ',year, month, day 
          
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

        ; get blue band
        fname = Input_file[2]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        BLUE = Get_Zipped_Hdf(fname, Temp_file)

        ; get green band
        fname = Input_file[3]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        GREEN = Get_Zipped_Hdf(fname, Temp_file)

        ; get SWIR1 band
        fname = Input_file[4]
        ;ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
        ;ENVI_FILE_QUERY, fid, dims=dims
        ;RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
        SWIR1 = Get_Zipped_Hdf(fname, Temp_file)

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
          BLUE[0] eq -1 or $
          GREEN[0] eq -1 or $
          SWIR1[0] eq -1 or $
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
      		where_all_bands_ok = Where (RED ne 32767 AND $
      		                            NIR ne 32767 AND $
                                      BLUE ne 32767 AND $
                                      GREEN ne 32767 AND $
                                      SWIR1 ne 32767 AND $
                                      SWIR2 ne 32767 AND $
                                      SWIR3 ne 32767 AND $
                                      Land eq 1, count) ;, complement=where_all_bands_NoOk)
 
          if count gt 0 then  begin  ;in case there are no pixels with valid data will make a "fake array"

          ; get rid of ocean and other stuf we don't want  
          B1 = RED[where_all_bands_ok] * 0.0001
          B2 = NIR[where_all_bands_ok] * 0.0001
          B3 = BLUE[where_all_bands_ok] * 0.0001
          B4 = GREEN[where_all_bands_ok] * 0.0001
          B5 = SWIR1[where_all_bands_ok] * 0.0001
          B6 = SWIR2[where_all_bands_ok] * 0.0001
          B7 = SWIR3[where_all_bands_ok] * 0.0001
          
          ; Get rid of RED and NIR (no longer needed in memory)
          undefine, RED, NIR, BLUE, GREEN, SWIR1, SWIR2, SWIR3
          
          t = Systime(1) 
            satelliteReflectanceTransformed = $
               [[b1],[b2],[b3],[b4],[b5],[b6],[b7], $
               [alog(b1)],[alog(b2)],[alog(b3)],[alog(b4)],[alog(b5)],[alog(b6)],[alog(b7)], $
               [alog(b1)*b1],[alog(b2)*b2],[alog(b3)*b3],[alog(b4)*b4],[alog(b5)*b5],[alog(b6)*b6],[alog(b7)*b7], $
                [b1*b2],[b1*b3],[b1*b4],[b1*b5],[b1*b6],[b1*b7], $
                        [b2*b3],[b2*b4],[b2*b5],[b2*b6],[b2*b7], $
                                [b3*b4],[b3*b5],[b3*b6],[b3*b7], $
                                        [b4*b5],[b4*b6],[b4*b7], $
                                                [b5*b6],[b5*b7], $
                                                        [b6*b7], $
               [alog(b1)*alog(b2)],[alog(b1)*alog(b3)],[alog(b1)*alog(b4)],[alog(b1)*alog(b5)],[alog(b1)*alog(b6)],[alog(b1)*alog(b7)], $
                        [alog(b2)*alog(b3)],[alog(b2)*alog(b4)],[alog(b2)*alog(b5)],[alog(b2)*alog(b6)],[alog(b2)*alog(b7)], $
                                [alog(b3)*alog(b4)],[alog(b3)*alog(b5)],[alog(b3)*alog(b6)],[alog(b3)*alog(b7)], $
                                        [alog(b4)*alog(b5)],[alog(b4)*alog(b6)],[alog(b4)*alog(b7)], $
                                                [alog(b5)*alog(b6)],[alog(b5)*alog(b7)], $
                                                        [alog(b6)*alog(b7)], $
                [(b2-b1)/(b2+b1)],[(b3-b1)/(b3+b1)],[(b4-b1)/(b4+b1)],[(b5-b1)/(b5+b1)],[(b6-b1)/(b6+b1)],[(b7-b1)/(b7+b1)], $
                                  [(b3-b2)/(b3+b2)],[(b4-b2)/(b4+b2)],[(b5-b2)/(b5+b2)],[(b6-b2)/(b6+b2)],[(b7-b2)/(b7+b2)], $
                                                    [(b4-b3)/(b4+b3)],[(b5-b3)/(b5+b3)],[(b6-b3)/(b6+b3)],[(b7-b3)/(b7+b3)], $
                                                                      [(b5-b4)/(b5+b4)],[(b6-b4)/(b6+b4)],[(b7-b4)/(b7+b4)], $
                                                                                        [(b6-b5)/(b6+b5)],[(b7-b5)/(b7+b5)], $
                                                                                                          [(b7-b6)/(b7+b6)]]
          
          print, systime(1)-t, ' seconds for computing satelliteReflectanceTransformed'



;      			; calculates NDVI
;      			NDVI =  (float(NIR[where_all_bands_ok]) - RED[where_all_bands_ok]) / (NIR[where_all_bands_ok] + RED[where_all_bands_ok])
;      			; calculate simple ratio SWIR3/SWIR2
;      			SWIR3_SWIR2 =  float(SWIR3[where_all_bands_ok]) / SWIR2[where_all_bands_ok]

      		EndIf Else Begin

      			where_all_bands_ok[0] = 0

      		EndElse

  
;    
;          		;-------------------------------------------------------
;          		; Perform linear unmixing
;          		t= Systime (1)
;          		PV_NPV_BS = unmix_nbar_recalibrated(NDVI, SWIR3_SWIR2)
;          		print, SysTime(1) - t, ' seconds for unmixing'
;          		PV =  REFORM (PV_NPV_BS [0,*])
;          		NPV = REFORM (PV_NPV_BS [1,*])
;          		BS =  REFORM (PV_NPV_BS [2,*])
;          		undefine, PV_NPV_BS, NDVI, SWIR3_SWIR2
;          		;-------------------------------------------------------
;    
;    
;          		;-------------------------------------------------------
;          		; corrects unmixing
;          		t= Systime (1)
;          		Threshold = 0.20
;          		PV_NPV_BS = correct_unmixing (PV, NPV, BS, Threshold)
;          		PV =  REFORM (PV_NPV_BS [*,*,0])
;          		NPV = REFORM (PV_NPV_BS [*,*,1])
;          		BS =  REFORM (PV_NPV_BS [*,*,2])
;          		FLAG = BYTE(REFORM (PV_NPV_BS [*,*,3]))
;          		undefine, PV_NPV_BS
;          		print, SysTime(1) - t, '  Seconds for correcting'
;          		;-------------------------------------------------------

          restore, 'Z:\work\Juan_Pablo\PV_NPV_BS\New_Validation\SAGE\plots\Subset_Data\NEW_20130729\TransformedReflectance_MCD43A4_WeightEQ_-1_no_crypto_subsetData.SAV'
        
          n_pixels = count
        ;  test = satelliteReflectanceTransformed[0:n_pixels-1,*]
          test = satelliteReflectanceTransformed 
        
          
          t = Systime(1) 
          sum2oneWeight=0.02
          lower_bound=-0.0 
          upper_bound=1.0 
          print, 'start running unmixing'
          retrievedCoverFractions = unmix_3_fractions_bvls(transpose(test), endmembersWeighted, $
              lower_bound=lower_bound, upper_bound=upper_bound, sum2oneWeight=sum2oneWeight)
          tt = Systime(1)
          elapsed = tt-t
          print, elapsed, ' seconds for unmix', n_pixels, ' pixels' 

          PV = retrievedCoverFractions[*,0]
          NPV = retrievedCoverFractions[*,1]
          BS = retrievedCoverFractions[*,2]
          
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


;      		FLAG_output =  BytArr (SIZE_DATA[1], SIZE_DATA[2])  & FLAG_output [*] =  255
;      		FLAG_output  [where_all_bands_ok] = FLAG
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

      		WRITE_PNG, MCD43A4_fname_output_png(day, month, year), IMG_for_PNG, green,red,blue, /order
      		undefine, IMG_for_PNG, WHERE_255, WHERE_254
      		PRINT, sYStIME(1) - T, '  SECONDS for png  '
      		;-------------------------------------------------------



      		;-------------------------------------------------------
      		;save ENVI files
      		t=Systime(1)
      		ENVI_WRITE_ENVI_FILE, PV_output, OUT_NAME = Output_file[0], MAP_INFO = MAP_INFO, R_FID=FID_PV   
      		ENVI_FILE_QUERY, FID_PV, DIMS=DIMS_PV
      		undefine, PV
      		undefine, PV_output


      		ENVI_WRITE_ENVI_FILE, NPV_output, OUT_NAME = Output_file[1], MAP_INFO = MAP_INFO, R_FID=FID_NPV   
          ENVI_FILE_QUERY, FID_NPV, DIMS=DIMS_NPV
      		undefine, NPV
      		undefine, NPV_Output


      		ENVI_WRITE_ENVI_FILE, BS_output, OUT_NAME = Output_file[2], MAP_INFO = MAP_INFO, R_FID=FID_BS 
          ENVI_FILE_QUERY, FID_BS, DIMS=DIMS_BS
      		undefine, BS
      		undefine, BS_output


;      		ENVI_WRITE_ENVI_FILE, FLAG_output, OUT_NAME = Output_file[3], MAP_INFO = MAP_INFO, R_FID=FID_FLAG 
;          ENVI_FILE_QUERY, FID_FLAG, DIMS=DIMS_FLAG
;      		undefine, FLAG
;      		undefine, FLAG_output
       		print, SysTime(1) - t, '  Seconds for saving ENVI files'
      		;-------------------------------------------------------

          ;-------------------------------------------------------
          ;save GeoTIFF files
;          ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_PV, DIMS=DIMS_PV, OUT_NAME=Output_file_TIFF[0], POS=0, /TIFF
;          ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_NPV, DIMS=DIMS_NPV, OUT_NAME=Output_file_TIFF[1], POS=0, /TIFF
;          ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_BS, DIMS=DIMS_BS, OUT_NAME=Output_file_TIFF[2], POS=0, /TIFF
;          ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_FLAG, DIMS=DIMS_FLAG, OUT_NAME=Output_file_TIFF[3], POS=0, /TIFF
          ;-------------------------------------------------------


          ;-------------------------------------------------------
          ;zip files
          t= SysTime (1)
             for i=0,3 do SPAWN, 'gzip ' + Output_file[i] , Result, ErrResult, /HIDE    ; zip File
;          Print, SysTime (1) - t, ' Seconds for zipping files (ENVI)'
;
;          t= SysTime (1)
;             for i=0,3 do SPAWN, 'gzip ' + Output_file_TIFF[i] , Result, ErrResult, /HIDE    ; zip File
;          Print, SysTime (1) - t, ' Seconds for zipping files (TIFF)'

          ;-------------------------------------------------------



      		; GETS RID OF THE REST OF THE VARS NO LONGER NEEDED
      		undefine, where_all_bands_ok

      		;Print, 'memory (in Mbytes) currently in use - END OF LOOP ', (Memory())[0] / 1000000
      		Print, Systime(1) - tt, '   seconds for processing all loop'


      Endif ELSE Begin
        Print, 'at least one on the input files does not exist. Skip to next.', Input_file
      EndElse

      ; delete dummy_file
      file_delete, dummy_file


    Endif ELSE Begin
       Print, 'File already exists. Skip to next'
    EndElse

	ENDFOR

	EXIT, /NO_CONFIRM

end

