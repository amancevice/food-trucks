module Day
  SUNDAY    = 'Sunday'
  MONDAY    = 'Monday'
  TUESDAY   = 'Tuesday'
  WEDNESDAY = 'Wednesday'
  THURSDAY  = 'Thursday'
  FRIDAY    = 'Friday'
  SATURDAY  = 'Saturday'

  class << self
    def all
      [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY]
    end
  end
end