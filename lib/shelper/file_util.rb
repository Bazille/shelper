#
# Author: Vitalie Lazu <vitalie.lazu@gmail.com>
# Date: Thu, 27 Nov 2008 16:10:04 +0200
#

module SHelper
  # File operations like:
  # remove line that match substring or regexp
  # add line at end
  # TODO
  # comment line
  # un-comment line
  class FileUtil
    attr_accessor :backup_store
    attr_reader :bytes_read

    def initialize(file_path)
      @file_path =file_path
    end

    # Remove lines from file that match regexp or substring
    # +match+ - regexp or substring
    # Returns true if file was modified, otherwise false
    # TODO: returns how many lines were removed
    def remove_line(match)
      func = nil

      if match.is_a?(Regexp)
        func = Proc.new { |x| x =~ match }
      else
        func = Proc.new { |x| x.index(match) }
      end

      lines = []
      modified = false

      open do |f|
        all_lines = f.readlines

        for line in all_lines
          unless func.call(line)
            lines << line
          end
        end

        if all_lines.size != lines.size
          modified = true
        end
      end

      if modified
        # TODO copy original file to backup store

        write do |f|
          f.write lines.join
        end
      end

      modified
    end

    # Append text to matched lines
    def append_to_lines(regexp, str)
      modified = false
      lines = []

      open do |f|
        all_lines = f.readlines

        for line in all_lines
          if line =~ regexp
            lines << (line.chomp << str << "\n")
            modified = true
          else
            lines << line
          end
        end
      end

      write do |f|
        f.write lines.join
      end if modified

      modified
    end

    def add_line(line)
      # TODO backup

      File.open(@file_path, "a") do |f|
        f.write line
        f.write "\n" unless line =~ /\n$/
      end
    end

    # filter lines from a file based on regexp
    # for example mail.log with filter /status=bounced/
    def filter_lines(regexp, offset = 0, &block)
      f = File.open(@file_path)
      f.seek(offset) if offset > 0
      @bytes_read = 0

      begin
        while line = f.gets
          @bytes_read += line.length
          yield line if line =~ regexp
        end
      ensure
        f.close
      end
    end

    protected
    def open(&block)
      File.open(@file_path) do |f|
        block.call(f)
      end
    end

    def write(&block)
      File.open(@file_path, "w") do |f|
        block.call(f)
      end
    end
  end
end
