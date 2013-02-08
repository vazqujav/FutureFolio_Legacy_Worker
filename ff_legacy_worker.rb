#!/usr/bin/env ruby 

# == Synopsis 
#   Renames PDFs in directories to FutureFolio standard and creates a JPG thumbnail for every PDF
#
# == Examples
#   ff_legacy_worker.rb -smd <directory containing SMD PDFs>

#   This would recursively parse the <directory> and apply itself to PDFs in subdirectories
#
# == Usage 
#   ff_legacy_worker.rb [options] directory
#
#   For help use: ff_legacy_worker.rb -h
#
# == Options
#   -s, --smd           Work on SMD legacy PDFs
#   -r, --ringier       Work on Ringier legacy PDFs
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#
# == Author
#   Javier Vazquez
#
# == Copyright
#   Copyright 2013 Ringier AG, Javier Vazquez
# == License
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'trollop'
require 'RMagick'
require 'date'

class App
  VERSION = '1.0'
  
  def initialize(args, stdin)
    
    @opts = Trollop::options do
      # --version shows:
      version "FutureFolio Legacy Worker 1.0.0 (c) 2013 Ringier AG, Javier Vazquez"
      # --help shows:
      banner <<-EOS
      Renames PDFs in directories to FutureFolio naming convention and creates a JPG thumbnail for every PDF

      Usage:
        ff_legacy_worker.rb [options] <directory>
      where [options] are:
      EOS
      # Options available for this application
      opt :smd, "Work on SMD legacy PDFs"
      opt :ringier, "Work on Ringier legacy PDFs"
      opt :dir, "Working directory", :type => :string
    end
    
  end
  
  # Parse options, check arguments, then process the command
  def run
    start_time = Time.now
    validate_opts
    
    parse_dir(@opts[:dir])
    
    puts "\nProcess took #{Time.now - start_time} seconds"      
  end
  
  protected
  
  def parse_dir(dir)
    working_dirs = []
    Dir.foreach(dir) {|x| working_dirs << x.class }
    puts working_dirs
  end
  
  def validate_opts
    Trollop::die :dir, "must be defined" if @opts[:dir].empty?
    Trollop::die :dir, "must be a valid directory" unless File.directory?(@opts[:dir])
    Trollop::die "Either SMD or Ringier option needs to be defined" if !@opts[:smd] && !@opts[:ringier]
  end
  
end

# Create and run the application
app = App.new(ARGV, STDIN)
app.run