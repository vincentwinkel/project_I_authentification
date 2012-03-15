require 'active_record';
require_relative 'lib/user';
require_relative 'lib/application';

config_file = File.join(File.dirname(__FILE__),"config","database.yml");

#puts YAML.load(File.open(config_file)).inspect;

base_dir=File.expand_path File.dirname(__FILE__);
conf=YAML.load(File.open(config_file))["auth"];
conf["database"]=File.join(base_dir,conf["database"]);

ActiveRecord::Base.establish_connection(conf);


