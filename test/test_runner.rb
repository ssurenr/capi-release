require 'rubygems'
require 'bundler/setup'
require "test/unit"

require File.dirname(File.absolute_path(__FILE__)) + '/test_helpers.rb'

Dir[File.dirname(File.absolute_path(__FILE__)) + '/**/*_test.rb'].each {|file| require file }