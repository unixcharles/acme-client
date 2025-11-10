# frozen_string_literal: true

class Acme::Client::Resources::RenewalInfo
  attr_reader :suggested_window, :explanation_url, :retry_after

  def initialize(client, **arguments)
    @client = client
    assign_attributes(**arguments)
  end

  def suggested_window_start
    suggested_window&.fetch('start', nil)
  end

  def suggested_window_end
    suggested_window&.fetch('end', nil)
  end

  def suggested_renewal_time
    return nil unless suggested_window_start && suggested_window_end

    start_time = DateTime.rfc3339(suggested_window_start).to_time
    end_time = DateTime.rfc3339(suggested_window_end).to_time
    window_duration = end_time - start_time

    random_offset = rand(0.0..window_duration)
    selected_time = start_time + random_offset

    selected_time > Time.now ? selected_time : Time.now
  end

  def to_h
    {
      suggested_window: suggested_window,
      explanation_url: explanation_url,
      retry_after: retry_after
    }
  end

  private

  def assign_attributes(suggested_window:, explanation_url: nil, retry_after: nil)
    @suggested_window = suggested_window
    @explanation_url = explanation_url
    @retry_after = retry_after
  end
end
