

PRO PickColorName_CenterTLB, tlb

; Center the top-level base widget.

screenSize = Get_Screen_Size()
Device, Get_Screen_Size=screenSize
IF screenSize[0] GT 2000 THEN screenSize[0] = screenSize[0]/2
xCenter = screenSize(0) / 2
yCenter = screenSize(1) / 2

geom = Widget_Info(tlb, /Geometry)
xHalfSize = geom.Scr_XSize / 2
yHalfSize = geom.Scr_YSize / 2

Widget_Control, tlb, XOffset = xCenter-xHalfSize, $
   YOffset = yCenter-yHalfSize

END ;-------------------------------------------------------------------------------


FUNCTION PickColorName_RGB_to_24Bit, number

; Convert RGB values to 24-bit number values.

IF Size(number, /N_Dimensions) EQ 1 THEN BEGIN
   RETURN, number[0] + (number[1] * 2L^8) + (number[2] * 2L^16)
ENDIF ELSE BEGIN
   RETURN, number[*,0] + (number[*,1] * 2L^8) + (number[*,2] * 2L^16)
ENDELSE
END ;-------------------------------------------------------------------------------


FUNCTION PickColorName_Count_Rows, filename, MaxRows = maxrows

; This utility routine is used to count the number of
; rows in an ASCII data file.

IF N_Elements(maxrows) EQ 0 THEN maxrows = 500L
IF N_Elements(filename) EQ 0 THEN BEGIN
   filename = Dialog_Pickfile()
   IF filename EQ "" THEN RETURN, -1
ENDIF

OpenR, lun, filename, /Get_Lun

Catch, error
IF error NE 0 THEN BEGIN
   count = count-1
   Free_Lun, lun
   RETURN, count
ENDIF

RESTART:

count = 1L
line = ''
FOR j=count, maxrows DO BEGIN
   ReadF, lun, line
   count = count + 1

      ; Try again if you hit MAXROWS without encountering the
      ; end of the file. Double the MAXROWS parameter.

   IF j EQ maxrows THEN BEGIN
      maxrows = maxrows * 2
      Point_Lun, lun, 0
      GOTO, RESTART
   ENDIF

ENDFOR

RETURN, -1
END ;-------------------------------------------------------------------------------


PRO PickColorName_Select_Color, event

; This event handler permits color selection by clicking on a color window.

IF event.type NE 0 THEN RETURN

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Get the color names from the window you clicked on and set it.

Widget_Control, event.id, Get_UValue=thisColorName
;Widget_Control, event.top, Update=0
Widget_Control, info.labelID, Set_Value=thisColorName
;Widget_Control, event.top, Update=1

   ; Get the color value and load it as the current color.

WSet, info.mixWID
info.theName = thisColorName
theIndex = Where(info.colorNames EQ StrUpCase(StrCompress(thisColorName, /Remove_All)))
theIndex = theIndex[0]
info.nameIndex = theIndex

IF info.theDepth GT 8 THEN BEGIN
   Erase, Color=info.colors24[theIndex]
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=info.black
ENDIF ELSE BEGIN
   TVLCT, info.red[theIndex], info.green[theIndex], info.blue[theIndex], info.mixcolorIndex
   Erase, Color=info.mixcolorIndex
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=info.black
ENDELSE

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------


PRO PickColorName_Buttons, event

; This event handler responds to CANCEL and ACCEPT buttons.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Which button is this?

Widget_Control, event.id, Get_Value=buttonValue

   ; Branch on button value.

CASE buttonValue OF

   'Cancel': BEGIN

         ; Simply destroy the widget. The pointer info is already
         ; set up for a CANCEL event.

      Widget_Control, event.top, /Destroy
      ENDCASE

   'Accept': BEGIN

         ; Get the new color table after the color has been selected.

      TVLCT, r, g, b, /Get

         ; Save the new color and name in the pointer.

      *(info.ptr) = {cancel:0.0, r:info.red[info.nameIndex], g:info.green[info.nameIndex], $
         b:info.blue[info.nameIndex], name:info.theName}

         ; Destoy the widget.

      Widget_Control, event.top, /Destroy

      ENDCASE
