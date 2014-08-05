doubles_string = String.new
i = 1

puts "Enter a number between 1 and 3 200 000"
N = gets.chomp
if N.scan(/\/D/)
	puts "Bad input"
	N = -1
end
N = N.to_i

if N < 0 or N > 3200000
	puts "You've entered bad index!!! Please try again"
else

	while ( doubles_string.length < N ) 
		doubles_string += (i*i).to_s 
		i+=1
	end

	puts "The number sequence is: "
	puts doubles_string
	puts "The #{N} indexed number in the sequence is: "
	puts doubles_string[N-1]
end