require 'rubygems'
require 'configatron'

require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'xmpp4r/version/iq/version'

require 'utils/annotatable'
require 'shelper/base_plugin'
require 'shelper/agent'


Thread.abort_on_exception = true

module SHelper
  class << self
    # pass config file
    def start(argv = ARGV)
      if argv.size > 0
        configatron.configure_from_yaml(argv[0]) if test ?f, argv[0]
      else
        raise "Provide config file!"
      end

      configatron.log_dir = File.dirname(__FILE__) + "/../log/"
      logger.info("SHelper start")

      if configatron.xmpp.debug
        Jabber.logger = Logger.new "#{configatron.log_dir}/jabber.log"
      end

      Jabber.debug = configatron.xmpp.debug

      @agent = Agent.new

      load_plugins

      begin
        @agent.connect
        @agent.send_message(configatron.admin.jid, "Agent #{`hostname`.strip} reporting for duty at #{Time.now}", false)
        @agent.start_worker
      rescue Interrupt => ignore
      ensure
        @agent.disconnect
      end
    end

    def load_plugins
      # load system plugins
      load_plugins_from File.dirname(__FILE__) + "/../plugins/"

      # load other plugins
      plugins_dir = configatron.plugins_dir

      if plugins_dir && test(?d, plugins_dir)
        load_plugins_from plugins_dir
      end
    end

    def load_plugins_from(dir)
      Dir["#{File.expand_path dir}/**/*.rb"].each do |f|
        logger.debug "Loading plugin: #{f}"
        require f
      end
    end

    def register_plugin(klass)
      obj = klass.new
      obj.agent = @agent
      cmd_map = obj.init
      @agent.add_plugin(obj, cmd_map)
    end

    def logger
      @@logger ||= Logger.new "#{configatron.log_dir}/shelper.log"
    end
  end
end
