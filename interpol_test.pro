



; Interpol test:



; ----

; The input vector
V = RandomU(-3L, 12) * 10

; Set some 'bad' values
V[[2,5]] = [15, 25]

; Get an index of the 'bad' values
bad_index = WHERE(V GT 10, bad_count, COMPLEMENT=good_index, NCOMPLEMENT=good_count)

; Interpolate
IF (bad_count GT 0) && (good_count GT 1) THEN V[bad_index] = INTERPOL(V[good_index], good_index, bad_index)

cgOPlot, V, LineStyle=2, Thick=2, Color='red'
cgOPlot, [2,5], V[bad_index], PSym=2, SymSize=2, Color='grn6'

; ----


; The input vector
V = RandomU(-3L, 12) * 10

; Set some 'bad' values
V[[2,5]] = [!values.F_NAN, !values.F_NAN]

; Get an index of the 'bad' values
bad_index = WHERE((FINITE(V) EQ 0), bad_count, COMPLEMENT=good_index, NCOMPLEMENT=good_count)

; Interpolate
IF (bad_count GT 0) && (good_count GT 1) THEN V[bad_index] = INTERPOL(V[good_index], good_index, bad_index)

cgOPlot, V, LineStyle=2, Thick=2, Color='red'
cgOPlot, [2,5], V[bad_index], PSym=2, SymSize=2, Color='grn6'


; ---- 

; Multiband data? - we need to struture the files as: [band, data] not as: [data, band]

V = RandomU(-3L, [5,12]) * 10

HELP, V

; Set some 'bad' values
V[1,[2,5]] = [!values.F_NAN, !values.F_NAN]

; Get an index of the 'bad' values
bad_index = WHERE((FINITE(V) EQ 0), bad_count, COMPLEMENT=good_index, NCOMPLEMENT=good_count)

; Interpolate
IF (bad_count GT 0) && (good_count GT 1) THEN V[bad_index] = INTERPOL(V[good_index], good_index, bad_index)


; ----

; Multiband data - no data for a pixel

V = RandomU(-3L, [5,12]) * 10
HELP, V

; Set some 'bad' values
V[1,[2,5]] = [!values.F_NAN, !values.F_NAN]
V[*,8] = !values.F_NAN

; Get an index of the 'bad' values
bad_index = WHERE((FINITE(V) EQ 0), bad_count, COMPLEMENT=good_index, NCOMPLEMENT=good_count)

cgPlot, V, Thick=2, Color='red'

; Interpolate
IF (bad_count GT 0) && (good_count GT 1) THEN V[bad_index] = INTERPOL(V[good_index], good_index, bad_index)

cgOPlot, V, LineStyle=2, Thick=2, Color='red'
cgOPlot, bad_index, V[bad_index], PSym=2, SymSize=2, Color='grn6'

; ----












; The interpolate function?

p = cgScaleVector(Findgen(110), 70, 1051)
t = cgScaleVector(Findgen(150), 180, 329)

; Find pressure fractional index
pval = 700.6
pstep = p[1] - p[0]
closeIndex = Value_Locate(p, pval)
pFracIndex = closeIndex + ((pval - p[closeIndex]) / pstep)

; Find temperature fractional index
tval = 234.56
tstep = t[1] - t[0]
closeIndex = Value_Locate(t, tval)
tFracIndex = closeIndex + ((tval - t[closeIndex]) / tstep)

; Interpolate
interpValue = Interpolate(griddedArray, pFracIndex, tFracIndex)













