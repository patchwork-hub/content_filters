# frozen_string_literal: true

module ContentFilters
  class BanStatusService
    include Redisable
    include DatabaseHelper

    def check_and_ban_status(status_id)
      setting_filter_types = ['Content filters', 'Spam filters']

      @status = Status.find(status_id)
      unless @status.sensitive?
        with_read_replica do
          setting_filter_types.each do |setting_filter_type|

            # The keys wil generated as below
            # 1.) content_filters_banned_status_ids
            # 2.) span_filters_banned_status_ids
            redis_key = "#{setting_filter_type.downcase.gsub(/\s+/, '_')}_banned_status_ids"

            server_setting = ContentFilters::ServerSetting.find_by(name: setting_filter_type)
            next unless server_setting&.value

            keyword_filter_groups = ContentFilters::KeywordFilterGroup.includes(:keyword_filters)
                                              .where(is_active: true, server_setting_id: server_setting.id)

            keyword_filter_groups.each do |keyword_filter_group|
              keyword_filter_group.keyword_filters.each do |keyword_filter|
                keyword = keyword_filter.keyword.downcase

                if keyword_filter.hashtag? || keyword_filter.both?
                  tag_id = @status.tags.where(name: keyword.gsub('#', '')).ids
                  redis.zadd(redis_key, @status.id, @status.id) if tag_id.present?
                end
                if keyword_filter.both? || keyword_filter.content?
                  redis.zadd(redis_key, @status.id, @status.id) if @status.search_word_in_status(keyword_filter.keyword)
                end
              end
            end
          end
        end

        # Combine banned status_ids both content & spam filters
        # And also remove if the records exceeded 400 limit
        return combine_banned_status_ids(status_id)
      end
    end

    def keyword_matches_in_status?(status_id, community_id, filter_type)
      @status = Status.find(status_id)
      filter_keywords = ContentFilters::CommunityFilterKeyword.where(patchwork_community_id: community_id, filter_type: filter_type)

      filter_keywords.any? do |keyword|
        if keyword.is_filter_hashtag
          tag_id = @status.tags.where(name: keyword.keyword).ids
          tag_id.present?
        else
          @status.search_word_in_status(keyword.keyword)
        end
      end
    end

    private

      def combine_banned_status_ids(status_id)
        banned_status_keys = ['excluded_status_ids', 'content_filters_banned_status_ids', 'spam_filters_banned_status_ids']
        redis.zunionstore(banned_status_keys[0], [banned_status_keys[1], banned_status_keys[2]] )

        # Trim the combined list if it exceeds 400 items
        banned_status_keys.each do |banned_status_key|
          if redis.zcard(banned_status_key) > 400
            redis.zremrangebyrank(banned_status_key, 0, -401)
          end
        end

        return true if redis.zscore("excluded_status_ids", status_id)
        false

      end

  end
end
