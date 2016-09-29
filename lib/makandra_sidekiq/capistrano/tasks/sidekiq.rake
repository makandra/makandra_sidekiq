namespace :sidekiq do

  def run_task(name, allow_missing_task: false)
    on roles :sidekiq do
      within release_path do
        with rails_env: fetch(:rails_env) do
          if !allow_missing_task || test(:rake, "-T sidekiq:#{name} | grep sidekiq:#{name}")
            execute :rake, "sidekiq:#{name}"
          end
        end
      end
    end
  end

  desc 'Quiet sidekiq (stop processing new tasks)'
  task :quiet do
    run_task('quiet', allow_missing_task: true)
  end

  desc 'Stop sidekiq'
  task :stop do
    run_task('stop')
  end

  desc 'Start sidekiq'
  task :start do
    run_task('start')
  end

  desc 'Restart sidekiq'
  task :restart do
    run_task('restart')
  end
end

after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:updated', 'sidekiq:stop'
after 'deploy:reverted', 'sidekiq:stop'
after 'deploy:published', 'sidekiq:start'
