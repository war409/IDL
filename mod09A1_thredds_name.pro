

function MOD09A1_Thredds_name, band, day, month, year
  compile_opt idl2

  text1 = 'http://thredds0.nci.org.au/thredds/dodsC/u39/modis/lpdaac-mosaics-cmar/v1-hdf4/aust/MOD09A1.005/'
 
  if month le 9 then app_month = '0' else app_month = ' '
  if day le 9 then app_day = '0' else app_day = ' '
  
  doy = JULDAY(month, day, year)  -  JULDAY(1,1,year) + 1
  if doy le 9 then app_doy = '00'
  if doy gt 9 and doy le 99 then app_doy = '0'
  if doy gt 99 then app_doy = ' '

  IF Band le 9 then app_band = '0' else app_band = ' '
  
  Case band of
      1: file = '500m_0620_0670nm_refl'
      2: file = '500m_0841_0876nm_refl'
      3: file = '500m_0459_0479nm_refl'
      4: file = '500m_0545_0565nm_refl'
      5: file = '500m_1230_1250nm_refl'
      6: file = '500m_1628_1652nm_refl'
      7: file = '500m_2105_2155nm_refl' 
      8: file = '500m_quality' 
      9: file = '500m_solar_zenith' 
     10: file = '500m_view_zenith' 
     11: file = '500m_relative_azimuth' 
     12: file = '500m_state_flags' 
     13: file = '500m_day_of_year' 
   EndCase

    fname = strcompress( $
      text1 +  $
      String (year) + '.' + $
      app_month + String(month) +  '.' + $
      app_day + String(day) +  '/' + $
      'MOD09A1.' + $
      String (year) + '.' + $
      app_doy + String(doy) + '.' + $
      'aust.005.' +  $
      'b' + $
      app_band + $
      STRING(band) + '.' + $
      file + $
      '.hdf.gz.ascii?'  + $
      file  , $
      /REMOVE_ALL )

  return, fname

end
