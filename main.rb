require 'fileutils'
require 'optparse'

require_relative 'lib/line_tracer'
require_relative 'lib/line_tracer/core_ext/range'

include LineTracer::PointUtils

class Frag
  include LineTracer::ColorUtils

  def process(options)
    [1, 1, 1, 1]
  end

  def call(options)
    color_encode(process(options))
  end
end

class LsdFrag < Frag
  attr_accessor :range
  attr_accessor :saturation
  attr_accessor :value
  attr_accessor :mode
  attr_accessor :rate_mod

  def initialize
    @range = 0...360
    @saturation = 1.0
    @value = 1.0
    @mode = nil
    @rate_mod = ->(r) { r }
  end

  def process(options)
    r = options[:true_frame]
    r = @rate_mod.call(r)
    hue = (@range.begin + (r * @range.size).to_i)
    v = @value * (1.0 - options[:true_ghost] / 2)
    c = hsv_to_rgba(hue, @saturation, v)
    case @mode
    when :overlay
      color_blend_overlay(c, options[:color])
    when :add
      color_blend_add(options[:color], c)
    when :mul
      color_blend_mul(options[:color], c)
    when :sub
      color_blend_sub(options[:color], c)
    else
      c
    end
  end
end

class GrayscaleFrag < Frag
  def process(options)
    value = 128 + (options[:ghost] * 127).to_i
    [value, value, value, 255]
  end
end

norm_wrap      = ->(r) { r % 1 }
invert_wrap    = ->(r) { (1 - r) % 1 }
ping_pong_wrap = ->(r) { (r > 1 ? 2 - r : r).abs }
sine_wrap      = ->(r) { Math.sin(Math::PI * r).abs }
make_mul_rate  = ->(a) { ->(r) { r * a } }
inclusive_wrap = ->(r) { (r > 1 || r < 0) ? (r % 1) : r }

dirname = 'out/main'
OptionParser.new do |opts|
  opts.on '-d', '--dirname NAME', String, 'Output directory' do |v|
    dirname = v
  end
end.parse(ARGV)

cw, ch = 16, 16
default_frag = LsdFrag.new
#default_frag.range = (0...30).translate(20).translate(0)
default_frag.range = (0...30).translate(20).translate(150)
#default_frag.range = 0...180
default_frag.rate_mod = sine_wrap
default_frag.mode = :overlay
#default_frag.mode = nil
default_frag.value = 0.85
default_frag.saturation = 0.8

frag_prog_mid = default_frag.dup
frag_prog_mid.range = (0..30).translate(20).translate(90)
frag_prog_mid.mode = nil

frag_prog_outer = default_frag.dup
frag_prog_outer.range = (0..30).translate(20).translate(0)

point_buffers = []
bkg = nil

#bkg = Minil::Image.load_file('autocraft.png')
#point_buffers << LineTracer::PointBuffer.new(make_rect_points(1, 1, 14, 14).reverse, offset: 29, ghost_frames: 12, frag_prog: frag_prog_outer)
point_buffers << LineTracer::PointBuffer.new(make_rect_points(1, 1, 14, 14),
  offset: 0, ghost_frames: 0, mode: :fan, point_count: 8)
#point_buffers << LineTracer::PointBuffer.new(make_rect_points(3, 3, 10, 10))
#point_buffers << LineTracer::PointBuffer.new(make_rect_points(5, 5, 6, 6), offset: 15)
#point_buffers << LineTracer::PointBuffer.new(make_rect_points(7, 7, 2, 2), offset: 30, frag_prog: frag_prog_mid)

#point_buffers << LineTracer::PointBuffer.new(make_rect_points(3, 3, 10, 10).rotate(2))
#point_buffers = [
#  LineTracer::PointBuffer.new([[4, 6], [11, 6]], offset: 0),
#  LineTracer::PointBuffer.new([[9, 4], [9, 11]], offset: 12),
#  LineTracer::PointBuffer.new([[4, 9], [11, 9]], offset: 24),
#  LineTracer::PointBuffer.new([[6, 4], [6, 11]], offset: 36)
#]

