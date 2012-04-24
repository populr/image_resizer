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

    def resize_and_crop_around_point(temp_object, options)
      analyzer = ImageResizer::Analyzer.new

      desired_width = options[:width].to_i
      desired_height = options[:height].to_i
      desired_ratio = desired_height > 0 ? desired_width.to_f / desired_height : 0

      original_width = analyzer.width(temp_object)
      original_height = analyzer.height(temp_object)
      original_ratio = original_width.to_f / original_height

      if desired_ratio > original_ratio
        width = original_width
        height = width / desired_ratio
      else
        height = original_height
        width = height * desired_ratio
      end

      focus_x = options[:point][0] * original_width
      focus_y = options[:point][1] * original_height

      half_width = width * 0.5
      half_height = height * 0.5

      upper_left_x = [focus_x - half_width, 0].max
      upper_left_y = [focus_y - half_height, 0].max

      lower_right_x = upper_left_x + width
      lower_right_y = upper_left_y + height

      x_offset = [lower_right_x - original_width, 0].max
      y_offset = [lower_right_y - original_height, 0].max

      upper_left_x -= x_offset
      upper_left_y -= y_offset

      lower_right_x -= x_offset
      lower_right_y -= y_offset

      upper_left_x_percent = upper_left_x / original_width
      upper_left_y_percent = upper_left_y / original_height

      lower_right_x_percent = lower_right_x / original_width
      lower_right_y_percent = lower_right_y / original_height

      crop_to_frame_and_resize(temp_object,
                              :upper_left => [upper_left_x_percent, upper_left_y_percent],
                              :lower_right => [lower_right_x_percent, lower_right_y_percent],
                              :width => desired_width,
                              :height => desired_height
                              )
    end


    def crop_to_frame_and_resize(temp_object, options)
      analyzer = ImageResizer::Analyzer.new

      desired_width = options[:width].to_i
      desired_height = options[:height].to_i

      upper_left_x_percent = options[:upper_left].first
      upper_left_y_percent = options[:upper_left].last

      lower_right_x_percent = options[:lower_right].first
      lower_right_y_percent = options[:lower_right].last

      original_width = analyzer.width(temp_object)
      original_height = analyzer.height(temp_object)

      upper_left_x = (original_width * upper_left_x_percent).round
      upper_left_y = (original_height * upper_left_y_percent).round
      frame_width = (original_width * (lower_right_x_percent - upper_left_x_percent)).round
      frame_height = (original_height * (lower_right_y_percent - upper_left_y_percent)).round

      if desired_width == 0 && frame_height > 0
        ratio = frame_width.to_f / frame_height
        desired_width = (desired_height * ratio).round
      end

      if desired_height == 0 && frame_width > 0
        ratio = frame_height.to_f / frame_width
        desired_height = (desired_width * ratio).round
      end


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
