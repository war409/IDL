FUNCTION OWL, RED_, NIR_, BLUE_, SWIR2_

  ;convert to reflectance
  RED_ /= 10000.
  NIR_ /= 10000.
  BLUE_ /= 10000.
  SWIR2_ /= 10000.
 
  EVI = (2.5* ((NIR_ - RED_) / (NIR_ + 6 * RED_ - 7.5 * BLUE_ + 1) ))

  GVMI = ((RED_ + 0.1) - (SWIR2_ + 0.02)) / ((RED_ + 0.1) + (SWIR2_ + 0.02))

  ;DVEL = EVI - LSWI

    OWI = GVMI - EVI

    OWL = (1. / (1+ (exp(-50* (OWI-0.1))))) * (EVI Lt 0.3)
    
    ; converto to byte
    OWL *= 100 
    OWL += .5
    
    OWL = BYTE(Temporary(OWL))
      
  return, OWL

End

FUNCTION NDVI, RED_, NIR_ 

    ;convert to float
    RED_ *= 1.
    NIR_ *= 1.
  
    NDVI = (NIR_ - RED_) / (NIR_ + RED_)
   
    ; converto to byte
    NDVI += 1
    NDVI *= 100 
    NDVI += .5
    
    NDVI = BYTE(Temporary(NDVI))
      
  return, NDVI

End




function MOD09A1_MDB_fname, day, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\MOD09A1.005\MDB\'

  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '

  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '


  fname = strarr(10)


  for i=0, 9 do begin

    Case i of
      0: Band_text= 'MDB.005.b01.500m_0620_0670nm_refl.img'
      1: Band_text= 'MDB.005.b02.500m_0841_0876nm_refl.img'
      2: Band_text= 'MDB.005.b03.500m_0459_0479nm_refl.img'
      3: Band_text= 'MDB.005.b04.500m_0545_0565nm_refl.img'
      4: Band_text= 'MDB.005.b05.500m_1230_1250nm_refl.img'
      5: Band_text= 'MDB.005.b06.500m_1628_1652nm_refl.img'
      6: Band_text= 'MDB.005.b07.500m_2105_2155nm_refl.img'
      7: Band_text= 'MDB.005.b08.500m_quality.img'
      8: Band_text= 'MDB.005.b12.500m_state_flags.img'
      9: Band_text= 'MDB.005.b13.500m_day_of_year.img'

    EndCase

    fname_i = strcompress( $
      path + $
    ; String (year) + '.' + $
    ; app_month + String(month) +  '.' + $
    ; app_day + String(day) +  '\' + $
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

function NDVI_MDB_fname, day, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\NWCEO\MODIS\NDVI\'

  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '

  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '

      Band_text= 'MDB.005.NDVI.img'
 
    fname_i = strcompress( $
      path + $
    ; String (year) + '.' + $
    ; app_month + String(month) +  '.' + $
    ; app_day + String(day) +  '\' + $
      'MOD09A1.' + $
      String (year) + '.' + $
      app_doy + String(doy) + '.' + $
      Band_text , $
      /REMOVE_ALL )

 
 
    ;fname_search = FILE_SEARCH(fname_case)

    ;if n_elements(Fname_search) ne 1 then stop else $
    ; fname[i*2+j] = Fname_case

  return, fname_i
end


function OWL_MDB_png_fname, day, month, year
  compile_opt idl2

  path = '\\file-wron\Working\work\Juan_Pablo\NWCEO\MODIS\OWL\png\'

  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '

  doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '

      Band_text= 'MDB.005.OWL.png'
 
    fname_i = strcompress( $
      path + $
    ; String (year) + '.' + $
    ; app_month + String(month) +  '.' + $
    ; app_day + String(day) +  '\' + $
      'MOD09A1.' + $
      String (year) + '.' + $
      app_doy + String(doy) + '.' + $
      Band_text , $
      /REMOVE_ALL )

 
 
    ;fname_search = FILE_SEARCH(fname_case)

    ;if n_elements(Fname_search) ne 1 then stop else $
    ; fname[i*2+j] = Fname_case

  return, fname_i
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

  dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, dates_2007, dates_2008, dates_2009]
  ;dates = [dates_2007, dates_2008]

  return, dates

end


