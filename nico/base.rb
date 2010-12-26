# -*- coding: utf-8 -*-

####################################
# Base
####################################

module Nicovideo
  
  # constant values
  BASE_URL    = 'http://www.nicovideo.jp'
  BASE_HOST   = 'www.nicovideo.jp'
  EXT_HOST    = 'ext.nicovideo.jp'
  FLAPI_HOST  = 'flapi.nicovideo.jp'
  WATCH_PATH  = '/watch/'
  
  GETFLV_PATH       = '/api/getflv/'
  GETFLV_QUERY      = '?as3=1'
  GETTHUMBINFO_PATH = '/api/getthumbinfo/'
  BUFFER_SIZE       = 1024*1024
  
  # proxy configuration
  PROXY_HOST = nil
  PROXY_PORT = 3128
  
  # error classes
  class AuthenticationError < StandardError; end
  class VideoNotFoundError  < StandardError; end
  class AccessLockedError   < StandardError; end
  
  class Base
    
    LOGIN_HOST = 'secure.nicovideo.jp'
    LOGIN_PATH = '/secure/login?site=niconico'
    
    ####################################
    # login operations
    ####################################
    
    def initialize(mail=nil, password=nil)
      @mail      = mail
      @password  = password
      @session   = nil
      @videopage = nil
      @logged_in = false
      self
    end
    
    def login(mail=nil, password=nil)
      unless logged_in?
        @mail     ||= mail
        @password ||= password
        
        https = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT).new(LOGIN_HOST, 443)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.start {|w|
          body = "mail=#{@mail}&password=#{@password}"
          response = w.post(LOGIN_PATH, body)
          response['Set-Cookie'] =~ /(user_session=user_session[0-9_]+)/
          @session = $1 || nil
        }
        @logged_in = true
      end
      # raise exception
      raise AuthenticationError.new unless @session
      self
    end
    
    def logged_in?()
      @logged_in
    end
    
    ####################################
    # sub class operations
    ####################################
    
    def watch(video_id)
      videopage = Videopage.new(@session, video_id)
      yield videopage if block_given?
      videopage
    end
    
    def mylist(mylist_id)
      mylist = Mylist.new(@session, mylist_id)
      yield mylist if block_given?
      mylist
    end
    
    def deflist
      deflist = Deflist.new(@session)
      yield deflist if block_given?
      deflist
    end
  end
  
  ####################################
  # dummy operations
  ####################################
  
  def Nicovideo.new(mail, password)
    Base.new(mail, password)
  end
  
  def Nicovideo.login(mail, password)
    Base.new(mail, password).login
  end
end
