require 'httparty'

module HTTPartyWIthCookies
#  include HTTParty
  attr :cookies

  def self.included(base)
    base.extend HTTParty
    base.send :include, HTTParty
  end

  #####this way we can support the same http verbs as httparty
  HTTParty::Request::SupportedHTTPMethods.each do | netclass |
    method_sym = netclass.to_s.split('::').last.downcase.to_sym
    define_method method_sym do |uri, options={}, &block|

      base_options = {:headers => {'Cookie' => request_cookies} }
      if options
        options = base_options.merge options
      else
        options = base_options
      end
      options = options.delete_if{|k,v| v == {}}
      @last_response = self.class.method( method_sym ).call uri, options, &block
      set_cookies
      return @last_response
    end
  end


  private
    def request_cookies
      URI.unescape( @cookies.to_a.map do |cookie|
        cookie.join('=')
      end.join(';') )
    end
    def set_cookies
      response_cookies = @last_response.headers['set-cookie']
      return unless response_cookies and !response_cookies.empty?
      response_cookies = [ response_cookies ] if response_cookies.is_a? String
      response_cookies.each { |cookie|
        add_cookies( cookie.split(';')[0] )
      }
    end
    def add_cookies *cookies
      @cookies||= {}
      cookies.each do |cookie|
        key, value = cookie.split '='
        @cookies[ key ] = value
      end
    end
end

class Foo
  include HTTPartyWIthCookies
  debug_output $stderr
end

f = Foo.new
puts f.get( 'http://google.com').headers.inspect
f.get( 'http://google.com')