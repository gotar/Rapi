#!/usr/bin/ruby

require "digest/md5"
require "open-uri"
require "pp"

class Rapi
  def initialize avi_file_path
    @avi_file_path = avi_file_path
  end

  def download_txt
    File.open('napisy.7z','w') do |f|
      f.write(open(url).read)
    end
    `7z x -y -so -piBlm8NTigvru0Jr0 napisy.7z 2>/dev/null > "#{output_file('txt')}"`
    `rm napisy.7z`
    if File.size?(output_file('txt')).nil?
      puts "Nie mozna znalezc napisow dla #{@avi_file_path}"
    else
      puts "Pobrano napisy dla #{@avi_file_path}"
      return output_file('txt')
    end
  end

  private
  
  def file_header
    File.open(@avi_file_path).read(10485760)
  end
  
  def url
    "http://napiprojekt.pl/unit_napisy/dl.php?l=PL&f=#{digest}&t=#{rapi_digest(digest)}&v=other&kolejka=false&nick=&pass=&napios=posix"
  end
  
  def digest
    Digest::MD5.hexdigest(file_header)
  end
  
  def rapi_digest(z)
    idx = [ 0xe, 0x3,  0x6, 0x8, 0x2 ]
    mul = [   2,   2,    5,   4,   3 ]
    add = [   0, 0xd, 0x10, 0xb, 0x5 ]
    b = []

    idx.length.times do |i|
        a = add[i]
        m = mul[i]
        i = idx[i]

        t = a + z.split('')[i].to_i(16)
        v = z.split('')[t..t+1].join('').to_i(16)
        b.push(('%x' % (v*m)).split('').last)
    end
    return b.join('')
  end
  
  def output_file(extension)
    "#{File.dirname(@avi_file_path)}/#{File.basename(@avi_file_path, @avi_file_path.split('.').last)}#{extension}"
  end
end

txt2srt = "#{File.dirname(__FILE__)}/txt2srt-1.0.8.jar"

txt_files = ARGV.map { |arg| Rapi.new(arg).download_txt }.compact.each do |f|
  cmd = "java -jar #{txt2srt} #{"\"#{f}\""}"
  puts cmd
  `#{cmd}`
end
`rm #{txt_files.join(' ')}`
