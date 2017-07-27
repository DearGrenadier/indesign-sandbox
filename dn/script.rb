require 'nokogiri'
require 'zip'
require 'pry'

class ZipFolder
  def initialize(inputDir, outputFile)
    @inputDir = inputDir
    @outputFile = outputFile
  end

  def write
    FileUtils.rm(@outputFile)
    entries = Dir.entries(@inputDir)
    entries.delete('.')
    entries.delete('..')
    io = Zip::File.open(@outputFile, Zip::File::CREATE);

    write_entries(entries, '', io)
    io.close();
  end

  private

  def write_entries(entries, path, io)
    entries.each do |entry|
      zip_file_path = path == '' ? entry : File.join(path, entry)
      disk_file_path = File.join(@inputDir, zip_file_path)

      if File.directory?(disk_file_path)
        io.mkdir(zip_file_path)
        subdir = Dir.entries(disk_file_path)
        subdir.delete('.')
        subdir.delete('..')
        write_entries(subdir, zip_file_path, io)
      else
        io.get_output_stream(zip_file_path) { |file| file.puts(File.open(disk_file_path, 'rb').read()) }
      end
    end
  end
end

# Unzip IDML to src folder
Zip.on_exists_proc = true
Zip::File.open('comments-input.idml') do |zip|
  zip.each do |entry|
    file_path  = File.join('src', entry.name)
    FileUtils.mkdir_p(File.dirname(file_path))
    zip.extract(entry, file_path)
  end
end

# Remove all comments nodes
file_name = 'src/Stories/Story_u125.xml'
doc = Nokogiri::XML(File.open(file_name))
# doc.xpath("//Cell").first.remove
# doc.xpath("//Row").first.remove
File.write(file_name, doc.to_xml)

# Zip IDML back
ZipFolder.new('src', 'comments-output.idml').write
