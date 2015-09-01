require 'minil/image'
require_relative 'point_buffer'
require_relative 'utils/color_utils'
require_relative 'utils/math_utils'
require_relative 'utils/point_utils'

module LineTracer
  class Context
    include PointUtils
    include MathUtils

    attr_reader :frames
    attr_reader :frame_images
    attr_accessor :upscale
    attr_accessor :vert_prog
    attr_accessor :frag_prog

    def initialize(w, h, options = {})
      @frames = options.fetch(:frames, 64)
      @rendered_frames = options.fetch(:rendered_frames, @frames)
      @width, @height = w, h
      @upscale = 4
      @px_size = 1
      create_frame_images
    end

    def create_frame_images
      @frame_images = Array.new(@rendered_frames) { Minil::Image.create(@width, @height) }
    end

    def make_frame_points(point_buffer)
      points = point_buffer.points
      @frames.times.map do |i|
        index_r = i * points.size / frames.to_f
        index = index_r.to_i
        norm = index_r - index
        a, b = points[index % points.size], points[(index + 1) % points.size]
        lerp_a(a, b, norm).map(&:round)
      end
    end

    def draw(point_buffer, **options)
      offset = options.fetch(:offset, 0)
      ghost_frames = options.fetch(:ghost_frames, 0)
      rate_mod = options.fetch(:rate_mod) { ->(r) { r } }
      frame_mod = options.fetch(:frame_mod) { ->(r) { r % 1 } }

      if !point_buffer.frame_points || point_buffer.frame_points.size != @frames
        point_buffer.frame_points = make_frame_points(point_buffer)
      end

      ghost_frames = [ghost_frames, 1].max

      offset += point_buffer.offset
      step_per_frame = 1.0 / @frames.to_f
      @frame_images.each_with_index do |img, frame_index|
        i = @frames * frame_index / @frame_images.size
        i = rate_mod.call(i)

        frame = frame_index / @frame_images.size.to_f

        ghost_frames.times do |j|
          index = offset + i - j
          index = (frame_mod.call(index / @frames.to_f) * @frames).to_i

          r = frame_mod.call((offset + j) / ghost_frames.to_f)
          norm = frame + r * step_per_frame
          ghost_frame = frame_mod.call(index / @frames.to_f)

          timng = { frame: frame, ghost: r, norm: norm, ghost_frame: ghost_frame }

          pnt = get_point(point_buffer.frame_points, index)
          prev_p = prev_point(point_buffer.frame_points, index)
          pnt = @vert_prog.call(timng.merge(pos: pnt))
          prev_p = @vert_prog.call(timng.merge(pos: prev_p))
          c = @frag_prog.call(timng.merge(color: img.get_pixel(pnt[0], pnt[1])))

          draw_line prev_p, pnt do |x, y|
            img.fill_rect(x, y, @px_size, @px_size, c)
          end
        end
      end
    end

    def save(dirname)
      frame_names = []
      @frame_images.each_with_index do |img, i|
        puts "\tSAVING FRAME #{i}"
        outimg = img
        outimg = img.upscale(@upscale) if @upscale > 1
        filename = File.join(dirname, "frame_%04d.png" % i)
        File.delete(filename) if File.exist?(filename)
        outimg.save_file filename
        frame_names << filename
      end

      File.write('to_gif.sh', "#!/usr/bin/env bash\nmake_me_a_gif -d 1x60 -f #{dirname}.gif #{frame_names.join(' ')}")
    end
  end
end
