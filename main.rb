require 'fileutils'
require 'optparse'

require_relative 'lib/line_tracer'

def frag(&block)
  Class.new do
    include LineTracer::ColorUtils

    class_eval(&block)
  end
end

lsd_frag = frag do
  def call(options)
    r = options[:ghost]
    r = Math.sin(Math::PI * 2 * r)
    color_encode(hsv_to_rgba(r * 360, 1, 1))
  end
end.new

gray_frag = frag do
  def call(options)
    value = 128 + (options[:ghost] * 127).to_i
    color_encode([value, value, value, 255])
  end
end.new

include LineTracer::PointUtils

dirname = 'out/main'
OptionParser.new do |opts|
  opts.on '-d', '--dirname NAME', String, 'Output directory' do |v|
    dirname = v
  end
end.parse(ARGV)

cw, ch = 16, 16
point_buffers = [
  LineTracer::PointBuffer.new(make_rect_points(3, 3, 10, 10))
]
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

ctx = LineTracer::Context.new(cw, ch, frames: 64)
ctx.upscale = 1
ctx.vert_prog = ->(options) { options[:pos] }
ctx.frag_prog = lsd_frag
ctx.ghost_frames = ctx.frames

point_buffers.each_with_index do |point_buffer, i|
  ctx.draw(point_buffer, i)
end

FileUtils.mkdir_p(dirname)
ctx.save(dirname)
