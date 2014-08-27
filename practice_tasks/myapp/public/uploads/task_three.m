function drawq(a,b,c)
	x = [-100:1:100]

	y = a * (x.^2) - (b .* x)  + c 

	hold("on")
		plot(x,y)
		x = linspace(-200, 200, 200)
		y = x.*0
		plot(x,y)
		x = x.*0
		y = linspace(-20000, 20000, 200)
		plot(x,y)
	hold("off")
endfunction

drawq(2,-6,-4)