ENDCASE
END ;---------------------------------------------------------------------------


FUNCTION PickColorName, theName, $         ; The name of the starting color.
   Brewer=brewer, $                        ; Select brewer colors.
   Bottom=bottom, $                        ; The index number where the colors should be loaded.
   Cancel=cancelled, $                     ; An output keyword set to 1 if the user cancelled or an error occurred.
   Columns = ncols, $                      ; The number of columns to display the colors in.
   Filename=filename, $                    ; The name of the file which contains color names and values.
   Group_Leader=group_leader, $            ; The group leader of the TLB. Required for modal operation.
   Index=index, $                          ; The color index number where the final selected color should be loaded.
   Title=title                             ; The title of the top-level base widget.

   ; Error handling for this program module.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(/Traceback)
   cancel = 1
   IF N_Elements(theName) NE 0 THEN RETURN, theName ELSE RETURN, 'White'
ENDIF

   ; Get depth of visual display.

IF (!D.Flags AND 256) NE 0 THEN Device, Get_Visual_Depth=theDepth ELSE theDepth = 8

   ; Is there a filename? If so, get colors from there.

IF N_Elements(filename) NE 0 THEN BEGIN

      ; Count the number of rows in the file.

   NCOLORS = PickColorName_Count_Rows(filename)

      ; Read the data.

   OpenR, lun, filename, /Get_Lun
   red = BytArr(NCOLORS)
   green = BytArr(NCOLORS)
   blue = BytArr(NCOLORS)
   colors = StrArr(NCOLORS)
   redvalue = 0B
   greenvalue = 0B
   bluevalue = 0B
   namevalue = ""
   FOR j=0L, NCOLORS-1 DO BEGIN
      ReadF, lun, redvalue, greenvalue, bluevalue, namevalue
      colors[j] = namevalue
      red[j] = redvalue
      green[j] = greenvalue
      blue[j] = bluevalue
   ENDFOR

      ; Trim the colors array of blank characters.

   colors = StrTrim(colors, 2)

      ; Calculate the number of columns to display colors in.

   IF N_Elements(ncols) EQ 0 THEN ncols = Fix(Sqrt(ncolors))
   Free_Lun, lun
