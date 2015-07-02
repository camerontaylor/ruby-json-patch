module RubyJsonPatch
  class Patch
    class Exception < StandardError
    end

    class FailedTestException < Exception
      attr_accessor :path, :value

      def initialize path, value
        super "expected #{value} at #{path}"
        @path  = path
        @value = value
      end
    end

    class OutOfBoundsException < Exception
    end

    class ObjectOperationOnArrayException < Exception
    end

    class IndexError < Exception
    end

    class MissingTargetException < Exception
    end

    def initialize is, options = {}
      @is = is
      @pather = options[:pather] || Pather.new
    end

    VALID = Hash[%w{ add move test replace remove copy }.map { |x| [x, x] }] # :nodoc:

    def apply doc
      @is.inject(doc) { |d, ins|
        send VALID.fetch(ins[OP].strip) { |k|
               raise Exception, "bad method `#{k}`"
             }, ins, d
      }
    end

    private

    PATH  = 'path' # :nodoc:
    FROM  = 'from' # :nodoc:
    VALUE = 'value' # :nodoc:
    OP    = 'op' # :nodoc:

    def add ins, doc
      list = @pather.parse ins[PATH]
      key  = list.pop
      dest = @pather.eval list, doc
      obj  = ins.fetch VALUE

      raise(MissingTargetException, ins[PATH]) unless dest

      if key
        add_op dest, key, obj
      else
        dest.replace obj
      end
      doc
    end

    def move ins, doc
      from     = @pather.parse ins.fetch FROM
      to       = @pather.parse ins[PATH]
      from_key = from.pop
      key      = to.pop
      src      = @pather.eval from, doc
      dest     = @pather.eval to, doc

      obj = rm_op src, from_key
      add_op dest, key, obj
      doc
    end

    def copy ins, doc
      from     = @pather.parse ins.fetch FROM
      to       = @pather.parse ins[PATH]
      from_key = from.pop
      key      = to.pop
      src      = @pather.eval from, doc
      dest     = @pather.eval to, doc

      if Array === src
        raise Patch::IndexError unless from_key =~ /\A\d+\Z/
        obj = src.fetch from_key.to_i
      else
        obj = src.fetch from_key
      end

      add_op dest, key, obj
      doc
    end

    def test ins, doc
      expected = @pather.new(ins[PATH]).eval doc

      unless expected == ins.fetch(VALUE)
        raise FailedTestException.new(ins[VALUE], ins[PATH])
      end
      doc
    end

    def replace ins, doc
      list = @pather.parse ins[PATH]
      key  = list.pop
      obj  = @pather.eval list, doc

      return ins.fetch VALUE unless key

      if Array === obj
        raise Patch::IndexError unless key =~ /\A\d+\Z/
        obj[key.to_i] = ins.fetch VALUE
      elsif obj.kind_of? ActiveRecord::Base
        obj.update_attributes({key => ins.fetch(VALUE)})
      else
        obj[key] = ins.fetch VALUE
      end
      doc
    end

    def remove ins, doc
      list = @pather.parse ins[PATH]
      key  = list.pop
      obj  = @pather.eval list, doc
      rm_op obj, key
      doc
    end

    def check_index obj, key
      return -1 if key == '-'

      raise ObjectOperationOnArrayException unless key =~ /\A-?\d+\Z/
      idx = key.to_i
      raise OutOfBoundsException if idx > obj.length || idx < 0
      idx
    end

    def add_op dest, key, obj
      # DT.p "Adding"
      # DT.p dest
      # DT.p dest.class
      if Array === dest
        dest.insert check_index(dest, key), obj
      elsif dest.kind_of? ActiveRecord::Base
        # DT.p "Modifying ActiveRecord object"
        dest.update_attributes({key => obj})
      elsif  ActiveRecord::Associations::CollectionProxy === dest
        newr = dest.build
        valid, invalid =  obj.partition {|k, v| newr.respond_to?(k + '=')}.map(&:to_h)
        DT.p valid
        DT.p invalid
        newr.update_attributes(valid) # Do the ones that work
        newr.update_attributes(invalid) # Then fail
      else
        # DT.p "Modifying basic object"
        dest[key] = obj
      end
    end

    def rm_op obj, key
      if Array === obj
        raise Patch::IndexError unless key =~ /\A\d+\Z/
        obj.delete_at key.to_i
      else
        obj.delete key
      end
    end
  end
end
