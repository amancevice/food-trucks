module Like
  def like? name
    begin
      self.patterns.any?{|pattern| name =~ pattern }
    rescue
      self.name =~ name
    end
  end

  def =~ name
    self.like? name
  end
end
