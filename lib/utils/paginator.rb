# frozen_string_literal: true

module Utils
  module Paginator
    DEFAULT_PAGE_SIZE = 30

    def initialize_pagination!
      @total_count = 0
      @offset = 0
      @per_page = DEFAULT_PAGE_SIZE
    end
    alias reset_pagination! initialize_pagination!

    def paginate
      # update_pagination
      @total_count = @result.length

      # OUTPUT
      @result[@offset, @per_page]
    end

    def next_page!
      @offset += @per_page
      @offset = @total_count if @offset > @total_count
    end

    def previous_page!
      @offset -= @per_page
      @offset = 0 if @offset.negative?
    end
  end
end
