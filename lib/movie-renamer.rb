#!/usr/bin/env ruby
$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'imdb'
require 'highline'
require 'highline/import'
require 'htmlentities'
require 'yaml'


#VERSION = File.open(File.join(File.dirname(__FILE__), '..', 'VERSION'), 'r') { |f| f.read.strip }

$config = ''
CONFIGFILE = File.join(File.expand_path(ENV['HOME']), '.movie-renamer')
begin 
    $config = YAML.load_file(CONFIGFILE)
rescue
end

begin
    require 'imdb'
rescue LoadError
    $stderr.print "#{File.basename($0)} requires imdb gem to work\nPlease install it with gem install imdb\n"
    exit
end


if $config['language']
    $language = $config['language']
else
    $language = 'com'
end

require File.join(File.dirname(__FILE__), "movie-renamer/misc")
require File.join(File.dirname(__FILE__), "movie-renamer/movie")
require File.join(File.dirname(__FILE__), "movie-renamer/imdb")
require File.join(File.dirname(__FILE__), "movie-renamer/parse")
