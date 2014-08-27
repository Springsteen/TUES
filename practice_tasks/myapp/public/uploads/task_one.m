function drawsc(start,stop)
	angles = [start:1:stop]

	y = sin(pi./angles) .*cos(pi./angles) 

	plot(angles,y)
endfunction

drawsc(1,90)