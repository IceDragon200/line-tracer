require 'minil/image'
require_relative 'point_buffer'
require_relative 'utils/color_utils'
require_relative 'utils/math_utils'
require_relative 'utils/point_utils'

class Context
  include PointUtils
  include MathUtils

  attr_reader :frames
  attr_accessor :upscale
  attr_accessor :ghost_frames
  attr_accessor :vert_prog
  attr_accessor :frag_prog

  def initialize(w, h, options = {})
    @frames = options.fetch(:frames, 64)
    @ghost_frames = 1
    @width, @height = w, h
    @upscale = 4
    @px_size = 1
    create_frame_images
  end

  def create_frame_images
    @frame_images = Array.new(@frames) { Minil::Image.create(@width, @height) }
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

  def draw(point_buffer, offset = 0)
    if !point_buffer.frame_points || point_buffer.frame_points.size != @frames
      point_buffer.frame_points = make_frame_points(point_buffer)
    end

    step_per_frame = 1.0 / @frame_images.size.to_f
    @frame_images.each_with_index do |img, i|
      frame = i / @frame_images.size.to_f
      (@ghost_frames).times do |j|
        index = offset + i - j

        r = ((offset + j) % @ghost_frames) / @ghost_frames.to_f
        norm = frame + r * step_per_frame
        ghost_frame = (index % @frame_images.size) / @frame_images.size.to_f

        pnt = get_point(point_buffer.frame_points, index)
        prev_p = prev_point(point_buffer.frame_points, index)
        next unless pnt
        next unless prev_p
        timng = { frame: frame, ghost: r, norm: norm, ghost_frame: ghost_frame }
        pnt = @vert_prog.call(timng.merge(pos: pnt))
        prev_p = @vert_prog.call(timng.merge(pos: prev_p))
        c = @frag_prog.call(timng)

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

    puts "make_me_a_gif -f #{dirname}.gif #{frame_names.join(' ')}"
  end
end
