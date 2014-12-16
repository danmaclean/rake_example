#!/usr/bin/ruby
# encoding: utf-8
#
#  parse_rakes.rb
#
#  Created by Dan MacLean (TSL) on 2013-11-10.
#  Copyright (c). All rights reserved.
#
require 'pp'
require 'rake'
require 'graphviz'
require 'sourcify'


if RUBY_VERSION < "2.0.0"
  $stderr.puts "This won't work with Ruby < version 2.0.0\nYou are currently running #{RUBY_VERSION}"
  exit
end


def parse_invocations task
  invocations = []
   task.actions.each do |action| 
      text = action.to_raw_source
      invocations << text.scan(/Rake::Task\["(.+)?"\]\.invoke/) 
   end
   invocations.flatten
end
#/Rake::Task["(.+)?"]\.invoke
## let Rake do the parsing ...
rake = Rake::Application.new
Rake.application = rake
rake.init
rake.load_rakefile


GraphViz::options( :use => "dot" )
g = GraphViz::new( "G" , :size => "11.7,8.3", :ratio => "auto")

invokes = Hash.new {|h,k| h[k] = [] }
rake.tasks.each do |task|
  if task.class == Rake::Task
    g.add_nodes( task.to_s, 
              "shape" => "cds", 
              "fillcolor" => "gold2", 
              "style" => "filled,bold",
              "fontname" => "monospace",
              "fontsize" => "21"
              )
    invocations = parse_invocations task
    next if invocations.empty?
    invocations.each {|inv| invokes[task.to_s] << inv }
    
  elsif task.class == Rake::FileTask
    g.add_nodes( task.to_s, 
                 "shape" => "note",  
                  "fillcolor" => "lightblue", 
                  "style" => "filled,bold",
                  "fontname" => "monospace",
                  "fontsize" => "21"
                  )
  elsif task.class == Rake::FileCreationTask
    g.add_nodes( task.to_s, 
                 "shape" => "folder",  
                 "fillcolor" => "firebrick1", 
                 "style" => "filled,bold",
                 "fontname" => "monospace",
                 "fontsize" => "21"
                 )
  end

  
  task.prerequisites.each { |dep| g.add_edges(dep, task.to_s)}
  
end


invokes.each_pair do |h,k|
  k.each do |i|
    g.add_edges(h,i, "style" => "dashed", "color"=> "darkgray", "dir"=>"none")
  end
end

g.output(:pdf => "task_overview.pdf")  
