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

;FILE_IN = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.500m.img'
;data = READ_BINARY(FILE_IN, DATA_TYPE=1)
;new_Array = FltArr(9580, 7451)
;new_Array[0:9579,0:7450] = data
;new_Array_250 = Congrid(new_Array, 19160, 14902)
;OUT_FNAME='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\PET.250.img'
;OPENW, UNIT_OUT, OUT_FNAME, /GET_LUN ; Create the output file.
;FREE_LUN, UNIT_OUT ; Close the output file.
;OPENU, UNIT_OUT, OUT_FNAME, /APPEND, /GET_LUN
;WRITEU, UNIT_OUT, new_Array_250 
;FREE_LUN, UNIT_OUT
        
        
        
        
        



