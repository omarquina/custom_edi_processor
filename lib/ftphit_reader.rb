require 'net/ftp'
class FTPHitReader
  attr_accessor :usuario,:password,:server,:directory,:directorio_destino

  def logger
    @logger ||= $LOG
  end

  def ftp
    #puts "GETINg ftp class attribute"
    @ftp ||= init
  end

  def ftp=(value)
    #puts "ASIGNANDO variable de clase ftp #{value}"
    @ftp = value
  end

  def objeto server
     Net::FTP.new( server )
  end

  def init
    puts "INIt"
    ftp = objeto server
    ftp.passive = true
    #puts "FTP: #{ftp.inspect}"
    ftp.login usuario,password
    ftp.chdir( File.join( directory ) )
    #puts "LISTADO de FTP: "+( ftp.list.inspect )
    ftp
    #<TODO: capture errors>
  end

  def initialize params={}
    self.usuario    = 'bremat\ftp_hit'
    self.password   = 'hi123456**'
    self.server     = 'ftpus.veconinter.com'
    #self.directory = ['Liberaciones']
    self.directory  = ['Movimientos']
    self.directory_destino  = ['.','inputs','']
  end

  def files cantidad=nil,&block
    @files = ftp.nlst("*CODECO*")
    #puts "LEIDOS LOS ARCHIVOS: #{@files}"
    #exit
    @files = @files[(0..cantidad-1)] if cantidad
    @files.map! do |filename|
       puts "filename: #{filename}"
       puts "    FILE: #{ftp.get filename,nil}"
       yield( ftp.get filename,nil )
    end
  end
end
