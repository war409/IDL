; ##############################################################################################
; Name: fractional_cover_version_301.pro
; Language: IDL
; Author: Juan Pablo Guerschman & Garth Warren
; Date: ~2011
; DLM: 10072014 (Garth Warren)
; Description: The purpose of this program is to generate the fractional Cover product (v3.0.1) 
;   and save the outputs to the \\wron server.
; Input: 
; Output: 
; Parameters:   You will need to set the input / output paths and set the date range
;             
; 
; Notes: 
; ##############################################################################################



FUNCTION get_compressed_hdf, filename_input, filename_temp
  COMPILE_OPT idl2
  ON_ERROR
  
  input = filename_input
  temp = filename_temp
  
  ; Uncompress the file. Save the file with the temp_file name.
  
  fileinfo = FILE_INFO(input)
    
  IF fileinfo.Exists EQ 1 THEN BEGIN
    time = SYSTIME(1)
    
    SPAWN, 'gzip -d -c ' + input + ' > ' + temp, Result, ErrResult, /HIDE 
    
    violated = TOTAL(STRMATCH(ErrResult, '*violated*'))
    invalid  = TOTAL(STRMATCH(ErrResult, '*invalid*'))
    
    ; Continue if the spawn command did not return an error.
    IF (violated EQ 0) AND (invalid EQ 0) THEN BEGIN 
      
      ; Read the HDF.
      sdfileID = HDF_SD_START(temp, /READ)
      sdsID = HDF_SD_SELECT(sdfileID, 0)
      HDF_SD_FILEINFO, sdfileID, datasets, attributes
      HDF_SD_GETINFO, sdsID, NAME=name
      time = SYSTIME(1)
      HDF_SD_GETDATA, sdsID, data
      HDF_SD_END, sdfileID
      FILE_DELETE, temp
      
    ENDIF ELSE BEGIN
      PRINT, 'bad file, returning -1'
      data = -1
    ENDELSE 
  ENDIF ELSE BEGIN
    PRINT, 'file not found, returning -1'
    data = -1
  ENDELSE
  
  RETURN, data
END



FUNCTION date_string, day, month, year
  COMPILE_OPT idl2
  
  count = N_ELEMENTS(day)
  return_strings = MAKE_ARRAY(count, 4, /STRING)
  day_of_year_suffix = MAKE_ARRAY(count, /STRING)
  month_suffix = MAKE_ARRAY(count, /STRING)
  day_suffix = MAKE_ARRAY(count, /STRING)
  
  day_of_year = JULDAY(month, day, year)  -  JULDAY(1, 1, year) + 1
  k = WHERE((day_of_year LE 9), k_count)
  l = WHERE((day_of_year GT 9) AND (day_of_year LE 99), l_count)
  m = WHERE((month LE 9), m_count)
  n = WHERE((day LE 9), n_count)
  
  day_of_year_suffix[*] = ''
  month_suffix[*] = ''
  day_suffix[*] = ''
  
  IF (k_count GT 0) THEN day_of_year_suffix[k] = '00'
  IF (l_count GT 0) THEN day_of_year_suffix[l] = '0'
  IF (m_count GT 0) THEN month_suffix[m] = '0'
  IF (n_count GT 0) THEN day_suffix[n] = '0'
  
  return_strings[*,0] = day_suffix + STRTRIM(day, 2)
  return_strings[*,1] = month_suffix + STRTRIM(month, 2)
  return_strings[*,2] = STRTRIM(year, 2)
  return_strings[*,3] = day_of_year_suffix + STRTRIM(day_of_year, 2)
  
  RETURN, return_strings
END



