module JsonPatch
  class Pointer
    include Enumerable

    def initialize path
      @path = Pointer.parse path
    end

    def each(&block); @path.each(&block); end

    def eval object
      Pointer.eval @path, object
    end

    ESC = {'^/' => '/', '^^' => '^', '~0' => '~', '~1' => '/'} # :nodoc:

    def self.eval list, object
      list.inject(object) { |o, part|
        return nil unless o

        if Array === o
          raise Patch::IndexError unless part =~ /\A\d+\Z/
          part = part.to_i
        end
        o[part]
      }
    end

    def self.parse path
      return [''] if path == '/'

      path.sub(/^\//, '').split(/(?<!\^)\//).each { |part|
        part.gsub!(/\^[\/^]|~[01]/) { |m| ESC[m] }
      }
    end
  end
end
