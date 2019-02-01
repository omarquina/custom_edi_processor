require_relative 'spec_helper'
require_relative '../lib/release'

 describe "Output Edi File Caucedo" do
   before do
     @liberacion = ReleaseCaucedo.new( {equipoId: "TCHD-1234567", status: 0} )
     @bloqueo = ReleaseCaucedo.new( {equipoId: "TCHD-1234567", status: 4} ) 
   end

   context "Liberacion" do 
	  it "El nombre del archivo edi debe contener una -L" do
            expect( @liberacion.filename ).to be_eql( "TCHD1234567-L.edi" )
	  end
   end

   context "Bloqueo" do
	  it "El nombre del archivo edi debe contener una -I" do 
            expect( @bloqueo.filename ).to be_eql( "TCHD1234567-I.edi" )
	  end
   end
end
