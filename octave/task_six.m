function threedee 
	[x,y] = meshgrid(-2:.2:2)
	 z =sin(x).*cos(y)
	 surf(x,y,z) 
endfunction 
threedee