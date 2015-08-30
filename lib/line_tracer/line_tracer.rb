require 'minil'
require 'minil/functions'
require 'minil/color'
require 'fileutils'
require 'murmurhash3'

module Enumerable
  def map_with_index
    return to_enum :map_with_index unless block_given?

    i = 0
    map do |a|
      r = yield a, i
      i += 1
      r
    end
  end
end

class PointBuffer
  attr_accessor :points
  attr_accessor :frame_points

  def initialize(points)
    @points = points
  end
end

module PointUtils
  def get_point(points, i, length = nil)
    #return nil if i < 0
    #return nil if points.size < i
    points[i % (length || points.size)]
  end

  def prev_point(points, i, length = nil)
    get_point(points, i - 1, length)
  end

  # http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Ruby
  def draw_line(p1, p2)
    x1, y1 = p1[0], p1[1]
    x2, y2 = p2[0], p2[1]

    steep = (y2 - y1).abs > (x2 - x1).abs

    if steep
      x1, y1 = y1, x1
      x2, y2 = y2, x2
    end

    if x1 > x2
      x1, x2 = x2, x1
      y1, y2 = y2, y1
    end

    deltax = x2 - x1
    deltay = (y2 - y1).abs
    error = deltax / 2
    ystep = y1 < y2 ? 1 : -1

    y = y1
    x1.upto(x2) do |x|
      pixel = steep ? [y, x] : [x, y]
      yield(*pixel)
      error -= deltay
      if error < 0
        y += ystep
        error += deltax
      end
    end
  end

  def make_rect_points(x, y, w, h)
    [
      [x, y],
      [x + w, y],
      [x + w, y + h],
      [x, y + h]
    ]
  end

  # http://stackoverflow.com/questions/398299/looping-in-a-spiral
  def make_square_helix_points(w, h, rep = nil)
    x = y = 0
    dx = 0
    dy = -1

    points = []
    rep ||= [w, h].max ** 2
    rep.times do |i|
      wx = -w / 2
      hy = -h / 2
      if (wx < x && x < (w / 2)) && (hy < y && y < (h / 2))
        points << [x, y]
      end
      if x == y || (x < 0 && x == -y) || (x > 0 && x == 1-y)
        dx, dy = -dy, dx
      end
      x, y = x + dx, y + dy
    end
    points
  end

  def translate_points(points, ox, oy)
    points.map do |point|
      [point[0] + ox, point[1] + oy]
    end
  end

  def scale_points(points, sx, sy = sx)
    points.map do |point|
      [point[0] * sx, point[1] * sy]
    end
  end
end

module ColorUtils
  # http://www.cs.rit.edu/~ncs/color/t_convert.html
  def hsv_to_rgb_norm(h, s, v)
    if s == 0
      # full gray
      return v, v, v
    end

    h /= 60.0      # sector 0 to 5
    i = h.floor
    f = h - i      # factorial part of h
    p = v * ( 1 - s )
    q = v * ( 1 - s * f )
    t = v * ( 1 - s * ( 1 - f ) )

    case i
    when 0
      return v, t, p
    when 1
      return q, v, p
    when 2
      return p, v, t
    when 3
      return p, q, v
    when 4
      return t, p, v
    else
      return v, p, q
    end
  end

  def hsv_to_rgb(h, s, v)
    hsv_to_rgb_norm(h, s, v).map { |f| [[0, f * 255].max, 255].min.to_i }
  end

  def hsv_to_rgba(h, s, v)
    [*hsv_to_rgb(h, s, v), 255]
  end

  def color_encode(ary)
    Minil::Color.encode(*ary)
  end
end

module MathUtils
  def lerp(a, b, d)
    a + (b - a) * d
  end

  def lerp_a(a, b, d)
    a.map_with_index do |x, i|
      lerp(x, b[i], d)
    end
  end

  def diff_a(a, b)
    a.map_with_index do |x, i|
      b[i] - x
    end
  end
end

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
    @frame_images = Array.new(@frames) { Image.create(@width, @height) }
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
