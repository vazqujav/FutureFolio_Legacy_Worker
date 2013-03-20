#!/usr/bin/env ruby 

# == Synopsis 
#   Renames PDFs and JPGs in directories to FutureFolio naming convention
#   Requires: Trollop (gem) and rubyzip (gem)
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

require 'rubygems'
require 'zip/zip'
require 'trollop'
require 'date'

class App
  
  def initialize(args, stdin)
    @opts = Trollop::options do
      # --version shows:
      version "FutureFolio Legacy Worker 2.2.0 (c) 2013 Ringier AG, Javier Vazquez"
      # --help shows:
      banner <<-EOS
      Renames PDFs and JPGs in directories to FutureFolio naming convention and moves them into ZIP
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
      # start working on all PDFs and JPGs that are found in <issue_dir>
      create_ff_package(issue_dir)
    end
    puts "\nProcess took #{Time.now - start_time} seconds"      
  end
  
  protected
  
  # Creates FutureFolio (zip) package from PDFs and JPGs found within <issue_dir>
  def create_ff_package(issue_dir)
    puts "Begin working on Folder #{issue_dir}"
    zip_dir = File.join(issue_dir,'../'+File.basename(issue_dir))+'.zip'
    zipfile = Zip::ZipFile.new(zip_dir, true)
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
        zipfile.add("page-#{ind}.pdf", "#{issue_dir}/page-#{ind}.pdf")
      end
      my_jpgs.each_with_index do |my_jpg,ind|
        File.rename(my_jpg,"#{issue_dir}/page-#{ind}.jpg")
        zipfile.add("page-#{ind}.jpg", "#{issue_dir}/page-#{ind}.jpg")
      end
    # loop through SMD files
    when @opts[:smd] then
      my_pdfs.each do |my_pdf|
        # Fetch page number from filename
        my_pdf =~ /si_\d{8}_\d_\d_(\d{1,3}).pdf/
        # Pages start at 0 with FutureFolio naming convention
        page = ($1.to_i - 1).to_s
        File.rename(my_pdf,"#{issue_dir}/page-#{page}.pdf")
        zipfile.add("page-#{page}.pdf", "#{issue_dir}/page-#{page}.pdf")
      end
      my_jpgs.each_with_index do |my_jpg,ind|
        # Fetch page number from filename
        my_jpg =~ /si_\d{8}_\d_\d_(\d{1,3}).jpg/
        # Pages start at 0 with FutureFolio naming convention
        page = ($1.to_i - 1).to_s
        File.rename(my_jpg,"#{issue_dir}/page-#{page}.jpg")
        zipfile.add("page-#{page}.jpg", "#{issue_dir}/page-#{page}.jpg")
      end
    else
      Trollop::die "No type has been defined."
    end
    add_static_files(zipfile, my_pdfs.size)
    zipfile.close
  end
  
  # Gather all directories which supposedly contain PDFs
  def gather_working_dirs(dir)
    working_dirs = []
    # gather all directories within <dir>
    Dir.foreach(dir) {|d| working_dirs << "#{dir}/#{d}" if valid_working_dir?(dir, d) }
    return working_dirs
  end
  
  # adds background and manifest.xml to zip package
  def add_static_files(zipfile, number_of_pages)
    zipfile.add("folioIssueBackgroundPhoneLandscape.png", "./folioIssueBackgroundPhoneLandscape.png")
    zipfile.add("folioIssueBackgroundPhonePortrait.png", "./folioIssueBackgroundPhonePortrait.png")
    zipfile.add("folioIssueBackgroundTabletLandscape.png", "./folioIssueBackgroundTabletLandscape.png")
    zipfile.add("folioIssueBackgroundTabletPortrait.png", "./folioIssueBackgroundTabletPortrait.png")
    zipfile.get_output_stream("manifest.xml") { |f| f.puts get_manifest(number_of_pages) }
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
  
  def get_manifest(number_of_pages)
    manifest = <<-EOD
    <fonz>
    	<pageWidth>2032</pageWidth>
    	<pageHeight>2729</pageHeight>
    	<pages>#{number_of_pages}</pages>
    	<tocMode>1</tocMode>
    	<centreCoversInLandscape>True</centreCoversInLandscape>
    	<portraitPageAlignmentMode>1</portraitPageAlignmentMode>
    	<coverPageNumber>0</coverPageNumber>
    	<linkColour>f4da237c</linkColour>
    	<linkPadding>2</linkPadding>
    	<linkBorderColour>f4da23b4</linkBorderColour>
    	<linkBorderWidth>1</linkBorderWidth>
    	<enableSpreadMode>1</enableSpreadMode>
    </fonz>
    EOD
    return manifest
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