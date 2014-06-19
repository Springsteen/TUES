function drawcubic(a,b,c,d)
	x = [-100:1:100]

	y = a * (x.^3) - b *(x.^2)  + (c.*x) + d 

	plot(x,y)
endfunction

drawcubic(-3,2,2,-3)