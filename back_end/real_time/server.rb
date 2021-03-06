require 'eventmachine'
require 'em-websocket'
require "redis"
require_relative './class'

soc = []


EM::WebSocket.start(host: '10.42.0.1',port: 4000) do |ws|

	git_user = nil
	repo_id=nil

	ws.onopen do
		soc << ws
		puts "#{soc.length} clients are connected"
		d = Directory.new
		tmp = []
		d.get_files_in_directory ".." , "" , tmp
		hash = {opt: "dir",content: tmp}
		puts hash
		ws.send(hash.to_json)
	end

	ws.onmessage do |msg|
	  puts "got message #{msg}"
		temp = msg.split(":")
		op = temp[0]
		#Create an instance of the git repo !!
		if(op=="cmd")

			temp.delete(op)
			out=git_user.execute temp.join(':')
			puts out.inspect
			puts "HEREE"
			out.each_line do |line|
				ws.send({opt: "output",content: line}.to_json)
			end
			valid = Validator.new(repo_id)
			# puts "IT IS FINALLY:"+(valid.validate(msg,out)).to_s
			if(valid.validate(msg,out))
				new_stage = valid.next_stage
				puts "-"*25
				puts new_stage.inspect
				base="course-"
				output_array=[{opt: base+"body", content: new_stage.pbody},{opt: base+"references", content: new_stage.references},{opt: base+"hint", content: new_stage.hints},{opt: base+"objective", content: new_stage.objective}]
				puts "-"*25
				puts output_array

				output_array.each do |hash|
					ws.send(hash.to_json)
				end
				ws.send({opt: "progress1",content: valid.step_index,size: Repo.find(repo_id).order.size}.to_json)
				# ws.send()
				ws.send("Success!!")
			else

			end
		elsif op == "open"
			temp.delete(op)
			text=Directory.new.get_content "../",temp.join(':')
			if text
				text.each_line do |line|
					puts line
				  ws.send({opt: "file-content",content: line}.to_json)
				end
			end
		elsif op == "save"
			puts "temp0"*100
			temp.delete(op)
			file_path=temp[0]
			temp.delete(op)
			text=Directory.new.save_content "../",file_path,temp.join(':')
			#SEND SOMETHING TO CONFIRM AND AVOID SAVE BUTTON FOR Repeation
		else
			git_user = GitUser.new(temp[1])
			puts "-"*100
			repo_id = temp[1]
			puts repo_id
		end
	end

	ws.onclose do
		puts "Someone disconnected"
		# git_user.destroy
		soc.delete(ws)
	end

end

