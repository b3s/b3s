# frozen_string_literal: true

module Paginatable
  module PositionKeyed
    extend ActiveSupport::Concern

    module Pagination
      attr_writer :pagination_offset

      def pagination_offset
        @pagination_offset || 0
      end
    end

    class_methods do
      def page(page = nil, options = {})
        page_num = [page.to_i, 1].max
        context = page_num > 1 ? options[:context].to_i : 0
        position_range = page_position_range(page_num, context)
        paginate_by_position(position_range, context, page_num,
                             options[:total_count])
      end

      def current_page
        scope = all
        return 1 unless scope.respond_to?(:pagination_memo)

        scope.pagination_memo[:current_page] || 1
      end

      private

      def page_position_range(page_num, context)
        first = ((page_num - 1) * pagination_limit) + 1 - context
        first..(page_num * pagination_limit)
      end

      def paginate_by_position(range, context, page_num, total_count)
        scope = scope_with_context(context, total_count:)
                .where(position: range)
                .extending(Pagination)
        scope.pagination_offset = range.first - 1
        scope.pagination_memo[:current_page] = page_num
        scope
      end
    end
  end
end
