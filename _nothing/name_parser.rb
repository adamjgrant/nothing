class NameParser
  def initialize(filename)
    @filename = filename

    # Extension
    split = @filename.split(".")
    @extension = split.pop

    # Subdomain
    if split[0].match?(/\d{4}-\d{2}-\d{2}/) || split[0].match?(/today/) || split[0].match?(/tomorrow/) || split[0].match?(/(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/) || split[0].match?(/\d+[dwmy]/)
      @subdomain = split.shift
    else
      @subdomain = nil
    end

    # Domain
    @domain = split.shift
    
    # Repeat Logic
    if split.length > 0
      @repeat_logic = split.shift
    end
  end

  def date_decorators
    # Iterate through and shift each character off the @subdomain and collect all that are not alphanumeric
    return [] if (@subdomain == nil || @subdomain == "")
    return @subdomain.chars.select { |char| !char.match?(/[a-zA-Z0-9\-\+]/) }
  end

  def date
    without_the_rest = @subdomain.split("+")[0]
    
    # Remove date_decorators
    without_decorators = without_the_rest.chars.select { |char| !self.date_decorators.include?(char) }.join
    return without_decorators if without_decorators.match?(/\d{4}-\d{2}-\d{2}/)

    # If without_decorators is "today" or "tomorrow", return the appropriate date
    if without_decorators == "today"
      return Date.today.strftime('%Y-%m-%d')
    elsif without_decorators == "tomorrow"
      return (Date.today + 1).strftime('%Y-%m-%d')
    end

    # If without_decorators is a day of the week, return the appropriate date
    if without_decorators.match?(/(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/)
      day_name = without_decorators
      target_wday = %w[sunday monday tuesday wednesday thursday friday saturday].index(day_name)
      today = Date.today
      today_wday = today.wday
      days_until_target = target_wday - today_wday
      days_until_target += 7 if days_until_target < 0
      return (today + days_until_target).strftime('%Y-%m-%d')
    end

    # If date is relative (number + d/w/m/y), calculate the date
    if without_decorators.match?(/\d+[dwmy]/)
      prefix = without_decorators
      number = prefix.match(/\d+/).to_s.to_i
      unit = prefix.match(/[dwmy]/).to_s
      date = case unit
             when 'd'
               Date.today + number
             when 'w'
               Date.today + (number * 7)
             when 'm'
               Date.today >> number # Add months
             when 'y'
               Date.today >> (number * 12) # Add years
             end
      return date.strftime('%Y-%m-%d')
    end
  end

  def time
    without_the_former = @subdomain.split("+")
    without_the_former.shift
    _time = without_the_former.join
    return nil if _time == ""
    return _time
  end

  def notify
    # Return true if the last character of @subdomain is a "+"
    return @subdomain[-1] == "+"
  end

  def name_decorators
    decorators = []
    chars = @domain.chars
    next_character = chars.shift
    while (!next_character.match?(/[a-zA-Z0-9\-\+]/) && chars.length > 0)
      decorators << next_character
      next_character = chars.shift
    end
    return decorators
  end

  def name
    # Return the domain minus the name_decorators
    return @domain.chars.select { |char| !self.name_decorators.include?(char) }.join
  end

  def repeat_logic
    return @repeat_logic
  end

  def extension
    return @extension
  end

  def modify_filename_with_time(modification_string)
    return "Not implemented"
  end
end