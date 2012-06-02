#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'erb'
require 'time'

DOC_VERSION = Time.new.strftime('%Y%m%d.%H%M%S')

TREE_FILE = File.join 'doc', 'panel', 'tree.js'
SEARCH_INDEX_FILE = File.join 'doc', 'panel', 'search_index.js'

# Used in js to reduce index sizes
TYPE_CLASS  = 1
TYPE_METHOD = 2
TYPE_FILE   = 3


def search_string(string)
  string ||= ''
  string.downcase.gsub(/\s/,'')
end

def strip_tags(str)
  str.to_s.gsub( %r{</?[^>]+?>}, '' )
end

def strip_p(str)
  str.to_s.gsub( %r{</?[^>]+?>}, '' )
end

### Strip comments on a space after 100 chars
def snippet(str)
  str ||= ''
  if str =~ /^(?>\s*)[^\#]/
    content = str
  else
    content = str.gsub(/^\s*(#+)\s*/, '')
  end
  
  content = content.sub(/^(.{100,}?)\s.*/m, "\\1").gsub(/\r?\n/m, ' ')
  
  begin
    content.to_json(:max_nesting => 0)
  rescue # might fail on non-unicode string
    begin
      content = Iconv.conv('latin1//ignore', "UTF8", content) # remove all non-unicode chars
      content.to_json(:max_nesting => 0)
    rescue
      content = '' # something hugely wrong happend
    end
  end
  content
end

def debug_msg(str)
  puts "DEBUG: #{str}"
end


### Recursivly build class tree structure
def generate_class_tree_level(parent='')
  $all.map { |klass|
    if parent == klass['parentname']
      [
       klass['name'],
       "classes/#{klass['fullname']}.html", # klass.path, 
       '',
       generate_class_tree_level(klass['fullname'])
      ]
    else
      nil
    end
  }.compact
end


### Create class tree structure and write it as json
def generate_class_tree
  debug_msg "Generating class tree"
  tree = generate_class_tree_level
  debug_msg "  writing class tree to %s" % TREE_FILE
  File.open(TREE_FILE, "w", 0644) do |f|
    f.write('var tree = '); f.write(tree.to_json(:max_nesting => 0))
  end unless $dryrun
end


def generate_search_index
  debug_msg "Generating search index"
  
  index = {
    :searchIndex => [],
    :longSearchIndex => [],
    :info => []
  }
  
  add_class_search_index(index)
  add_method_search_index(index)
  
  debug_msg "  writing search index to %s" % SEARCH_INDEX_FILE
  data = {
    :index => index
  }
  File.open(SEARCH_INDEX_FILE, "w", 0644) do |f|
    f.write('var search_data = '); f.write(data.to_json(:max_nesting => 0))
  end unless $dryrun
end


### Add classes to search +index+ array
def add_class_search_index(index)
  debug_msg "  generating search index"
  
  $all.each do |klass|
    index[:searchIndex].push( search_string(klass['fullname']) )
    index[:longSearchIndex].push( search_string(klass['fullname']) )
    index[:info].push([ klass['name'], # klass.name, 
                        klass['parentname'], # files.include?(klass.parent.full_name) ? files.first : klass.parent.full_name, 
                        "classes/#{klass['fullname']}.html", # klass.path, 
                        '', # modulename ? " < #{modulename}" : '', 
                        snippet(strip_tags(klass['description'])),
                        TYPE_CLASS
                      ])
  end
end


### Add methods to search +index+ array
def add_method_search_index(index)
  debug_msg "  generating method search index"

  $all.each do |klass|
    klass['methods'].each do |method|
      params = method['parameters'].map{|p| p['name']}
      index[:searchIndex].push( search_string(method['name']) + ' ()' )
      index[:longSearchIndex].push( search_string([klass['fullname'], method['name']].join('.')) )
      index[:info].push([ method['name'], 
                          klass['fullname'],
                          "classes/#{klass['fullname']}.html\##{method['name']}-method", # filename
                          " (#{params.join(', ')})", 
                          snippet(strip_tags(method['value'])),
                          TYPE_METHOD
                        ])
    end
    klass['properties'].each do |property|
      index[:searchIndex].push( search_string(property['name']) )
      index[:longSearchIndex].push( search_string([klass['fullname'], property['name']].join('.')) )
      index[:info].push([ property['name'], 
                          klass['fullname'],
                          "classes/#{klass['fullname']}.html\##{property['name']}-property", # filename
                          "", 
                          snippet(strip_tags(property['value'])),
                          TYPE_METHOD
                        ])
    end
  end
end


# .gsub(/href=\\"([\w.]+)\.(\w+)\.html\\"/,'href=\\"\1.html#\2-method\\"')
$all = JSON::parse(STDIN.read.gsub(/href=\\"([\w.]+)\\"/,'href=\\"\1.html\\"').gsub(/href=\\"([\w.]+)-module.html\\"/,'href=\\"\1.html\\"').gsub(".html.html", ".html")).sort { |a, b|
  a[0] <=> b[0]
}.map { |mod|
  klass = mod[1]
  klass['fullname'] = mod[0]
  names = mod[0].split(".")
  klass['name'] = names.pop
  klass['parentname'] = names.join(".")
  klass
}

generate_search_index
generate_class_tree

include ERB::Util
rel_prefix = '..'
erb = ERB.new(open('templates/class.rhtml').read)
$all.each do |klass|
  open("doc/classes/#{klass['fullname']}.html", 'w') do |f|
    f.write erb.result(binding)
  end
  klass['methods'].each do |m|
    open("doc/classes/#{klass['fullname']}.#{m['name']}.html", 'w') do |f|
      f.write <<__HTML__
<html>
<head><meta http-equiv="refresh" content="0;url=#{klass['fullname']}.html\##{m['name']}-method"></head>
<body>
<a href="#{klass['fullname']}.html\##{m['name']}-method">#{klass['fullname']}.html\##{m['name']}-method</a>
</body>
</html>

__HTML__
    end
  end
end

manifest = ['CACHE MANIFEST', "# VERSION: #{DOC_VERSION}","NETWORK:", 'http://tidocs-comments.appspot.com/', 'http://www.google-analytics.com/', 'CACHE:']
Dir.chdir("doc")
Dir.glob("**/*").each do |f|
  manifest.push f if File.file?(f) && f != 'tidocs.manifest'
end
open('tidocs.manifest','w').write(manifest.join("\n"))

