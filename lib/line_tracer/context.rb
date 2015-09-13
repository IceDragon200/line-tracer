require 'minil/image'
require_relative 'minil/image/draw_line'

require_relative 'utils/color_utils'
require_relative 'utils/math_utils'
require_relative 'utils/point_utils'
require_relative 'core/color_blender'
require_relative 'core/shape'
require_relative 'core/entity'
require_relative 'core/point_buffer'

module LineTracer
  # Deprecated, will be replace by Project in the future
  class Context
    include PointUtils
    include MathUtils
    include ColorUtils

    attr_reader :width
    attr_reader :height
    attr_reader :frame_images
    attr_accessor :stages
    attr_accessor :frames
    attr_accessor :scale
    attr_accessor :vert_prog
    attr_accessor :frag_prog
    attr_accessor :point_size

    def initialize(w, h, **options)
      @frames = options.fetch(:frames, 64)
      @stages = options.fetch(:stages, @frames)
      @rendered_frames = options.fetch(:rendered_frames, @stages)
      @width, @height = w, h
      @scale = 1
      @point_size = 1
      create_frame_images
    end

    def create_frame_images
      @frame_images = Array.new(@rendered_frames) { Minil::Image.create(@width, @height) }
    end

    def mode_point_count(mode)
      case mode
      when :points
        1
      when :lines
        2
      when :triangles
        3
      when :quads
        4
      when :fan
        3
      when :strips
        raise "Supply a point_count with the draw options for #{mode} mode"
      else
        raise 'Unknown mode, or some custom mode...'
      end
    end

    def get_point(points, index, length = nil)
      points[index % (length || points.size)]
    end

    def draw(point_buffer, **options)
      # render mode
      #   points - treat the points, as well, points
      #   lines - treat the points as lines
      #   triangles - treat the points as triangles
      #   quads - treat the points as quads
      #   strips - treat the points as a strip polygon
      #   fan   - requires a point_count, will render the points in a wind
      #            strips will only work correctly if the point_count is
      #            3 or more
      mode = options.fetch(:mode, :lines)
      # render point count - how many points make up 1 point render
      point_count = options.fetch(:point_count) { mode_point_count(mode) }
      fan_length = options.fetch(:fan_length, 3)
      # how many frames to skip ahead
      offset = options.fetch(:offset, 0)
      ghost_offset = options.fetch(:ghost_offset, 0)
      # how many ghost frames (frames before the current) should rendered
      ghost_frames = options.fetch(:ghost_frames, 0)
      # rate modifier, affects how quickly or slowy a frame is ran, values
      # over 1 are a multiplier, values under 1 will increase the frames
      # required to fully render the animation
      rate_mod = options.fetch(:rate_mod) { ->(r) { r } }
      ghost_rate_mod = options.fetch(:ghost_rate_mod) { ->(r) { r } }
      # frame modifier, this normalizes a frame rate
      frame_mod = options.fetch(:frame_mod)
      ghost_frame_mod = options.fetch(:ghost_frame_mod, frame_mod)
      # stages - a number of intermediate points to generate from the given points
      # therefore simulating motion
      stages = options.fetch(:stages, @stages)
      # frames -
      frames = options.fetch(:frames, @frames)
      # range - when the animation should start and when it ends
      range = options[:range]
      # scale frames to range
      autoscale = options.fetch(:autoscale, true)

      point_clip = options.fetch(:point_clip, false)

      points = if stages > 0
        if !point_buffer.stage_points || point_buffer.stage_points.size != stages
          point_buffer.stage_points = make_stage_points(point_buffer.points, stages)
        end
        point_buffer.stage_points
      else
        point_buffer.points
      end

      frame_imgs = @frame_images
      frame_imgs = frame_imgs[range] if range
      frames = frames * frame_imgs.size / @frame_images.size if autoscale

      ghost_frames = [ghost_frames, 1].max
      offset += point_buffer.offset
      offset_r = offset / frames.to_f
      fps = 1.0 / frames.to_f

      frame_imgs.each_with_index do |img, img_frame_index|
        img_frame = img_frame_index / @frame_images.size.to_f
        true_frame = rate_mod.call(frames * img_frame) / frames.to_f
        stage_index = (offset + stages * img_frame).to_i
        frame_index = (offset + frames * img_frame).to_i
        stage = (stages * true_frame) / stages.to_f
        frame = frame_index / frames.to_f

        ghost_frames.times do |j|
          true_ghost = j / ghost_frames.to_f
          true_norm = frame_mod.call(true_frame - true_ghost * fps)

          index = (frame_mod.call((offset + frame_index - j)) * frames).to_i
          stage_point_index = (ghost_frame_mod.call((ghost_rate_mod.call(stage_index - j)) / stages.to_f) * stages).to_i

          stage_frame = frame_mod.call(stage_point_index / stages.to_f)
          ghost = frame_mod.call((offset - j) / ghost_frames.to_f)
          norm = frame_mod.call(frame - ghost * fps)
          ghost_frame = frame_mod.call(index / frames.to_f)

          if point_clip
            next if stage_point_index < 0 || points.size < stage_point_index
          end

          # timing variables
          #   frame: current frame (with offset)
          #   ghost: current ghost frame (with offset)
          #   norm: frame + ghost (with offset) (as substeps of 1 frame)
          #   ghost_frame: frame + ghost (with offset) (full steps)
          #   true_frame: current frame
          #   true_ghost: current ghost frame
          #   true_norm: ghost + frame
          timing = {
            frame: frame,
            ghost: ghost,
            norm: norm,
            ghost_frame: ghost_frame,
            stage_frame: stage_frame,
            true_frame: true_frame,
            true_ghost: true_ghost,
            true_norm: true_norm
          }

          pnt = get_point(points, stage_point_index)
          pnt = @vert_prog.call(timing.merge(pos: pnt))
          c = @frag_prog.call(timing.merge(color: color_decode(img.get_pixel(pnt[0], pnt[1]))))

          pnts = (point_count - 1).times.map do |pi|
            ind = stage_point_index - pi - 1
            next if point_clip && (ind < 0 || points.size < ind)
            prev_p = get_point(points, ind)
            @vert_prog.call(timing.merge(pos: prev_p))
          end.compact
          pnts << pnt

          case pnts.size
          when 1
            img.fill_rect(pnt[0], pnt[1], @point_size, @point_size, c)
          when 2
            draw_line(*pnts) do |x, y|
              img.fill_rect(x, y, @point_size, @point_size, c)
            end
          else
            case mode
            when :fan
              draw_line_fan pnts, fan_length do |x, y|
                img.fill_rect(x, y, @point_size, @point_size, c)
              end
            else
              draw_line_polygon pnts do |x, y|
                img.fill_rect(x, y, @point_size, @point_size, c)
              end
            end
          end
        end
      end
    end

    def save(dirname)
      frame_names = []
      @frame_images.each_with_index do |img, i|
        puts "\tSAVING FRAME #{i}"
        outimg = img
        outimg = img.scale(@scale) if @scale != 1
        filename = File.join(dirname, "frame_%04d.png" % i)
        File.delete(filename) if File.exist?(filename)
        outimg.save_file filename
        frame_names << filename
      end

      File.write('to_gif.sh', "#!/usr/bin/env bash\nmake_me_a_gif -d 6 -f #{dirname}.gif #{frame_names.join(' ')}")
    end
  end
end