ENDIF ELSE BEGIN

   IF theDepth GT 8 THEN BEGIN

      ; The colors with their names.

   IF N_Elements(ncols) EQ 0 THEN ncols = 12
   IF Keyword_Set(brewer) THEN BEGIN
       colors = [ 'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'WT7', 'WT8']
       red =   [   255,   255,   255,   255,   255,   245,   255,   250 ]
       green = [   255,   250,   255,   255,   248,   245,   245,   240 ]
       blue =  [   255,   250,   240,   224,   220,   220,   238,   230 ]
       colors = [ colors, 'TAN1', 'TAN2', 'TAN3', 'TAN4', 'TAN5', 'TAN6', 'TAN7', 'TAN8']
       red =   [ red,      250,   255,    255,    255,    255,    245,    222,    210 ]
       green = [ green,    235,   239,    235,    228,    228,    222,    184,    180 ]
       blue =  [ blue,     215,   213,    205,    196,    181,    179,    135,    140 ]
       colors = [ colors, 'BLK1', 'BLK2', 'BLK3', 'BLK4', 'BLK5', 'BLK6', 'BLK7', 'BLK8']
       red =   [ red,      250,   230,    210,    190,    112,     110,    70,       0 ]
       green = [ green,    250,   230,    210,    190,    128,     110,    70,       0 ]
       blue =  [ blue,     250,   230,    210,    190,    128,     110,    70,       0 ]
       colors = [ colors, 'GRN1', 'GRN2', 'GRN3', 'GRN4', 'GRN5', 'GRN6', 'GRN7', 'GRN8']
       red =   [ red,      250,   223,    173,    109,     53,     35,      0,       0 ]
       green = [ green,    253,   242,    221,    193,    156,     132,    97,      69 ]
       blue =  [ blue,     202,   167,    142,    115,     83,      67,    52,      41 ]
       colors = [ colors, 'BLU1', 'BLU2', 'BLU3', 'BLU4', 'BLU5', 'BLU6', 'BLU7', 'BLU8']
       red =   [ red,      232,   202,    158,     99,     53,     33,      8,       8 ]
       green = [ green,    241,   222,    202,    168,    133,    113,     75,      48 ]
       blue =  [ blue,     250,   240,    225,    211,    191,    181,    147,     107 ]
       colors = [ colors, 'ORG1', 'ORG2', 'ORG3', 'ORG4', 'ORG5', 'ORG6', 'ORG7', 'ORG8']
       red =   [ red,      254,    253,    253,    250,    231,    217,    159,    127 ]
       green = [ green,    236,    212,    174,    134,     92,     72,     51,     39 ]
       blue =  [ blue,     217,    171,    107,     52,     12,      1,      3,      4 ]
       colors = [ colors, 'RED1', 'RED2', 'RED3', 'RED4', 'RED5', 'RED6', 'RED7', 'RED8']
       red =   [ red,      254,    252,    252,    248,    225,    203,    154,    103 ]
       green = [ green,    232,    194,    146,     97,     45,     24,     12,      0 ]
       blue =  [ blue,     222,    171,    114,     68,     38,     29,     19,     13 ]
       colors = [ colors, 'PUR1', 'PUR2', 'PUR3', 'PUR4', 'PUR5', 'PUR6', 'PUR7', 'PUR8']
       red =   [ red,      244,    222,    188,    152,    119,    106,     80,     63 ]
       green = [ green,    242,    221,    189,    148,    108,     82,     32,      0 ]
       blue =  [ blue,     248,    237,    220,    197,    177,    163,    139,    125 ]
       colors = [ colors, 'PBG1', 'PBG2', 'PBG3', 'PBG4', 'PBG5', 'PBG6', 'PBG7', 'PBG8']
       red =   [ red,      243,    213,    166,     94,     34,      3,      1,      1 ]
       green = [ green,    234,    212,    189,    164,    138,    129,    101,     70 ]
       blue =  [ blue,     244,    232,    219,    204,    171,    139,     82,     54 ]
       colors = [ colors, 'YGB1', 'YGB2', 'YGB3', 'YGB4', 'YGB5', 'YGB6', 'YGB7', 'YGB8']
       red =   [ red,      244,    206,    127,     58,     30,     33,     32,      8 ]
       green = [ green,    250,    236,    205,    175,    125,     95,     48,     29 ]
       blue =  [ blue,     193,    179,    186,    195,    182,    168,    137,     88 ]
       colors = [ colors, 'RYB1', 'RYB2', 'RYB3', 'RYB4', 'RYB5', 'RYB6', 'RYB7', 'RYB8']
       red =   [ red,       201,    245,    253,    251,    228,    193,    114,     59 ]
       green = [ green,      35,    121,    206,    253,    244,    228,    171,     85 ]
       blue =  [ blue,       38,    72,     127,    197,    239,    239,    207,    164 ]
       colors = [ colors, 'TG1', 'TG2', 'TG3', 'TG4', 'TG5', 'TG6', 'TG7', 'TG8']
       red =   [ red,      84,    163,   197,   220,   105,    51,    13,     0 ]
       green = [ green,    48,    103,   141,   188,   188,   149,   113,    81 ]
       blue =  [ blue,      5,     26,    60,   118,   177,   141,   105,    71 ]   
   ENDIF ELSE BEGIN
       colors= ['White']
       red =   [ 255]
       green = [ 255]
       blue =  [ 255]
       colors= [ colors,      'Snow',     'Ivory','Light Yellow',   'Cornsilk',      'Beige',   'Seashell' ]
       red =   [ red,            255,          255,          255,          255,          245,          255 ]
       green = [ green,          250,          255,          255,          248,          245,          245 ]
       blue =  [ blue,           250,          240,          224,          220,          220,          238 ]
       colors= [ colors,     'Linen','Antique White',    'Papaya',     'Almond',     'Bisque',  'Moccasin' ]
       red =   [ red,            250,          250,          255,          255,          255,          255 ]
       green = [ green,          240,          235,          239,          235,          228,          228 ]
       blue =  [ blue,           230,          215,          213,          205,          196,          181 ]
       colors= [ colors,     'Wheat',  'Burlywood',        'Tan', 'Light Gray',   'Lavender','Medium Gray' ]
       red =   [ red,            245,          222,          210,          230,          230,          210 ]
       green = [ green,          222,          184,          180,          230,          230,          210 ]
       blue =  [ blue,           179,          135,          140,          230,          250,          210 ]
       colors= [ colors,      'Gray', 'Slate Gray',  'Dark Gray',   'Charcoal',      'Black',   'Honeydew', 'Light Cyan' ]
       red =   [ red,            190,          112,          110,           70,            0,          240,          224 ]
       green = [ green,          190,          128,          110,           70,            0,          255,          255 ]
       blue =  [ blue,           190,          144,          110,           70,            0,          255,          240 ]
       colors= [ colors,'Powder Blue',  'Sky Blue', 'Cornflower Blue', 'Cadet Blue', 'Steel Blue','Dodger Blue', 'Royal Blue',  'Blue' ]
       red =   [ red,            176,          135,         100,           95,            70,           30,           65,            0 ]
       green = [ green,          224,          206,         149,          158,           130,          144,          105,            0 ]
       blue =  [ blue,           230,          235,         237,          160,           180,          255,          225,          255 ]
       colors= [ colors,      'Navy', 'Pale Green','Aquamarine','Spring Green',       'Cyan' ]
       red =   [ red,              0,          152,          127,            0,            0 ]
       green = [ green,            0,          251,          255,          250,          255 ]
       blue =  [ blue,           128,          152,          212,          154,          255 ]
       colors= [ colors, 'Turquoise', 'Light Sea Green', 'Sea Green','Forest Green',  'Teal','Green Yellow','Chartreuse', 'Lawn Green' ]
       red =   [ red,             64,       143,             46,           34,             0,      173,           127,         124 ]
       green = [ green,          224,       188,            139,          139,           128,      255,           255,         252 ]
       blue =  [ blue,           208,       143,             87,           34,           128,       47,             0,           0 ]
       colors= [ colors,     'Green', 'Lime Green', 'Olive Drab',     'Olive','Dark Green','Pale Goldenrod']
       red =   [ red,              0,           50,          107,           85,            0,          238 ]
       green = [ green,          255,          205,          142,          107,          100,          232 ]
       blue =  [ blue,             0,           50,           35,           47,            0,          170 ]
       colors =[ colors,     'Khaki', 'Dark Khaki',     'Yellow',       'Gold','Goldenrod','Dark Goldenrod']
       red =   [ red,            240,          189,          255,          255,          218,          184 ]
       green = [ green,          230,          183,          255,          215,          165,          134 ]
       blue =  [ blue,           140,          107,            0,            0,           32,           11 ]
       colors= [ colors,'Saddle Brown',       'Rose',       'Pink', 'Rosy Brown','Sandy Brown',      'Peru']
       red =   [ red,            139,          255,          255,          188,          244,          205 ]
       green = [ green,           69,          228,          192,          143,          164,          133 ]
       blue =  [ blue,            19,          225,          203,          143,           96,           63 ]
       colors= [ colors,'Indian Red',  'Chocolate',     'Sienna','Dark Salmon',    'Salmon','Light Salmon' ]
       red =   [ red,            205,          210,          160,          233,          250,          255 ]
       green = [ green,           92,          105,           82,          150,          128,          160 ]
       blue =  [ blue,            92,           30,           45,          122,          114,          122 ]
       colors= [ colors,    'Orange',      'Coral', 'Light Coral',  'Firebrick',   'Dark Red',    'Brown',  'Hot Pink' ]
       red =   [ red,            255,          255,          240,          178,       139,          165,        255 ]
       green = [ green,          165,          127,          128,           34,         0,           42,        105 ]
       blue =  [ blue,             0,           80,          128,           34,         0,           42,        180 ]
       colors= [ colors, 'Deep Pink',    'Magenta',     'Tomato', 'Orange Red',        'Red', 'Crimson', 'Violet Red' ]
       red =   [ red,            255,          255,          255,          255,          255,      220,        208 ]
       green = [ green,           20,            0,           99,           69,            0,       20,         32 ]
       blue =  [ blue,           147,          255,           71,            0,            0,       60,        144 ]
       colors= [ colors,    'Maroon',    'Thistle',       'Plum',     'Violet',    'Orchid','Medium Orchid']
       red =   [ red,            176,          216,          221,          238,          218,          186 ]
       green = [ green,           48,          191,          160,          130,          112,           85 ]
       blue =  [ blue,            96,          216,          221,          238,          214,          211 ]
       colors= [ colors,'Dark Orchid','Blue Violet',     'Purple']
       red =   [ red,            153,          138,          160]
       green = [ green,           50,           43,           32]
       blue =  [ blue,           204,          226,          240]
       colors= [ colors, 'Slate Blue',  'Dark Slate Blue']
       red =   [ red,           106,            72]
       green = [ green,            90,            61]
       blue =  [ blue,           205,           139]
       colors = [ colors, 'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'WT7', 'WT8']
       red =   [ red,     255,   255,   255,   255,   255,   245,   255,   250 ]
       green = [ green,   255,   250,   255,   255,   248,   245,   245,   240 ]
       blue =  [ blue,    255,   250,   240,   224,   220,   220,   238,   230 ]
       colors = [ colors, 'TAN1', 'TAN2', 'TAN3', 'TAN4', 'TAN5', 'TAN6', 'TAN7', 'TAN8']
       red =   [ red,      250,   255,    255,    255,    255,    245,    222,    210 ]
       green = [ green,    235,   239,    235,    228,    228,    222,    184,    180 ]
       blue =  [ blue,     215,   213,    205,    196,    181,    179,    135,    140 ]
       colors = [ colors, 'BLK1', 'BLK2', 'BLK3', 'BLK4', 'BLK5', 'BLK6', 'BLK7', 'BLK8']
       red =   [ red,      250,   230,    210,    190,    112,     110,    70,       0 ]
       green = [ green,    250,   230,    210,    190,    128,     110,    70,       0 ]
       blue =  [ blue,     250,   230,    210,    190,    128,     110,    70,       0 ]
       colors = [ colors, 'GRN1', 'GRN2', 'GRN3', 'GRN4', 'GRN5', 'GRN6', 'GRN7', 'GRN8']
       red =   [ red,      250,   223,    173,    109,     53,     35,      0,       0 ]
       green = [ green,    253,   242,    221,    193,    156,     132,    97,      69 ]
       blue =  [ blue,     202,   167,    142,    115,     83,      67,    52,      41 ]
       colors = [ colors, 'BLU1', 'BLU2', 'BLU3', 'BLU4', 'BLU5', 'BLU6', 'BLU7', 'BLU8']
       red =   [ red,      232,   202,    158,     99,     53,     33,      8,       8 ]
       green = [ green,    241,   222,    202,    168,    133,    113,     75,      48 ]
       blue =  [ blue,     250,   240,    225,    211,    191,    181,    147,     107 ]
       colors = [ colors, 'ORG1', 'ORG2', 'ORG3', 'ORG4', 'ORG5', 'ORG6', 'ORG7', 'ORG8']
       red =   [ red,      254,    253,    253,    250,    231,    217,    159,    127 ]
       green = [ green,    236,    212,    174,    134,     92,     72,     51,     39 ]
       blue =  [ blue,     217,    171,    107,     52,     12,      1,      3,      4 ]
       colors = [ colors, 'RED1', 'RED2', 'RED3', 'RED4', 'RED5', 'RED6', 'RED7', 'RED8']
       red =   [ red,      254,    252,    252,    248,    225,    203,    154,    103 ]
       green = [ green,    232,    194,    146,     97,     45,     24,     12,      0 ]
       blue =  [ blue,     222,    171,    114,     68,     38,     29,     19,     13 ]
       colors = [ colors, 'PUR1', 'PUR2', 'PUR3', 'PUR4', 'PUR5', 'PUR6', 'PUR7', 'PUR8']
       red =   [ red,      244,    222,    188,    152,    119,    106,     80,     63 ]
       green = [ green,    242,    221,    189,    148,    108,     82,     32,      0 ]
       blue =  [ blue,     248,    237,    220,    197,    177,    163,    139,    125 ]
       colors = [ colors, 'PBG1', 'PBG2', 'PBG3', 'PBG4', 'PBG5', 'PBG6', 'PBG7', 'PBG8']
       red =   [ red,      243,    213,    166,     94,     34,      3,      1,      1 ]
       green = [ green,    234,    212,    189,    164,    138,    129,    101,     70 ]
       blue =  [ blue,     244,    232,    219,    204,    171,    139,     82,     54 ]
       colors = [ colors, 'YGB1', 'YGB2', 'YGB3', 'YGB4', 'YGB5', 'YGB6', 'YGB7', 'YGB8']
       red =   [ red,      244,    206,    127,     58,     30,     33,     32,      8 ]
       green = [ green,    250,    236,    205,    175,    125,     95,     48,     29 ]
       blue =  [ blue,     193,    179,    186,    195,    182,    168,    137,     88 ]
       colors = [ colors, 'RYB1', 'RYB2', 'RYB3', 'RYB4', 'RYB5', 'RYB6', 'RYB7', 'RYB8']
       red =   [ red,       201,    245,    253,    251,    228,    193,    114,     59 ]
       green = [ green,      35,    121,    206,    253,    244,    228,    171,     85 ]
       blue =  [ blue,       38,    72,     127,    197,    239,    239,    207,    164 ]
       colors = [ colors, 'TG1', 'TG2', 'TG3', 'TG4', 'TG5', 'TG6', 'TG7', 'TG8']
       red =   [ red,      84,    163,   197,   220,   105,    51,    13,     0 ]
       green = [ green,    48,    103,   141,   188,   188,   149,   113,    81 ]
       blue =  [ blue,      5,     26,    60,   118,   177,   141,   105,    71 ]   
   ENDELSE
   ENDIF ELSE BEGIN

   IF N_Elements(ncols) EQ 0 THEN ncols = 8
   colors  = ['Black', 'Magenta', 'Cyan', 'Yellow', 'Green']
   red =     [  0,        255,       0,      255,       0  ]
   green =   [  0,          0,     255,      255,     255  ]
   blue =    [  0,        255,     255,        0,       0  ]
   colors  = [colors,  'Red', 'Blue', 'Navy', 'Pink', 'Aqua']
   red =     [red,     255,     0,      0,    255,    112]
   green =   [green,     0,     0,      0,    127,    219]
   blue =    [blue,      0,   255,    115,    127,    147]
   colors  = [colors,  'Orchid', 'Sky', 'Beige', 'Charcoal', 'Gray','White']
   red =     [red,     219,      0,     245,       80,      135,    255  ]
   green =   [green,   112,    163,     245,       80,      135,    255  ]
   blue =    [blue,    219,    255,     220,       80,      135,    255  ]

   ENDELSE
ENDELSE

NCOLORS = N_Elements(colors)



   ; Save decomposed state and restore it, if possible.

IF Float(!Version.Release) GE 5.2 THEN BEGIN
   Device, Get_Decomposed=decomposedState
ENDIF ELSE decomposedState = 0

   ; Different color decomposition based on visual depth.

IF theDepth GT 8 THEN BEGIN
   Device, Decomposed=1
   colors24 = PickColorName_RGB_to_24Bit([[red], [green], [blue]])
ENDIF ELSE BEGIN
   IF NCOLORS GT !D.Table_Size THEN $
      Message, /NoName, 'Number of colors exceeds color table size. Returning...'
   Device, Decomposed=0
   colors24 = -1
ENDELSE

   ; Check argument values. All arguments are optional.

IF N_Elements(theName) EQ 0 THEN IF Keyword_Set(brewer) THEN theName = 'WT1' ELSE theName = 'White'
IF Size(theName, /TName) NE 'STRING' THEN $
   Message, 'Color name argument must be STRING type.', /NoName
theName = StrCompress(theName, /Remove_All)

IF N_Elements(bottom) EQ 0 THEN bottom = 0 > (!D.Table_Size - (NCOLORS + 2))
mixcolorIndex = bottom
IF N_Elements(title) EQ 0 THEN title='Select a Color'

   ; We will work with all uppercase names.

colorNames = StrUpCase(StrCompress(colors, /Remove_All))

   ; Get the current color table vectors before we change anything.
   ; This will allow us to restore the color table when we depart.

TVLCT, r_old, g_old, b_old, /Get

   ; Load the colors if needed. The "bottom" index is reserved as the "mixing color" index.

IF theDepth LE 8 THEN TVLCT, red, green, blue, bottom+1

   ; Can you find the color name in the colors array?

nameIndex = WHERE(colorNames EQ StrUpCase(theName), count)
IF count EQ 0 THEN BEGIN
   Message, 'Unable to resolve color name: ' + StrUpCase(theName) + '. Replacing with WHITE.', /Informational
   theName = 'WT1'
   nameIndex = WHERE(colorNames EQ StrUpCase(theName), count)
   IF count EQ 0 THEN Message, /NoName, 'Unable to resolve color name: ' + StrUpCase(theName) + '. Returning...'
ENDIF
nameIndex = nameIndex[0]

   ; Who knows how the user spelled the color? Make it look nice.

theName = colors[nameIndex]

   ; Load the mixing color in the mixcolorIndex.

IF theDepth LE 8 THEN TVLCT, red[nameIndex], green[nameIndex], blue[nameIndex], mixcolorIndex

   ; Create the widgets. TLB is MODAL or BLOCKING, depending upon presence of
   ; Group_Leader variable.

IF N_Elements(group_leader) EQ 0 THEN BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center)
ENDIF ELSE BEGIN
   tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center, /Modal, $
      Group_Leader=group_leader)
