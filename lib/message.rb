# frozen_string_literal: true

class Message
  MSG = {}.freeze

  MSG[400] =
    "<strong>Bad Input</strong>: The input that you submitted is invalid. Please
    correct it and try again."

  MSG[404] =
    "<strong>Not Found</strong>: No resource was found that matched your
    request. Please correct the URL and try again."

  MSG[413] =
    "<strong>Too Long</strong>: The amount of text you have entered exceeds the
    maximum length we accept. Please reduce the amount of text and try again."

  MSG[414] =
    "<strong>Bad URL</strong>: The URL you have requested is too long. Please
    reduce the length and try again."

  MSG[500] =
    "<strong>Server Error</strong>: A server error occurred while processing
    your request."

  def self.[](key)
    MSG[key]
  end
end
