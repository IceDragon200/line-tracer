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

def frag(&block)
  Class.new(Frag) do
    class_eval(&block)
  end
end

lsd_frag = frag do
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
    r = options[:frame]
    r = @rate_mod.call(r)
    hue = (@range.begin + (r * @range.size).to_i)
    v = @value * (1.0 - options[:ghost] / 2)
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

gray_frag = frag do
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


dirname = 'out/main'
OptionParser.new do |opts|
  opts.on '-d', '--dirname NAME', String, 'Output directory' do |v|
    dirname = v
  end
end.parse(ARGV)

cw, ch = 16, 16
default_frag = lsd_frag.new
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


#bkg = Minil::Image.load_file('crank_face.png')
#point_buffers = [
#  #LineTracer::PointBuffer.new(make_rect_points(1, 1, 14, 14).rotate(0)),
#  LineTracer::PointBuffer.new(make_rect_points(2, 2, 12, 12).rotate(1)),
#  LineTracer::PointBuffer.new(make_rect_points(4, 4, 8, 8).rotate(2)),
#  LineTracer::PointBuffer.new(make_rect_points(6, 6, 4, 4).rotate(3)),
#]

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

ctx = LineTracer::Context.new(cw, ch, frames: 60, rendered_frames: 12)
ctx.upscale = 4
ctx.vert_prog = ->(options) { options[:pos] }
ctx.frag_prog = default_frag

ctx.frame_images.each do |img|
  img.blit(bkg, 0, 0, 0, 0, bkg.width, bkg.height)
end if bkg

point_buffers.each_with_index do |point_buffer, i|
  ctx.frag_prog = point_buffer.options[:frag_prog] || default_frag
  opts = { ghost_frames: 24 }.merge(point_buffer.options)
  ctx.draw(point_buffer, opts)
end

FileUtils.mkdir_p(dirname)
ctx.save(dirname)
