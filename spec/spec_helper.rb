require "rubygems"
require 'spec'

require File.join(File.dirname(__FILE__), '../lib/couchquilt')
require File.join(File.dirname(__FILE__), '../lib/couchquilt/debugged_fs')

SERVER_NAME = "http://127.0.0.1:5984"
TESTDB   = "quilt-test-db"
