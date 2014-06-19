x = [-5:0.5:5]
abv = [2, -12, 16, 7];
rts = roots(abv);

disp(rts)

plot(x, polyval(abv,x))
hold on
	x = linspace(min([1,2])-3, max([1,2])+3, 100)
	y = x.*0
	plot(x,y)
	x = x.*0
	y = linspace(min([1,2])-500, max([1,2])+500, 100)
	plot(x,y)
	plot(rts, zeros(size(rts)),'o', "color", "pink")
hold off
