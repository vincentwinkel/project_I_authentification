ENV["RACK_ENV"]="test";

require 'rspec';
require 'active_record';
$:.unshift File.join(File.dirname(__FILE__),"..","lib");
$:.unshift File.join(File.dirname(__FILE__),"..");

require_relative '../database';
require_relative '../sauth';