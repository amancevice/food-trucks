class Gig < ActiveRecord::Base
  # Relations
  belongs_to :truck
  belongs_to :city
  belongs_to :place
  belongs_to :provider

  # Validations
  validates :truck, :city, :place, :provider, :start, :stop, presence: true

  # Callbacks
  after_validation{ self.uuid = SecureRandom.hex 8 }

  # Scopes
  scope :expired, -> { where 'stop < ?', Time.now.utc }
  scope :weekday, -> wday { where id:select{|x| x.weekday == wday }.map(&:id) }
  scope :sunday,    -> { weekday Day::SUNDAY    }
  scope :monday,    -> { weekday Day::MONDAY    }
  scope :tuesday,   -> { weekday Day::TUESDAY   }
  scope :wednesday, -> { weekday Day::WEDNESDAY }
  scope :thursday,  -> { weekday Day::THURSDAY  }
  scope :friday,    -> { weekday Day::FRIDAY    }
  scope :saturday,  -> { weekday Day::SATURDAY  }
  scope :meal, -> meal { where id:select{|x| x.meals.include? meal }.map(&:id) }
  scope :breakfast,  -> { meal Meal::BREAKFAST  }
  scope :lunch,      -> { meal Meal::LUNCH      }
  scope :dinner,     -> { meal Meal::DINNER     }
  scope :late_night, -> { meal Meal::LATE_NIGHT }

  def weekday
    @weekday ||= begin
      Hash[(0..6).zip Day.all][self.start.wday]
    end
  end

  def meals
    @meals ||= begin
      range = self.start.to_i..self.stop.to_i
      hours = range.step(1.hour).map{|x| Time.at(x).in_time_zone(self.city.timezone).hour }
      meals = []
      meals << Meal::BREAKFAST  if hours.map{|x|  (5...11).include? x }.include? true
      meals << Meal::LUNCH      if hours.map{|x| (11...16).include? x }.include? true
      meals << Meal::DINNER     if hours.map{|x| (16...20).include? x }.include? true
      meals << Meal::LATE_NIGHT if hours.map do |x|
        (20...24).include?(x) || (0...5).include?(x)
      end.include? true

      meals
    end
  end

  def serialize
    { start:   start,
      stop:    stop,
      source:  provider.type,
      uuid:    uuid,
      meals:   meals,
      weekday: weekday,
      place:   place.serialize,
      truck:   truck.serialize,
      city:    city.serialize }
  end
end
