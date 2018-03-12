require 'net/ftp'
class FTPHitReader
  attr_accessor :usuario,:password,:server,:directory,:directorio_destino,:files_processing,:cantidad

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
    puts "    INIt"
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
    self.directorio_destino  = ['.','inputs','hit','processing']
    self.cantidad = nil
  end
  
  def files_filter
    @files_filter ||= "*CODECO*"
  end


  def files cantidad=nil,&block
    files_processing = ftp.nlst(files_filter)
    if block_given?
	puts "LEIDOS LOS ARCHIVOS: #{files.size}"
	#exit
	@files = @files[(0..cantidad-1)] if cantidad
	@files.map! do |filename|
	#puts "filename: #{filename}"
	#puts "    FILE: #{ftp.get filename,nil}"
	yield( ftp.get filename , nil )
	end
    end
  end

  def procesar
    
  end

  def processing_files
     
  end

  def origin_files
    _files = ftp.nlst( files_filter )
    @origin_files = cantidad ? _files[(0..cantidad-1)] : _files
  end

  def get_files cantidad,type=:file
    puts "FTPHITREADER#get_files"
    self.cantidad = cantidad 
    #files_processing# = ftp.nlst(files_filter)
    #@files = @files[(0..cantidad-1)] if cantidad
	origins = origin_files.map do |filename|
	  puts "     filename: #{filename}"
	  #puts "    FILE: #{ftp.get filename,nil}"
          case type
            when :file
              ftp.get filename , File.join( directorio_destino + [filename] )
              #puts "   FILE"
              file = FileCodeco.new( filename: filename , directorio: self.directorio_destino )
              puts "   FILE: #{file}"
              file
            when :text 
              StringCodeco.new filename, ftp.get( filename , nil )
          end
	end
    puts "   EXIT get_files: #{origin_files}"  
    origins
  end

  def remove_from_origin files
     
  end
end
