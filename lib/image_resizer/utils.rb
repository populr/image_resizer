require 'tempfile'
require 'cocaine'

module ImageResizer
  module Utils

    include Loggable
    include Configurable
    configurable_attr :convert_command, "convert"
    configurable_attr :identify_command, "identify"

    private

    def convert(temp_object=nil, args='', format=nil)
      tempfile = new_tempfile(format)
      interpolation_data = {}

      if temp_object.is_a?(Array)
        temp_object.length.times { |index| interpolation_data["input#{index}".to_sym] = temp_object[index].path }
        keys = interpolation_data.keys.map { |s| ":#{s}" }
        args = "#{keys.join(' ')} #{args} :output"
      elsif temp_object
        interpolation_data[:input] = temp_object.path
        args = ":input #{args} :output"
      else
        args = "#{args} :output"
      end

      interpolation_data[:output] = tempfile.path

      line = Cocaine::CommandLine.new(convert_command, args)
      line.run(interpolation_data)

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

    def verbose_identify(temp_object)
      raw_identify(temp_object, '-verbose')
    end

    def raw_identify(temp_object, args='')
      line = Cocaine::CommandLine.new(identify_command, "#{args} :input")
      line.run(:input => temp_object.path)
    end

    def new_tempfile(ext=nil)
      tempfile = ext ? Tempfile.new(['ImageResizer', ".#{ext}"]) : Tempfile.new('ImageResizer')
      tempfile.binmode
      tempfile.close
      tempfile
    end

  end
end
