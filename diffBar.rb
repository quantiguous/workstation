require 'rubygems'
require 'zipruby'
require 'md5'
require 'diffy'

FILES_TO_IGNORE = ['bar-refresh.links','service.log','user.log']

FILE1 = ARGV[0]
FILE2 = ARGV[1]
OUTPUT = ARGV[2]
OUTPUT ||= 'D'

def is_zip(fileName)
  return ['zip','jar'].include?(fileName.partition('/').first.reverse[0..2].reverse)
end

def readBar(barName, bar)
   files = Hash.new
   bar.each do |entry|
     if is_zip(entry.name)
        files.merge!(readBar(entry.name, Zip::Archive.open_buffer(bar.fopen(entry.name).read)))
     else
       unless entry.directory?
         md5 = MD5.md5(bar.fopen(entry.name).read)
         files[barName + '/' + entry.name] = md5
       end
     end
   end
   return files
end

def findFileInBar(fileName, barName, bar)
   bar.each do |entry|
     p "#{fileName} #{fileName.split('/').first} #{barName} #{entry.name}"
     if ( is_zip(fileName) && fileName.partition('/').first == barName && fileName.partition('/').last == entry.name ) || ( !is_zip(fileName) && entry.name == fileName ) 
       return bar.fopen(entry.name)
     end
     if is_zip(entry.name) then
       f = findFileInBar(fileName, entry.name, Zip::Archive.open_buffer(bar.fopen(entry.name).read))
       unless f.nil?
         return f
       end
     end
   end
   return nil
end

def readFile(fileName, barFileName)
  bar = Zip::Archive.open(barFileName)
  f = findFileInBar(fileName, File.basename(barFileName), bar)
  if f.nil? then
   raise "file #{fileName} not found in #{barFileName}"
  end
  return f.read
end

def compare_files(files1, files2)
  diff = Hash.new
  files1.each_pair do |file, md5|
    if files2.has_key?(file) then
      diff[file] = (files2[file] == md5) ? 'S' : 'D'
    else
      diff[file] = 'L'
    end
  end
  files2.each_pair do |file, md5|
    unless files1.has_key?(file) then
      diff[file] = 'R'
    end
  end
  diff.each_pair do |file,result|
    if FILES_TO_IGNORE.any? {|ignore| file.include?(ignore)} then
      diff[file] = 'I'
    end
  end
  return diff
end

def runBarDiff(barFile1, barFile2, outputWhat)
  bar = Zip::Archive.open(barFile1)
  files1 = readBar(File.basename(barFile1), bar)
  bar = Zip::Archive.open(barFile2)
  files2 = readBar(File.basename(barFile2), bar)
  diff = compare_files(files1, files2)
  summary = diff.group_by{|k,v| v}
  summary.each do |s|
    puts "#{s[0]} #{s[1].size}"
  end
  diff.sort.each do |d|
    if outputWhat == 'A' || outputWhat == d[1] then
      puts "#{d[0]} : #{d[1]}"
    end
  end
  nil
end

def runFileDiff(barFile1, barFile2, fileName)
  content1 = readFile(fileName, barFile1)
  content2 = readFile(fileName, barFile2)
  if MD5.md5(content1) == MD5.md5(content2) then
    p "files are identical"
    p content1
  else
    p "files differ"
    p content1
    p content2
    p Diffy::Diff.new(content1, content2).to_s(:html_simple)
  end
end

if OUTPUT.length > 1 then
  runFileDiff(FILE1, FILE2, OUTPUT)
else
  runBarDiff(FILE1, FILE2, OUTPUT)
end
