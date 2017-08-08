# basic check of LDAP consistency
$LOAD_PATH.unshift File.realpath(File.expand_path('../../lib', __FILE__))
require 'whimsy/asf'

fix = (ARGV.include? '--fix')

ASF::LDAP.bind if fix

groups = ASF::Group.preload # for performance
committees = ASF::Committee.preload # for performance
projects = ASF::Project.preload

puts "project.members ~ group.members"
groups.keys.sort_by {|a| a.name}.each do |entry|
    project = ASF::Project[entry.name]
    if project
      p = []
      project.members.sort_by {|a| a.name}.each do |e|
          p << e.name
      end
      g = []
      entry.members.sort_by {|a| a.name}.each do |e|
          g << e.name
      end
      if p != g
        puts "#{entry.name}: pm-g=#{p-g} g-pm=#{g-p}" 

        if fix
          project.add_members(entry.members-project.members) unless (g-p).empty?
          project.remove_members(project.members-entry.members) unless (p-g).empty?
        end
      end
    end
end

puts ""
puts "project.owners ~ committee.members"
committees.keys.sort_by {|a| a.name}.each do |entry|
    project = ASF::Project[entry.name]
    if project
      p = []
      project.owners.sort_by {|a| a.name}.each do |e|
          p << e.name
      end
      c = []
      entry.members.sort_by {|a| a.name}.each do |e|
          c << e.name
      end
      if p != c
        puts "#{entry.name}: po-c=#{p-c} c-po=#{c-p}" 

        if fix
          project.add_owners(entry.members-project.owners) unless (c-p).empty?
          project.remove_owners(project.owners-entry.members) unless (p-c).empty?
        end
      end
    end
end

puts ""
puts "current podlings(asf-auth) ~ project(members, owners)"
pods = Hash[ASF::Podling.list.map {|podling| [podling.name, podling.status]}]
ASF::Authorization.new('asf').each do |grp, mem|
  if pods[grp] == 'current'
    mem.sort!.uniq!
    project = ASF::Project[grp]
    if project
      pm = []
      project.members.sort_by {|a| a.name}.each do |e|
          pm << e.name
      end
      po = []
      project.owners.sort_by {|a| a.name}.each do |e|
          po << e.name
      end
      if mem != pm
        puts "#{grp}: pm-auth=#{pm-mem} auth-pm=#{mem-pm}" 
      end
      if mem != po
        puts "#{grp}: po-auth=#{po-mem} auth-po=#{mem-po}" 
      end
    end
  end
end
