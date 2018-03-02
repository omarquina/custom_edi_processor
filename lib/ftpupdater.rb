class FTPUpdater
  attr_writer :logger
  
  def config
    
  end

  def initialize params={}
    
  end

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

  def init
    puts "INIt"
    ftp = Net::FTP.new(server)
    ftp.passive = true
    #puts "FTP: #{ftp.inspect}"
    ftp.login usuario,password
    ftp.chdir( File.join( directory ) )
    #puts "LISTADO de FTP: "+( ftp.list.inspect )
    ftp
    #<TODO: capture errors>
  end

  def pre_envio
    #puts "    PRE_ENVIO_FTP:"
    result = `unix2dos #{data.outputdir}`
    #puts "    RESULTADO DE PRE_ENVIO_FTP: #{}"
    result
  end

  def move data
    errors = []
    success = [] 
    #pre_envio data
    logger.debug "--------------------------------------------------------"
    data.each do |objeto|
      begin
        puts "MOVE #{self.class.name}: file to move #{objeto.output_filename}"
        logger.debug "   Copiando: #{objeto.output_filename}"
        result = ftp.puttextfile( objeto.output_filename )
        #puts "    RESULT: #{result}"
        #puts "    LISTADO FTP: #{ftp.list.inspect}"
        objeto.exito!
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        logger.error "    ERROR copiando: #{objeto.output_filename}"
        logger.error "          mensaje: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        objeto.error!
        errors << objeto
      end
    end

    
    logger.debug "-------------------------------------------------------------"
    logger.debug "   LISTADO de Archivos Transferidos: "
    ftp.ls.each do |filename|
      puts "   REMOTE FILE: #{filename}"
      logger.debug "      #{filename}"
    end
 
    [errors,success]
    ensure
      ftp.close
  end

  def clean
    FileUtils.rm_rf(Dir.glob(File.join(directory,'*')))
  end
end
