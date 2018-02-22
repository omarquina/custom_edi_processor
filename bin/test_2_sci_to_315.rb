# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require "erb"
require 'logger'

releasesFromSci = ReleaseFromSci.new
relesesFromSci.notificadores << Ftp1.new

origenes << ReleaseFromSci.execute
origenes << HoldFromSCI.execute


origenes.notificar(   ).notificar

