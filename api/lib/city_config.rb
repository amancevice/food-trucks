class CityConfig
  def initialize city
    @city          = city
    @neighborhoods = nil
    @trucks        = nil
  end

  def neighborhoods
    @neighborhoods ||= begin
      yaml = YAML.load_file path('neighborhoods.yaml') || {}
      yaml = yaml.map{|k,v| { k => { :places => v } } }.reduce &:deep_merge
      yaml.deep_merge kml || {}
    end
  end

  def trucks
    @trucks ||= begin
      yaml = YAML.load_file(path('trucks.yaml')) || {}
      yaml = yaml.map do |truck,config|
        { truck => config||{} }
      end.reduce &:merge
    end || {}
  end

  private

  def root
    (__FILE__.split('/')[0..-3] + ['config']).join '/'
  end

  def path filename
    [root, @city, filename].join('/')
  end

  def kml
    xml = Oga.parse_xml open(path('neighborhoods.kml'))
    xml.xpath('//Placemark').map do |placemark|
      name         = placemark.xpath('./name').text
      coordinates  = placemark.xpath('./Polygon//coordinates').text
      coordinates  = coordinates.split(/ /).map{|x| x.split(/,/) }
      coordinates << coordinates[0] unless coordinates.first == coordinates.last
      coordinates.map!{|lon,lat| [lat.to_f, lon.to_f] }

      { name => { polygon: coordinates } }
    end.reduce &:deep_merge
  end
end
