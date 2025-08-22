module ContentFilters::Concerns::TagConcern
  extend ActiveSupport::Concern

  def self.prepended(base)
    # Define instance-level scopes
    base.class_eval do
      scope :without_banned, -> { where(is_banned: false) }
    end

    # Override class methods
    base.singleton_class.class_eval do
      def matching_name(name_or_names, consider_ban_case=true)
        names = Array(name_or_names).map { |name| arel_table.lower(normalize(name)) }

        scope = if names.size == 1
          where(arel_table[:name].lower.eq(names.first))
        else
          where(arel_table[:name].lower.in(names))
        end
        
        scope = scope.where(is_banned: false) if consider_ban_case
        scope
      end

      def find_or_create_by_names(name_or_names)
        names = Array(name_or_names).map { |str| [normalize(str), str] }.uniq(&:first)

        names.map do |(normalized_name, display_name)|
          tag = matching_name(normalized_name, false).first || create(name: normalized_name,
                                                              display_name: display_name.gsub(HASHTAG_INVALID_CHARS_RE, ''))
          yield tag if block_given?
          tag
        end
      end
    end
  end
end