ENDELSE

   ; Draw widgets for the possible colors. Store the color name in the UVALUE.

colorbaseID = Widget_Base(tlb, Column=ncols, Event_Pro='PickColorName_Select_Color')
drawID = LonArr(NCOLORS)
FOR j=0,NCOLORS-1 DO BEGIN
   drawID[j] = Widget_Draw(colorbaseID, XSize=20, YSize=15, $
      UValue=colors[j], Button_Events=1)
ENDFOR

   ; System colors.

IF N_Elements(colors) GT NCOLORS THEN BEGIN
   systemColorbase = Widget_Base(tlb, Column=8, Event_Pro='PickColorName_Select_Color')
   drawID = [Temporary(drawID), LonArr(8)]
   FOR j=NCOLORS,N_Elements(colors)-1 DO BEGIN
      drawID[j] = Widget_Draw(systemColorbase, XSize=20, YSize=15, $
         UValue=colors[j], Button_Events=1)
   ENDFOR
ENDIF

   ; Set up the current or mixing color draw widget.

currentID = Widget_Base(tlb, Column=1, Base_Align_Center=1)

; Special concerns with LABEL widgets to work around a widget update bug in
; X11 libraries.
IF StrUpCase(!Version.OS_Family) EQ 'WINDOWS' $
    THEN labelID = Widget_Label(currentID, Value=theName, /Dynamic_Resize) $
    ELSE labelID = Widget_Label(currentID, Value=theName, /Dynamic_Resize, SCR_XSIZE=150)
