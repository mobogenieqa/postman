require 'open3'
require 'optparse'

options = {}
option_parser = OptionParser.new do |opts|
	# Create a switch

	opts.on("-c COL") do |col|
		options[:col] = col
	end
	opts.on("-e ENV") do |env|
		options[:env] = env
	end
	opts.on("-z ZBX") do |zbx|
		options[:zbx] = zbx
	end

end.parse!

$ENV = options[:env]
$COL = options[:col]
$ZBX = options[:zbx]
p $COL
p $ZBX
cmd = "newman -c #{$COL} -e #{$ENV}"
str=''
cases_number = 0
zabbix = $ZBX                    #{}"global-webmonitor"
Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
	while line = stdout_err.gets

		if line.include? "http://"
			cases_result = 1
			cases_number = cases_number + 1
			line.gsub!("\e",'').gsub!(/\[[0-9,;]+m/,'').gsub!("\n",'')
			code,time,name,url = line.split " "
			time.gsub!("ms","")
			#code = /\d\d\d/.match(line).to_s
			#time = /\d+ms/.match(line).to_s
			#url = /http:.+/.match(line).to_s
			#name = line.delete(code).delete(time).delete(url).strip
			str << zabbix + " " + "\"postman.test.url[#{name}]\"" + " " + "\"" + url + "\"" + "\n"
			str << zabbix + " " + "\"postman.test.code[#{name}]\"" + " " + code + "\n"
			str << zabbix + " " + "\"postman.test.time[#{name}]\"" + " " + time + "\n"
			#name = /\D.+/.match(line.delete!(code).delete!(time).delete!(url)).to_s
		elsif /\u2714/.match(line) or /\u2717/.match(line)

			#line.gsub!(/\e\[[0-9,;]+m/,'').gsub!("\n",'')
			if (/\u2717/.match(line))
				result =0
				line.gsub!(/\u2717/,'')
			else
				result =1
				line.gsub!(/\u2714/,'')
			end

			cases_result = cases_result*result
			test = line.gsub!("\e",'').gsub!(/\[[0-9,;]+m/,'').gsub!("\n",'').strip!
			str << zabbix + " " + "\"postman.test.step[#{name},#{test}]\"" + " " + result.to_s+ "\n"
			#str << "the result for #{test} is #{result} \n "
		end
	end

	exit_status = wait_thr.value
	unless exit_status.success?
		abort "FAILED !!! #{cmd}"
	end
end
IO.write("/home/duanliwei/project/NewMan/newman#{Time.now.to_s}.log",str)
