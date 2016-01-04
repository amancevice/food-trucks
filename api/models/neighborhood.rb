class Neighborhood < ActiveRecord::Base
  # Relations
  belongs_to :city
  has_many   :gigs,   dependent: :destroy
  has_many   :places, dependent: :destroy

  # Validations
  validates :name, uniqueness: {scope: :city}
  validates :name, :city, presence: true

  # Scopes
  default_scope -> { order 'lower(name)' }
  scope :containing, -> lat, lon { where id:select{|x| x.contains? lat, lon }.collect(&:id) }

  def config
    @config ||= begin
      self.city.config.neighborhoods[self.name]
    rescue NoMethodError
      nil
    end || {}
  end

  def polygon
    @polygon ||= begin
      coords = self.config[:polygon] || []
      BorderPatrol::Polygon.new coords.map{|x,y| BorderPatrol::Point.new x, y }
    rescue BorderPatrol::InsufficientPointsToActuallyFormAPolygonError
      nil
    end
  end

  def contains? latitude, longitude
    begin
      self.polygon.contains_point? BorderPatrol::Point.new(latitude, longitude)
    rescue NoMethodError
      nil
    end
  end

  class << self
    def seed
      City.all.each do |city|
        city.config.neighborhoods.each do |name, cfg|
          city.neighborhoods.find_or_create_by name:name
        end
      end
    end
  end
end