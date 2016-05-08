require 'rexml/document'
require 'fileutils'

MQSIPROFILE = '/opt/ibm/mqsi/9.0.0.2/bin/mqsiprofile'
USERNAME = ARGV[0]
PASSWORD = ARGV[1]
REPO = ARGV[2]
PROJECT = ARGV[3]
PROPERTY_FILE = ARGV[4]
BARFILE = ARGV[5]
ENV_NAME = ARGV[6]

def get_property_file(repo, projectName, propertyFile)
  cmd =  "svn export https://github.com/quantiguous/#{repo}.git/trunk/deploy/#{projectName}/#{propertyFile}/ --username #{USERNAME} --password #{PASSWORD} --force"
  p cmd
  system cmd
end

def applyOverrides(barFile, envName, propertyFile)
  outBarFile = barFile.chomp('bar') + envName + '.bar'
  cmd = ". #{MQSIPROFILE};mqsiapplybaroverride -b #{barFile} -r -p #{propertyFile} -o #{outBarFile}"
  system cmd
end


def run
 get_property_file(REPO, PROJECT, PROPERTY_FILE)
 applyOverrides(BARFILE, ENV_NAME, PROPERTY_FILE)
end

run