pro Calculate_NDVI_MOD09A1
  ;open the following image and extract header info (particularly MAP_INFO )
  fname = '\\file-wron\Working\work\Juan_Pablo\MOD09A1.005\MDB\sample\MOD09A1.2009.001.MDB.005.b01.500m_0620_0670nm_refl.img'
  ENVI_OPEN_FILE , fname , R_FID = FID_dummy, /NO_REALIZE
  ENVI_FILE_QUERY, FID_dummy, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE, XSTART=XSTART, YSTART=YSTART, DEF_STRETCH=DEF_STRETCH, ns=ns, nl=nl
  projection = ENVI_GET_PROJECTION (FID= FID_dummy)
  MAP_INFO = ENVI_GET_MAP_INFO  ( FID=FID_dummy)


  Dates = MODIS_8d_dates()
  For dates_n = 6, n_elements(Dates)-1 do begin   ; Starts in 6 because composites 0 to 5  don't exist
    t_date = SysTime(1)
    CALDAT, Dates[dates_n], Month, Day, Year

      ;---------------------------------------------------------------------------------
      ; OPEN and READ FILES
      Input_file = MOD09A1_MDB_fname(day, month, year)
      ;Output_file = MOD09A1_fname_output (day, month, year)

      ; get RED band
      fname = Input_file[0]
      ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
      ENVI_FILE_QUERY, fid, dims=dims
      RED = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
      
      ; get NIR band
      fname = Input_file[1]
      ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
      ENVI_FILE_QUERY, fid, dims=dims
      NIR = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
      
;      ; get BLUE band
;      fname = Input_file[2]
;      ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
;      ENVI_FILE_QUERY, fid, dims=dims
;      BLUE = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
;      
;      ; get SWIR2 band
;      fname = Input_file[5]
;      ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
;      ENVI_FILE_QUERY, fid, dims=dims
;      SWIR2 = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)

      ; get STATE_FLAGS band
      fname = Input_file[8]
      ENVI_OPEN_FILE , fname , R_FID=FID, /NO_REALIZE
      ENVI_FILE_QUERY, fid, dims=dims
      STATE = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
      ;---------------------------------------------------------------------------------


      ;---------------------------------------------------------------------------------
      ; calculate NDVI
      
      NDVI=NDVI(RED, NIR)
      MASK_OK = ((STATE AND 7) eq 0 ) AND (RED ge 0 and NIR ge 0)
      NDVI= NDVI * (MASK_OK eq 1) + 255 * ((MASK_OK eq 0))
 
;      OWL_png=OWL              ; saves a copy for png later on
;      MASK_OK_png=MASK_OK     ; saves a copy for png later on
      
      ;---------------------------------------------------------------------------------


      ;---------------------------------------------------------------------------------
      ; saves output (ENVI)
 
      fname_output = NDVI_MDB_fname(day, month, year)
      ENVI_WRITE_ENVI_FILE, NDVI, OUT_NAME = fname_output, $
          MAP_INFO=MAP_INFO, DATA_IGNORE_VALUE=255, $
          XSTART=XSTART, YSTART=YSTART, /No_Open
      ;---------------------------------------------------------------------------------


      ;---------------------------------------------------------------------------------
      ; saves png
;        ; Color scheme for pngs outputs
;          red = reverse(Indgen(256))   & red[255]=200          
;          green = reverse(Indgen(256))  & green[255]=200
;          blue = intarr(256) & blue[*]=255   & blue[255]=200
;          transparent = Indgen(256)  
;          
;          color_scale =  intarr(3, 256)
;          color_scale[0,*] = indgen (256)
;          color_scale[1,*] = indgen (256)
;          color_scale[2,*] = indgen (256)
;          
;          nfile = '\\file-wron\Working\work\Juan_Pablo\NWCEO\MODIS\OWL\png\color_scale.png'
;          WRITE_PNG, nfile, color_scale, red,green,blue, /order
;      
;          OWL_png=Byte(Temporary(OWL_png) * 2.54)      ;converts OWL from 0 to 254
;          OWL_png= OWL_png * (MASK_OK_png eq 1) + 255 * ((MASK_OK_png eq 0))
;          
;           fname_png=OWL_MDB_png_fname(day, month, year)
;
;          WRITE_PNG, fname_png, OWL_png, red,green,blue, transparent=transparent ,/order
;      ;---------------------------------------------------------------------------------
           

         print, SysTime(1)-t_date,' seconds for date', day, month, year
      
    endfor


end

