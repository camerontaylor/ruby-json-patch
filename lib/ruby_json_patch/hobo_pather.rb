module RubyJsonPatch
  class HoboPather < Pather
    def initialize (acting_user)
      @acting_user = acting_user
      @records_modified = []
    end

    attr_reader :records_modified

    def save
      @records_modified.*.save
    end

    def eval list, object
      result = list.inject(object) { |o, part|
        # DT.p "Part: #{part}"
        # DT.p "o: #{o}"
        # DT.p "o.class: #{o.class.name}"
        return nil unless o
        result = nil
        # binding.pry

        if Array === o
          # DT.p "o: #{o}"
          raise Patch::IndexError unless part =~ /\A\d+\Z/
          result = o[part.to_i]
        elsif ActiveRecord::Associations::CollectionProxy === o
          raise Patch::IndexError unless part =~ /\A\d+\Z/
          result = o.find(part.to_i)
        elsif o.kind_of?(Class) && o < ActiveRecord::Base
          raise Patch::IndexError unless part =~ /\A\d+\Z/
          result = o.find(part.to_i)
        elsif o.respond_to?(part)
          result = o.send(part)
        else
          result = o[part]
        end
        if result.respond_to?(:update_permitted?)
          @records_modified.push(result)
          raise "Update permission denied" unless result.with_acting_user(@acting_user) {result.update_permitted?}
        end
        result
      }
      if ActiveRecord::Associations::CollectionProxy === result
        raise "Update permission denied" unless result.with_acting_user(@acting_user) {
          result.model.new.update_permitted?
        }
      end
      # if result < ActiveRecord::Base
      #   raise "Update permission denied" unless result.with_acting_user(@acting_user) {
      #     result.new.update_permitted?
      #   }
      # end

      if result.respond_to?(:update_permitted?)
        @records_modified.push(result)
        raise "Update permission denied" unless result.with_acting_user(@acting_user) {result.update_permitted?}
      end
      # DT.p result
      result
    end

  end
end