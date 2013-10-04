require "csv"

all = []

	CSV.foreach(ARGV[0]) do |row|		
		two_names = row[0].split("_")[0..1]
		full_name = two_names[0]+" "+two_names[1]
		all << [full_name,row[2] == "true" ? 1:0]
	end

	all = all.sort { |a,b| a[0] <=> b[0]}

	names = Hash.new("")

	CSV.foreach("names.csv") do |row|
		names[row[1]] = row[0]
	end

	all.each do |element|
		element[0] = names[element[0]]
		if element[0] == nil
			element[0] = ""
		end
	end


	CSV.open("output.csv","w") do |csv|
		all.each do |element|
			csv << [element[0],element[1]] 
		end
	end
