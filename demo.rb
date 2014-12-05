require 'open3'
require 'optparse'

#{}`sudo git pull`
options = {}
option_parser = OptionParser.new do |opts|
	# Create a switch

	opts.on("-c COL") do |col|
		options[:col] = col
	end
	opts.on("-e ENV") do |env|
		options[:env] = env
	end
	opts.on("-p PRO") do |pro|
		options[:pro] = pro
	end

end.parse!

$ENV  = options[:env]
$COL  = options[:col]
$PRO = options[:pro]
cmd = "newman -c #{$COL} -e #{$ENV}"
str=''

Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
	while line = stdout_err.gets

		if line.include? "http://"
			line.gsub!("\e",'').gsub!(/\[[0-9,;]+m/,'').gsub!("\n",'')
			code,time,name,url = line.split " "
			time.gsub!("ms","")
			
			str << "\"postman.test.url[#{name}]\"" + " " + "\"" + url + "\"" + "\n"
			str << "\"postman.test.rspcode[#{name}]\"" + " " + code + "\n"
			str << "\"postman.test.time[#{name}]\"" + " " + time + "\n"
			
		elsif /\u2714/.match(line) or /\u2717/.match(line)

			
			if (/\u2717/.match(line))
				result =0
				line.gsub!(/\u2717/,'')
			else
				result =1
				line.gsub!(/\u2714/,'')
			end

			test = line.gsub!("\e",'').gsub!(/\[[0-9,;]+m/,'').gsub!("\n",'').strip!
			str << "\"postman.test.step[#{name},#{test}]\"" + " " + result.to_s+ "\n"
			
		end
	end

	exit_status = wait_thr.value
	unless exit_status.success?
		abort "FAILED !!! #{cmd}"
	end
end
file_name= $PRO+Time.now.to_s 
IO.write("/tmp/#{$PRO}.data",str)
