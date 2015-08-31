require 'fileutils'
require_relative 'lib/line_tracer'

class LsdFrag
  include ColorUtils

  def call(options)
    r = options[:ghost]
    r = Math.sin(Math::PI * 2 * r)
    color_encode(hsv_to_rgba(r * 360, 1, 1))
  end
end

class GrayscaleFrag
  include ColorUtils

  def call(options)
    value = 128 + (options[:ghost] * 127).to_i
    color_encode([value, value, value, 255])
  end
end

include PointUtils

cw, ch = 128, 128
point_buffers =cw.times.map do |i|
  #next if i % 2 != 0
  points = [
    [i, 0],
    [i, ch - 1]
  ]
  PointBuffer.new(points)
end.compact
#point_buffers = 0.upto((cw - 2) / 2).map do |i|
#  #next if i % 2 != 0
#  points = make_rect_points(i, i, cw - i * 2 - 1, ch - i * 2 - 1)
#  #points = points.reverse if i % 4 == 0
#  points = points.reverse if i % 2 == 0
#  PointBuffer.new(points)
#end.compact
#point_buffers = [PointBuffer.new(translate_points(make_square_helix_points(cw / 2, ch / 2, cw * ch), cw / 2, ch / 2))]

ctx = Context.new(cw, ch, frames: 64)
ctx.upscale = 1
ctx.vert_prog = ->(options) { options[:pos] }
ctx.frag_prog = GrayscaleFrag.new
ctx.ghost_frames = ctx.frames

point_buffers.each_with_index do |point_buffer, i|
  ctx.draw(point_buffer, i)
end

dirname = File.join('out', 'test')
FileUtils.mkdir_p(dirname)
ctx.save(dirname)
