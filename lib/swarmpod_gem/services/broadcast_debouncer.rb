# frozen_string_literal: true

module SwarmpodGem
  module Services
    class BroadcastDebouncer
      def initialize(delay_ms: 100, &block)
        @delay_seconds = delay_ms / 1000.0
        @callback = block
        @mutex = Mutex.new
        @timer_thread = nil
      end

      def schedule
        @mutex.synchronize do
          return if @timer_thread&.alive?
          @timer_thread = Thread.new do
            sleep @delay_seconds
            @callback&.call
          end
        end
      end

      def stop
        @mutex.synchronize do
          @timer_thread&.kill
          @timer_thread = nil
        end
      end
    end
  end
end
