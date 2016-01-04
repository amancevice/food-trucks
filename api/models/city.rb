class City < ActiveRecord::Base
  include Firebase
  @@config = {}

  # Relations
  has_many :gigs,          dependent: :destroy
  has_many :neighborhoods, dependent: :destroy
  has_many :places,        dependent: :destroy
  has_many :providers,     dependent: :destroy
  has_many :trucks,        dependent: :destroy

  def config
    @@config[key] ||= CityConfig.new key unless key.nil?
  end

  def update
    # Remove old gigs
    gigs.expired.destroy_all

    gigs = providers.collect(&:gigs).flatten.select{|x| x.id.nil? }
    gigs.collect &:save!
    puts "Added #{gigs.count} gigs"
  end

  def serialize
    { name:name, key:key }
  end

  def sync_deprecated
    deprecated = syncdata_deprecated
    firebase.child(:v2_0).child(Firebase.normalize(key)).set deprecated
    firebase.child(:v1_2).child(Firebase.normalize(key)).set deprecated
    firebase.child(:v1_1).child(Firebase.normalize(key)).set deprecated
  end

  def syncdata
    Hash[gigs.collect{|x| [ x.uuid, x.serialize ] }]
  end

  def syncdata_deprecated
    gigs.map do |gig|
      gig.meals.map do |meal|
        mongoid      = "#{gig.uuid}-#{meal}"
        meal         = meal.to_s.split(/_/).map(&:capitalize).join(' ')
        neighborhood = (gig.place.neighborhood && gig.place.neighborhood.name) || 'Other'
        { mongoid =>
          { mongoid:       mongoid,
            name:          gig.truck.name,
            site:          gig.truck.site,
            day:           gig.weekday.capitalize,
            meal:          meal,
            neighborhood:  neighborhood,
            square:        gig.place.name,
            lat:           gig.place.latitude,
            lon:           gig.place.longitude,
            source:        gig.provider.type,
            created_at:    Time.now.utc,
            updated_at:    Time.now.utc,
            last_seen:     Time.now.utc,
            last_modified: Time.now.utc,
            deprecated:    false } }
      end
    end.flatten.reduce &:merge
  end

  class << self
    def seed
      boston = City.find_or_create_by(
        name:     'Boston',
        key:      'boston',
        timezone: 'America/New_York' )
      street_food    = 'http://data.streetfoodapp.com/1.1/schedule/boston/'
      city_of_boston = 'http://www.cityofboston.gov/foodtrucks/schedule-app-min.asp'
      boston.providers.find_or_create_by type:'StreetFood',   endpoint:street_food
      boston.providers.find_or_create_by type:'CityOfBoston', endpoint:city_of_boston

      vancouver = City.find_or_create_by(
        name:     'Vancouver',
        key:      'vancouver',
        timezone: 'Pacific Time (US & Canada)' )
      street_food = 'http://data.streetfoodapp.com/1.1/schedule/vancouver/'
      vancouver.providers.find_or_create_by type:'StreetFood', endpoint:street_food

      toronto = City.find_or_create_by(
        name:     'Toronto',
        key:      'toronto',
        timezone: 'Eastern Time (US & Canada)' )
      street_food = 'http://data.streetfoodapp.com/1.1/schedule/toronto/'
      toronto.providers.find_or_create_by type:'StreetFood', endpoint:street_food
    end
  end
end