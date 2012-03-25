require 'active_record';
require_relative 'lib/user';
require_relative 'lib/application';

config_file = File.join(File.dirname(__FILE__),"config","database.yml");
base_dir=File.expand_path File.dirname(__FILE__);
sep="-------------------------------";
print ("\n#{sep}\nLoad db ENV: " + ENV["RACK_ENV"] + "\n#{sep}\n\n");
conf=YAML.load(File.open(config_file))[ENV["RACK_ENV"]];
conf["database"]=File.join(base_dir,conf["database"]);
ActiveRecord::Base.establish_connection(conf);


