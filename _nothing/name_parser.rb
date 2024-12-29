class NameParser
  def initialize(filename)
    @filename = filename

    # Extension
    split = @filename.split(".")
    @extension = split.pop

    # Subdomain
    if split[0].match?(/\d{4}-\d{2}-\d{2}/) || split[0].match?(/today/) || split[0].match?(/tomorrow/) || split[0].match?(/(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/)
      @subdomain = split.shift
    else
      @subdomain = nil
    end

    # Domain
    @domain = split.shift
    
    # Repeat Logic
    if split[0].match?(/\d+[dwmy]/)
      @repeat_logic = split.shift
    end
  end

  def date_decorators
    # Iterate through and shift each character off the @subdomain and collect all that are not alphanumeric
    return @subdomain.chars.select { |char| !char.match?(/[a-zA-Z0-9\-\+]/) }
  end

  def date
    return "Not Implemented"
  end

  def time
    return "Not Implemented"
  end

  def notify
    return "Not Implemented"
  end

  def name_decorators
    return "Not Implemented"
  end

  def name
    return "Not Implemented"
  end

  def repeat_logic
    return "Not Implemented"
  end

  def extensions
    return "Not Implemented"
  end
end