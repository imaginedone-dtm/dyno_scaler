# encoding: utf-8

module DynoScaler
  class Manager
    attr_accessor :options

    def scale_up(options)
      return unless config.enabled?

      self.options = options

      heroku.scale_workers(number_of_workers_needed) if scale_up?
    end

    def scale_up?
      workers_needed = number_of_workers_needed

      options[:pending] > 0 && workers_needed > options[:workers] && workers_needed <= config.max_workers
    end

    def scale_down(options)
      return unless config.enabled?

      self.options = options

      heroku.scale_workers(config.min_workers) if scale_down?
    end

    def scale_down?
      options[:workers] > config.min_workers && options[:pending] == 0 && options[:working] == 0
    end

    def scale_with(options)
      send(options[:action], options)
    end

    protected
      def config
        DynoScaler.configuration
      end

      def number_of_workers_needed
        value = config.job_worker_ratio.reverse_each.find do |_, pending_jobs|
          options[:pending] >= pending_jobs
        end

        value ? value.first : 0
      end

      def heroku
        @heroku ||= DynoScaler::Heroku.new config.application
      end
  end
end
