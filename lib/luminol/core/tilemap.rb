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
      _area.make_current # Create the GL context
      GL.load_lib # Load the GL library
      # This order is specific lest we get a segfault because... reasons

      # Print out OpenGL version
      version = GL::GetString(GL::VERSION).to_s
      puts "OpenGL Version: #{version}\n"
      # Create the tilemap shader
      create_shader
    end
  end

  def create_shader
    # Get the path to the shaders
    base_path = File.join(__dir__, 'Shader', 'GeometryRenderer')

    vert_handle = compile_shader(File.read("#{base_path}.vert"), GL::VERTEX_SHADER)
    geom_handle = compile_shader(File.read("#{base_path}.geom"), GL::GEOMETRY_SHADER)
    frag_handle = compile_shader(File.read("#{base_path}.frag"), GL::FRAGMENT_SHADER)

    # Boilerplate
    @progam_handle = GL.CreateProgram
    GL.AttachShader(@progam_handle, vert_handle)
    GL.AttachShader(@progam_handle, geom_handle)
    GL.AttachShader(@progam_handle, frag_handle)
    GL.LinkProgram(@progam_handle)

    # Free up the shaders
    GL.DetachShader(@progam_handle, vert_handle)
    GL.DeleteShader(vert_handle)

    GL.DetachShader(@progam_handle, geom_handle)
    GL.DeleteShader(geom_handle)

    GL.DetachShader(@progam_handle, frag_handle)
    GL.DeleteShader(frag_handle)
    # Wow that was painful
  end

  def create_vbo
    vbo_buf = ' ' * 4
    GL.GenBuffers(1, vbo_buf)
    @vbo_handle = vbo_buf.unpack1('L')
    GL.BindBuffer(GL::ARRAY_BUFFER, @vbo_handle)

    GL.BufferData(GL::ARRAY_BUFFER, System.map.data.size * Fiddle::SIZEOF_SHORT, System.map.data.pack('S*'), GL::STATIC_DRAW)
  end

  def create_vao
    vao_buf = ' ' * 4
    GL.GenVertexArrays(1, vao_buf)
    @vao_handle = vao_buf.unpack1('L')
    GL.BindVertexArray(@vao_handle)

    GL.BindBuffer(GL::ARRAY_BUFFER, @vbo_handle)
    GL.EnableVertexAttribArray(0)
    GL.VertexAttribIPointer(0, 1, GL::VERTEX_ATTRIB_ARRAY_INTEGER, Fiddle::SIZEOF_SHORT, 0)
  end

  def compile_shader(source, type)
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
    if @vao_handle
      GL.DeleteVertexArrays(0, @vao_handle)
      GL.DeleteBuffers(0, @vbo_handle)
      @vbo_handle, @vao_handle = nil
    end
    create_vbo
    create_vao

    @atlas = TileAtlas.new
  end

  def render(area, _context)
    # Get the background color
    color = area.style.lookup_color('theme_bg_color')[1]

    # Fill in the tilemap with the background to make it look normal
    GL.ClearColor(color.red / MAX_C, color.green / MAX_C, color.blue / MAX_C, 1)
    GL.Clear(GL::COLOR_BUFFER_BIT)

    return unless @atlas

    @atlas.bind
    GL.BindVertexArray(@vao_handle)

    GL.Uniform2i(GL.GetUniformLocation(@progam_handle, "mapSize"), System.map.width, System.map.height)
    mat = [
      0,  0,  0,  0,
      0,  0,  0,  0,
      0,  0, -2,  0,
      -1, -1, -1, 1
    ]
    GL.UniformMatrix4fv(GL.GetUniformLocation(@progam_handle, "projection"), 1, GL::FALSE, mat.pack('F*'))

    GL.UseProgram(@progam_handle)
    GL.DrawArrays(GL::POINTS, 0, System.map.data.size)
    # Not sure why we need to return true but it works
    true
  end
end