mixColorID = Widget_Draw(currentID, XSize=60, YSize=15)

   ; CANCEL and ACCEPT buttons.

buttonbase = Widget_Base(tlb, ROW=1, Align_Center=1, Event_Pro='PickColorName_Buttons')
cancelID = Widget_Button(buttonbase, VALUE='Cancel')
acceptID = Widget_Button(buttonbase, VALUE='Accept')

   ; Center the TLB.

PickColorName_CenterTLB, tlb
Widget_Control, tlb, /Realize

   ; Load the drawing colors.

wids = IntArr(NCOLORS)
IF theDepth GT 8 THEN BEGIN
   FOR j=0,NCOLORS-1 DO BEGIN
      Widget_Control, drawID[j], Get_Value=thisWID
      wids[j] = thisWID
      WSet, thisWID
      PolyFill, [1,1,19,19,1], [0,13,13,0,0], /Device, Color=colors24[j]
   ENDFOR
   IF (N_Elements(colors) GT NCOLORS) THEN BEGIN
      wids = [Temporary(wids), Intarr(8)]
      FOR j=NCOLORS, N_Elements(colors)-1 DO BEGIN
      Widget_Control, drawID[j], Get_Value=thisWID
      wids[j] = thisWID
      WSet, thisWID
      PolyFill, [1,1,19,19,1], [0,13,13,0,0], /Device, Color=colors24[j]
      ENDFOR
   ENDIF
