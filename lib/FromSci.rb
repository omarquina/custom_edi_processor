require 'tiny_tds'

class FromSci < OpenStruct
# username: 'sa'
# password: 'avila'
# dataserver: dataserver
#dataserver= 'USMIAVS029.bremat.local\MSQL2008'
#dataserver= 'USMIAVS033.bremat.local\MSQL2008'
#database: 'SCI'
  def client
     @client ||= TinyTds::Client.new username: self.username, password: self.password, dataserver: self.dataserver, database: "SCI", encoding: 'UTF-8', use_utf16: 'false'

  end

  def command
    
  end

  def exec 
    client.execute command
  end
end
