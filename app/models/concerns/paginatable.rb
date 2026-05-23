# frozen_string_literal: true

module Paginatable
  extend ActiveSupport::Concern

  module ClassMethods
    module Inheritance
      def inherited(subclass)
        super
        subclass.per_page = per_page
      end
    end

    module WithContext
      attr_writer :context

      def context
        @context || 0
      end

      # Shared by all relations spawned from a `.page` call (clone copies the
      # reference, not the Hash), so memoized values survive `all.clone`.
      def pagination_memo
        @pagination_memo ||= {}
      end
    end

    def self.extended(base)
      base.extend Inheritance if base.is_a?(Class)
    end

    def page(page = nil, options = {})
      scope = scope_with_context(page.to_i > 1 ? options[:context].to_i : 0)
      scope
        .limit(pagination_limit + scope.context)
        .offset(pagination_offset(page.to_i) - scope.context)
    end

    delegate :context, to: :all

    def context?
      context != 0
    end

    def total_pages
      (total_count.to_f / (pagination_limit - context)).ceil
    end

    def current_page
      [
        (((all.offset_value || 0) + context) /
         (pagination_limit - context)) + 1,
        total_pages
      ].min
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
      scope = all
      memo = scope.pagination_memo if scope.respond_to?(:pagination_memo)
      return memo[:total_count] if memo&.key?(:total_count)

      count = scope.except(:limit, :offset, :order, :includes).count
      value = count.is_a?(Hash) ? count.length : count
      memo[:total_count] = value if memo
      value
    end

    def per_page
      defined?(@per_page) ? @per_page : 30
    end

    def per_page=(limit)
      @per_page = limit
    end

    private

    def pagination_limit
      all.limit_value || per_page
    end

    def pagination_offset(page = 1)
      [(pagination_limit * (page - 1)), 0].max
    end

    def scope_with_context(context)
      all.extend(WithContext).tap do |s|
        s.context = context
        s.pagination_memo
      end
    end
  end
end
