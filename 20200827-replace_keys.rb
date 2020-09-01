# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Replace keys  with  'ICCU'    #################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = HashWithIndifferentAccess.new(YAML.load_file("#{File.dirname($0)}/#{File.basename($0, '.rb')}.yml")) rescue nil
PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where wf_owner=268 and wf_stage = 0"
size = Source.find_by_sql(sql).size
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("#{sql} order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!

    record.marc.by_tags("240").each do |n|
      n.each_by_tag("r") do |sf|
        if yaml.include?(sf.content)
          sf.content = yaml[sf.content]
          modified = true
        end
      end
    end
    if modified
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} replaced 240$r key")
    end
  end
end
