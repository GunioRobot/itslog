module Itslog
  module BufferedLoggerExtension
    extend ActiveSupport::Concern
    include Itslog::Configure
    attr_accessor :namespace

    def namespace
      @namespace ||= ''
    end

    def add_with_format(severity, message = nil, progname = nil, &block)
      return if @level > severity

      time    = Time.now.to_s(:db).split.last
      message = "\e[37m" + message.to_s.strip
      msg     = ''
      msg     << Itslog::Configure.color(namespace, severity)
      msg     << Itslog::Configure.format.dup
      {'%t' => time, '%n' => namespace, '%m' => message}.each do |k,v|
        msg.gsub! k, v if v.present?
      end

      add_without_format severity, msg, progname, &block
    end

    included do
      alias_method_chain :add, :format
    end
  end

  module LogSubscriberExtension
    extend ActiveSupport::Concern

    def call_with_namespace(message, *args)
      namespace = message.split('.').last if logger
      if logger.respond_to?(:namespace=)
        logger.namespace = namespace.present? ? namespace : ''
      end
      call_without_namespace(message, *args)
    end

    included do
      alias_method_chain :call, :namespace
    end
  end
end
