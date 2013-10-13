require "open3"

class SetupNitrous
  def self.begin(data, &block)
    data = data.read.scan(/^# (.*)\n\n((?:.|\n(?!\n))*)/)
    files = data.inject({}) do |hash, (key,value)|
      hash.merge(key => value)
    end

    Runner.run(files, &block)
  end

  class Runner
    def self.run(data, &block)
      new(data).instance_eval(&block)
    end

    def initialize(data)
      @data = data
    end

    def run(command)
      @failure = @setup = @update = @converge = nil
      @test = true

      puts "\e[0;32m#{command}\e[0m"
      yield
    end

    def test(bool)
      @test = bool
    end

    def failure(&block)
      @failure = block
    end

    def setup
      puts "\e[0;32mAlready set up\e[0m" if @test
      yield unless @test
    end

    def update(&block)
      puts "\e[0;32mUpdating...\e[0m" unless @test
      yield if @test
    end

    def converge(&block)
      puts "\e[0;32mConverging...\e[0m"
      yield
    end

    def parts_install(package)
      `parts status #{package} 2>/dev/null`
      test $?.exitstatus.zero?

      setup do
        command "parts install #{package}"
      end
    end

    def command(command)
      columns = `tput cols`.to_i

      Open3.popen2e("#{command}") do |stdin, out, wait|
        out.each_line do |line|
          line = line[0...columns].chomp
          padding = " " * (columns - line.size)
          print "#{line}#{padding}\r"
        end

        print "\n"

        status = wait.value

        if status != 0
          puts "\e[0;31mCommand failed with error code #{status}\e[0m"
          @failure ? @failure[status] : exit
        end
      end
    end

    def copy(name)
      File.open(File.expand_path(name), "w") do |file|
        file.puts @data[name]
      end
    end
  end
end
