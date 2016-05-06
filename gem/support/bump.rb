# Rake tasks borrowed from ruby_lib
# https://github.com/bootstraponline/ruby_lib/blob/7935fc02afb7720306c7a273d205a2db9bdfb417/Rakefile

def version_file
  @version_file ||= 'lib/earlgrey/version.rb'.freeze
end

def version_rgx
  /\s*VERSION\s*=\s*'([^']+)'/m
end

def bump(value)
  data = File.read version_file

  v_line = data.match version_rgx

  old_v = v_line[0]

  old_num = v_line[1]
  new_num = old_num.split('.')
  new_num[-1] = new_num[-1].to_i + 1

  if value == :y
    new_num[-1] = 0 # x.y.Z -> x.y.0
    new_num[-2] = new_num[-2].to_i + 1 # x.Y -> x.Y+1
  elsif value == :x
    new_num[-1] = 0 # x.y.Z -> x.y.0
    new_num[-2] = 0 # x.Y.z -> x.0.z
    new_num[-3] = new_num[-3].to_i + 1
  end

  new_num = new_num.join '.'

  new_v = old_v.sub old_num, new_num
  puts "#{old_num} -> #{new_num}"

  data.sub! old_v, new_v

  File.write version_file, data
end

desc 'Bump the z version number.'
task :bump do
  bump :z
end

desc 'Bump the y version number, set z to zero.'
task :bumpy do
  bump :y
end

desc 'Bump the x version number, set y & z to zero.'
task :bumpx do
  bump :x
end
