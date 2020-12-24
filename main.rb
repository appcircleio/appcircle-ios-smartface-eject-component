require 'open3'
require 'pathname'
require 'fileutils'
require 'json'

def env_has_key(key,skip_abort)
	if (ENV[key] != nil && ENV[key] !="")
		return ENV[key]
	elsif skip_abort
		return false
	else
		abort("Missing #{key}.")
	end
end

$repository_path = env_has_key("AC_REPOSITORY_DIR",false)
$temp_path = env_has_key("AC_TEMP_DIR",false)
$appcircle_output_path = env_has_key("AC_OUTPUT_DIR",false)
$include_xcode_project = env_has_key("AC_INCLUDE_XCODE_PROJECT",false)
$xcode_list_path = env_has_key("AC_XCODE_LIST_DIR",false)
$output_path = "#$temp_path/smartface_xcode_project"

$smartface_temp_folder = "#$temp_path/smartface_temp_folder"
$smartface_output_folder =  "#$output_path/SmartfaceiOS"

$smartface_cli_version = env_has_key("AC_SMARTFACE_CLI_VERSION",true) || "latest"
$smartface_player_version = env_has_key("AC_SMARTFACE_PLAYER_VERSION",true) || "latest"

$appcircle_output_zip_path = "#$appcircle_output_path/SmartfaceiOS.zip"
$smartface_xcode_version_path = "#$smartface_output_folder/xcodeversion"

$smartface_project_json = JSON.parse(File.read("#$repository_path/config/project.json"))

def run_command(command,skip_abort)
	puts "@@[command] #{command}"
	status = nil
	stdout_str = nil
	stderr_str = nil
	Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
		stdout.each_line do |line|
		puts line
		end
		stdout_str = stdout.read
		stderr_str = stderr.read
		status = wait_thr.value
	end

	unless status.success?
	   if skip_abort
	      puts stderr_str
	    else
	      abort_script(stderr_str)
	    end
	end
end

def abort_script(error)
	abort("#{error}")
end

command = "rm -rf \"#$output_path\""
run_command(command,false)

command = "mkdir \"#$output_path\""
run_command(command,false)

# Install smartface cli
run_command("npm i -g smartface@#$smartface_cli_version",false)
run_command("smfc -v",false)

# Specify player version
run_command("smfc use #$smartface_player_version --os iOS",false)

# Install dependencies
Dir.chdir("#$repository_path/scripts") do
	command = "npm i"
	run_command(command,false)
end

Dir.chdir("#$repository_path") do
	command = "npm i && npm run build:transpile"
	run_command(command,false)
end

command = "smfc --projectRoot=\"#$repository_path\" --task=export:iOS --outputFolder=\"#$output_path\" --tempFolder=\"#$smartface_temp_folder\""
run_command(command,false)

if $include_xcode_project == "true"
	Dir.chdir("#$smartface_output_folder") do
		command = "zip -r \"#$appcircle_output_zip_path\"  \".\""
		run_command(command,false)
	end
end

text = File.open($smartface_xcode_version_path).read
text.gsub!(/\r\n?/, "\n")
text.each_line do |line|
  line_split = line.split(" ")
  if line_split[0] == "Xcode"
  	$smartface_xcode_version = line_split[1]
  end
end

def find_compatible_xcode_version(playerXcodeVersion)
	version_major = playerXcodeVersion.to_s.split(".")[0]
	version_minor = playerXcodeVersion.to_s.split(".")[1]
	version_patch = playerXcodeVersion.to_s.split(".")[2]

	xcode_versions = []
	if File.directory? $xcode_list_path
	    Dir.chdir($xcode_list_path) do
	        Dir.glob('*').select { |f| 
	            File.directory? f 
	            xcode_versions << "#{f}"
	        }
	    end
	end

	sort_list = xcode_versions.sort_by { |v| Gem::Version.new(v) }

	sort_list.each { |version|
    	major = version.split(".")[0]
    	if version_major == major
    		minor = version.split(".")[1]
    		if version_minor <= minor
    			if version_patch
    				patch = version.split(".")[2]
    				if patch && version_patch <= patch
    					return version	
    				end
				else
    				return version	
    			end
    		end
    	end
	  }

	return nil
end

$compatible_xcode_version = find_compatible_xcode_version($smartface_xcode_version)
unless $compatible_xcode_version
	puts "Compatible xcode version does not found. Version : #$smartface_xcode_version"
end

$pod_file_path = "#$smartface_output_folder/Podfile"
if File.file? "#$pod_file_path"
	$ac_project_path = "#$smartface_output_folder/Smartface.xcworkspace"
else
	$ac_project_path = "#$smartface_output_folder/Smartface.xcodeproj"
end

$ac_scheme = "Smartface"
$bundle_identifiers = $smartface_project_json["build"]["output"]["ios"]["bundleIdentifier"]

puts "AC_PROJECT_PATH = #$ac_project_path"
puts "AC_SCHEME = #$ac_scheme"
puts "AC_XCODE_VERSION = #$compatible_xcode_version"
puts "AC_BUNDLE_IDENTIFIERS = #$bundle_identifiers"

#Write Environment Variable
open(ENV['AC_ENV_FILE_PATH'], 'a') { |f|
	f.puts "AC_PROJECT_PATH=#$ac_project_path"
	f.puts "AC_SCHEME=#$ac_scheme"
	f.puts "AC_XCODE_VERSION=#$compatible_xcode_version"
	f.puts "AC_BUNDLE_IDENTIFIERS=#$bundle_identifiers"
}

exit 0