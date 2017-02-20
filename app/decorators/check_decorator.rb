class CheckDecorator < SimpleDelegator
  include CheckHelper

  def current_status
    @__current_status ||= if record = current_metric
      return record['status_code'] if record['status_code'].present? && record['status_code'] != 0

      if record['status'] == "0" || record['error'] == true
        "Down"
      end
    else
      "Unknow"
    end
  end

  def mean_time(unit: :ms)
    result = influxdb.query "select mean(time_Total) from http_response where check_id = '#{id.to_s}' AND time > now() - 1h"
    if result&.first && m = result&.first['values']&.first['mean']
      "#{m.round(2)}ms"
    else
      "0ms"
    end
  end

  def uptime_stat
    uptime_1hour
  end

  def simple_line_chart_data(duration = 24, group = 5, label_step = 5)
    if result = influxdb.query("select mean(time_Total) from http_response where check_id = '#{id.to_s}' AND time > now() - #{duration}h GROUP BY time(#{group}m)").try(:first)
      {
        labels: result['values'].each_with_index.map { |p, i| i % label_step == 0 ? Time.parse(p['time']).strftime("%H:%M") : ''},
        series: [result['values'].map { |p| p['mean']&.round(2) || 0 }],
      }
    else
      { labels: [], series: [] }
    end
  end

  def last_hour_chart_data
    simple_line_chart_data(1, 1).to_json.html_safe
  end

  def last_day_chart_data
    simple_line_chart_data(24, 20, 5).to_json.html_safe
  end

  # Build histogram with 50ms step
  def last_day_distributed_chart_data(duration = 24)
    histogram = nil
    influxdb.query("select mean(time_Total) from http_response where check_id = '#{id.to_s}' AND time > now() - #{duration}h group by time(5m)") do |name, tag, points|
      histogram = Hash[*points.select { |p| p['mean'].present? }.
        map { |p| ((p['mean'] || 0).to_i / 50 ) * 50 }.
        group_by { |v| v }.
        flat_map { |k, v| [k, v.length] }].
        sort_by { |k| k }.flatten
    end

    if histogram
      {
        labels: histogram.each_with_index.select { |v, k| k % 2 == 0}.map { |e| "#{e.first}ms" },
        series: histogram.each_with_index.select { |v, k| k % 2 == 1}.map(&:first),
      }.to_json.html_safe
    else
      "{}"
    end
  end

  # Return chart data for last year uptime
  # The structure is organize into a 2 dimmension array
  # first index is the week. second index is day of week
  def last_year_uptime
    return @__last_year_uptime if @__last_year_uptime

    first_sunday = first_dow_one_year_ago
    @__last_year_uptime ||= Array.new(52) do |week|
      Array.new(7) do |day_of_week|
        shift = first_sunday + week.week + day_of_week.day
        OpenStruct.new(
          time: shift,
          up: '90%',
          summary: 'up',
          desc: "#{shift.year}/#{shift.month}/#{shift.day}: No down time",
          stat: ['up', 'down', 'slow'].sample
        )
      end
    end
  end

  private
  def influxdb
    @__c ||= Trinity::InfluxDB.client
  end

  def current_metric
    return @__current_metric if @__current_metric

    influxdb.query "select * from http_response where check_id = '#{id.to_s}' order by time desc limit 1" do |name, tags, points|
      @__current_metric = points.first
    end

    return @__current_metric
  end
end