ENDIF ELSE BEGIN
   FOR j=1,NCOLORS DO BEGIN
      Widget_Control, drawID[j-1], Get_Value=thisWID
      wids[j-1] = thisWID
      WSet, thisWID
      PolyFill, [1,1,19,19,1], [0,13,13,0,0], /Device, Color=bottom + black
   ENDFOR
   IF (N_Elements(colors) GT NCOLORS) THEN BEGIN
      wids = [Temporary(wids), Intarr(8)]
      FOR j=NCOLORS+1, N_Elements(colors) DO BEGIN
      Widget_Control, drawID[j-1], Get_Value=thisWID
      wids[j-1] = thisWID
      WSet, thisWID
      PolyFill, [1,1,19,19,1], [0,13,13,0,0], /Device, Color=bottom + j
      ENDFOR
   ENDIF
ENDELSE

   ; Load the current or mixing color.

Widget_Control, mixColorID, Get_Value=mixWID
WSet, mixWID
IF theDepth GT 8 THEN BEGIN
   Erase, Color=colors24[nameIndex]
   eraseColor = Keyword_Set(brewer) ? 'BLK8' : 'BLACK
   black = Where(colornames EQ eraseColor)
   black = black[0]
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=colors24[black]
ENDIF ELSE BEGIN
   eraseColor = Keyword_Set(brewer) ? 'BLK8' : 'BLACK
   black = Where(colornames EQ eraseColor)
   Erase, Color=mixcolorIndex
   PlotS, [0,0,59,59,0], [0,14,14,0,0], /Device, Color=black
