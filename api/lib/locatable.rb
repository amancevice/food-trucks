module Locatable

  def nearby? lat, lon
    # True if point within a 50m radius
    unless lat.nil? || lon.nil? || self.latitude.nil? || self.longitude.nil?
      max  = 50.0
      r    = 6371.0
      dlat = radians lat - self.latitude
      dlon = radians lon - self.longitude
      a    = Math::sin(dlat/2.0) ** 2 +
             Math::cos(radians self.latitude) *
             Math::cos(radians lat) *
             Math::sin(dlon/2.0) ** 2
      c    = 2.0 * Math::atan2(Math::sqrt(a), Math::sqrt(1.0 - a))

      r * c * 1000.0 <= max
    end
  end

  private

  def radians degrees
    degrees * Math::PI/180.0
  end
end
