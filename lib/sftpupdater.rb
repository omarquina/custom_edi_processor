class SFTPUpdater
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

  def connection
    #Net::FTP.new(SERVER)
    Net::SFTP.start(server,usuario,password: password)
    #ftp.passive = true
  end

  def init
    #puts "INIt"
    ftp = connection
    #puts "FTP: #{ftp.inspect}"
    #puts "LOGIN "+(ftp.login USUARIO,PASSWORD).to_s
    # ftp.chdir(File.join(DIRECTORY))
    #puts "LISTADO de FTP: "+(ftp.list.inspect)
    ftp
    #<TODO: capture errors>
  end

  def pre_envio
    
  end

  def move data
    errors = []
    success = [] 

    #pre_envio

    data.each do |objeto|
      begin
        puts "MOVE: file to move #{objeto.output_filename}"
        logger.debug "     Copiando: #{objeto.output_filename}"
        #result = ftp.puttextfile( objeto.output_filename )
        result = ftp.upload!( objeto.output_filename,File.join(directory,objeto.filename) )
        #puts "    RESULT: #{result}"
        #puts "    LISTADO FTP: #{ftp.list.inspect}"
        success << objeto
        objeto.exito!
      rescue => e
        puts "ERROR: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        errors << objeto
        objeto.error!
      end
        #files = ftp.chdir('pub/lang/ruby/contrib')
        #files = ftp.list('n*')
        #ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
    end

logger.debug "-------------------------------------------------------------"
logger.debug "LISTADO DE ARCHIVOS TRANSFERIDOS"
    ftp.dir.foreach(directory) do |file|
logger.debug "    #{file.longname}"

      puts "  FILE Remoto: #{file.longname}"
    end


    [errors,success]
    ensure
     # ftp.close
  end

  def clean
    FileUtils.rm_rf(Dir.glob(File.join(directory,'*')))
  end
end

