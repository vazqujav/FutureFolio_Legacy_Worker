#!/usr/bin/env ruby 

# == Synopsis 
#   Renames PDFs in directories to FutureFolio standard and creates a JPG thumbnail for every PDF
#
# == Author
#   Javier Vazquez
#
# == Copyright
#   Copyright 2013 Ringier AG, Javier Vazquez
#
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
      opt :dir, "Working directory containing issue directories", :type => :string
    end
    
  end
  
  # Parse options, check arguments, then process the command
  def run
    start_time = Time.now
    validate_opts
    
    gather_working_dirs(@opts[:dir]).each do |issue_dir|
      work_on_pdfs(issue_dir)
    end
    
    puts "\nProcess took #{Time.now - start_time} seconds"      
  end
  
  protected
  
  def work_on_pdfs(issue_dir)
    my_pdfs = []
    Dir.foreach(issue_dir) {|pdf| my_pdfs << "#{issue_dir}/#{pdf}" if valid_pdf?(issue_dir, pdf) }
    my_pdfs.each do |my_pdf|
      puts "Working on #{my_pdf}"
      create_thumbnail(my_pdf)
    end
  end
  
  def gather_working_dirs(dir)
    working_dirs = []
    # gather all directories within dir
    Dir.foreach(dir) {|d| working_dirs << "#{dir}/#{d}" if valid_working_dir?(dir, d) }
    return working_dirs
  end
  
  def create_thumbnail(my_pdf)
    pdf = Magick::ImageList.new(my_pdf)
    thumb = pdf.resize_to_fit(256, 256)
    thumb.strip!
    thumb.add_profile("./lib/CoatedGRACoL2006.icc")
    thumb.colorspace = Magick::SRGBColorspace
    thumb.add_profile("./lib/AppleRGB.icc")
    thumb.format = 'JPG'
    thumb.sharpen(0,0.8)
    thumb.write("#{File.dirname(my_pdf)}/#{File.basename(my_pdf, '.pdf')}.jpg") { self.quality = 100 }
  end
  
  # check if we're looking at a directory and if directory is not . or ..
  def valid_working_dir?(base_dir, dir)
    regex_str = "#{base_dir}\/(\.\.|\.)"
    working_dir = "#{base_dir}/#{dir}"
    is_directory = File.directory?("#{base_dir}/#{dir}")
    is_real_dir = true unless working_dir =~ /.*\/(\.\.|\.)/
    return is_directory && is_real_dir
  end
  
  # check if we're looking at a valid PDF
  def valid_pdf?(base_dir, my_file)
    is_file = File.file?("#{base_dir}/#{my_file}")
    # FIXME check if file is actually a PDF
    is_pdf = true if my_file =~ /.*.(pdf|PDF)/ 
    return is_file && is_pdf
  end
  
  # validate command-line options
  def validate_opts
    Trollop::die :dir, "must be defined" if @opts[:dir].empty?
    Trollop::die :dir, "must be a valid directory" unless File.directory?(@opts[:dir])
    Trollop::die "Either SMD or Ringier option needs to be defined" if !@opts[:smd] && !@opts[:ringier]
  end
  
end

# Create and run the application
app = App.new(ARGV, STDIN)
app.run