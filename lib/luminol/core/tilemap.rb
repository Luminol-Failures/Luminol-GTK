require 'opengl'
require 'gtk3'

require_relative 'tileatlas'

MAX_C = 65535.0
USHORT_MAX = 65535

class Tilemap
  def initialize(area)
    @area = area

    area.signal_connect 'render' do |_area, _context|
      render _area, _context
    end

    area.signal_connect 'realize' do |_area, _context|
      puts 'realize'
      _area.make_current # Create the GL context
      GL.load_lib # Load the GL library
      # This order is specific lest we get a segfault because... reasons

      # Print out OpenGL version
      version = GL::GetString(GL::VERSION).to_s
      puts "OpenGL Version: #{version}\n"
      # Create the tilemap shader
      create_vao
      create_vbo
      create_shader
    end
  end

  def create_shader
    # Get the path to the shaders
    # base_path = File.join(__dir__, 'Shader', 'GeometryRenderer')

    vertex_source = <<~VERT
      #version 400
      in vec3 vp;
      void main () {
        gl_Position = vec4 (vp, 1.0);
      };
    VERT
    fragment_source = <<~FRAG
      #version 400
      out vec4 frag_colour;
      void main () {
        frag_colour = vec4 (0.5, 0.0, 0.5, 1.0);
      };
    FRAG
    @vertex_handle = compile_shader(GL::VERTEX_SHADER, vertex_source)
    @fragment_handle = compile_shader(GL::FRAGMENT_SHADER, fragment_source)

    @program_handle = GL.CreateProgram
    GL.AttachShader(@program_handle, @vertex_handle)
    GL.AttachShader(@program_handle, @fragment_handle)
    GL.LinkProgram(@program_handle)

    # Wow that was painful
  end

  def create_vao
    vao_buf = ' ' * 4
    GL.GenVertexArrays(1, vao_buf)
    @vao = vao_buf.unpack1('L')

    GL.BindVertexArray(@vao)
  end

  def create_vbo
    points = [
      0.0, 0.5, 0.0,  # x1, y1, z1
      0.5, -0.5, 0.0, # x2, y2, z2
      -0.5, -0.5, 0.0 # x3, y3, z3
    ]

    vbo_buf = ' ' * 4
    GL.GenBuffers(1, vbo_buf)
    @vbo = vbo_buf.unpack1('L')

    GL.BindBuffer(GL::ARRAY_BUFFER, @vbo)
    GL.BufferData(GL::ARRAY_BUFFER, 3 * 4 * Fiddle::SIZEOF_FLOAT, points.pack('F*'), GL::STATIC_DRAW)
    GL.EnableVertexAttribArray(0)
    GL.VertexAttribPointer(0, 3, GL::FLOAT, GL::FALSE, 0, 0)

    GL.BindVertexArray(0)
  end

  def compile_shader(type, source)
    handle = GL.CreateShader(type)
    GL.ShaderSource(handle, 1, [source].pack('p'), [source.bytesize].pack('I'))
    GL.CompileShader(handle)

    # More boilerplate to check if the shader compiled okay
    compiled_buf = ' ' * 4
    GL.GetShaderiv(handle, GL::COMPILE_STATUS, compiled_buf)
    compiled = compiled_buf.unpack1('L')
    if compiled == 0
      log = ' ' * 1024
      GL.GetShaderInfoLog(handle, 1023, nil, log)
      puts "Shader Compile Info Log:\n#{log}\n"
      return false
    end
    return handle
  end

  def prepare
    @atlas&.dispose

    @atlas = TileAtlas.new
  end

  def render(area, _context)
    puts 'render'
    # Get the background color
    color = area.style.lookup_color('theme_bg_color')[1]

    # Fill in the tilemap with the background to make it look normal
    GL.ClearColor(color.red / MAX_C, color.green / MAX_C, color.blue / MAX_C, 1)
    GL.Clear(GL::COLOR_BUFFER_BIT)

    GL.UseProgram(@program_handle)
    GL.BindVertexArray(@vao)
    GL.DrawArrays(GL::TRIANGLES, 0, 3)

    # Not sure why we need to return true but it works
    true
  end
end
