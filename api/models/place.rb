class Place < ActiveRecord::Base
  include Like, Locatable
  @@cache = { like:{}, near:{}, geo:{} }

  # Relations
  belongs_to :city
  belongs_to :neighborhood
  belongs_to :provider
  has_many   :gigs, dependent: :destroy

  # Validations
  validates :name, uniqueness: {scope: :neighborhood}
  validates :name, :city, presence: true

  # Geocoding
  geocoded_by         :long_name
  reverse_geocoded_by :latitude, :longitude, address: :name

  # Scopes
  scope :active,   ->         { joins(:gigs) }
  scope :floating, ->         { where("latitude is NULL or longitude is NULL") }
  scope :inactive, ->         { where.not id:active.collect(&:id) }
  scope :like,     -> n       { where id:select{|x| x.like? n          }.collect(&:id) }
  scope :nearby,   -> lat,lon { where id:select{|x| x.nearby? lat, lon }.collect(&:id) }
  scope :neargeo,  -> n,*args { @@cache[:geo][n] ||= near n, *args }
  scope :unknown,  ->         { where type:'Unknown' }
  scope :match, lambda{ |args|
    city     = args[:city]
    provider = args[:provider]
    name     = args[:name]
    lat      = args[:latitude]
    lon      = args[:longitude]
    search   = args[:search]
    dist     = args[:dist]

    # Find Place like or near
    place = like(name).first || nearby(lat, lon).first

    # Geocode location if lat/lon not provided
    search  = "#{name} #{city.name}"
    dist    = 0.025
    place ||= neargeo(search, dist, order:'distance').first if lat.nil? || lon.nil?

    # Create an Unknown place otherwise
    place ||= create! name:name, latitude:lat, longitude:lon, provider:provider, type:'Unknown'
  }

  # Callbacks
  before_validation :locate
  before_destroy :relink

  def clones
    @clones ||= patterns.map do |pattern|
      city.places.where.not(id:id).like(pattern)
    end.flatten
  end

  def config
    @config ||= begin
      neighborhood.config[:places][name]
    rescue NoMethodError
      nil
    end || {}
  end

  def like? name
    unless id.nil?
      @@cache[:like][id] ||= {}
      @@cache[:like][id][name] ||= super
    end
  end

  def locate
    # Find Neighborhood by lat, lon
    self.neighborhood ||= city.neighborhoods.containing(latitude, longitude).first
  end

  def long_name
    @long_name ||= "#{name} #{city.name}"
  end

  def master
    @master ||= city.places.where.not(id:id).like(name).first
  end

  def nearby? lat, lon
    unless id.nil?
      @@cache[:near][id] ||= {}
      @@cache[:near][id][[lat,lon]] ||= super
    end
  end

  def patterns
    @patterns ||= [ Regexp.new(Regexp.escape(name), Regexp::IGNORECASE) ] + (config['patterns'] || [])
  end

  def relink
    unless master.nil?
      puts "Relinking #{name} -> #{master.name}"
      gigs.map{|x| x.update place:master }
    end
  end

  def serialize
    { name:         name,
      type:         type,
      neighborhood: neighborhood ? neighborhood.name : 'Unknown',
      source:       provider     ? provider.type     : 'None',
      latitude:     latitude     ? latitude.to_f     : 0.0,
      longitude:    longitude    ? longitude.to_f    : 0.0 }
  end

  class << self
    def seed
      City.all.each do |city|
        city.neighborhoods.each do |neighborhood|
          places = neighborhood.config[:places] || {}
          places.each do |name, cfg|
            type     = cfg[:type.to_s]
            lat, lon = cfg[:latlon.to_s].split(/,/)
            place    = neighborhood.places.find_or_create_by(
              city: city,
              name: name,
              type: type )
            place.update latitude:lat, longitude:lon unless lat.nil? || place.latitude  == lat
            place.longitude = lon unless lon.nil? || place.longitude == lon

            # Remove clones
            place.clones.collect &:destroy
          end
        end
      end
    end
  end
end

class Intersection < Place
  def patterns
    super

    unless self.main.nil? || self.cross.nil?
      addenda = [
        Regexp.new("#{self.main} .*? #{self.cross}", Regexp::IGNORECASE),
        Regexp.new("#{self.cross} .*? #{self.main}", Regexp::IGNORECASE) ]
      addenda.each do |addendum|
        @patterns << addendum unless @patterns.include? addendum
      end
    end

    @patterns
  end

  def main
    self.config['main']
  end

  def cross
    self.config['cross']
  end
end

class Address < Place
  def patterns
    super

    unless self.street.nil? || self.number.nil?
      addendum = Regexp.new("#{self.number} .*?#{self.street}", Regexp::IGNORECASE)
      @patterns << addendum unless @patterns.include? addendum
    end

    @patterns
  end

  def street
    self.config['street']
  end

  def number
    self.config['number']
  end
end

class Landmark < Place
end

class Event < Place
end

class Unknown < Place
end
