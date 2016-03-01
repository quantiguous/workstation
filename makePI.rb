require 'rexml/document'
require 'fileutils'

USERNAME = ARGV[0]
PASSWORD = ARGV[1]
REPO = ARGV[2]
PROJECT = ARGV[3]


def zip(folder)
  cmd = "zip -r #{PROJECT}.zip #{folder}"
  p cmd
  system cmd
end

def get_project(repo, project)
  cmd =  "svn export https://github.com/quantiguous/#{repo}.git/trunk/#{project}/ --username #{USERNAME} --password #{PASSWORD} --force"
  p cmd
  system cmd
  zip(project)
end

def get_references(repo, project)
  doc = REXML::Document.new(File.read("#{project}/.project"))
  doc.elements.each('/projectDescription/projects/project') do |p|
    p p.text
    if ['UDPManager'].include?(p.text)
      get_project('iib', p.text)
    else
      get_project(repo, p.text)
    end
    FileUtils.rm_r p.text
  end
end


def run
 get_project(REPO, PROJECT)
 get_references(REPO, PROJECT)
 FileUtils.rm_r PROJECT
end


run
