namespace :db
  desc 'Refresh MongoDB'
  task :mongo do
    require 'mongo'
    require 'uri'

    include Mongo

    # Connection details
    uri  = URI.parse ENV['MONGOHQ_URL']||''
    host = uri.host||'localhost'
    port = uri.port||MongoClient::DEFAULT_PORT
    dbn  = uri.path.empty? ? 'development' : uri.path.gsub(/^\//, '')
    user = uri.user
    pass = uri.password

    # Connect to MongoDB and flush collection
    connection = Mongo::Connection.new(host, port).db dbn
    connection.authenticate user, pass unless user.nil? || pass.nil?

    response = Net::HTTP.get URI.parse('http://bft-api.herokuapp.com/2.0/boston')


    # Cities
    coll = connection.collection('cities')
    cities = City.all.map{|x| {'name' => x.name} }
    coll.remove
    coll.insert cities

    # Neighborhoods
    coll = connection.collection('neighborhoods')
    neighborhoods = Neighborhood.all.map{|x| {'city' => x.city.name, 'name' => x.name} }
    coll.remove
    coll.insert neighborhoods

    # Trucks
    coll = connection.collection('trucks')
    trucks = Truck.all.map{|x| {'city' => x.city.name, 'name' => x.name, 'site' => x.site} }
    coll.remove
    coll.insert trucks

    # Locations
    coll = connection.collection('locations')
    locations = Location.all.map{|x| x.serialize.merge({city:x.city.name}) }
    coll.remove
    coll.insert locations
  end
end