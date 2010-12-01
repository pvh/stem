module Stem
  module Tag
    include Util
    extend self

    def create resource_ids, tags
      resource_ids = [ resource_ids ] unless resource_ids.is_a? Array
      swirl.call("CreateTags", tag_opts(tags).merge("ResourceId" => resource_ids) )
    end

    def destroy resource_ids, tags
      resource_ids = [ resource_ids ] unless resource_ids.is_a? Array
      swirl.call("DeleteTags", tag_opts(tags).merge("ResourceId" => resource_ids) )
    end

    def tag_opts(tags)
      if tags.is_a? Array
        {
          "Tag.#.Key" => tags,
          "Tag.#.Value" => (1..tags.size).map { '' }
        }
      else
        { "Tag.1.Key" => tags.to_s, "Tag.1.Value" => '' }
      end
    end

  end
end