
doubles_string = String.new
i = 1

puts "Enter a number between 1 and 3 200 000"
N = (gets.chomp).to_i

while ( doubles_string.length < N ) 
	doubles_string += (i*i).to_s 
	i+=1
end

puts "The number sequence is: "
puts doubles_string
puts "The #{N} number in the sequence is: "
puts doubles_string[N-1]

