$: << File.dirname(__FILE__);
require 'active_record';

databases=YAML.load_file("config/database.yml");

databases.each { |db,conf|
	ENV['RACK_ENV']=db;
	load "database.rb";
	ActiveRecord::Migration.verbose=true;
	ActiveRecord::Migrator.migrate("db/migrate");
}