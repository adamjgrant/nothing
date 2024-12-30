require "date"
require "time"

class NameParser
  def initialize(filename)
    @filename = filename

    @dow_regex = /(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/
    @standard_regex = /\d{4}-\d{2}-\d{2}/
    @relative_regex = /\d+[dwmy]/

    split = @filename.split(".")

    # Subdomain
    split_nd = split[0].gsub(/[^a-zA-Z0-9\-\+]+/, "")
    next_part_is_date_like = split_nd.match?(/^\d{4}-\d{2}-\d{2}/) || split_nd.match?(/^today/) || split_nd.match?(/^tomorrow/) || split_nd.match?(/^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/) || split_nd.match?(/^\d+[dwmy]/) 
    if next_part_is_date_like && split.length > 1
      @subdomain = split.shift
    else
      @subdomain = nil
    end

    # Domain
    @domain = split.shift
    
    # Repeat Logic
    if split.length > 0 && split[0].match?(@relative_regex)
      @repeat_logic = split.shift
    end

    if split.length > 0
      @extension = split.pop
    else
      @extension = nil
    end

    @subdomain_date_and_time = nil
    @date_decorators = nil
  end

  def date_decorators
    # Iterate through and shift each character off the @subdomain and collect all that are not alphanumeric
    return @date_decorators if @date_decorators
    return [] if (@subdomain == nil || @subdomain == "")
    return @subdomain.chars.select { |char| !char.match?(/[a-zA-Z0-9\-\+]/) }
  end

  def date_decorators=(new_decorators)
    @date_decorators = new_decorators
  end

  def date
    return nil if @subdomain == nil
    without_the_rest = @subdomain.split("+")[0]
    
    # Remove date_decorators
    without_decorators = without_the_rest.chars.select { |char| !self.date_decorators.include?(char) }.join
    # Extra assurance that no special characters still exist
    without_decorators.gsub!(/[^a-zA-Z0-9\-\+]/, "")
    if without_decorators.match?(@standard_regex)
      return without_decorators
    end

    # If without_decorators is "today" or "tomorrow", return the appropriate date
    if without_decorators == "today"
      return Date.today.strftime('%Y-%m-%d')
    elsif without_decorators == "tomorrow"
      return (Date.today + 1).strftime('%Y-%m-%d')
    end

    # If without_decorators is a day of the week, return the appropriate date
    if without_decorators.match?(@dow_regex)
      day_name = without_decorators
      target_wday = %w[sunday monday tuesday wednesday thursday friday saturday].index(day_name)
      today = Date.today
      today_wday = today.wday
      days_until_target = target_wday - today_wday
      days_until_target += 7 if days_until_target < 0
      return (today + days_until_target).strftime('%Y-%m-%d')
    end

    # If date is relative (number + d/w/m/y), calculate the date
    if without_decorators.match?(@relative_regex)
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
    return nil if @subdomain == nil
    without_the_former = @subdomain.split("+")
    without_the_former.shift
    _time = without_the_former.join
    return nil if _time == ""
    return _time
  end

  def notify
    # Return true if the last character of @subdomain is a "+"
    return false if @subdomain == nil
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
    # Parse the modification string
    match = modification_string.match(/^(\d+)?([dwmy])?/)
    day_match = modification_string.match(/^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/)
    today_tomorrow_match = modification_string.match(/^(today|tomorrow)/)
    new_time = modification_string.match(/(\+?\d+h?)$/)[1] if modification_string.match?(/(\+?\d+h?)$/)
    raise ArgumentError, "Invalid modification string: #{modification_string}" unless match || new_time || day_match || today_tomorrow_match

    # If it matches a day of the week, set the amount and unit accordingly
    if day_match
      # Calculate the amount by counting when the next occurence of the day would be from today.
      amount = %w[sunday monday tuesday wednesday thursday friday saturday].index(day_match[1]) - Date.today.wday
      unit = "d"
    elsif today_tomorrow_match
      if today_tomorrow_match[1] == "today"
        # Calculate the amount of days today is from self.date or if it doesn't exist, make it 0.
        starting_date = self.date ? Date.parse(self.date) : Date.today
        amount = starting_date - Date.today
      elsif today_tomorrow_match[1] == "tomorrow"
        # Calculate the amount of days tomorrow is from self.date or if it doesn't exist, make it 1.
        starting_date = self.date ? Date.parse(self.date) : Date.today
        amount = starting_date - Date.today + 1
      end
      unit = "d"
    else
      amount = match[1].to_i
      unit = match[2]
    end
  
    # new_time could be formatted as +1300 to set an explicit time
    # or +3h to set a time relative to the current time
    explicit_time = nil
    relative_time = nil
    base_time = self.time ? Time.strptime(self.time, "%H%M") : Time.now # Parse self.time or default to midnight
    
    if new_time && new_time.match?(/\+?\d+h/)
      found_relative_time = new_time.match(/(\d+)h/)[1].to_i  # Extract the number of hours
      relative_time = (base_time + found_relative_time * 3600).strftime('%H%M')  # Add hours and format to HHMM
    elsif new_time && new_time.match?(/\+\d{4}/)
      found_explicit_time = new_time.match(/\d{4}/)[0]
      base_time = Time.strptime(found_explicit_time, "%H%M") # Replace base_time with explicit time
      explicit_time = base_time.strftime("%H%M")
    end

    new_time_str = explicit_time || relative_time || self.time
  
    # Determine the starting date
    starting_date = self.date ? Date.parse(self.date) : Date.today
  
    # Increment the date based on the unit
    new_date = case unit
               when 'd' then starting_date + amount
               when 'w' then starting_date + (amount * 7)
               when 'm' then starting_date >> amount
               when 'y' then starting_date.next_year(amount)
               else
                 nil
               end

    if new_date.nil? && explicit_time.nil? && relative_time.nil?
      raise ArgumentError, "Unknown time unit: #{unit}"
    end

    # Create the new date string
    if new_date.nil?
      new_date_str = self.date || Date.today.strftime('%Y-%m-%d')
    else
      new_date_str = new_date.strftime('%Y-%m-%d')
    end

    # Construct the new filename
    new_date_component = new_time_str ? "#{new_date_str}+#{new_time_str}" : new_date_str

    self.subdomain_date_and_time = new_date_component
    return self.filename
  end

  def subdomain_date_and_time
    return @subdomain_date_and_time if @subdomain_date_and_time
    return "#{self.date}#{"+" if self.time}#{self.time}"
  end

  def subdomain_date_and_time=(new_date_and_time)
    @subdomain_date_and_time = new_date_and_time
  end

  def remove_date_decorators(decorators)
    @date_decorators = self.date_decorators - decorators
  end

  def add_date_decorators(decorators)
    @date_decorators = decorators + self.date_decorators
  end

  def filename
    return "#{self.date_decorators.join}#{self.subdomain_date_and_time}#{"+" if self.notify}.#{self.name_decorators.join}#{self.name}#{"." if self.repeat_logic}#{self.repeat_logic}#{"." if self.extension}#{self.extension}"
  end
end