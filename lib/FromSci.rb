require 'tiny_tds'

class FromSci < OpenStruct
# username: 'sa'
# password: 'avila'
# dataserver: dataserver
#dataserver= 'USMIAVS029.bremat.local\MSQL2008'
#dataserver= 'USMIAVS033.bremat.local\MSQL2008'
#database: 'SCI'
  def client
     @client ||= TinyTds::Client.new username: self.username, password: self.password, dataserver: self.dataserver, database: self.database, encoding: 'UTF-8', use_utf16: 'false'
  end

  def database
    @db ||= 'SCI'
  end

  def command
    
  end

  def data
    
  end

  def clasificador
    @clasificador ||= Clasificador.new
  end

  def clasificar
    self.clasificador.exec data
     
  end
 
  def get param
    if param == ''
     
    end
  end

  def exec
    client.execute command
  end
end
