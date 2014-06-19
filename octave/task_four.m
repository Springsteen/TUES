function cubic(a,b,c,d)
	p = - ( (b^2) / (3*(a^2))) + (c/a)
	q =( (2 * (b^3)) / (27*(a^3))) - ((b*c) / (3*(a^2))) + (d/a)
	ur1 = (-q/2) + sqrt(((q^2) /4) + ((p^3) / 27))
	ur2 = (-q/2) - sqrt(((q^2) /4) + ((p^3) / 27))
	y1 = nthroot(ur1 , 3)
	y2 = nthroot(ur2 , 3)
	y = y1 + y2
	x = y - (b / (3*a))
endfunction

cubic(2,-3,-3,2)