#bkg = Minil::Image.load_file('crank_face.png')
#point_buffers = [
#  #LineTracer::PointBuffer.new(make_rect_points(1, 1, 14, 14).rotate(0)),
#  LineTracer::PointBuffer.new(make_rect_points(2, 2, 12, 12).rotate(1)),
#  LineTracer::PointBuffer.new(make_rect_points(4, 4, 8, 8).rotate(2)),
#  LineTracer::PointBuffer.new(make_rect_points(6, 6, 4, 4).rotate(3)),
#]

#bkg = Minil::Image.load_file('condenser.png')

# frame outer hooks
#points1, points2, points3, points4 = make_pinwheel_from_points(make_rect_points(4, -6, 8, 8), cw, ch)
#point_buffers << LineTracer::PointBuffer.new(points1, offset:  0, ghost_frames: 24)
#point_buffers << LineTracer::PointBuffer.new(points2, offset: 15, ghost_frames: 24)
#point_buffers << LineTracer::PointBuffer.new(points3, offset: 30, ghost_frames: 24)
#point_buffers << LineTracer::PointBuffer.new(points4, offset: 45, ghost_frames: 24)

#points1, points2, points3, points4 = make_pinwheel_from_points([[6, 4], [6, 3], [9, 3], [9, 6], [8, 6]], cw, ch)
#point_buffers << LineTracer::PointBuffer.new(points1, offset: 0)
#point_buffers << LineTracer::PointBuffer.new(points2, offset: 15)
#point_buffers << LineTracer::PointBuffer.new(points3, offset: 30)
#point_buffers << LineTracer::PointBuffer.new(points4, offset: 45)

#points1, points2, points3, points4 = make_pinwheel_from_points([[9, 6], [9, 3], [12, 3], [12, 6]], cw, ch)
#point_buffers << LineTracer::PointBuffer.new(points1, frag_prog: frag_prog_mid, ghost_frames: 12, offset: 0)
#point_buffers << LineTracer::PointBuffer.new(points2, frag_prog: frag_prog_mid, ghost_frames: 12, offset: 15)
#point_buffers << LineTracer::PointBuffer.new(points3, frag_prog: frag_prog_mid, ghost_frames: 12, offset: 30)
#point_buffers << LineTracer::PointBuffer.new(points4, frag_prog: frag_prog_mid, ghost_frames: 12, offset: 45)

#point_buffers = [
#  LineTracer::PointBuffer.new(translate_points(make_square_helix_points(cw / 2, ch / 2), cw / 2, ch / 2))
#]

#point_buffers = cw.times.map do |i|
#  #next if i % 2 != 0
#  points = [
#    [i, 0],
#    [i, ch - 1]
#  ]
#  LineTracer::PointBuffer.new(points)
#end.compact
#point_buffers = 0.upto((cw - 2) / 2).map do |i|
#  #next if i % 2 != 0
#  points = make_rect_points(i, i, cw - i * 2 - 1, ch - i * 2 - 1)
#  #points = points.reverse if i % 4 == 0
#  points = points.reverse if i % 2 == 0
#  LineTracer::PointBuffer.new(points)
#end.compact
#point_buffers = [LineTracer::PointBuffer.new(translate_points(make_square_helix_points(cw / 2, ch / 2, cw * ch), cw / 2, ch / 2))]

ctx = LineTracer::Context.new(cw, ch, frames: 64, rendered_frames: 16)
ctx.upscale = 4
ctx.vert_prog = ->(options) { options[:pos] }
ctx.frag_prog = default_frag

ctx.frame_images.each do |img|
  img.blit(bkg, 0, 0, 0, 0, bkg.width, bkg.height)
end if bkg

point_buffers.each_with_index do |point_buffer, i|
  ctx.frag_prog = point_buffer.options[:frag_prog] || default_frag
  opts = { ghost_frames: 24, mode: :lines }.merge(point_buffer.options)
  ctx.draw(point_buffer, opts)
end

FileUtils.mkdir_p(dirname)
ctx.save(dirname)
