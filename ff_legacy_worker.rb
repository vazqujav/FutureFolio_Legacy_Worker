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

require 'optparse' 
require 'rdoc'
require 'ostruct'
require 'date'
require 'find'
require 'tempfile'

require 'RMagick'

class App
  VERSION = '1.0'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.ringier = true
    @options.smd = false
    @options.verbose = false
    @options.quiet = false
    @options.quality = 95
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      start_time = Time.now
      puts "Start at #{Time.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      process_arguments            
      process_command
      
      puts "\nFinished at #{Time.now}" if @options.verbose
      puts "\nProcessing took #{Time.now - start_time} seconds" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-r', '--ringier')    { @options.ringier = true }  
      opts.on('-s', '--smd')        { @options.smd = true }
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-V', '--verbose')    { @options.verbose = true }  
      opts.on('-q', '--quiet')      { @options.quiet = true }
            
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
      puts " "
    end

    # True if required arguments were provided
    def arguments_valid?
      # TODO arguments should be validated in a better way.
      true if @arguments.length == 1
    end
    
    # Setup the arguments
    def process_arguments
      @dir = @arguments.first
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::new.usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command    
      smart_puts("INFO: Starting script...")

      smart_puts("INFO: Script ended.")
    end

    def process_standard_input
      input = @stdin.read      
    end
  
  end   

  # return my_string if quiet-option wasn't set
  def smart_puts(my_string)
    puts my_string unless @options.quiet
  end

# Create and run the application
app = App.new(ARGV, STDIN)
app.run