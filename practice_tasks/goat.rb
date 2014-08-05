puts "Enter N"
n = gets.to_i

return if n == 0 

puts "Enter K"
k = gets.to_i

return if k == 0

puts "Enter the weights"
weights_input = gets
weights_input = weights_input.split(" ")
weights_input.each do |e|
	return if e.to_i == 0
end
weights_input = weights_input.collect{|i| i.to_i}
weights_input = weights_input.sort.reverse

puts n 
puts weights_input.length
puts n != weights_input.length 

if (n != weights_input.length)
	puts ("You have entered more/less goat weights than you've declared")
else

	current_trips = 0
	current_capacity = weights_input[0]
	current_weight = 0
	next_goat = 0
	taken_goats = 0

	current_weights_arr = Array.new
	current_weights_arr = current_weights_arr.replace(weights_input)
	puts current_weights_arr
	while (true)
		while (current_trips < k)
			print "=====TRIP#{current_trips}====="
			puts
			while ((current_weight < current_capacity) and (next_goat < current_weights_arr.length) )
				if (current_weight + current_weights_arr[next_goat]) <= current_capacity 
					current_weight += current_weights_arr[next_goat]
					taken_goats += 1
					print "goats taken: #{taken_goats}\n"
					print next_goat
					print "weight is " 
					print current_weights_arr[next_goat]
					print "\n"
					print "delete :"
					current_weights_arr.delete_at(next_goat)
					print "after delete:--------------"
					print current_weights_arr
					print "-----------------"
					puts
				else
					next_goat += 1
				end
			end
			next_goat = 0
			current_weight = 0
			current_trips += 1
		end
		print "taken goats: #{taken_goats}\n" 
		if (taken_goats < weights_input.length)
			current_capacity += 1
			current_trips = 0
			taken_goats = 0
			puts current_capacity
			next_goat = 0
			current_weights_arr = current_weights_arr.replace(weights_input) 
		else
			break
		end
	end

	puts current_capacity
end