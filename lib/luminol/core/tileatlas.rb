require 'opengl'
require_relative '../core/texture'

class TileAtlas
  def initialize
    @tileset_tex = Texture.new 'Graphics', 'Tilesets', System.tileset.tileset_name
  end

  def bind
    @tileset_tex.bind
  end

  def dispose
    @tileset_tex.delete
  end
end