FUNCTION MCD43A4_filename, day, month, year
  COMPILE_OPT idl2
  
  ;directory = '\\cmar-04-cdc.it.csiro.au\work\lpdaac-mosaics\c5\v1-hdf4\aust\MCD43A4.005\'
  directory = '\\wron\Working\work\war409\GEOGLAM\MCD43A4.005\'
  date_strings = date_string(day, month, year)
  filename = STRARR(7)
  
  FOR i=0, 6 DO BEGIN
    CASE i OF
      0: band = 'aust.005.b01.500m_0620_0670nm_nbar.hdf.gz'
      1: band = 'aust.005.b02.500m_0841_0876nm_nbar.hdf.gz'
      2: band = 'aust.005.b03.500m_0459_0479nm_nbar.hdf.gz'
      3: band = 'aust.005.b04.500m_0545_0565nm_nbar.hdf.gz'
      4: band = 'aust.005.b05.500m_1230_1250nm_nbar.hdf.gz'
      5: band = 'aust.005.b06.500m_1628_1652nm_nbar.hdf.gz'
      6: band = 'aust.005.b07.500m_2105_2155nm_nbar.hdf.gz'
    ENDCASE

    filename_i = STRCOMPRESS(directory + $
      date_strings[*,2] + '.' + $
      date_strings[*,1] +  '.' + $
      date_strings[*,0] +  '\' + $
      'MCD43A4.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
      
    filename[i] = filename_i
  ENDFOR

  RETURN, filename
END



FUNCTION unmix_output_filename, day, month, year
  COMPILE_OPT idl2

  ;directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\'
  directory = '\\wron\Working\work\war409\GEOGLAM\v3.0.1\'
  date_strings = date_string(day, month, year)
  filename = STRARR(4)
  
  FOR i=0, 3 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV.img'
      1: band = 'aust.005.NPV.img'
      2: band = 'aust.005.BS.img'
      3: band = 'aust.005.FLAG.img'
    ENDCASE

    filename_i = STRCOMPRESS(directory + $
      date_strings[*,2] + '\' + $
      'FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    filename[i] = filename_i
  ENDFOR
  
  RETURN, filename
END



FUNCTION unmix_output_filename_tiff, day, month, year
  COMPILE_OPT idl2

  ;directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\geoTIFF\'
  directory = '\\wron\Working\work\war409\GEOGLAM\v3.0.1\geoTIFF\'
  date_strings = date_string(day, month, year)
  filename = STRARR(4)
  
  FOR i=0, 3 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV.tif'
      1: band = 'aust.005.NPV.tif'
      2: band = 'aust.005.BS.tif'
      3: band = 'aust.005.FLAG.tif'
    ENDCASE

    filename_i = STRCOMPRESS(directory + $
      'FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    filename[i] = filename_i
  ENDFOR
  
  RETURN, filename
END



FUNCTION MCD43A4_filename_output_png, day, month, year
  COMPILE_OPT idl2

  ;directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\'
  directory = '\\wron\Working\work\war409\GEOGLAM\v3.0.1\'
  date_strings = date_string(day, month, year)
  
  filename = STRCOMPRESS(directory + $
    date_strings[*,2] + '\' + $
    'FractCover.V3_0_1.' + $
    date_strings[*,2] + '.' + $
    date_strings[*,3] + '.' + $
    'aust.005.quicklook.png' , $
    /REMOVE_ALL)
  
  RETURN, filename
END



FUNCTION modis_eight_day_dates, start_date, end_date
  COMPILE_OPT idl2
  
  CALDAT, start_date, start_month, start_day, start_year ; Get the start date in calendar date format.
  CALDAT, end_date, end_month, end_day, end_year ; Get the end date in calendar date format.
  
  ; Get the eight day date, by-year, in Julien-Day date format.
  FOR i = start_year, end_year DO BEGIN
    dates = INDGEN(46) * 8 +  JULDAY(1, 1, i)
    IF i EQ start_year THEN all_dates = dates ELSE all_dates = [all_dates, dates]
  ENDFOR
  
  ; Create an index of file dates that occur between the start and end dates.
  index = WHERE((all_dates GE start_date) AND (all_dates LE end_date)) 
  dates = all_dates[index]
  
  RETURN, dates
END



FUNCTION unmix_3_fractions_bvls, spectra, endmembers, lower_bound=lower_bound, upper_bound=upper_bound, sum2oneWeight=sum2oneWeight
  COMPILE_OPT idl2
  
  IF (NOT KEYWORD_SET(lower_bound)) THEN lower_bound = 0.0
  IF (NOT KEYWORD_SET(upper_bound)) THEN upper_bound = 1.0
  IF (NOT KEYWORD_SET(sum2oneWeight)) THEN sum2oneWeight = 1.0
  
  endmembers_size = SIZE(endmembers) 
  spectra_size = SIZE(spectra)
  unmixed = FLTARR(spectra_size[2], endmembers_size[2]) & unmixed[*] = !VALUES.F_NAN
  AA = [endmembers, FLTARR(1, endmembers_size[2]) + sum2oneWeight]
    
  band = FLTARR(2, endmembers_size[2])
  band[0, *] = lower_bound * 1.0
  band[1, *] = upper_bound * 1.0
   
  FOR i=0, spectra_size[2] - 1 DO BEGIN
    A = AA
    B = [spectra[*,i], 1]
    bvls, A, B, band, X_BVLS
    unmixed[i,*] = X_BVLS
  ENDFOR
  
  RETURN, unmixed
END



PRO fractional_cover_version_301
  COMPILE_OPT idl2
  start_time = SYSTIME(1)
  
  start_date = JULDAY(1, 1, 2001)
  end_date =  JULDAY(1, 18, 2001)
  dates = modis_eight_day_dates(start_date, end_date)
  
  ; Open the template grid.
  ;template_file = '\\wron\Working\work\Juan_Pablo\MOD09A1.005\header_issue\MOD09A1.2009.001.aust.005.b01.500m_0620_0670nm_refl.img' 
  template_file = '\\wron\Working\work\war409\GEOGLAM\MOD09A1.2009.001.aust.005.b01.500m_0620_0670nm_refl.img'
  template = READ_BINARY(template_file, DATA_DIMS=[9580, 7451], DATA_TYPE=2)
  
  ; Open the land mask.
  ;mask_file = '\\wron\Working\work\Juan_Pablo\auxiliary\land_mask_australia_MCD43' 
  mask_file = '\\wron\Working\work\war409\GEOGLAM\land_mask_australia_MCD43.img'
  mask = READ_BINARY(mask_file, DATA_DIMS=[9580, 7451], DATA_TYPE=1)
  land = WHERE(mask EQ 1, count_land)
  
  ; Loop from the end date to the start date.
  
  FOR d = N_ELEMENTS(dates) - 1, 0, -1 DO BEGIN 
    loop_time = SYSTIME(1)
    PRINT, 'memory (in Mb) currently in use - start of loop: ', (MEMORY())[0] / 1000000
    
    CALDAT, dates[d], month, day, year
    
    input_filename = MCD43A4_filename(day, month, year)
    time = SYSTIME(1, /JULIAN)  
    temp_file = STRCOMPRESS('\\wron\Working\work\war409\GEOGLAM\' + STRING(time, format='(f15.5)') + '.hdf', /REMOVE_ALL)
    output_filename = unmix_output_filename(day, month, year)
    dummy_filename = output_filename[0] + '.dummy'
    
    ; Check whether the outputs (either .img .gz or .dummy) exists. Skip loop if true.
    fileinfo1 = FILE_INFO(output_filename[0])
    fileinfo2 = FILE_INFO(output_filename[0] + '.gz')
    fileinfo3 = FILE_INFO(dummy_filename)
    
    IF fileinfo1.Exists + fileinfo2.Exists + fileinfo3.Exists EQ 0 THEN BEGIN
      
      ; Create a dummy variable to tell other instances of this program that the current date is being processed.
      OPENW, 1, dummy_filename 
      PRINTF, 1, 'dummy'
      CLOSE, 1
      
      PRINT, 'date: ', year, month, day 
      
      ; Load the input MODIS data.
      
      red = get_compressed_hdf(input_filename[0], temp_file) ; Get the red band.
      nir = get_compressed_hdf(input_filename[1], temp_file) ; Get the NIR band.
      blue = get_compressed_hdf(input_filename[2], temp_file) ; Get the blue band.
      green = get_compressed_hdf(input_filename[3], temp_file) ; Get the green band.
      swir1 = get_compressed_hdf(input_filename[4], temp_file) ; Get the SWIR1 band.
      swir2 = get_compressed_hdf(input_filename[5], temp_file) ; Get the SWIR2 band.
      swir3 = get_compressed_hdf(input_filename[6], temp_file) ; Get the SWIR3 band.
      data_size = SIZE(red) ; Get the size of the data.
      
      ; Check wether any of the bands returned -1.
      
      IF (red[0] EQ -1) OR $
        (nir[0] EQ -1) OR $
        (blue[0] EQ -1) OR $
        (green[0] EQ -1) OR $
        (swir1[0] EQ -1) OR $
        (swir2[0] EQ -1) OR $
        (swir3[0] EQ -1) $
      THEN corrupted = 1 ELSE corrupted = 0
      
      PRINT, SYSTIME (1) - loop_time, ' seconds to read MODIS data
      
      ; Skip this date if at least one of the input file does not exist.
      
      IF corrupted EQ 0 THEN BEGIN
        
        ; Create an index of data elements that have valid land-based values.
        
        ok = WHERE(red NE 32767 AND $
          nir NE 32767 AND $
          blue NE 32767 AND $
          green NE 32767 AND $
          swir1 NE 32767 AND $
          swir2 NE 32767 AND $
          swir3 NE 32767 AND $
          Land EQ 1, count)
        
        IF count GT 0 THEN BEGIN 
          
          b1 = red[ok] * 0.0001
          b2 = nir[ok] * 0.0001
          b3 = blue[ok] * 0.0001
          b4 = green[ok] * 0.0001
          b5 = swir1[ok] * 0.0001
          b6 = swir2[ok] * 0.0001
          b7 = swir3[ok] * 0.0001
          
          ; Kill the original full size input arrays (no longer needed in memory).
          UNDEFINE, red, nir, blue, green, swir1, swir2, swir3
          
          time = SYSTIME(1) 
          
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
          
          PRINT, SYSTIME(1) - time, ' seconds for computing satelliteReflectanceTransformed'
          
        ENDIF ELSE BEGIN
          ok[0] = 0
        ENDELSE
      
;     ;-------------------------------------------------------
;     ; Linear unmixing
;     time = SYSTIME(1)
;     PV_NPV_BS = unmix_nbar_recalibrated(NDVI, SWIR3_SWIR2)
;     PRINT, SYSTIME(1) - time, ' seconds for unmixing'
;     PV =  REFORM(PV_NPV_BS [0,*])
;     NPV = REFORM(PV_NPV_BS [1,*])
;     BS =  REFORM(PV_NPV_BS [2,*])
;     undefine, PV_NPV_BS, NDVI, SWIR3_SWIR2
;     ;-------------------------------------------------------
     
;     ;-------------------------------------------------------
;     ; Correct unmixing
;     time = SYSTIME(1)
;     Threshold = 0.20
;     PV_NPV_BS = correct_unmixing (PV, NPV, BS, Threshold)
;     PV =  REFORM(PV_NPV_BS [*,*,0])
;     NPV = REFORM(PV_NPV_BS [*,*,1])
;     BS =  REFORM(PV_NPV_BS [*,*,2])
;     FLAG = BYTE(REFORM(PV_NPV_BS [*,*,3]))
;     undefine, PV_NPV_BS
;     PRINT, SYSTIME(1) - time, ' Seconds for correcting'
;     ;-------------------------------------------------------
      
      ; Calculate the cover fractions.
      
;      RESTORE, 'Z:\work\Juan_Pablo\PV_NPV_BS\New_Validation\SAGE\plots\Subset_Data\NEW_20130729\TransformedReflectance_MCD43A4_WeightEQ_-1_no_crypto_subsetData.SAV'
      
      n_pixels = count
      test = satelliteReflectanceTransformed 
      time = SYSTIME(1) 
      sum2oneWeight = 0.02
      lower_bound = -0.0 
      upper_bound = 1.0
      
      PRINT, 'start running unmixing'
      
      retrievedCoverFractions = unmix_3_fractions_bvls(TRANSPOSE(test), endmembersWeighted, lower_bound=lower_bound, upper_bound=upper_bound, sum2oneWeight=sum2oneWeight)
      
      loop_time = SYSTIME(1)
      elapsed = loop_time-time
      
      PRINT, elapsed, ' seconds to unmix: ', n_pixels, ' pixels' 
      
      pv = retrievedCoverFractions[*,0]
      npv = retrievedCoverFractions[*,1]
      BS = retrievedCoverFractions[*,2]
      
      ; Rescale and convert vectors to byte, and set extreme values to 0.
      
      time = SYSTIME(1)
      
      pv += 0.005
      pv *= 100
      pv = BYTE(TEMPORARY(pv))
      
      npv += 0.005
      npv *= 100
      npv =  BYTE(TEMPORARY(npv))
      
      bs += 0.005
      bs *=  100
      bs = BYTE(TEMPORARY(bs))
      
      PRINT, SYSTIME(1) - time, ' seconds for rescaling'
      
      ; Reconstruct the full size arrays.
      
      time = SYSTIME(1)
      
      pv_output = BYTARR(data_size[1], data_size[2]) & pv_output[*] = 255
      pv_output[ok] = pv
      
      npv_output = BYTARR(data_size[1], data_size[2]) & npv_output[*] = 255
      npv_output[ok] = npv
      
      bs_output = BYTARR(data_size[1], data_size[2]) & bs_output[*] = 255
      bs_output[ok] = bs
      
;     flag_output = BYTARR(data_size[1], data_size[2]) & FLAG_output[*] = 255
;     flag_output[ok] = flag
      
      UNDEFINE, ok ; Kill the ok variable.
      
      PRINT, SYSTIME(1) - time, ' seconds for reconstructing arrays'
      
      ; Write the PNG output.
      
      time = SYSTIME(1)
      
      reduction_factor = 8
      
      img_for_png = BYTARR(3, data_size[1] / reduction_factor, data_size[2] / reduction_factor)
      img_for_png[1,*,*] = CONGRID(PV_output, data_size[1] / reduction_factor, data_size[2] / reduction_factor)
      img_for_png[0,*,*] = CONGRID(NPV_output, data_size[1] / reduction_factor, data_size[2] / reduction_factor)
      img_for_png[2,*,*] = CONGRID(BS_output, data_size[1] / reduction_factor, data_size[2] / reduction_factor)
      
      where_255 = WHERE(img_for_png EQ 255)
      where_254 = WHERE(img_for_png EQ 254)
      
      img_for_png *= 2.55
      img_for_png[where_255] = 255
      img_for_png[where_254] = 0
      
      WRITE_PNG, MCD43A4_filename_output_png(day, month, year), img_for_png, green, red, blue, /order
      UNDEFINE, img_for_png, where_255, where_254
      PRINT, SYSTIME(1) - time, ' seconds to write the PNG output'
      
      ; Write the flat binary (img) output.
      
      time = SYSTIME(1)
      
      OPENW, lun_pv, output_filename[0], /GET_LUN
      WRITEU, lun_pv, pv_output
      FREE_LUN, lun_pv
      UNDEFINE, pv
      UNDEFINE, pv_output
      
      OPENW, lun_npv, output_filename[1], /GET_LUN
      WRITEU, lun_npv, npv_output
      FREE_LUN, lun_npv
      UNDEFINE, npv
      UNDEFINE, npv_output

      OPENW, lun_bs, output_filename[2], /GET_LUN
      WRITEU, lun_bs, bs_output
      FREE_LUN, lun_bs
      UNDEFINE, bs
      UNDEFINE, bs_output
      
;      OPENW, lun_flag, output_filename[3], /GET_LUN
;      WRITEU, lun_flag, flag_output
;      FREE_LUN, lun_flag
;      UNDEFINE, flag
;      UNDEFINE, flag_output
      
      PRINT, SYSTIME(1) - time, ' seconds to write the flat binary (ENVI) output'
      
      ; Compress (zip) the output files.
      
      time = SYSTIME(1)
      FOR i=0,3 DO SPAWN, 'gzip ' + output_filename[i] , Result, ErrResult, /HIDE ; Compress file.
      
      PRINT, 'memory (in Mb) currently in use - end of loop: ', (Memory())[0] / 1000000
      PRINT, SYSTIME(1) - loop_time, ' seconds for loop'
      
      ENDIF ELSE BEGIN
        PRINT, 'One or more input files do not exist. Skip to next date.', input_filename
      ENDELSE
    
    FILE_DELETE, dummy_filename ; Delete dummy_filename.
    
    ENDIF ELSE Begin
       PRINT, 'File already exists. Skip to the next date.'
    ENDELSE
  ENDFOR
  
  ;EXIT, /NO_CONFIRM
END


