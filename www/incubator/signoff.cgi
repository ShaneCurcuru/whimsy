#!/usr/bin/env ruby

# quick and dirty script to tally up which mentors have been providing
# signoffs and which have not.

require 'whimsy/asf'

# authenticate
user = ASF::Person.find($USER)
incubator = ASF::Committee.find('incubator').members
unless user.asf_member? or incubator.include? user
  print "Status: 401 Unauthorized\r\n"
  print "WWW-Authenticate: Basic realm=\"Incubator PMC and Members\"\r\n\r\n"
  exit
end

BOARD = ASF::SVN['private/foundation/board']

agendas = Dir["#{BOARD}/board_agenda_*.txt",
  "#{BOARD}/archived_agendas/board_agenda_*.txt"]

agendas = agendas.sort_by {|file| File.basename(file)}[-13..-1]

if File.read(agendas.last).include? 'The Apache Incubator is the entry path'
  agendas.shift
else
  agendas.pop
end

ASF::Person.preload('cn')
ASF::ICLA.preload()
people = Hash[ASF::Person.list.map {|person| [person.public_name, person.id]}]
mentors = {}

agendas.each do |file|
  date = file[/\d+_\d+_\d+/].gsub('_', '-')
  agenda = File.read(file)
  signoffs = agenda.scan(/^Signed-off-by:\s+.*?\n\n/m).join
  signoffs.scan(/\[(.+?)\]\((.*?)\) (.*)/).each do |check, podling, name|
    name.strip!
    name.sub! /\s+\(.*?\)/, ''
    mentors[name] = [] unless mentors[name]
    mentors[name] << {
      date: date,
      checked: !check.strip.empty?,
      podling: podling.strip
    }
  end
end

roster = 'https://whimsy.apache.org/roster/committer/'

_html do
  # http://bconnelly.net/2013/10/creating-colorblind-friendly-figures/
  _style %{
    .check {color: rgb(0,114,178)}
    .blank {color: rgb(230,159,0); font-style: italic; font-weight: bold}
  }

  _h1 'Mentor signoffs over the last twelve months'

  _p! do
    _span.check 'Blue'
    _ ' means signoff is present, '
    _span.blank 'orange'
    _ ' means signoff is absent.'
  end

  _p 'Hover over podling name to see date.'

  _table_ do
    mentors.sort.each do |name, entries|
      _tr_ do
        _td do
          if people[name]
            if ASF::Person.find(people[name]).asf_member?
              _b! {_a name, href: roster + people[name]}
            else
              _a name, href: roster + people[name]
            end
          else
            _a name, href: roster + '?q=' + URI.encode(name)
          end
        end

        _td do
          entries.each do |entry|
            if entry[:checked]
              _span.check entry[:podling], title: entry[:date]
            else
              _span.blank entry[:podling], title: entry[:date]
            end
          end
        end
      end
    end
  end
end