ENDELSE

   ; Pointer to hold the color form information.

ptr = Ptr_New({cancel:1.0, r:0B, g:0B, b:0B, name:theName})

   ; Info structure for program information.

info = { ptr:ptr, $                    ; The pointer to the form information.
         mixColorIndex:mixColorIndex, $
         colorNames:colorNames, $
         nameIndex:nameIndex, $
         red:red, $
         green:green, $
         blue:blue, $
         black:black, $
         colors24:colors24, $
         mixWid:mixWid, $
         theDepth:theDepth, $
         labelID:labelID, $
         theName:theName $
       }

   ; Store the info structure in the UVALUE of the TLB.

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Set up program event loop. This will be blocking widget
   ; if called from the IDL command line. Program operation
   ; will stop here until widget interface is destroyed.

XManager, 'pickcolor', tlb

   ; Retrieve the color information from the pointer and free
   ; the pointer.

colorInfo = *ptr
Ptr_Free, ptr

   ; Set the Cancel flag.

cancelled = colorInfo.cancel

   ; Restore color table, taking care to load the color index if required.

IF N_Elements(index) NE 0 AND (NOT cancelled) THEN BEGIN
   r_old[index] = colorInfo.r
   g_old[index] = colorInfo.g
   b_old[index] = colorInfo.b
ENDIF
TVLCT, r_old, g_old, b_old

   ; Restore decomposed state if possible.

IF Float(!Version.Release) GE 5.2 THEN Device, Decomposed=decomposedState

   ; Return the color name.

RETURN, colorInfo.name
END
