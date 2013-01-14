require 'FileUtils'

=begin
	Ensure all the path doesn't throw exception in dynamic language is so hard.
	Especially after much code refactor...
=end

$root_path = "./rb_notes"

class Note
	def initialize
		@user_choose = $root_path
		$categories = []
		@indent = ""

		Dir.mkdir $root_path unless File.exist? $root_path
	end

	def cmd_loop
		loop { _cmd_loop }
	end

	private
	def _cmd_loop (s=false) # s->show
		begin
			p = @user_choose
			under_categories = dir_show p, s
			print "Please input[crud i(nit) all q(uit) b(ack) ws a(dd) s(how)]:"
			i = gets.chomp.strip
			case i
				when "i" then # back to init state
					@user_choose = $root_path
					_cmd_loop true
				 	return
				when "q" then # quit
					exit ;
				when "all" then # all items under current category
					dir_show p, true
					puts sep
					return
				when "b" then # back one layer
					puts sep; 
					@user_choose = (p == $root_path) ? p : File.dirname(@user_choose)
					_cmd_loop true
				 	return
				when "a" then # add category
					print "Please input the new category:"
					new_category = gets.chomp.strip
					puts "\nnew_category is #{new_category}"
					Dir.mkdir File.join(File.join(@user_choose, new_category))
					puts sep
					return
				when "d" then #delete
					files = all_files_under
					ret = get_user_input_index_with_prompt "Please input the file you want to delete:", files
					if ret != -1 
						ret -= 1
						if File.directory? files[ret]
							print ">>>>>> #{name} is one category type, are you sure to delete it? Y/N[N]:"
							yes_or_no = gets.chomp.strip.capitalize
							yes_or_no = yes_or_no == "" ? "N" : yes_or_no[0]
							if yes_or_no == "N"
								puts "\n>>>>>> rm action cancled", sep
								return
							end
						end

						File.delete files[ret] if File.file? files[ret]
						FileUtils.rm_r files[ret] if File.directory? files[ret]

						puts "\n>>>>>> Delete #{files[ret]} successfully!"
					else
						puts "\n>>>>>> Wrong index inputed!"
					end
					puts sep
					return

				when "r" then # read
					files = all_files_under
					if files.length > 0
						ret = get_user_input_index_with_prompt "Please choose the file you want to read:", files
						if ret != -1
							show_file_content files[ret - 1]
						else
							puts ">>>>>> Wrong index inputed!"
						end
					else
						puts "\nNo file type items in this category"
					end
					puts sep
					return
				when "c" then #create
					add_new_item #if dir_files_num_check p
					puts sep
					return
				when "ws" then # write short files
					add_new_item true #if dir_files_num_check p
					puts sep
					return
				when "u" then # update
					files = all_files_under
					if files.length > 0
						ret = get_user_input_index_with_prompt "Please choose the file you want to update:", files
						if ret != -1
							system "gvim.exe #{files[ret - 1]}"
						else
							puts ">>>>>> Wrong index inputed!"
						end
					else
						puts "\nNo file type items in this category"
					end

					puts sep
					return
				when "s" then # show
					init_categories
					puts sep
					return
			end

			i = i.to_i
			if i > 0 && i <= under_categories.length
				if File.file? under_categories[i - 1]
					show_file_content under_categories[i - 1]
					puts sep
				else
					@user_choose = under_categories[i - 1] 
					puts sep
					_cmd_loop true
				end
			else
				puts "\n>>>>>> Error: what a index you have input!"
				puts sep
			end
		rescue SignalException
			puts "\n>>>>>> action cancled"
			puts sep
			return
		end
	end

	def show_file_content f
		obj = eval IO.read(f)
		puts "\n[File]: #{File.basename f}"
		puts "\n[Desc]:"
		puts obj[:desc], ""
		puts "[Content]:"
		puts obj[:content], ""
	end
	
	def sep
		"\n-------------------------#{@user_choose}--------------------------------------\n"
	end

	def get_user_input_index_with_prompt prompt, arr
		print prompt
		input = gets.chomp.strip.to_i
		if input > 0 && input <= arr.length
			input
		else
			-1
		end
	end

	def all_files_under 
		files = Dir[@user_choose + "/*"].keep_if {|item| File.file? item}
		puts "\nFiles:" if files.length > 0
		j = 1
		files.each do |item|
			puts "#{j}: #{File.basename item}"
			j += 1
		end
		puts
		files
	end

	def dir_show p, s=false
		# for categories classified by directory
		puts "Categories[#{p}]:" if s
		i = 1
		under_categories = []
		dirs = Dir["#{p}/*"].keep_if {|f| File.directory? f}
		dirs.each do |d|
			puts "#{i}: #{File.basename d}" if s
			under_categories << d
			i += 1
		end

		#for content files classified by normal files
		files = Dir["#{p}/*"].keep_if {|f| File.file? f}
		if files.length > 0
			#indent = " "*4
			puts "\nFiles:" if s
			files.each do |f|
				puts "#{i}: #{File.basename(f)}" if s
				under_categories << f
				i += 1
			end
		end
		under_categories
	end

	def dir_files_num_check p
		files = Dir["#{p}/*"].keep_if {|item| File.directory? item}
		if files.length >= 20
			puts ">>>>>> Files under #{p} have reached 20, please consider to add new sub-category!"
			return false
		else
			return true
		end
	end

	def add_new_item is_short=false
		print "\nnew file name:"
		fn = gets.chomp.strip
=begin
		print "desc:"
		desc = gets.chomp.strip
		print "content:"
		content = gets.chomp.strip
=end
		target_file = File.join(@user_choose, fn)
		unless is_short
			print "Input CR to input the description:"
			gets
			desc = target_file + "_desc"
			system("gvim.exe #{desc}")
			print "Input CR to input the content:"
			gets
			content = target_file + "_content"
			system("gvim.exe #{content}")

			item = {:desc => IO.read(desc), :content =>IO.read(content)}
			File.delete desc
			File.delete content
		else
			print "Content:"
			content = gets.chomp.strip
			item = {:desc => "", :content =>content}
		end

		File.open(target_file, "w") do |f|
			f.puts item.to_s
		end

		puts "done"
	end

	def init_categories
		puts "\nCurrent categories:"
		_init_categories $root_path
	end

	def _init_categories path
		#puts "checking directory #{path}"
		indent_bkup = @indent
		puts @indent + File.basename(path) + " [c]"
		@indent += "  "*4
		#ret = [File.basename(path)]
		#dirs = Dir["#{path}/*"].keep_if {|f| File.directory? f}
		#dirs.each do |d|
		#	ret << _init_categories(d)
		#end
		Dir["#{path}/*"].each do |f|
			if File.directory? f
				_init_categories f
			else
				puts @indent + "#{File.basename(f)}"
			end
		end
		@indent = indent_bkup
		#ret
	end
end

n = Note.new
n.cmd_loop