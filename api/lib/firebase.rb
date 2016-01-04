module Firebase
  def firebase *args
    @firebase ||= Firebase.ref *args
  end

  def firedata *args
    begin
      firebase.read
    rescue Bigbertha::Faults::NoDataError
      {}
    end
  end

  class << self
    def normalize name
      name.gsub(/[\.\$#\[\]\/]/, '')
    end

    def ref *args
      home   = ENV['FIREBASE_HOME']
      secret = ENV['FIREBASE_SECRET']
      user   = ENV['FIREBASE_USER']
      token  = Firebase::FirebaseTokenGenerator.new(secret).create_token user:user
      ref    = Bigbertha::Ref.new home, token

      args.reduce ref, :child
    end
  end
end
