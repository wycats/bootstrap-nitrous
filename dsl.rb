require "open3"
require "fileutils"

class SetupNitrous
  def self.find_os
    if `which parts`.empty?
      return :chromeos
    else
      return :nitrous
    end
  end

  PACKAGES = {
    binaries: {
      "curl" => "curl",
      "zsh" => "zsh",
      "vim" => "vim",
      "rust" => "rustc",
      "phantomjs" => "phantomjs",
      "postgresql" => "psql",
      "tmux" => "tmux"
    },

    chromeos: {
      "curl" => "curl",
      "zsh" => "zsh",
      "vim" => "vim",
      "rust" => "rust-nightly",
      "phantomjs" => "phantomjs",
      "postgresql" => "postgresql"
    },

    nitrous: {
      "curl" => "curl",
      "zsh" => "zsh",
      "vim" => "vim",
      "rust" => "rust",
      "phantomjs" => "phantomjs",
      "postgresql" => "postgresql"
    }
  }

  PACKAGE_PREREQ = {
    chromeos: {
      "rust" => "sudo add-apt-repository ppa:hansjorg/rust && sudo apt-get update"
    }
  }

  PACKAGE_INSTALL = {
    nitrous: "parts install %{package}",
    chromeos: "sudo apt-get install %{package} --assume-yes"
  }

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
      @data   = data
      @os     = SetupNitrous.find_os
      @indent = ""

      if @os == :chromeos
        dependency "software-properties-common"
      end
    end

    def dependency(package)
      run "Installing #{package}" do
        name = PACKAGES[@os] && PACKAGES[@os][package] || package

        test succeeds?("which #{PACKAGES[:binaries][package]}")

        setup do
          if prereq = PACKAGE_PREREQ[@os] && PACKAGE_PREREQ[@os][package]
            command prereq
          end

          command PACKAGE_INSTALL[@os] % { package: name }
        end
      end
    end

    alias package dependency

    def run(command)
      @failure = @setup = @update = @converge = nil
      @test = true

      say "\e[0;32m#{command}\e[0m"

      indent { yield }
      puts
    end

    def test(bool)
      @test = bool
    end

    def failure(&block)
      @failure = block
    end

    def setup
      say "\e[0;32mAlready set up\e[0m" if @test
      yield unless @test
    end

    def update(&block)
      say "\e[0;32mUpdating...\e[0m" if @test
      indent { yield } if @test
    end

    def converge(&block)
      say "\e[0;32mConverging...\e[0m"
      indent { yield }
    end

    def parts_install(package)
      `parts status #{package} 2>/dev/null`
      test $?.exitstatus.zero?

      setup do
        command "parts install #{package}"
      end
    end

    def command(command)
      say "Running \e[0;33m#{command}\e[0m:"
      
      columns = `tput cols`.to_i

      outputs = []

      indent do
        Open3.popen2e("#{command}") do |stdin, out, wait|
          out.each_line do |line|
            line = line[0...(columns - @indent.size)].chomp
            padding = " " * (columns - line.size - @indent.size)
            output = "#{@indent}#{line}#{padding}"
            outputs << output
            print "#{output}\r"
          end

          final = "Done."
          padding = " " * (columns - final.size - @indent.size)
          puts "#{@indent}\e[0;33m#{final}\e[0m#{padding}"

          print "\n"

          status = wait.value

          if status != 0
            say "\e[0;31mCommand failed with error code #{status}\e[0m"
            puts
            puts "\e[0;31mTrace\e[0m:"
            puts outputs.join("\n")
            exit
          end
        end
      end
    end

    def copy(name, dest=nil)
      if dest
        FileUtils.cp(File.expand_path(name), File.expand_path(dest))
      else
        File.open(File.expand_path(name), "w") do |file|
          file.puts @data[name]
        end
      end
    end

  private
    def say(string)
      puts "#{@indent}#{string}"
    end

    def indent
      @indent += "  "
      yield
      @indent.slice!(0, 2)
    end

    def succeeds?(command)
      `#{command}`
      $?.exitstatus.zero?
    end
  end
end
