#!/usr/bin/env ruby 

# == Synopsis 
#   Renames PDFs and JPGs in directories to FutureFolio naming convention
#   Requires: Trollop (gem)
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
require 'date'

class App
  
  def initialize(args, stdin)
    @opts = Trollop::options do
      # --version shows:
      version "FutureFolio Legacy Worker 2.1.0 (c) 2013 Ringier AG, Javier Vazquez"
      # --help shows:
      banner <<-EOS
      Renames PDFs and JPGs in directories to FutureFolio naming convention
      Expects directories with issues to be named <si_YearMonthDay> (e.g. si_20100802)

      Usage:
        ff_legacy_worker.rb [options] <directory>
      where [options] are:
      EOS
      # Options available for this application
      opt :dir, "Working directory containing directories with legacy files", :type => :string
      opt :ringier, "Work on Ringier legacy files"
      opt :smd, "Work on SMD legacy files"
    end
  end
  
  # Parse options, check arguments, then process the command
  def run
    start_time = Time.now
    validate_opts
    gather_working_dirs(@opts[:dir]).each do |issue_dir|
      # start working on all PDFs that are found in <issue_dir>
      work_on_pdfs(issue_dir)
    end
    puts "\nProcess took #{Time.now - start_time} seconds"      
  end
  
  protected
  
  # Works on single PDFs within <issue_dir>
  def work_on_pdfs(issue_dir)
    puts "Begin working on Folder #{issue_dir}"
    my_pdfs = []
    my_jpgs = []
    Dir.foreach(issue_dir) {|pdf| my_pdfs << "#{issue_dir}/#{pdf}" if valid_issue_dir_and_pdf?(issue_dir, pdf) }
    Dir.foreach(issue_dir) {|jpg| my_jpgs << "#{issue_dir}/#{jpg}" if valid_issue_dir_and_jpg?(issue_dir, jpg) }
    if my_pdfs.empty?
      Trollop::die "There seem to be no PDFs in #{issue_dir}"
    end
    if my_jpgs.empty?
      Trollop::die "There seem to be no JPGs in #{issue_dir}"
    end
    case
    # loop through Ringier files
    when @opts[:ringier] then
      my_pdfs.each_with_index do |my_pdf,ind|
        File.rename(my_pdf,"#{issue_dir}/page-#{ind}.pdf")
      end
      my_jpgs.each_with_index do |my_jpg,ind|
        File.rename(my_jpg,"#{issue_dir}/page-#{ind}.jpg")
      end
    # loop through SMD files
    when @opts[:smd] then
      my_pdfs.each do |my_pdf|
        # Fetch page number from filename
        my_pdf =~ /si_\d{8}_\d_\d_(\d{1,2}).pdf/
        # Pages start at 0 with FutureFolio naming convention
        page = ($1.to_i - 1).to_s
        File.rename(my_pdf,"#{issue_dir}/page-#{page}.pdf")
      end
      my_jpgs.each_with_index do |my_jpg,ind|
        # Fetch page number from filename
        my_jpg =~ /si_\d{8}_\d_\d_(\d{1,2}).jpg/
        # Pages start at 0 with FutureFolio naming convention
        page = ($1.to_i - 1).to_s
        File.rename(my_jpg,"#{issue_dir}/page-#{page}.jpg")
      end
    else
      Trollop::die "No type has been defined."
    end
  end
  
  # Gather all directories which supposedly contain PDFs
  def gather_working_dirs(dir)
    working_dirs = []
    # gather all directories within <dir>
    Dir.foreach(dir) {|d| working_dirs << "#{dir}/#{d}" if valid_working_dir?(dir, d) }
    return working_dirs
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
  def valid_issue_dir_and_pdf?(base_dir, my_file)
    is_file = File.file?("#{base_dir}/#{my_file}")
    # FIXME find smarter way to check for PDF
    is_pdf = true if my_file =~ /.*.(pdf|PDF)/ 
    is_issue_dir = true if base_dir =~ /.*\/si_\d{8}/
    return is_file && is_pdf && is_issue_dir
  end
  
  # check if we're looking at a valid PDF
  def valid_issue_dir_and_jpg?(base_dir, my_file)
    is_file = File.file?("#{base_dir}/#{my_file}")
    # FIXME find smarter way to check for JPG
    is_jpg = true if my_file =~ /.*.(jpg|JPG)/ 
    is_issue_dir = true if base_dir =~ /.*\/si_\d{8}/
    return is_file && is_jpg && is_issue_dir
  end
  
  # validate command-line options
  def validate_opts
    Trollop::die "type must be defined" unless @opts[:ringier] or @opts[:smd]
    Trollop::die :dir, "must be defined" if @opts[:dir].empty?
    Trollop::die :dir, "must be a valid directory" unless File.directory?(@opts[:dir])
  end
end

# Create and run the application
app = App.new(ARGV, STDIN)
app.run