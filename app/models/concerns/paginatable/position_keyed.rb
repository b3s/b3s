# frozen_string_literal: true

module Paginatable
  module PositionKeyed
    extend ActiveSupport::Concern

    module Pagination
      attr_writer :pagination_offset, :context

      def pagination_offset
        @pagination_offset || 0
      end

      def context
        @context || 0
      end

      def pagination_memo
        @pagination_memo ||= {}
      end

      def current_page
        pagination_memo[:current_page] || 1
      end

      def total_pages
        (max_position.to_f / klass.per_page).ceil
      end

      def first_page
        1
      end

      def last_page
        total_pages
      end

      def first_page?
        current_page == first_page
      end

      def last_page?
        current_page == last_page
      end

      def previous_page
        current_page - 1 if current_page > 1
      end

      def next_page
        current_page + 1 if current_page < total_pages
      end

      def total_count
        return pagination_memo[:total_count] if pagination_memo.key?(:total_count)

        value = unscope(where: :position)
                .except(:limit, :offset, :order, :includes)
                .count
        value = value.length if value.is_a?(Hash)
        pagination_memo[:total_count] = value
        value
      end

      private

      def max_position
        return pagination_memo[:max_position] if pagination_memo.key?(:max_position)

        value = unscope(where: :position).maximum(:position) || 0
        pagination_memo[:max_position] = value
        value
      end
    end

    module ClassMethods
      def paginate_by_position(page = nil, options = {})
        page_num = [page.to_i, 1].max
        context = page_num > 1 ? options[:context].to_i : 0
        range = position_range_for_page(page_num, context)
        scope_for_position_page(range, context, page_num, options[:total_count])
      end

      private

      def position_range_for_page(page_num, context)
        first = ((page_num - 1) * per_page) + 1 - context
        first..(page_num * per_page)
      end

      def scope_for_position_page(range, context, page_num, total_count)
        scope = where(position: range).extending(Pagination)
        scope.pagination_offset = range.first - 1
        scope.context = context
        scope.pagination_memo[:current_page] = page_num
        scope.pagination_memo[:total_count] = total_count unless total_count.nil?
        scope
      end
    end
  end
end
