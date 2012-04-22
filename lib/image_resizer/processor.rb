module ImageResizer
  class Processor

    GRAVITIES = {
      'nw' => 'NorthWest',
      'n'  => 'North',
      'ne' => 'NorthEast',
      'w'  => 'West',
      'c'  => 'Center',
      'e'  => 'East',
      'sw' => 'SouthWest',
      's'  => 'South',
      'se' => 'SouthEast'
    }

    # Geometry string patterns
    RESIZE_GEOMETRY         = /^\d*x\d*[><%^!]?$|^\d+@$/ # e.g. '300x200!'
    CROPPED_RESIZE_GEOMETRY = /^(\d+)x(\d+)#(\w{1,2})?$/ # e.g. '20x50#ne'
    CROP_GEOMETRY           = /^(\d+)x(\d+)([+-]\d+)?([+-]\d+)?(\w{1,2})?$/ # e.g. '30x30+10+10'
    THUMB_GEOMETRY = Regexp.union RESIZE_GEOMETRY, CROPPED_RESIZE_GEOMETRY, CROP_GEOMETRY

    include Configurable
    include Utils

    def resize(temp_object, geometry)
      convert(temp_object, "-resize #{geometry}")
    end

    def auto_orient(temp_object)
      convert(temp_object, "-auto-orient")
    end

    def crop(temp_object, opts={})
      width   = opts[:width]
      height  = opts[:height]
      gravity = GRAVITIES[opts[:gravity]]
      x       = "#{opts[:x] || 0}"
      x = '+' + x unless x[/^[+-]/]
      y       = "#{opts[:y] || 0}"
      y = '+' + y unless y[/^[+-]/]
      repage  = opts[:repage] == false ? '' : '+repage'

      resize = opts[:resize] ? "-resize #{opts[:resize]} " : ''
      gravity = gravity ? "-gravity #{gravity} " : ''

      convert(temp_object, "#{resize}#{gravity}-crop #{width}x#{height}#{x}#{y} #{repage}")
    end

    def crop_to_frame_and_scale(temp_object, options)
      analyzer = ImageResizer::Analyzer.new

      desired_width = options[:width]
      desired_height = options[:height]

      upper_left_x_percent = options[:upper_left].first.sub('%', '').to_i * 0.01
      upper_left_y_percent = options[:upper_left].last.sub('%', '').to_i * 0.01

      lower_right_x_percent = options[:lower_right].first.sub('%', '').to_i * 0.01
      lower_right_y_percent = options[:lower_right].last.sub('%', '').to_i * 0.01

      original_width = analyzer.width(temp_object)
      original_height = analyzer.height(temp_object)

      upper_left_x = (original_width * upper_left_x_percent).round
      upper_left_y = (original_height * upper_left_y_percent).round
      frame_width = (original_width * (lower_right_x_percent - upper_left_x_percent)).round
      frame_height = (original_height * (lower_right_y_percent - upper_left_y_percent)).round

      convert(temp_object, "-crop #{frame_width}x#{frame_height}+#{upper_left_x}+#{upper_left_y} -resize #{desired_width}x#{desired_height} +repage")
    end

    def flip(temp_object)
      convert(temp_object, "-flip")
    end

    def flop(temp_object)
      convert(temp_object, "-flop")
    end

    def greyscale(temp_object)
      convert(temp_object, "-colorspace Gray")
    end
    alias grayscale greyscale

    def resize_and_crop(temp_object, opts={})
      if !opts[:width] && !opts[:height]
        return temp_object
      elsif !opts[:width] || !opts[:height]
        attrs          = identify(temp_object)
        opts[:width]   ||= attrs[:width]
        opts[:height]  ||= attrs[:height]
      end

      opts[:gravity] ||= 'c'

      opts[:resize]  = "#{opts[:width]}x#{opts[:height]}^^"
      crop(temp_object, opts)
    end

    def rotate(temp_object, amount, opts={})
      convert(temp_object, "-rotate #{amount}#{opts[:qualifier]}")
    end

    def strip(temp_object)
      convert(temp_object, "-strip")
    end

    def thumb(temp_object, geometry)
      case geometry
      when RESIZE_GEOMETRY
        resize(temp_object, geometry)
      when CROPPED_RESIZE_GEOMETRY
        resize_and_crop(temp_object, :width => $1, :height => $2, :gravity => $3)
      when CROP_GEOMETRY
        crop(temp_object,
          :width => $1,
          :height => $2,
          :x => $3,
          :y => $4,
          :gravity => $5
        )
      else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
      end
    end

    def convert(temp_object, args='', format=nil)
      format ? [super, {:format => format.to_sym}] : super
    end

  end
end
