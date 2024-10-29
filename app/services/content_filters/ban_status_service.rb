# frozen_string_literal: true

module ContentFilters
  class BanStatusService
    include Redisable
    include DatabaseHelper

    def check_and_ban_status(status_id)
      setting_filter_types = ['Content filters', 'Spam filters']

      with_read_replica do
        setting_filter_types.each do |setting_filter_type|
          server_setting = ContentFilters::ServerSetting.find_by(name: setting_filter_type)
          next unless server_setting&.value

          keyword_filter_groups = ContentFilters::KeywordFilterGroup.includes(:keyword_filters)
                                            .where(is_active: true, server_setting_id: server_setting.id)

          keyword_filter_groups.each do |keyword_filter_group|
            keyword_filter_group.keyword_filters.each do |keyword_filter|
              keyword = keyword_filter.keyword.downcase
              status = Status.find(status_id)

              if keyword_filter.hashtag? || keyword_filter.both?
                tag_id = status.tags.where(name: keyword.gsub('#', '')).ids
                redis.zadd('banned_status_ids', status.id, status.id) if tag_id.present?
              end
              if keyword_filter.both? || keyword_filter.content?
                redis.zadd('banned_status_ids', status.id, status.id) if status.search_word_ban(keyword_filter.keyword)
              end
            end
          end
        end
      end

      # Remove old first inserted status when the list size exceeds 400
      redis.zremrangebyrank('banned_status_ids', 0, -401) if redis.zcard('banned_status_ids') > 400
      puts "Banned status ids: #{redis.zrange('banned_status_ids', 0, -1)}"
      true
    end
  end
end