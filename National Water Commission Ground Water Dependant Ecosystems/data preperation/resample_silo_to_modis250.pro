
function Resample_SILO_to_modis250, array
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
 
  ; resize new array to MODIS 250m dimensions
  new_Array_MCD43_Size = Congrid(new_Array, 19182, 14924)
  ; gets rid of left, top 5 pixels , bottom , right 6 pixels
  new_array_final = new_Array_MCD43_Size[10:19169, 10:14911]
 
  return, new_array_final
end