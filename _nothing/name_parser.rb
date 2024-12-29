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
    without_the_rest = @subdomain.split("+")[0]
    
    # Remove date_decorators
    without_decorators = without_the_rest.chars.select { |char| !self.date_decorators.include?(char) }.join
    return without_decorators

    # TODO convert human-readable dates to YYYY-MM-DD
  end

  def time
    without_the_former = @subdomain.split("+")
    without_the_former.shift
    _time = without_the_former.join
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
    return "Not Implemented"
  end

  def repeat_logic
    return "Not Implemented"
  end

  def extensions
    return "Not Implemented"
  end
end