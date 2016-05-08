require 'zipruby'

def is_appzip(fileName)
  return ['appzip'].include?(fileName.partition('/').first.reverse[0..5].reverse)
end


def addVersion(inBarName, version, commit)
  keywordStrings = []
  keywordStrings << "$MQSI_VERSION=#{version} MQSI$"
  keywordStrings << "$MQSI Author=Quantiguous Solutions MQSI$"
  keywordStrings << "$MQSI Author=Quantiguous Solutions MQSI$"
  keywordStrings << "$MQSI Release Date=#{Time.now} MQSI$"
  keywordStrings << "$MQSI Commit=#{commit} MQSI$"

  inBar = Zip::Archive.open(inBarName)

  inBar.each do |entry|
     if is_appzip(entry.name) 
        appZip = Zip::Archive.open_buffer(inBar.fopen(entry.name).read)
        appZip.add_or_replace_buffer('META-INF/keywords.txt', keywordStrings.join('\n'))
        appZip.commit
        inBar.replace_buffer(entry.name, appZip.read)
     end
  end
  inBar.commit
end


addVersion('VC.bar', '1.2.5', '056b88c')
