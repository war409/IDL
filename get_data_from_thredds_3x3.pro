

function get_data_from_thredds_3x3, url, lat, lon

  ; determine sample and line of MCD43A4 
  LatLonMODIS= latlon_MODIS500m()
  
  sample = where(LatLonMODIS.lon - lon eq min(LatLonMODIS.lon - lon, /absolute))
  line   = where(LatLonMODIS.lat - lat eq min(LatLonMODIS.lat - lat, /absolute))


  position1 = STRCOMPRESS('['+STRING(sample)+':1:'+STRING(sample+2)+']' , /REMOVE_ALL)
  position2 = STRCOMPRESS('['+STRING(line)  +':1:'+STRING(line+2)+  ']' , /REMOVE_ALL)
  position = position2 + position1
 
   
    ; obtain data from URL  
    t=Systime(1)
    a= webget(url+position, TIMEOUT = 60)
    print, Systime(1)-t, ' seconds for getting the data' 
    ;print, a
    ;for zz=0, n_elements(a)-1 do print, a.text[zz]
    
    ; array will store the 3x3 data values
    array= Strarr(3,3) ; & array[*]= !VALUES.F_NAN
    
    Wh_0 = Where(STRMATCH(a.text, '\[0\]*') eq 1, count0)
    Wh_1 = Where(STRMATCH(a.text, '\[1\]*') eq 1, count1)
    Wh_2 = Where(STRMATCH(a.text, '\[2\]*') eq 1, count2)
    
    if count0+count1+count2 eq 3 then begin
      line0 = (STRSPLIT(a.text[Wh_0], ',', /EXTRACT))[1:*]  ; * 1.0
      line1 = (STRSPLIT(a.text[Wh_1], ',', /EXTRACT))[1:*]  ; * 1.0
      line2 = (STRSPLIT(a.text[Wh_2], ',', /EXTRACT))[1:*]  ; * 1.0
      
      array[*, 0]= line0
      array[*, 1]= line1
      array[*, 2]= line2
    endif  
        
    return, array
  
end

