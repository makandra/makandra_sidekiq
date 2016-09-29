module MakandraSidekiq
  if defined?(::Rails::Railtie)
    class Railtie < ::Rails::Railtie

      rake_tasks do
        load File.expand_path('tasks/sidekiq.rake', __dir__)
      end

    end
  end
end
