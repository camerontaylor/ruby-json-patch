module RubyJsonPatch
  class Pointer
    include Enumerable

    def initialize path, pather=Pather
      @pather=pather
      @path = pather.parse path
    end

    def each(&block); @path.each(&block); end

    def eval object
      @pather.eval @path, object
    end
  end
end
