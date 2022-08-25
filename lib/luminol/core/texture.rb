require 'opengl'

class Texture

  attr_reader :id, :height, :width

  def initialize(*paths)
    pixbuf = System::Cache.load_image(*paths)

    @width, @height = pixbuf.width, pixbuf.height
    pixels = pixbuf.pixels

    id_buf = ' ' * 4
    GL.GenTextures(1, id_buf)
    @id = id_buf.unpack1('L')

    bind
    GL.TexImage2D(
      GL::TEXTURE_2D,
      0,
      GL::RGB,
      @width,
      @height,
      0,
      GL::RGB,
      GL::UNSIGNED_BYTE,
      pixels.pack("C#{pixels.size}")
    )
    unbind
  end

  def bind
    GL.BindTexture(GL::TEXTURE_2D, @id)
  end

  def unbind
    GL.BindTexture(GL::TEXTURE_2D, 0)
  end

  def delete
    GL.DeleteTextures(1, [@id].pack('L'))
  end
end
