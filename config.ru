if ENV["RACK_ENV"] == "production"
  ENV["SESSION_KEY"]= "e065b17b87036d4671418bb47500a4e7abe4f65eb28f4439c9de741b3e25cc21e1d88376ced1d694"
end

require(File.expand_path("../canvabadges", __FILE__))

$stdout.sync = true
run Canvabadges
