require 'rexml/document'
require 'fileutils'

REPLACE_PATHS = { :ORACLE_HOME => '/opt/oracle/instantclient_11_2' }

MQSIPROFILE = '/opt/ibm/mqsi/9.0.0.2/bin/mqsiprofile'
USERNAME = ARGV[0]
PASSWORD = ARGV[1]
REPO = ARGV[2]
PROJECT = ARGV[3]

FETCHED_PROJECTS = []


def zip(folder)
  cmd = "zip -r #{PROJECT}.zip #{folder}"
  p cmd
  system cmd
end

def get_project(repo, project)
  unless FETCHED_PROJECTS.include?(project)
    cmd =  "svn export https://github.com/quantiguous/#{repo}.git/trunk/#{project}/ --username #{USERNAME} --password #{PASSWORD} --force"
    p cmd
    system cmd
    FETCHED_PROJECTS << project
  end
  get_references(repo, project)
end

def get_references(repo, project)
  doc = REXML::Document.new(File.read("#{project}/.project"))
  doc.elements.each('/projectDescription/projects/project') do |p|
    p p.text
    if ['UDPManager','UDPManagerJava'].include?(p.text)
      get_project('iib', p.text)
    else
      if ['QManifest.lib'].include?(p.text)
        get_project('iib3', p.text)
      else
        get_project(repo, p.text)
      end
    end
  end
end

def fix_class_paths
 FETCHED_PROJECTS.each do |f|
   classPath = "./#{f}/.classpath"
   if File.file?(classPath) then
     replaced = false
     doc = REXML::Document.new(File.read(classPath))
     doc.elements.each('/classpath/classpathentry') do |p|
       REPLACE_PATHS.each { |k,v|
         o = p.attributes['path']
         r = o.sub("#{k}",v)
         if r != o then
           p.attributes['path'] = r
           p.attributes['kind'] = 'lib'
           p.attributes.delete 'exported'
           replaced = true
         end
       }
     end
     if replaced then
       FileUtils.cp(classPath, "#{classPath}.org")
       outXml = ''
       doc.write(outXml)
       File.open(classPath, 'w') {|f| f.write(outXml) }
     end
   end
 end
end


def createBarFile(project)
  cmd = ". #{MQSIPROFILE};mqsicreatebar -data . -b #{project}.bar -a #{project} -deployAsSource"
  system cmd
end

def run
 get_project(REPO, PROJECT)
 fix_class_paths
 createBarFile(PROJECT)
 FETCHED_PROJECTS.each do |f|
   zip(f)
   FileUtils.rm_r f
 end
end

run
