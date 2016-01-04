load "./Rakefile"

class FoodTruckAtlasService < Sinatra::Base
  register Sinatra::Cache

  # Locate neighborhood
  get '/:api/:city/locate' do
    content_type :json

    city = City.find_by key:params['city'].downcase
    location = begin
      lat_lon = params.keys.select{|x| x =~ /\A@/ }.first
      if lat_lon.nil?
        lat, lon = [params['lat'], params['lon']].collect &:to_f
      else
        lat, lon = lat_lon.scan(/@(.*?),(.*)/).flatten.collect &:to_f
      end
      neighborhood = city.neighborhoods.containing(lat, lon).first
      { neighborhood:neighborhood.name }
    rescue NoMethodError
      { neighborhood:nil }
    end

    location.to_json
  end

  get '/:api/:city' do
    content_type :json
    locations = get_locations params

    locations.to_json
  end

  post '/:api/:city' do
    content_type :json
    request.body.rewind
    locations = get_changes params, request.body.read

    locations.to_json
  end

  # DEPRECATED METHODS

  get '/' do
    content_type :json
    locations = get_locations({'api' => '1.1', 'city' => 'boston'})
    locations.to_json
  end

  post '/' do
    content_type :json
    request.body.rewind
    changes = get_changes({'api' => '1.1', 'city' => 'boston'}, request)
    changes.to_json
  end

  private

  def get_locations params
    api  = Gem::Version.new params['api']
    city = City.find_by key:params['city'].downcase

    # Turn Firebase into old-style JSON
    @locations = settings.cache.fetch("#{api.version}/#{city.key}", expires_in:1.hour) do
      begin
        apistr = "v#{api.version.sub(/\./, '_')}"
        begin
          city.firebase.child(apistr).child(city.key).read
        rescue Bigbertha::Faults::NoDataError
          {}
        end
      end
    end

    # API helpers
    if api < Gem::Version.new('3.0')
      @locations = @locations.values
      @locations.reject!{|x| x['lat'].nil?||x['lon'].nil? }
    end
    if api < Gem::Version.new('2.0')
      @locations.reject!{|x| x['meal'] == 'Late Night'}
      @locations.each do |location|
        location['created_at']    = Time.parse(location['created_at']).to_i
        location['updated_at']    = Time.parse(location['updated_at']).to_i
        location['last_seen']     = Time.parse(location['last_seen']).to_i
        location['last_modified'] = Time.parse(location['last_modified']).strftime('%Y-%m-%d %H:%M:%S UTC')
      end
    end
    if api < Gem::Version.new('1.2')
      scrub_apos
    end

    { locations:@locations }
  end

  def get_changes params, request_body
    get_locations params
    ids = begin
      JSON.parse(request_body)['mongoids']
    rescue
      nil
    end || []

    insertions   = @locations.reject{|x| ids.include? x['mongoid'] }
    deprecations = (ids - @locations.collect{|x| x['mongoid']}).map{|x| {mongoid:x} }

    { insertions:insertions, deprecations:deprecations }
  end


  # This is unfortunate but I F'd up older versions of the
  # Android app so until everyone is on 9+ I need to keep it
  def scrub_apos
    @locations = @locations.map do |location|
      location.map do |key, val|
        { key => val.to_s.gsub(/'/,'') }
      end.reduce &:merge
    end
  end

end