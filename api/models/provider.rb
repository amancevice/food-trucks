class Provider < ActiveRecord::Base
  # Relations
  belongs_to :city
  has_many   :gigs

  # Callbacks
  after_initialize :configure

  def configure
    @cache = { timestamp:nil, response:nil, rows:nil }
  end

  def endpoint
    URI.parse read_attribute(:endpoint)
  end

  def response
    now = DateTime.now
    if @cache[:timestamp].nil? || (now - @cache[:timestamp]) > 1.hour
      @cache[:timestamp] = now
      @cache[:response]  = Net::HTTP.get self.endpoint
    end

    @cache[:response]
  end

  def gigs
    self.rows.map(&:gig).compact
  end
end

class JSONProvider < Provider
  def response
    JSON.parse super
  end
end

class HTMLProvider < Provider
  def response
    Oga.parse_html super
  end
end

class StreetFood < JSONProvider
  def rows
    @cache[:rows] ||= self.response['vendors'].to_a.select{|x| x.last['open'].any? }
    @cache[:rows].map do |row|
      handle, info = row
      truck    = info['name']
      site     = info['url']
      openings = info['open']
      openings.map do |opening|
        start     = Time.at(opening['start']).utc
        stop      = Time.at(opening['end']).utc
        place     = opening['display']
        latitude  = opening['latitude']
        longitude = opening['longitude']

        unless stop <= Time.now.utc
          ProviderRow[ truck:     truck,
                       city:      self.city,
                       site:      site,
                       start:     start,
                       stop:      stop,
                       place:     place,
                       latitude:  latitude,
                       longitude: longitude,
                       provider:  self ]
        end
      end
    end.flatten
  end
end

class CityOfBoston < HTMLProvider
  def rows
    @cache[:rows] ||= self.response.xpath("//tr[@class='trFoodTrucks']").map do |row|
      # Get HTML nodes
      a_node     = row.xpath(".//td[@class='com']/a").first
      dow_node   = row.xpath(".//td[@class='dow']").first
      tod_node   = row.xpath(".//td[@class='tod']").first
      place_node = row.xpath(".//td[@class='loc']").first

      # Get values from nodes
      truck = a_node.text.strip
      site  = a_node.attribute('href').value.strip
      place = place_node.children.last.text.strip

      # Get start/stop
      date = Chronic.parse(dow_node.text).to_date
      datetime = date.in_time_zone city.timezone

      case tod_node.text
      when 'Breakfast'
        start = (datetime + 5.hours ).utc
        stop  = (datetime + 11.hours).utc
      when 'Lunch'
        start = (datetime + 11.hours).utc
        stop  = (datetime + 16.hours).utc
      when 'Dinner'
        start = (datetime + 16.hours).utc
        stop  = (datetime + 20.hours).utc
      when 'Late Night'
        start = (datetime + 20.hours).utc
        stop  = (datetime + 25.hours).utc
      end

      unless stop <= Time.now.utc
        ProviderRow[ truck:     truck,
                     city:      self.city,
                     site:      site,
                     start:     start,
                     stop:      stop,
                     place:     place,
                     latitude:  nil,
                     longitude: nil,
                     provider:  self ]
      end
    end
  end
end

class ProviderRow < Hash
  def gig
    city       = self[:city]
    lat        = self[:latitude]
    lon        = self[:longitude]
    place_name = self[:place]
    truck_name = self[:truck]
    provider   = self[:provider]
    site       = self[:site]
    start      = self[:start]
    stop       = self[:stop]
    search     = "#{place_name} #{city.name}"
    dist       = 0.025

    # Truck
    truck = city.trucks.like(truck_name).first ||
            (site ? city.trucks.find_by(site:site) : nil) ||
            city.trucks.find_or_create_by(name:truck_name)
    truck.site ||= site
    truck.save!

    # Find Place like or near
    place = city.places.match(
      city:      city,
      name:      place_name,
      latitude:  lat,
      longitude: lon,
      search:    search,
      dist:      dist,
      provider:  provider )

    # Gig
    city.gigs.find_or_initialize_by(
      truck:    truck,
      city:     city,
      place:    place,
      start:    start,
      stop:     stop,
      provider: provider )
  end
end
