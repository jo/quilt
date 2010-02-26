# Copyright 2010 Johannes J. Schmidt, TF
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# Quilt mixes CouchDB Design Documents into FUSE


require "rubygems"
begin
    require 'json'
rescue LoadError
    raise "You need install and require your own json compatible library since Quilt couldn't load the json/json_pure gem" unless Kernel.const_defined?("JSON")
end
require "rest_client"
require 'fusefs'

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
    $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'couchquilt/mapper'
require 'couchquilt/couch_client'
require 'couchquilt/fs'


# Set out your Quilt
module Couchquilt
end
