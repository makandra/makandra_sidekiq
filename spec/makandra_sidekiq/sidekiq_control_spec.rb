require 'makandra_sidekiq/sidekiq_control'

describe MakandraSidekiq::SidekiqControl do

  let(:root) { Pathname.new(File.expand_path('../fixtures/root', __dir__)) }
  let(:success) { instance_double(Process::Status, success?: true) }

  matcher :match_path do |expected|
    match do |actual|
      expand(actual) == expand(expected)
    end

    description do
      "be the same path as #{expected}"
    end

    failure_message do |actual|
      "expected #{actual} to be the same path as #{expected}"
    end

    failure_message_when_negated do |actual|
      "expected #{actual} not to be the same path as #{expected}"
    end

    def expand(path)
      Pathname.new(path).expand_path
    end
  end

  subject do
    control = described_class.new(root)
    allow(control).to receive(:puts)
    control
  end

  describe '#config validation' do
    let(:root) { Pathname.new(File.expand_path('../fixtures/root_with_empty_config', __dir__)) }

    it 'complains about missing config values' do
      expect {
        described_class.new(root)
      }.to raise_error(/does not set a :pidfile.*does not set a :logfile/m)
    end

  end

  describe '#quiet' do

    it 'runs "sidekiqctl quiet"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiqctl', 'quiet', match_path(root.join('tmp/pids/sidekiq.pid')),
        chdir: match_path(root)
      ).and_return(['', '', success])
      expect(subject).to receive(:running?).and_return(true)
      subject.quiet
    end

  end

  describe '#stop' do

    it 'runs "sidekiqctl stop"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiqctl', 'stop', match_path(root.join('tmp/pids/sidekiq.pid')),
        chdir: match_path(root)
      ).and_return(['', '', success])
      expect(subject).to receive(:running?).and_return(true)
      subject.stop
    end

  end

  describe '#start' do

    it 'runs "sidekiq start"' do
      expect(Open3).to receive(:capture3).with(
        'bundle', 'exec', 'sidekiq',
        '--index', '0',
        '--environment', 'test',
        '--config', match_path(root.join('config', 'sidekiq.yml')),
        '--daemon',
        chdir: match_path(root)
      ).and_return(['', '', success])
      expect(subject).to receive(:running?).and_return(false)
      subject.start
    end

    it 'uses the given RAILS_ENV' do
      begin
        old_env = ENV['RAILS_ENV']
        ENV['RAILS_ENV'] = 'rails_env'
        expect(Open3).to receive(:capture3) do |*arguments|
          expect(arguments).to include('rails_env')
          ['', '', success]
        end
        expect(subject).to receive(:running?).and_return(false)
        subject.start
      ensure
        ENV['RAILS_ENV'] = old_env
      end
    end

  end

end
