class Truck < ActiveRecord::Base
  include Like
  @@cache = {}

  # Relations
  belongs_to :city
  has_many   :gigs, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { scope: :city }
  validates :city, presence: true

  # Callbacks
  before_destroy :relink

  # Scopes
  default_scope    ->   { order 'lower(name)' }
  scope :active,   ->   { joins(:gigs) }
  scope :inactive, ->   { where.not id:active.collect(&:id) }
  scope :like,     -> n { where id:select{|x| x.like? n }.collect(&:id) }

  def clones
    @clones ||= patterns.map do |pattern|
      city.trucks.where.not(id:id).like(pattern)
    end.flatten
  end

  def config
    @config ||= begin
      city.config.trucks[name]
    rescue NoMethodError
      nil
    end || {}
  end

  def like? name
    unless id.nil?
      @@cache[id] ||= {}
      @@cache[id][name] ||= super
    end
  end

  def master
    @master ||= city.trucks.where.not(id:id).like(name).first
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
    { name:name, site:site }
  end

  class << self
    def seed
      City.all.each do |city|
        city.config.trucks.each do |name, config|
          truck = city.trucks.find_or_create_by name:name
          truck.site ||= config['site']
          truck.save

          # Remove clones
          truck.clones.collect &:destroy
        end
      end
    end
  end
end
