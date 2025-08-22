module ContentFilters::Concerns::TagConcern
  extend ActiveSupport::Concern

  def self.prepended(base)
    # Define instance-level scopes
    base.class_eval do
      scope :without_banned, -> { where(is_banned: false) }
    end

    # # Override class methods
    # base.singleton_class.class_eval do
    #   def matching_name(name_or_names)
    #     names = Array(name_or_names).map { |name| arel_table.lower(normalize(name)) }

    #     if names.size == 1
    #       where(arel_table[:name].lower.eq(names.first)).where(is_banned: false)
    #     else
    #       where(arel_table[:name].lower.in(names)).where(is_banned: false)
    #     end
    #   end
    # end
  end
end