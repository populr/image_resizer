require 'tempfile'

module ImageResizer
  module Utils

    include Shell
    include Loggable
    include Configurable
    configurable_attr :convert_command, "convert"
    configurable_attr :identify_command, "identify"

    private

    def convert(temp_object=nil, args='', format=nil)
      tempfile = new_tempfile(format)
      if temp_object.is_a?(Array)
        paths = temp_object.map { |obj| quote(obj.path) }.join(' ')
        run convert_command, %(#{paths} #{args} #{quote(tempfile.path)})
      else
        run convert_command, %(#{quote(temp_object.path) if temp_object} #{args} #{quote(tempfile.path)})
      end

      tempfile
    end

    def identify(temp_object)
      # example of details string:
      # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
      format, width, height, depth = raw_identify(temp_object).scan(/([A-Z0-9]+) (\d+)x(\d+) .+ (\d+)-bit/)[0]
      {
        :format => format.downcase.to_sym,
        :width => width.to_i,
        :height => height.to_i,
        :depth => depth.to_i
      }
    end

    def raw_identify(temp_object, args='')
      run identify_command, "#{args} #{quote(temp_object.path)}"
    end

    def new_tempfile(ext=nil)
      tempfile = ext ? Tempfile.new(['ImageResizer', ".#{ext}"]) : Tempfile.new('ImageResizer')
      tempfile.binmode
      tempfile.close
      tempfile
    end

  end
end
