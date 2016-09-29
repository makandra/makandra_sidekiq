require 'pathname'
require 'yaml'
require 'open3'
require 'erb'

module MakandraSidekiq
  class SidekiqControl

    CONFIG_PATH = ['config', 'sidekiq.yml']

    def initialize(root)
      @root = Pathname.new(root)
      @config = load_config
    end

    def quiet
      if running?
        puts 'Preventing Sidekiq from accepting new jobs...'
        run_sidekiqctl('quiet')
      else
        puts 'Sidekiq is not running.'
      end
    end

    def stop
      if running?
        puts 'Stopping Sidekiq...'
        run_sidekiqctl('stop')
      else
        puts 'Sidekiq is not running.'
      end
    end

    def start
      if running?
        puts 'Sidekiq is already running.'
      else
        puts 'Starting Sidekiq...'
        run_sidekiq
      end
    end

    private

    def rails_env
      @rails_env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def config_path
      @config_path ||= @root.join(*CONFIG_PATH)
    end

    def pid_file
      @pid_file ||= @root.join(@config[:pidfile])
    end

    def pid
      @pid ||= if pid_file.file?
        pid_file.read.to_i
      end
    end

    def running?
      Process.kill(0, pid) if pid
    rescue Errno::ESRCH
      # not running
      false
    end

    def load_config
      messages = []
      begin
        config_erb = ERB.new(config_path.read)
        config = YAML.load(config_erb.result)
      rescue
        messages << "Error: Could not load #{config_path}."
      end
      if config
        env_config = config[rails_env]
        config.merge!(env_config) if env_config
        unless config[:pidfile]
          messages << "Error: #{config_path} does not set a :pidfile"
        end
        unless config[:logfile]
          messages << "Error: #{config_path} does not set a :logfile."
        end
      end
      if messages.any?
        fail messages.join("\n")
      end
      config
    end

    def run_sidekiqctl(command)
      bundle_exec('sidekiqctl', command, pid_file.to_s)
    end

    def run_sidekiq
      arguments = [
        '--index', sidekiq_index.to_s,
        '--environment', rails_env,
        '--config', config_path.to_s,
        '--daemon'
      ]
      bundle_exec('sidekiq', *arguments)
    end

    def sidekiq_index
      ENV['SIDEKIQ_INDEX'] || 0
    end

    def bundle_exec(*command)
      stdout_str, stderr_str, status = Open3.capture3('bundle', 'exec', *command, chdir: @root.to_s)
      puts stdout_str
      unless status.success?
        fail "Sidekiqctl failed with message: #{stderr_str}"
      end
    end

  end
end
