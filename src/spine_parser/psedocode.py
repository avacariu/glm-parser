Initialization: C[s][s][d][c] = 0.0 (any s, d, c)

d is the direction of the subtree
c indicates if the subtree is complete (c=1, no more dependents; c=0, needs to be completed)

for k : 1..n
	for s : 1..n
		t = s + k
		if t > n then break
			pos_num = numbers of possiable adjoin position on header spine
			% First: create incomplete items
			C[s][t][←][0] = max (C[s][r][→][1] + C[r + 1][t][←][1] + s(t, s, i, j)) (where s≤r<t; 0≤i<pos_num; j=0,1 0 is sibling, 1 is regular)
			C[s][t][→][0] = max (C[s][r][→][1] + C[r + 1][t][←][1] + s(s, t, i, j)) (where s≤r<t; 0≤i<pos_num; j=0,1)
			% Second: create complete items
			C[s][t][←][1] = max (C[s][r][←][1] + C[r][t][←][0]) (where s≤r<t)
			C[s][t][→][1] = max (C[s][r][→][0] + C[r][t][→][1]) (where s≤r<t)
	end for
end for