class Message
  MSG = {}

  MSG[400] =
    "<strong>Bad Input</strong>: The input that you submitted is invalid. Please
    correct it and try again."

  MSG[413] =
    "<strong>Too Long</strong>: This form accepts a maximum of 1500 characters of text.
    Please reduce the amount of text and try again."

  def self.[](k)
    MSG[k]
  end
end

