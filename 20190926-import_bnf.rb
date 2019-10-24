# encoding: UTF-8
puts "##################################################################################################"
puts "################################   Import BNF sources      #######################################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"
#%x( tar -xjvf housekeeping/maintenance/20180720-iccu_sources.tar.bz2 -C /tmp/  )

#ifile = "/tmp/20180720-iccu_sources.xml"
ifile = "/home/dev/projects/import/data/BNF/output/output.xml"
PaperTrail.request.disable_model(Catalogue)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

if File.exists?(ifile)
  import = MarcImport.new(ifile, "Source", 0)
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts ifile + " is not a file!"
end

#FIXME only
puts "#########################################################################"
puts "################ Updateing new imported sources   #######################"
puts "#########################################################################"

sx = Source.where('id between ? and ?', 840010000, 840032000)
sx.update_all(:wf_stage => 0, :wf_audit => 1)

user = User.where(email: "francois-pierre.goy@bnf.fr").first
sx.update_all(wf_owner: user.id)

subentries = sx.where.not(:source_id => nil)
bar = ProgressBar.new(subentries.size)
  
subentries.each do |s|
  s.update_77x
  bar.increment!
end

px = Person.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
px.each do |p|
  p.scaffold_marc
end
px.update_all(wf_owner: user.id, wf_stage: 0)

ix = Institution.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
ix.each do |i|
  i.scaffold_marc
end
ix.update_all(wf_owner: user.id)

cx = Catalogue.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
end
cx.update_all(wf_owner: user.id)