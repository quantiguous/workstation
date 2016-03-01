require 'nokogiri'

USERNAME = ARGV[0]
PASSWORD = ARGV[1]
PROJECT = ARGV[2]

def zip(folder)
  cmd = "zip -r #{PROJECT}.zip #{folder}"
  system cmd
end

def get_project(repo, project)
  cmd =  "svn export https://github.com/quantiguous/#{repo}.git/trunk/#{project}/ --username #{USERNAME} --password #{PASSWORD} --force"
  p cmd
  system cmd
  zip(project)
end

def get_references(repo, project)
  doc = Nokogiri::XML(File.open("#{project}/.project"))
  doc.xpath('/projectDescription/projects/project').each do |p|
    p p.text
    if ['UDPManager'].include?(p.text)
      get_project('iib', p.text)
    else
      get_project(repo, p.text)
    end
  end
end


def run
 get_project('iib3', PROJECT)
 get_references('iib3', PROJECT)
end


run
