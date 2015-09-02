require_relative '../lib/line_tracer'

points = LineTracer::PointUtils.make_rect_points(7, 7, 17, 17)
cp = LineTracer::PointUtils.center_point_of(points)
points = LineTracer::PointUtils.rotate_points(points, cp, 45)
points = LineTracer::PointUtils.round_points(points)

p points

img = Minil::Image.create(32, 32)
img.draw_line_shape(points, 0xFF000000)
img.save_file('test.png')
