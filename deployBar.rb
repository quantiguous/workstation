require 'zipruby'

MQSIPROFILE = '/opt/ibm/mqsi/9.0.0.2/bin/mqsiprofile'
BROKER = ARGV[0]
EG = ARGV[1]
BARFILE = ARGV[2]


def getAppName(barFile)
 bar = Zip::Archive.open(barFile)
 bar.each do |entry|
   if entry.name.end_with? ".appzip" 
     return entry.name.chomp(".appzip")
   end
 end
end

def deployBar(brokerName, egName, barFile)
  appName = getAppName(barFile)
  cmd = ". #{MQSIPROFILE};mqsideploy #{brokerName} -e #{egName} -d #{appName}"
  system cmd
  cmd = ". #{MQSIPROFILE};mqsideploy #{brokerName} -e #{egName} -a #{barFile}"
  system cmd
end


def run
  deployBar(BROKER, EG, BARFILE)
end

run
