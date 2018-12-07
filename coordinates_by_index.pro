; 22-01-2014
; Garth Warren
; 
; This function may be used to convert grid cell identifiers (ID's) to regular map coordinates. 
; The function returns Easting and Northing coordinates that are intersected by the user defined 
; cell index. The user must specify the number of rows and columns in the grid of interest, and 
; one or more cell indices (1D cell positions)

FUNCTION coordinates_by_index, rows, columns, index

  flat_length = rows * columns
  grid_positions = LINDGEN(columns, rows)
  longitude_coordinates = LINDGEN(columns)+1
  latitude_coordinates = LINDGEN(rows)+1
  coordinates = MAKE_ARRAY(2, N_ELEMENTS(index), /LONG)
  
  FOR i=0, N_ELEMENTS(index)-1 DO BEGIN
    indices = ARRAY_INDICES(grid_positions, index[i]-1)
    x_position = indices[0]
    y_position = indices[1]
    coordinates[*,i] = [longitude_coordinates[x_position], latitude_coordinates[y_position]]
  ENDFOR
  
  return, coordinates
END

