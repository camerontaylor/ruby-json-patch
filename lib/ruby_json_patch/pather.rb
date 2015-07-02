module RubyJsonPatch
  class Pather

    ESC = {'^/' => '/', '^^' => '^', '~0' => '~', '~1' => '/'} # :nodoc:

    def eval list, object
      # DT.p "Pather eval"
      list.inject(object) { |o, part|
        return nil unless o

        if Array === o
          raise Patch::IndexError unless part =~ /\A\d+\Z/
          part = part.to_i
        end
        o[part]
      }
    end

    def parse path
      return [''] if path == '/'

      path.sub(/^\//, '').split(/(?<!\^)\//).each { |part|
        part.gsub!(/\^[\/^]|~[01]/) { |m| ESC[m] }
      }
    end
  end
end
